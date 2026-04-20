package ctxmem

import (
	"sync"
	"sync/atomic"
	"time"
)

// ChangeEvent is one update worth pushing to active WatchContextChanges
// or WatchPending subscribers. Kind is "node" / "edge" / "fact" /
// "scratchpad" / "analyzer" so the UI can filter without parsing ID
// prefixes. Seq is globally monotonic (not per-kind) — easier for
// subscribers to resume with a single cursor.
type ChangeEvent struct {
	Seq        int64
	Kind       string
	Op         string
	ID         string
	RepoID     string
	Message    string // human-readable detail (error text for op=error, stats etc)
	OccurredAt time.Time
}

// ChangeBroker fans a ChangeEvent out to all active subscribers.
// Non-blocking publish: a slow subscriber drops events rather than
// back-pressuring the writer path. Default per-subscriber buffer is
// 256, enough for a typical analyzer run (~50 entries) without
// flooding.
type ChangeBroker struct {
	mu      sync.RWMutex
	next    atomic.Uint64
	subs    map[uint64]chan *ChangeEvent
	buffer  int
	counter atomic.Int64
}

// NewChangeBroker returns a broker with per-subscriber buffer size.
// Pass 0 for the default (256).
func NewChangeBroker(buffer int) *ChangeBroker {
	if buffer <= 0 {
		buffer = 256
	}
	return &ChangeBroker{
		subs:   map[uint64]chan *ChangeEvent{},
		buffer: buffer,
	}
}

// Publish dispatches evt to every current subscriber. Seq is assigned
// from a monotonic counter; callers should not pre-populate it.
func (b *ChangeBroker) Publish(evt *ChangeEvent) {
	if evt == nil {
		return
	}
	if evt.Seq == 0 {
		evt.Seq = b.counter.Add(1)
	}
	if evt.OccurredAt.IsZero() {
		evt.OccurredAt = time.Now().UTC()
	}
	b.mu.RLock()
	defer b.mu.RUnlock()
	for _, ch := range b.subs {
		select {
		case ch <- evt:
		default:
			// Drop oldest by dequeueing one, then retry once.
			select {
			case <-ch:
			default:
			}
			select {
			case ch <- evt:
			default:
			}
		}
	}
}

// Subscribe returns (id, recv-only channel). The caller must call
// Unsubscribe when done.
func (b *ChangeBroker) Subscribe() (uint64, <-chan *ChangeEvent) {
	id := b.next.Add(1)
	ch := make(chan *ChangeEvent, b.buffer)
	b.mu.Lock()
	b.subs[id] = ch
	b.mu.Unlock()
	return id, ch
}

// Unsubscribe removes the subscriber and closes its channel.
func (b *ChangeBroker) Unsubscribe(id uint64) {
	b.mu.Lock()
	defer b.mu.Unlock()
	ch, ok := b.subs[id]
	if !ok {
		return
	}
	delete(b.subs, id)
	close(ch)
}
