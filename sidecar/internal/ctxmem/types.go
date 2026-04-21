// Package ctxmem implements FleetKanban's Context / Graph Memory subsystem.
//
// Structured knowledge about each registered repository is kept as a
// property graph (Node + Edge + Closure), vector embeddings, bi-temporal
// facts, a trust-gate pending queue (Scratchpad), and per-repo settings.
// Retrieval is hybrid: FTS5 BM25 + in-Go cosine similarity + graph
// neighborhood boost, fused via Reciprocal Rank Fusion. The result feeds
// a three-tier prompt injection pipeline (Passive / Reactive / Active)
// that prepends memory to Copilot sessions.
//
// The directory is named ctxmem rather than context to avoid clashing
// with the standard library's context package when files elsewhere pass
// around ctx values.
package ctxmem

import "time"

// Canonical node kinds. The retrieval / injection layers special-case
// some of these (e.g. Decision weighted higher in Passive injection),
// but the schema accepts arbitrary strings so domain-specific kinds can
// be introduced without a migration.
const (
	NodeKindFile       = "File"
	NodeKindModule     = "Module"
	NodeKindFunction   = "Function"
	NodeKindClass      = "Class"
	NodeKindConcept    = "Concept"
	NodeKindDecision   = "Decision"
	NodeKindConstraint = "Constraint"
	NodeKindTag        = "Tag"
	NodeKindTask       = "Task"
)

// Canonical edge relationships.
const (
	EdgeRelImports        = "imports"
	EdgeRelCalls          = "calls"
	EdgeRelContains       = "contains"
	EdgeRelDependsOn      = "dependsOn"
	EdgeRelRelatedTo      = "relatedTo"
	EdgeRelConflictsWith  = "conflictsWith"
	EdgeRelCoAccessedWith = "coAccessedWith"
	EdgeRelSupersedes     = "supersedes"
	EdgeRelTagged         = "tagged"
)

// Source kinds for both Node and ScratchpadEntry.
const (
	SourceManual         = "manual"
	SourceObserver       = "observer"
	SourceAnalyzer       = "analyzer"
	SourceStaticAnalysis = "static-analysis"
	SourceSessionSummary = "session-summary"
)

// Scratchpad status values.
const (
	ScratchpadPending  = "pending"
	ScratchpadPromoted = "promoted"
	ScratchpadRejected = "rejected"
	ScratchpadSnoozed  = "snoozed"
)

