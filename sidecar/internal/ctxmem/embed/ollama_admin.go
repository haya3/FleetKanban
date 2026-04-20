package embed

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"runtime"
	"time"
)

// OllamaAdmin talks to the local Ollama server for onboarding UI
// (status / model list / model pull with streaming progress). It is a
// thin HTTP client rather than an MCP-style wrapper: the sidecar
// speaks to Ollama directly so the UI never touches HTTP.
type OllamaAdmin struct {
	baseURL string
	http    *http.Client
}

// NewOllamaAdmin constructs an admin client. baseURL defaults to the
// canonical local endpoint.
func NewOllamaAdmin(baseURL string) *OllamaAdmin {
	if baseURL == "" {
		baseURL = "http://localhost:11434"
	}
	return &OllamaAdmin{
		baseURL: baseURL,
		http:    &http.Client{Timeout: 10 * time.Second},
	}
}

// OllamaStatus is the snapshot returned by GetStatus.
type OllamaStatus struct {
	Installed      bool
	Running        bool
	BaseURL        string
	Version        string
	Message        string
	InstallCommand string
}

// GetStatus checks whether Ollama is installed on PATH and whether
// the HTTP server is responding. On failure, Message carries a short
// human-readable reason and InstallCommand provides the platform's
// canonical winget / brew line.
func (a *OllamaAdmin) GetStatus(ctx context.Context) OllamaStatus {
	status := OllamaStatus{BaseURL: a.baseURL, InstallCommand: installCommand()}

	// PATH check is optional: even when ollama isn't on PATH, a
	// background service may still be running, so GET /api/version
	// is the authoritative check.
	if _, err := exec.LookPath("ollama"); err == nil {
		status.Installed = true
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, a.baseURL+"/api/version", nil)
	if err != nil {
		status.Message = err.Error()
		return status
	}
	resp, err := a.http.Do(req)
	if err != nil {
		status.Message = err.Error()
		return status
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		status.Message = fmt.Sprintf("ollama /api/version returned %d", resp.StatusCode)
		return status
	}
	var parsed struct {
		Version string `json:"version"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		status.Message = err.Error()
		return status
	}
	status.Running = true
	status.Installed = true
	status.Version = parsed.Version
	return status
}

// OllamaModel is one installed model as reported by /api/tags.
type OllamaModel struct {
	Name         string
	SizeBytes    int64
	SizeGB       float64
	ModifiedAt   string
	IsEmbedding  bool
	EmbeddingDim int32
	Description  string
}

// ListModels returns all currently installed models. Empty slice when
// Ollama is unavailable.
func (a *OllamaAdmin) ListModels(ctx context.Context) ([]OllamaModel, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, a.baseURL+"/api/tags", nil)
	if err != nil {
		return nil, err
	}
	resp, err := a.http.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ctxmem/embed/ollama admin: /api/tags status %d", resp.StatusCode)
	}
	var parsed struct {
		Models []struct {
			Name       string `json:"name"`
			Size       int64  `json:"size"`
			ModifiedAt string `json:"modified_at"`
			Details    struct {
				Family string `json:"family"`
			} `json:"details"`
		} `json:"models"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return nil, err
	}
	out := make([]OllamaModel, 0, len(parsed.Models))
	for _, m := range parsed.Models {
		model := OllamaModel{
			Name:       m.Name,
			SizeBytes:  m.Size,
			SizeGB:     float64(m.Size) / 1024 / 1024 / 1024,
			ModifiedAt: m.ModifiedAt,
		}
		if isLikelyEmbeddingModel(m.Name) {
			model.IsEmbedding = true
			model.EmbeddingDim = embeddingDimFor(m.Name)
		}
		out = append(out, model)
	}
	return out, nil
}

// RecommendedModel is one pre-curated suggestion for the Settings
// onboarding flow.
type RecommendedModel struct {
	Name         string
	Description  string
	SizeEstimate string
	EmbeddingDim int32
	Installed    bool
	Role         string // "embedding" | "llm"
}

// GetRecommendedModels returns the curated recommendation list. The
// `installed` flag is filled in by cross-referencing ListModels.
func (a *OllamaAdmin) GetRecommendedModels(ctx context.Context) ([]RecommendedModel, error) {
	installed := map[string]struct{}{}
	models, _ := a.ListModels(ctx) // err is tolerated — we still show the list
	for _, m := range models {
		installed[m.Name] = struct{}{}
	}
	out := make([]RecommendedModel, 0, len(recommendedModels))
	for _, r := range recommendedModels {
		_, ok := installed[r.Name]
		r.Installed = ok
		out = append(out, r)
	}
	return out, nil
}

// PullProgress is one streaming event from /api/pull. Exactly one of
// Status / Error / Done is set.
type PullProgress struct {
	Status     string
	Downloaded int64
	Total      int64
	Digest     string
	Error      string
	Done       bool
}

