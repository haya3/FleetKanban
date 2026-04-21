//go:build windows

package ihr

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"regexp"
	"strings"
	"time"

	copilot "github.com/github/copilot-sdk/go"
)

// proposerTimeout caps a single proposer session. Kept well under
// orchestrator-level timeouts so a stuck proposer fails fast and the
// observation row (already inserted before we are invoked) stays as the
// authoritative evidence of what happened.
const proposerTimeout = 60 * time.Second

// copilotClient is the subset of *copilot.Client the proposer needs. Kept
// as a narrow interface so future implementations (e.g. a local NPU-backed
// model via Phi Silica) can slot in without plumbing a full SDK through.
type copilotClient interface {
	CreateSession(ctx context.Context, cfg *copilot.SessionConfig) (*copilot.Session, error)
}

// CopilotProposer is a PatchProposer backed by the Copilot SDK. Each
// ProposePatch call opens an ephemeral deny-writes session that is only
// allowed to read the current SKILL.md contents we hand it in the user
// message — the session has no working directory tied to user source so
// it cannot inspect task code or leak private files into its prompt.
//
// The proposer is intentionally conservative:
//   - Only frontmatter edits are requested (body stays verbatim).
//   - Patches over 50 touched lines are refused downstream in ApplyPatch.
//   - Ambiguous output (multiple diff blocks, wrong shape) is an error —
//     we'd rather skip the evolution than apply a mis-parsed diff.
type CopilotProposer struct {
	client  copilotClient
	model   string
	log     *slog.Logger
	timeout time.Duration
}

// CopilotProposerConfig configures a CopilotProposer.
type CopilotProposerConfig struct {
	// Client is the started SDK client. Required.
	Client copilotClient
	// Model is the Copilot model ID to use. Empty uses the SDK default
	// (the session will pick whatever the server serves first).
	Model string
	// Logger, nil allowed (slog.Default substituted).
	Logger *slog.Logger
	// Timeout overrides the default session cap.
	Timeout time.Duration
}

// NewCopilotProposer returns a CopilotProposer. Returns an error only on
// missing required config — network / auth failures surface later at
// ProposePatch time.
func NewCopilotProposer(cfg CopilotProposerConfig) (*CopilotProposer, error) {
	if cfg.Client == nil {
		return nil, errors.New("ihr: copilot proposer: client is required")
	}
	log := cfg.Logger
	if log == nil {
		log = slog.Default()
	}
	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = proposerTimeout
	}
	return &CopilotProposer{
		client:  cfg.Client,
		model:   cfg.Model,
		log:     log,
		timeout: timeout,
	}, nil
}

// proposerSystemPrompt is the contract with the LLM. Kept terse because
// the SDK will also prepend its own tool-catalog preamble — extra verbosity
// inflates every call's input-token cost.
const proposerSystemPrompt = `You are the self-evolution component of the FleetKanban NLAH harness.

Your job is to look at recent failed-review observations and propose a single
unified-diff patch to the YAML frontmatter of SKILL.md that would prevent the
observed class of failures from recurring.

Hard constraints:
1. Touch ONLY the YAML frontmatter (the block between the leading "---" fences). Never modify the Markdown body.
2. Preserve the APPROVE/REWORK semantics — do not delete stages, remove failure_taxonomy entries, or invert terminals.
3. Emit AT MOST ONE unified-diff fenced block (` + "```diff … ```" + `). No additional prose outside the block except a 1-2 sentence rationale BEFORE the block.
4. The diff must apply cleanly against the SKILL.md provided; keep 1-2 lines of context around each change.
5. Total changed lines (added + removed) must be at most 50. If you cannot improve things within that budget, reply with the exact text "NO_PATCH" and nothing else.

If you are not confident the change is an improvement, reply "NO_PATCH".`

