package ipc

import (
	"google.golang.org/grpc"

	pb "github.com/haya3/FleetKanban/internal/ipc/gen/fleetkanban/v1"
)

// WatchEvents streams every persisted AgentEvent across all tasks until the
// client disconnects. Clients may pass since_seq_by_task to both suppress
// duplicates they already have and request a replay of events persisted
// after that seq: for each task id in the map, WatchEvents first sends
// every persisted event with seq > cutoff, then switches to live. Task ids
// absent from the map receive live events only (there is no snapshot to
// replay against; use ListTasks for the initial state).
//
// The replay closes the race where a status event fires on the sidecar
// between a reconnecting client's Subscribe arrival and broker.Subscribe
// actually registering the new channel — before this, those events were
// silently lost and the UI had to press Refresh to recover.
//
// Note on ordering: AgentEvent.Seq is monotonic per task, but this stream
// interleaves events across tasks. The client must bucket by task_id before
// applying seq-based ordering logic. Replayed and live events are deduped
// on the client using the same per-task seq watermark.
func (s *Server) WatchEvents(
	req *pb.WatchEventsRequest,
	stream grpc.ServerStreamingServer[pb.AgentEvent],
) error {
	id, ch := s.broker.Subscribe()
	defer s.broker.Unsubscribe(id)

	since := req.GetSinceSeqByTask() // nil when absent
	ctx := stream.Context()

	// Backfill persisted events whose seq > cutoff for each task the
	// client advertised a watermark for. Done AFTER Subscribe so any
	// event that lands mid-replay is also captured on the live channel
	// (the client dedupes by seq).
	//
	// We also bump `since` per task to the highest replayed seq so the
	// live filter below suppresses events the broker had already buffered
	// before Subscribe took effect — otherwise a client would see the
	// same status event twice per reconnect (once via replay, once via
	// the broker's per-subscriber backlog).
	if since == nil {
		since = map[string]int64{}
	}
	for taskID, cutoff := range since {
		events, err := s.app.TaskEvents(ctx, taskID, cutoff, 0 /* no limit */)
		if err != nil {
			// Non-fatal: a replay failure shouldn't drop the live
			// subscription. Log-less here because the Server struct does
			// not hold a logger; the client will still receive live
			// events and can fall back to ListTasks on its own.
			continue
		}
		highest := cutoff
		for _, ev := range events {
			if err := stream.Send(eventToPB(ev)); err != nil {
				return err
			}
			if ev.Seq > highest {
				highest = ev.Seq
			}
		}
		since[taskID] = highest
	}

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case ev, ok := <-ch:
			if !ok {
				return nil
			}
			if since != nil {
				if cutoff, present := since[ev.TaskID]; present && ev.Seq <= cutoff {
					continue
				}
			}
			if err := stream.Send(eventToPB(ev)); err != nil {
				return err
			}
		}
	}
}
