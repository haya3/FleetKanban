package ipc

import (
	"context"

	"github.com/haya3/FleetKanban/internal/store"

	pb "github.com/haya3/FleetKanban/internal/ipc/gen/fleetkanban/v1"
)

// GetInsights implements InsightsService.GetInsights. The handler is a thin
// adapter: app.Service.GetInsights returns a store.InsightsSummary struct
// which we convert to protobuf row-for-row. Nothing here performs I/O of
// its own beyond the app-layer call.
func (s *Server) GetInsights(ctx context.Context, req *pb.GetInsightsRequest) (*pb.InsightsSummary, error) {
	sum, err := s.app.GetInsights(ctx, req.GetRepositoryId())
	if err != nil {
		return nil, mapAppError(err)
	}
	return insightsSummaryToPB(sum), nil
}

func insightsSummaryToPB(s *store.InsightsSummary) *pb.InsightsSummary {
	if s == nil {
		return &pb.InsightsSummary{}
	}
	out := &pb.InsightsSummary{
		TotalTasks:            int32(s.TotalTasks),
		ActiveTasks:           int32(s.ActiveTasks),
		DoneTasks:             int32(s.DoneTasks),
		CancelledTasks:        int32(s.CancelledTasks),
		AbortedTasks:          int32(s.AbortedTasks),
		FailedTasks:           int32(s.FailedTasks),
		CompletedSamples:      int32(s.CompletedSamples),
		AvgDurationSeconds:    s.AvgDurationSeconds,
		MedianDurationSeconds: s.MedianDurationSeconds,
		P90DurationSeconds:    s.P90DurationSeconds,
		CompletionRate:        s.CompletionRate,
	}
	for _, b := range s.ReworkBuckets {
		out.ReworkBuckets = append(out.ReworkBuckets, &pb.ReworkBucket{
			ReworkCount: int32(b.ReworkCount),
			TaskCount:   int32(b.TaskCount),
		})
	}
	for _, b := range s.FailureBuckets {
		out.FailureBuckets = append(out.FailureBuckets, &pb.FailureBucket{
			ErrorCode: b.ErrorCode,
			Count:     int32(b.Count),
		})
	}
	for _, r := range s.Repositories {
		out.Repositories = append(out.Repositories, &pb.RepositoryInsight{
			RepositoryId:       r.RepositoryID,
			DisplayName:        r.DisplayName,
			Total:              int32(r.Total),
			Done:               int32(r.Done),
			Failed:             int32(r.Failed),
			Aborted:            int32(r.Aborted),
			Cancelled:          int32(r.Cancelled),
			CompletionRate:     r.CompletionRate,
			AvgDurationSeconds: r.AvgDurationSeconds,
		})
	}
	for _, d := range s.DailyThroughput {
		out.DailyThroughput = append(out.DailyThroughput, &pb.DailyThroughput{
			Date:      d.Date,
			Completed: int32(d.Completed),
			Failed:    int32(d.Failed),
		})
	}
	return out
}
