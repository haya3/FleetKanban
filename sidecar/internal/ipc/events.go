package ipc

import (
	"google.golang.org/grpc"

	pb "github.com/FleetKanban/fleetkanban/internal/ipc/gen/fleetkanban/v1"
)

// WatchEvents streams every persisted AgentEvent across all tasks until the
// client disconnects. Clients may pass since_seq_by_task to suppress events
// whose seq is already known after a reconnect; any task id not in the map
// receives every future event (no backfill — use TaskEvents for that).
//
// Note on ordering: AgentEvent.Seq is monotonic per task, but this stream
// interleaves events across tasks. The client must bucket by task_id before
// applying seq-based ordering logic.
func (s *Server) WatchEvents(
	req *pb.WatchEventsRequest,
	stream grpc.ServerStreamingServer[pb.AgentEvent],
) error {
	id, ch := s.broker.Subscribe()
	defer s.broker.Unsubscribe(id)

	since := req.GetSinceSeqByTask() // nil when absent
	ctx := stream.Context()

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
