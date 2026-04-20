package analyzer

import "testing"

// TestParseAnalyzerOutputHandlesCleanJSON — the canonical happy path
// where the LLM returns a bare JSON object.
func TestParseAnalyzerOutputHandlesCleanJSON(t *testing.T) {
	raw := `{"entries":[
		{"kind":"Concept","label":"event sourcing","content_md":"# ES","confidence":0.8,"signals":["foo"]},
		{"kind":"Decision","label":"SQLite","content_md":"# SQLite","confidence":0.9}
	]}`
	entries, err := parseAnalyzerOutput(raw)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(entries) != 2 {
		t.Fatalf("want 2 entries, got %d", len(entries))
	}
	if entries[0].ProposedLabel != "event sourcing" {
		t.Errorf("unexpected label: %q", entries[0].ProposedLabel)
	}
	if entries[0].Confidence != 0.8 {
		t.Errorf("confidence roundtrip failed: %f", entries[0].Confidence)
	}
}

// TestParseAnalyzerOutputStripsFences — the LLM often wraps the JSON
// in ```json ... ``` fences despite instructions; the parser must
// tolerate that.
func TestParseAnalyzerOutputStripsFences(t *testing.T) {
	raw := "```json\n{\"entries\":[{\"kind\":\"Module\",\"label\":\"auth\",\"content_md\":\"\"}]}\n```"
	entries, err := parseAnalyzerOutput(raw)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("want 1 entry, got %d", len(entries))
	}
}

// TestParseAnalyzerOutputTolerantOfTrailingFence — the model often
// follows a valid JSON body with a closing ``` fence and additional
// prose. json.Decoder reads exactly one top-level value and stops,
// so trailing content must not produce
// "invalid character '`' after top-level value".
func TestParseAnalyzerOutputTolerantOfTrailingFence(t *testing.T) {
	raw := "Here is the summary:\n\n```json\n" +
		`{"entries":[{"kind":"Module","label":"x","content_md":""}]}` +
		"\n```\n\nSome trailing prose with `code` backticks."
	entries, err := parseAnalyzerOutput(raw)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("want 1 entry, got %d", len(entries))
	}
}

// TestParseAnalyzerOutputTolerantOfBraceInString — content_md often
// contains literal `}` characters (e.g. code snippets). LastIndex-
// based parsing would slice past the JSON's actual close; json.Decoder
// respects string boundaries and reads only the first top-level value.
func TestParseAnalyzerOutputTolerantOfBraceInString(t *testing.T) {
	raw := `{"entries":[{"kind":"Class","label":"Foo","content_md":"Closes with } then more"}]}` +
		"\n\nTrailing: } } }"
	entries, err := parseAnalyzerOutput(raw)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("want 1 entry, got %d", len(entries))
	}
}

// TestParseAnalyzerOutputAcceptsArrayAttrs — the LLM sometimes emits
// attr values as arrays or objects despite the map[string,string]
// contract. The parser must stringify them via JSON rather than
// failing the whole run.
func TestParseAnalyzerOutputAcceptsArrayAttrs(t *testing.T) {
	raw := `{"entries":[{"kind":"Module","label":"auth","attrs":{` +
		`"tags":["security","oauth"],"port":8080,"enabled":true,"nested":{"k":1}` +
		`}}]}`
	entries, err := parseAnalyzerOutput(raw)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("want 1 entry, got %d", len(entries))
	}
	attrs := entries[0].ProposedAttrs
	if attrs["tags"] != `["security","oauth"]` {
		t.Errorf("tags: got %q", attrs["tags"])
	}
	if attrs["port"] != "8080" {
		t.Errorf("port: got %q", attrs["port"])
	}
	if attrs["enabled"] != "true" {
		t.Errorf("enabled: got %q", attrs["enabled"])
	}
	if attrs["nested"] != `{"k":1}` {
		t.Errorf("nested: got %q", attrs["nested"])
	}
}

// TestParseAnalyzerOutputSkipsInvalidRows — entries missing required
// fields (kind/label) are silently dropped rather than failing the
// whole run.
func TestParseAnalyzerOutputSkipsInvalidRows(t *testing.T) {
	raw := `{"entries":[
		{"kind":"","label":"no kind"},
		{"kind":"Concept","label":""},
		{"kind":"Concept","label":"good"}
	]}`
	entries, err := parseAnalyzerOutput(raw)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("want 1 valid entry, got %d", len(entries))
	}
}