// ProposePatch implements PatchProposer. Writes the current SKILL.md into
// a temporary working directory and points the session at it (deny-writes)
// so the LLM sees the concrete content without having access to real
// source code.
func (p *CopilotProposer) ProposePatch(ctx context.Context, current Charter, observations []Observation) (string, error) {
	if len(observations) == 0 {
		return "", nil
	}
	if strings.TrimSpace(current.RawContent) == "" {
		return "", errors.New("ihr: copilot proposer: charter has no raw content")
	}

	ctx, cancel := context.WithTimeout(ctx, p.timeout)
	defer cancel()

	// Stage the current SKILL.md in a scratch directory so the session has
	// a legitimate cwd. The deny-writes handler below keeps the session
	// from modifying it even if the model tries.
	workdir, err := os.MkdirTemp("", "fk-evolver-")
	if err != nil {
		return "", fmt.Errorf("ihr: copilot proposer: mkdtemp: %w", err)
	}
	defer func() { _ = os.RemoveAll(workdir) }()

	session, err := p.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            p.model,
		Streaming:        true,
		WorkingDirectory: workdir,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode:    "replace",
			Content: proposerSystemPrompt,
		},
		OnPermissionRequest: func(req copilot.PermissionRequest, _ copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
			// Deny every tool request. The prompt includes everything
			// the proposer needs; tool calls would only let a
			// misbehaving model explore the filesystem or hit the
			// network, which is out of scope for a frontmatter diff.
			return copilot.PermissionRequestResult{
				Kind: copilot.PermissionRequestResultKindDeniedByRules,
			}, nil
		},
	})
	if err != nil {
		return "", fmt.Errorf("ihr: copilot proposer: create session: %w", err)
	}
	defer func() { _ = session.Disconnect() }()

	idleCh := make(chan struct{})
	var idleOnce bool
	var transcript strings.Builder

	unsubscribe := session.On(func(e copilot.SessionEvent) {
		switch d := e.Data.(type) {
		case *copilot.AssistantMessageDeltaData:
			transcript.WriteString(d.DeltaContent)
		case *copilot.AssistantMessageData:
			// Final snapshot from a non-streaming code path — use it to
			// repair a transcript where deltas were never emitted (e.g.
			// the server only sent the final message). Writing the full
			// content on top of any buffered deltas would double-count,
			// so only fall back when no deltas arrived.
			if transcript.Len() == 0 {
				transcript.WriteString(d.Content)
			}
		case *copilot.SessionIdleData:
			if !idleOnce {
				idleOnce = true
				close(idleCh)
			}
		}
	})
	defer unsubscribe()

	if _, err := session.Send(ctx, copilot.MessageOptions{
		Prompt: buildProposerPrompt(current, observations),
	}); err != nil {
		return "", fmt.Errorf("ihr: copilot proposer: send: %w", err)
	}

	select {
	case <-idleCh:
	case <-ctx.Done():
		return "", ctx.Err()
	}

	reply := transcript.String()
	if strings.Contains(reply, "NO_PATCH") {
		p.log.Info("copilot proposer: model declined to propose patch",
			"observations", len(observations))
		return "", nil
	}
	patch, err := extractDiffBlock(reply)
	if err != nil {
		return "", err
	}
	return patch, nil
}

// diffBlockRE matches a single fenced diff block. Requires the opening
// fence to be "```diff" (the prompt asks for that exact shape) so we
// don't accidentally grab an unrelated fenced block.
var diffBlockRE = regexp.MustCompile("(?s)```diff\\s*\\n(.*?)```")

// extractDiffBlock returns the unified diff body from reply. Returns an
// error when zero or multiple blocks are present — both are shapes the
// caller should treat as "model misbehaved, drop this evolution attempt".
func extractDiffBlock(reply string) (string, error) {
	matches := diffBlockRE.FindAllStringSubmatch(reply, -1)
	if len(matches) == 0 {
		return "", errors.New("ihr: copilot proposer: no ```diff block in reply")
	}
	if len(matches) > 1 {
		return "", fmt.Errorf("ihr: copilot proposer: expected 1 ```diff block, got %d", len(matches))
	}
	body := strings.TrimSpace(matches[0][1])
	if body == "" {
		return "", errors.New("ihr: copilot proposer: empty ```diff block")
	}
	return body, nil
}

// buildProposerPrompt folds the current SKILL.md and observation list
// into a single user message. Observations are serialised as JSON to keep
// the shape unambiguous for the model — free-form text tends to get
// rearranged under summarisation.
func buildProposerPrompt(current Charter, observations []Observation) string {
	obsJSON, _ := json.MarshalIndent(observations, "", "  ")
	return fmt.Sprintf(`Current SKILL.md content:

`+"```markdown"+`
%s
`+"```"+`

Recent failed-review observations (JSON):

`+"```json"+`
%s
`+"```"+`

Propose a single unified-diff patch to the YAML frontmatter, or reply NO_PATCH.`,
		current.RawContent, string(obsJSON))
}