// Node is one entity in the property graph. Content is Markdown that is
// rendered directly in the Browse tab and serialized into injected
// prompts. Attrs is kind-specific metadata (File nodes carry path /
// language; Decision nodes carry decision_id / rationale_url, etc.).
type Node struct {
	ID              string
	RepoID          string
	Kind            string
	Label           string
	ContentMD       string
	Attrs           map[string]string
	SourceKind      string
	SourceTaskID    string
	SourceSessionID string
	Confidence      float32
	Enabled         bool
	Pinned          bool
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

// Edge is one directed relationship. Attrs can carry rel-specific
// metadata (e.g. a calls edge may carry "call_site_path" + "line").
type Edge struct {
	ID        string
	RepoID    string
	SrcNodeID string
	DstNodeID string
	Rel       string
	Attrs     map[string]string
	CreatedAt time.Time
}

// Fact is a bi-temporal predicate anchored on a subject node.
// ValidTo == zero means the fact is still active. Supersedes links to
// the ID of the fact this one replaces so the Facts Timeline can render
// succession chains.
type Fact struct {
	ID            string
	RepoID        string
	SubjectNodeID string
	Predicate     string
	ObjectText    string
	ValidFrom     time.Time
	ValidTo       time.Time
	Supersedes    string
	CreatedAt     time.Time
}

// ScratchpadEntry is a pending memory candidate awaiting the trust gate.
// Observer and analyzer push entries; users promote / reject / edit /
// snooze them from the Context Scratchpad tab.
type ScratchpadEntry struct {
	ID                string
	RepoID            string
	ProposedKind      string
	ProposedLabel     string
	ProposedContentMD string
	ProposedAttrs     map[string]string
	SourceKind        string
	SourceRef         string
	Signals           []string
	Confidence        float32
	Status            string
	RejectReason      string
	SnoozedUntil      time.Time
	PromotedNodeID    string
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

// Vector is a named embedding attached to a node. Dim is redundant with
// len(Vector) but persisted so legacy / partial rows can be detected
// without a float32 roundtrip.
type Vector struct {
	NodeID    string
	Model     string
	Dim       int
	Vector    []float32
	CreatedAt time.Time
}

// Settings is the per-repo memory configuration. Enabled=false is the
// default — Memory is opt-in, matching FleetKanban's "no autonomous
// action" philosophy.
type Settings struct {
	RepoID                    string
	Enabled                   bool
	EmbeddingProvider         string
	EmbeddingModel            string
	EmbeddingDim              int
	LLMProvider               string
	LLMModel                  string
	PassiveTokenBudget        int
	TopKNeighbors             int
	AutoPromoteHighConfidence bool
	AutoPromoteThreshold      float32
	UpdatedAt                 time.Time
}

// DefaultSettings returns the baseline Settings for a newly registered
// repository. Enabled=false so Memory contributes nothing until the user
// explicitly turns it on in the Settings page.
//
// LLMModel defaults to empty so the analyzer picks whatever the Copilot
// CLI advertises first — hardcoding a specific model id (e.g.
// "gpt-4o-mini") breaks on accounts whose plan does not expose that
// model. The user can still override in Settings → Memory.
func DefaultSettings(repoID string) Settings {
	return Settings{
		RepoID:                    repoID,
		Enabled:                   false,
		EmbeddingProvider:         "ollama",
		EmbeddingModel:            "nomic-embed-text",
		EmbeddingDim:              768,
		LLMProvider:               "copilot",
		LLMModel:                  "",
		PassiveTokenBudget:        3000,
		TopKNeighbors:             8,
		AutoPromoteHighConfidence: false,
		AutoPromoteThreshold:      0.9,
	}
}

// SearchHit is one result returned by the retrieval pipeline. Channel
// identifies where the hit surfaced so the Search tab can explain its
// ranking to the user.
type SearchHit struct {
	Node    Node
	Score   float32
	Rank    int
	Channel string // "semantic" | "keyword" | "graph-boost" | "fused"
	Reason  string
}

// SearchResult is the hybrid search response, bucketed by channel so
// the UI can display all three alongside the fused verdict.
type SearchResult struct {
	Channels    map[string][]SearchHit
	TotalUnique int
}

// Overview aggregates Memory statistics for a single repo, shown on
// the Context Overview tab. Byte sizes approximate on-disk storage.
type Overview struct {
	RepoID                  string
	NodeCountsByKind        map[string]int32
	EdgeCountsByRel         map[string]int32
	ActiveFactCount         int32
	ExpiredFactCount        int32
	PendingScratchpadCount  int32
	PromotedScratchpadCount int32
	RejectedScratchpadCount int32
	VectorCount             int32
	VectorDim               int32
	VectorBytes             int64
	ObservedSessionCount    int32
	Enabled                 bool
}

// TaskSuggestion is one finalized Task surfaced as a similar-task
// candidate on the New Task dialog. Carries the originating taskID so
// the UI can deep-link back to the task row in Kanban.
type TaskSuggestion struct {
	NodeID       string
	Label        string
	SummaryMD    string
	Score        float32
	SourceTaskID string
}

// NodeSummary is the slimmer companion of TaskSuggestion used for
// Decision / Constraint hits. Purpose-built for the New Task dialog —
// Browse uses Node directly for editing.
type NodeSummary struct {
	NodeID    string
	Kind      string
	Label     string
	ContentMD string
	Score     float32
}

// SuggestionBundle is the response of SuggestForNewTask. Bucketed by
// kind so the UI can render three discrete sections (similar past
// tasks, applicable decisions, binding constraints) instead of a
// single mixed list.
type SuggestionBundle struct {
	SimilarTasks       []TaskSuggestion
	RelatedDecisions   []NodeSummary
	RelatedConstraints []NodeSummary
}

// MemoryHealth is a light snapshot of the Memory subsystem suitable for
// sub-second polling by the Settings panel and Kanban badge. Distinct
// from Overview, which aggregates heavier counts across every node
// kind + scratchpad status.
type MemoryHealth struct {
	Enabled           bool
	ProviderReachable bool
	VectorCount       int32
	LastRebuildAt     time.Time
	LastError         string
}

// InjectionSource records one memory item that contributed to an
// assembled prompt block. Surfaced in the Injection Preview sidebar.
type InjectionSource struct {
	SourceType string // "node" | "fact"
	SourceRef  string
	Label      string
	Channel    string // "passive" | "reactive" | "active"
	Tokens     int32
	Relevance  float32
}

// InjectionPreview is what PreviewInjection and the three BuildXxx
// functions in the inject package return. SystemPrompt is the
// Markdown block ready to prepend; empty when Memory is disabled.
type InjectionPreview struct {
	SystemPrompt    string
	Sources         []InjectionSource
	EstimatedTokens int32
	Tier            string
}

// NodeDetail bundles a node with its adjacent edges / neighbors / facts
// for the Browse detail pane. Returned by Service.GetNode so the UI
// can render the detail view in a single round-trip.
type NodeDetail struct {
	Node            Node
	OutEdges        []Edge
	InEdges         []Edge
	Neighbors       []Node
	Facts           []Fact
	SourceTaskID    string
	SourceSessionID string
}
