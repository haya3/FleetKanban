package ipc

import (
	"testing"
	"time"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// waitEvent reads one event with a timeout so a broken broker does not hang
// the test.
func waitEvent(t *testing.T, ch <-chan *task.AgentEvent) *task.AgentEvent {
	t.Helper()
	select {
	case ev := <-ch:
		return ev
	case <-time.After(500 * time.Millisecond):
		t.Fatal("timed out waiting for event")
		return nil
	}
}

func TestEventBroker_DeliversToAllSubscribers(t *testing.T) {
	b := NewEventBroker(16)

	const nSubs = 4
	chs := make([]<-chan *task.AgentEvent, nSubs)
	ids := make([]uint64, nSubs)
	for i := range chs {
		ids[i], chs[i] = b.Subscribe()
	}

	// Publish synchronously; because the per-sub buffer (16) exceeds the
	// number of events (5), no drops should occur.
	const nEvents = 5
	for i := 1; i <= nEvents; i++ {
		b.Publish(&task.AgentEvent{ID: "ev", TaskID: "t1", Seq: int64(i)})
	}

	for i, ch := range chs {
		for j := 1; j <= nEvents; j++ {
			ev := waitEvent(t, ch)
			if ev.Seq != int64(j) {
				t.Errorf("sub %d event %d: seq = %d, want %d", i, j, ev.Seq, j)
			}
		}
	}

	for _, id := range ids {
		b.Unsubscribe(id)
	}
	if n := b.Count(); n != 0 {
		t.Errorf("Count after unsubscribe: %d, want 0", n)
	}
}

func TestEventBroker_DropsOldestWhenBufferFull(t *testing.T) {
	b := NewEventBroker(2)
	_, ch := b.Subscribe()

	for i := 1; i <= 4; i++ {
		b.Publish(&task.AgentEvent{TaskID: "t", Seq: int64(i)})
	}

	// Read what is currently buffered. At most 2 items remain and they must
	// be the most recent seqs (oldest were dropped to admit newer).
	got := make([]int64, 0, 2)
	for {
		select {
		case ev := <-ch:
			got = append(got, ev.Seq)
		case <-time.After(50 * time.Millisecond):
			if len(got) > 2 {
				t.Fatalf("received %d events, want at most 2", len(got))
			}
			for _, s := range got {
				if s < 3 {
					t.Errorf("leaked old event seq=%d (want >= 3)", s)
				}
			}
			return
		}
	}
}

func TestEventBroker_PublishNilIsSafe(t *testing.T) {
	b := NewEventBroker(4)
	_, ch := b.Subscribe()
	b.Publish(nil)

	select {
	case ev := <-ch:
		t.Fatalf("unexpected event on nil publish: %+v", ev)
	case <-time.After(20 * time.Millisecond):
	}
}

func TestEventBroker_UnsubscribeStopsDelivery(t *testing.T) {
	b := NewEventBroker(4)
	id, ch := b.Subscribe()

	b.Publish(&task.AgentEvent{TaskID: "t", Seq: 1})
	ev := waitEvent(t, ch)
	if ev.Seq != 1 {
		t.Fatalf("seq = %d, want 1", ev.Seq)
	}

	b.Unsubscribe(id)

	// After Unsubscribe, the channel is closed. A closed channel receive
	// returns (zero, false) immediately.
	select {
	case ev, ok := <-ch:
		if ok {
			t.Fatalf("unexpected event after unsubscribe: %+v", ev)
		}
	case <-time.After(200 * time.Millisecond):
		t.Fatal("channel not closed after Unsubscribe")
	}
}
