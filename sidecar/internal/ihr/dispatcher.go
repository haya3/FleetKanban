//go:build windows

package ihr

import "context"

// StageCallbacks abstracts the existing Orchestrator stage implementations.
// Phase B後半で orchestrator 側が実装する。今 phase では interface 定義のみ。
// The orchestrator's runPlanningPhase / runSubtaskLoop / runAIReview methods
// will satisfy this interface once the integration step wires them up.
type StageCallbacks interface {
	RunPlan(ctx context.Context, taskID string) (*PlanResult, error)
	RunCode(ctx context.Context, taskID string) (*CodeResult, error)
	RunReview(ctx context.Context, taskID string) (*ReviewResult, error)
}

// PlanResult carries the outputs of the plan stage.
type PlanResult struct {
	SubtaskCount  int
	PlanJSONBytes []byte
}

// CodeResult carries the outputs of the code stage.
type CodeResult struct {
	AllTerminal bool
}

// ReviewResult carries the outputs of the review stage.
type ReviewResult struct {
	Decision   string // APPROVE | REWORK
	FeedbackMD string
}
