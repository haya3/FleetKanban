//go:build windows

package ihr

import (
	"fmt"
	"strings"
)

// StageState is the data the interpreter receives after each stage completes.
// Fields are populated by dispatcher.go from orchestrator results.
type StageState struct {
	CurrentStage        string
	PlanSubtaskCount    int    // populated after plan stage
	AllSubtasksTerminal bool   // populated after code stage
	Decision            string // review result: APPROVE | REWORK | ""
	ReworkCount         int    // current rework iteration count
}

// NextStage evaluates the Charter's transitions table against s and returns
// the next stage (or terminal) and whether that destination is terminal.
//
// The evaluator is purely deterministic — no LLM calls. It supports the
// five expression patterns defined in harness-skill/SKILL.md:
//
//  1. plan_json.subtasks.length > 0
//  2. all_subtasks_terminal
//  3. decision == "APPROVE"
//  4. decision == "REWORK" && rework_count < max_rework_count
//  5. rework_count >= max_rework_count  (or as part of a disjunction)
//
// Conjunctions (&&) and disjunctions (||) between these atoms are also
// handled. Evaluation is left-to-right with equal precedence for && and ||.
// For the current SKILL.md schema this is sufficient; a full expression
// parser is unnecessary.
func (c *Charter) NextStage(s StageState) (nextStage string, terminal bool, err error) {
	for _, tr := range c.Transitions {
		if tr.From != s.CurrentStage {
			continue
		}
		matched, evalErr := evalWhen(tr.When, s, c.MaxReworkCount)
		if evalErr != nil {
			return "", false, fmt.Errorf("ihr: eval transition from=%q to=%q: %w",
				tr.From, tr.To, evalErr)
		}
		if matched {
			return tr.To, validTerminals[tr.To], nil
		}
	}
	return "", false, fmt.Errorf("ihr: no matching transition from stage %q (state: %+v)",
		s.CurrentStage, s)
}

// evalWhen evaluates a single when expression string against the given state.
// Supported atoms are listed in NextStage's doc comment.
func evalWhen(expr string, s StageState, maxRework int) (bool, error) {
	expr = strings.TrimSpace(expr)
	if expr == "" {
		return false, nil
	}

	// Split on || first (lowest precedence).
	orParts := splitOp(expr, "||")
	if len(orParts) > 1 {
		for _, part := range orParts {
			v, err := evalAnd(strings.TrimSpace(part), s, maxRework)
			if err != nil {
				return false, err
			}
			if v {
				return true, nil
			}
		}
		return false, nil
	}

	return evalAnd(expr, s, maxRework)
}

// evalAnd evaluates a conjunction of atoms.
func evalAnd(expr string, s StageState, maxRework int) (bool, error) {
	andParts := splitOp(expr, "&&")
	for _, part := range andParts {
		v, err := evalAtom(strings.TrimSpace(part), s, maxRework)
		if err != nil {
			return false, err
		}
		if !v {
			return false, nil
		}
	}
	return true, nil
}

// splitOp splits expr on the literal operator op, but only at top level
// (not inside quoted strings). For the SKILL.md expressions this is
// straightforward: no nested parens, no quoted operators.
func splitOp(expr, op string) []string {
	var parts []string
	for {
		idx := strings.Index(expr, op)
		if idx < 0 {
			parts = append(parts, expr)
			break
		}
		parts = append(parts, expr[:idx])
		expr = expr[idx+len(op):]
	}
	return parts
}

// evalAtom evaluates a single boolean atom from the supported vocabulary.
func evalAtom(atom string, s StageState, maxRework int) (bool, error) {
	atom = strings.TrimSpace(atom)

	switch {
	// plan_json.subtasks.length > 0
	case atom == "plan_json.subtasks.length > 0":
		return s.PlanSubtaskCount > 0, nil

	// all_subtasks_terminal
	case atom == "all_subtasks_terminal":
		return s.AllSubtasksTerminal, nil

	// decision == "APPROVE"
	case atom == `decision == "APPROVE"`:
		return s.Decision == "APPROVE", nil

	// decision == "REWORK"
	case atom == `decision == "REWORK"`:
		return s.Decision == "REWORK", nil

	// rework_count < max_rework_count
	case atom == "rework_count < max_rework_count":
		return s.ReworkCount < maxRework, nil

	// rework_count >= max_rework_count
	case atom == "rework_count >= max_rework_count":
		return s.ReworkCount >= maxRework, nil

	default:
		return false, fmt.Errorf("unrecognised expression atom: %q", atom)
	}
}
