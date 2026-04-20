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

// OpenAI wraps the /v1/embeddings endpoint. The text-embedding-3-*
// family accepts a `dimensions` parameter to output a shorter vector
// without retraining — useful for keeping storage in check when the
// repo only needs 768-dim.
type OpenAI struct {
	apiKey string
	model  string
	dim    int
	http   *http.Client
}

// NewOpenAI constructs an OpenAI provider. Pass requestedDim = 0 to
// use the model's default (1536 for text-embedding-3-small, 3072 for
// text-embedding-3-large).
func NewOpenAI(apiKey, model string, requestedDim int) *OpenAI {
	return &OpenAI{
		apiKey: apiKey,
		model:  model,
		dim:    requestedDim,
		http:   &http.Client{Timeout: 60 * time.Second},
	}
}

// Name returns "openai:<model>".
func (o *OpenAI) Name() string { return "openai:" + o.model }

// Dim returns the requested dimension.
func (o *OpenAI) Dim() int { return o.dim }

type openAIEmbedRequest struct {
	Model      string   `json:"model"`
	Input      []string `json:"input"`
	Dimensions *int     `json:"dimensions,omitempty"`
}

type openAIEmbedResponse struct {
	Data []struct {
		Embedding []float32 `json:"embedding"`
		Index     int       `json:"index"`
	} `json:"data"`
	Error *struct {
		Message string `json:"message"`
		Type    string `json:"type"`
	} `json:"error,omitempty"`
}

// Embed batches all texts into one OpenAI request. Empty input strings
// in the batch are preserved by index but skipped server-side —
// OpenAI rejects empty strings with a 400, so we filter them out and
// re-align the response.
func (o *OpenAI) Embed(ctx context.Context, texts []string) ([][]float32, error) {
	// Filter empties. OpenAI rejects them with 400; re-align later.
	nonEmpty := make([]string, 0, len(texts))
	posMap := make([]int, len(texts)) // original index → position in nonEmpty, -1 means skipped
	for i, t := range texts {
		if t == "" {
			posMap[i] = -1
			continue
		}
		posMap[i] = len(nonEmpty)
		nonEmpty = append(nonEmpty, t)
	}
	if len(nonEmpty) == 0 {
		return make([][]float32, len(texts)), nil
	}

	reqBody := openAIEmbedRequest{Model: o.model, Input: nonEmpty}
	if o.dim > 0 {
		dim := o.dim
		reqBody.Dimensions = &dim
	}
	body, _ := json.Marshal(reqBody)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://api.openai.com/v1/embeddings", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("ctxmem/embed/openai: build: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+o.apiKey)
	resp, err := o.http.Do(req)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/embed/openai: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("ctxmem/embed/openai: status %d: %s", resp.StatusCode, string(b))
	}
	var parsed openAIEmbedResponse
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return nil, fmt.Errorf("ctxmem/embed/openai: decode: %w", err)
	}
	if parsed.Error != nil {
		return nil, fmt.Errorf("ctxmem/embed/openai: %s: %s", parsed.Error.Type, parsed.Error.Message)
	}

	out := make([][]float32, len(texts))
	for origIdx, pos := range posMap {
		if pos < 0 {
			continue
		}
		if pos >= len(parsed.Data) {
			return nil, fmt.Errorf("ctxmem/embed/openai: short response (got %d, want %d)",
				len(parsed.Data), len(nonEmpty))
		}
		out[origIdx] = parsed.Data[pos].Embedding
	}
	return out, nil
}
