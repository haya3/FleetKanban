package orchestrator

import (
	"context"
	"testing"

	"github.com/haya3/fleetkanban/internal/task"
)

func TestSetConcurrency_Clamps(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}

	noopRunner := runnerFn(func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		close(out)
		return nil
	})

	o := newOrch(t, ts, es, wt, noopRunner, 4)

	if got := o.SetConcurrency(1000); got != ConcurrencyMax {
		t.Errorf("clamp high: got %d want %d", got, ConcurrencyMax)
	}
	if got := o.SetConcurrency(0); got != ConcurrencyMin {
		t.Errorf("clamp low: got %d want %d", got, ConcurrencyMin)
	}
	if got := o.SetConcurrency(3); got != 3 {
		t.Errorf("passthrough: got %d want 3", got)
	}
	if got := o.Concurrency(); got != 3 {
		t.Errorf("Concurrency(): got %d want 3", got)
	}
}
