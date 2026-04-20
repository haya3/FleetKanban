package embed

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Ollama wraps the /api/embeddings endpoint of a local Ollama server.
// https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embeddings
//
// Ollama's API is one-text-per-call (as of 0.6.x); the implementation
// loops over the batch to provide the same interface as OpenAI. For
// FleetKanban's single-repo scale this is fine — typical batches are
// < 50 chunks and run in < 1s on a local GPU.
type Ollama struct {
	baseURL string
	model   string
	dim     int
	http    *http.Client
}

// NewOllama constructs an Ollama provider. baseURL defaults to
// http://localhost:11434 when empty.
func NewOllama(baseURL, model string, dim int) *Ollama {
	if baseURL == "" {
		baseURL = "http://localhost:11434"
	}
	return &Ollama{
		baseURL: baseURL,
		model:   model,
		dim:     dim,
		http:    &http.Client{Timeout: 60 * time.Second},
	}
}

// Name returns "ollama:<model>".
func (o *Ollama) Name() string { return "ollama:" + o.model }

// Dim returns the configured dimension. Callers are expected to have
// set this correctly from ctxmem.Settings.EmbeddingDim — some Ollama
// models (e.g. nomic-embed-text at 768) lock the value regardless of
// what a client requests.
func (o *Ollama) Dim() int { return o.dim }

type ollamaEmbedRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
}

type ollamaEmbedResponse struct {
	Embedding []float32 `json:"embedding"`
}

// Embed issues one HTTP request per text. Empty / whitespace-only
// texts return a nil vector at the matching index without a network
// call.
func (o *Ollama) Embed(ctx context.Context, texts []string) ([][]float32, error) {
	out := make([][]float32, len(texts))
	for i, t := range texts {
		if t == "" {
			continue
		}
		v, err := o.embedOne(ctx, t)
		if err != nil {
			return nil, err
		}
		out[i] = v
	}
	return out, nil
}

func (o *Ollama) embedOne(ctx context.Context, text string) ([]float32, error) {
	body, _ := json.Marshal(ollamaEmbedRequest{Model: o.model, Prompt: text})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, o.baseURL+"/api/embeddings", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("ctxmem/embed/ollama: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := o.http.Do(req)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/embed/ollama: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("ctxmem/embed/ollama: status %d: %s", resp.StatusCode, string(b))
	}
	var parsed ollamaEmbedResponse
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return nil, fmt.Errorf("ctxmem/embed/ollama: decode: %w", err)
	}
	return parsed.Embedding, nil
}
