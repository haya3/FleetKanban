package ipc

import (
	"sync"
	"sync/atomic"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// EventBroker fans a single AgentEvent stream (from the orchestrator) out to
// N concurrent gRPC WatchEvents subscribers. The orchestrator's Sink is a
// synchronous non-blocking callback, so the broker must never block: per-sub
// channels are buffered and a full buffer drops the oldest events (the
// subscriber can resync via TaskEvents with since_seq).
//
// Subscribers are identified by an opaque uint64 so unsubscribe is O(1).
type EventBroker struct {
	mu     sync.RWMutex
	nextID atomic.Uint64
	subs   map[uint64]chan *task.AgentEvent

	// bufSize controls the per-subscriber channel capacity. Bursts above this
	// cause the oldest events to be dropped for that subscriber.
	bufSize int
}

// NewEventBroker returns a broker with the given per-subscriber buffer.
// 1024 matches orchestrator's default event channel so a fast client should
// almost never lose events in practice.
func NewEventBroker(bufSize int) *EventBroker {
	if bufSize <= 0 {
		bufSize = 1024
	}
	return &EventBroker{
		subs:    make(map[uint64]chan *task.AgentEvent),
		bufSize: bufSize,
	}
}

// Publish delivers e to every current subscriber. Non-blocking: if a
// subscriber's buffer is full, the broker drops one old event to make room
// for the new one so the subscriber always sees the latest. Safe for
// concurrent use from the orchestrator dispatch goroutine.
func (b *EventBroker) Publish(e *task.AgentEvent) {
	if e == nil {
		return
	}
	b.mu.RLock()
	defer b.mu.RUnlock()
	for _, ch := range b.subs {
		select {
		case ch <- e:
		default:
			// Buffer full: discard the oldest, enqueue the newest. The
			// subscriber can use TaskEvents(since_seq) to recover any gap.
			select {
			case <-ch:
			default:
			}
			select {
			case ch <- e:
			default:
			}
		}
	}
}

// Subscribe registers a new subscriber and returns (id, recvChan). The caller
// owns the channel's lifetime via Unsubscribe.
func (b *EventBroker) Subscribe() (uint64, <-chan *task.AgentEvent) {
	id := b.nextID.Add(1)
	ch := make(chan *task.AgentEvent, b.bufSize)
	b.mu.Lock()
	b.subs[id] = ch
	b.mu.Unlock()
	return id, ch
}

// Unsubscribe removes the subscriber and closes its channel.
func (b *EventBroker) Unsubscribe(id uint64) {
	b.mu.Lock()
	ch, ok := b.subs[id]
	if ok {
		delete(b.subs, id)
	}
	b.mu.Unlock()
	if ok {
		close(ch)
	}
}

// Count returns the current subscriber count (used by tests / diagnostics).
func (b *EventBroker) Count() int {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return len(b.subs)
}

// Sink returns a function suitable for orchestrator.Config.Sink. The returned
// closure holds a reference to b; callers keep the broker alive for the
// orchestrator's lifetime.
func (b *EventBroker) Sink() func(*task.AgentEvent) {
	return b.Publish
}