// PullModel streams /api/pull events to the supplied emit callback.
// Returns when the stream terminates. emit is called synchronously on
// the caller goroutine; callers should not block it longer than
// necessary (the gRPC send is cheap).
func (a *OllamaAdmin) PullModel(ctx context.Context, name string, emit func(PullProgress)) error {
	if name == "" {
		return fmt.Errorf("ctxmem/embed/ollama admin: model name required")
	}
	body, _ := json.Marshal(map[string]any{"name": name, "stream": true})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, a.baseURL+"/api/pull", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	// Pull can take several minutes; use a dedicated client without
	// the 10s timeout that the status client has.
	pullClient := &http.Client{Timeout: 30 * time.Minute}
	resp, err := pullClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		msg, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("ctxmem/embed/ollama admin: pull status %d: %s", resp.StatusCode, string(msg))
	}
	scanner := bufio.NewScanner(resp.Body)
	scanner.Buffer(make([]byte, 1<<20), 1<<20)
	for scanner.Scan() {
		line := scanner.Bytes()
		var raw struct {
			Status    string `json:"status"`
			Digest    string `json:"digest"`
			Total     int64  `json:"total"`
			Completed int64  `json:"completed"`
			Error     string `json:"error"`
		}
		if err := json.Unmarshal(line, &raw); err != nil {
			continue
		}
		progress := PullProgress{
			Status:     raw.Status,
			Digest:     raw.Digest,
			Total:      raw.Total,
			Downloaded: raw.Completed,
			Error:      raw.Error,
		}
		if raw.Error != "" {
			emit(progress)
			return fmt.Errorf("ctxmem/embed/ollama admin: %s", raw.Error)
		}
		if raw.Status == "success" {
			progress.Done = true
			emit(progress)
			return nil
		}
		emit(progress)
	}
	return scanner.Err()
}

// installCommand returns the canonical per-OS command to install Ollama.
func installCommand() string {
	switch runtime.GOOS {
	case "windows":
		return "winget install --id Ollama.Ollama"
	case "darwin":
		return "brew install ollama"
	default:
		return "curl -fsSL https://ollama.com/install.sh | sh"
	}
}

// isLikelyEmbeddingModel is a heuristic: Ollama's /api/tags does not
// advertise a role, so we infer from the model family / name. The
// list covers the curated models in GetRecommendedModels and common
// community embeddings.
func isLikelyEmbeddingModel(name string) bool {
	lower := name
	for _, hint := range []string{"embed", "bge-", "gte-", "jina-embed", "nomic-embed"} {
		if containsFold(lower, hint) {
			return true
		}
	}
	return false
}

func containsFold(s, sub string) bool {
	return len(sub) <= len(s) && indexFold(s, sub) >= 0
}

func indexFold(s, sub string) int {
	for i := 0; i+len(sub) <= len(s); i++ {
		if equalFold(s[i:i+len(sub)], sub) {
			return i
		}
	}
	return -1
}

func equalFold(a, b string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := 0; i < len(a); i++ {
		ca, cb := a[i], b[i]
		if ca >= 'A' && ca <= 'Z' {
			ca += 'a' - 'A'
		}
		if cb >= 'A' && cb <= 'Z' {
			cb += 'a' - 'A'
		}
		if ca != cb {
			return false
		}
	}
	return true
}

// embeddingDimFor returns the canonical dimension for a known
// embedding model, or 0 when unknown.
func embeddingDimFor(name string) int32 {
	for _, r := range recommendedModels {
		if r.Name == name {
			return r.EmbeddingDim
		}
	}
	return 0
}

// recommendedModels is the curated onboarding list. Sizes are
// nominal; Ollama re-downloads with a sha256 pin regardless.
var recommendedModels = []RecommendedModel{
	{
		Name:         "nomic-embed-text",
		Description:  "Popular general-purpose embedding model, 768 dim. Good starting point.",
		SizeEstimate: "274 MB",
		EmbeddingDim: 768,
		Role:         "embedding",
	},
	{
		Name:         "mxbai-embed-large",
		Description:  "Higher-accuracy embedding, 1024 dim.",
		SizeEstimate: "670 MB",
		EmbeddingDim: 1024,
		Role:         "embedding",
	},
	{
		Name:         "bge-m3",
		Description:  "Multilingual embedding (100+ languages), 1024 dim. Use when the repo mixes English + Japanese etc.",
		SizeEstimate: "1.2 GB",
		EmbeddingDim: 1024,
		Role:         "embedding",
	},
	{
		Name:         "qwen2.5-coder:7b",
		Description:  "Local LLM for analyzer/observer extraction when you do not want to use OpenAI.",
		SizeEstimate: "4.7 GB",
		EmbeddingDim: 0,
		Role:         "llm",
	},
}
