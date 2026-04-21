// Package embed provides pluggable embedding providers. The registry
// hands a Provider to the retrieval and analyzer layers; the concrete
// HTTP client is chosen per-repo via ctxmem.Settings.
package embed

import (
	"context"
	"fmt"

	"github.com/haya3/FleetKanban/internal/ctxmem"
)

// Provider is the interface every embedding backend implements. Callers
// are expected to batch multiple texts per call — Ollama and OpenAI
// both accept arrays and batching is the dominant throughput lever.
type Provider interface {
	// Name returns a canonical identifier used for cache keys and the
	// ctx_node_vec.model column. Format "<provider>:<model>".
	Name() string
	// Dim returns the embedding dimension the provider will produce.
	// Callers reject a batch when Dim() != len(existing vectors in the
	// repo) to keep ctx_node_vec consistent.
	Dim() int
	// Embed returns one float32 vector per input text. Empty texts
	// map to nil vectors (callers skip those rows) rather than
	// failing the whole batch.
	Embed(ctx context.Context, texts []string) ([][]float32, error)
}

// Registry holds the currently-configured Provider for each repo.
// The ctxmem Service consults it at retrieval / analyzer boundaries;
// configure by calling Set whenever MemorySettings changes.
type Registry struct {
	providers map[string]Provider
}

// NewRegistry returns an empty registry.
func NewRegistry() *Registry {
	return &Registry{providers: map[string]Provider{}}
}

// Set associates a Provider with a repo.
func (r *Registry) Set(repoID string, p Provider) {
	if p == nil {
		delete(r.providers, repoID)
		return
	}
	r.providers[repoID] = p
}

// Get returns the current provider or ErrProviderConfig if none is
// configured.
func (r *Registry) Get(repoID string) (Provider, error) {
	p, ok := r.providers[repoID]
	if !ok {
		return nil, fmt.Errorf("%w: no embedding provider for repo %q", ctxmem.ErrProviderConfig, repoID)
	}
	return p, nil
}

// Build constructs a Provider from Settings. It returns an error when
// the settings reference a provider that is not compiled in or when
// required credentials / endpoints are missing.
func Build(set ctxmem.Settings, opts BuildOptions) (Provider, error) {
	switch set.EmbeddingProvider {
	case "ollama":
		return NewOllama(opts.OllamaBaseURL, set.EmbeddingModel, set.EmbeddingDim), nil
	case "openai":
		if opts.OpenAIAPIKey == "" {
			return nil, fmt.Errorf("%w: openai embedding requires api key", ctxmem.ErrProviderConfig)
		}
		return NewOpenAI(opts.OpenAIAPIKey, set.EmbeddingModel, set.EmbeddingDim), nil
	default:
		return nil, fmt.Errorf("%w: unsupported embedding provider %q",
			ctxmem.ErrProviderConfig, set.EmbeddingProvider)
	}
}

// BuildOptions carries provider-specific credentials / endpoints that
// don't belong on a per-repo MemorySettings row (they're user-global).
type BuildOptions struct {
	OllamaBaseURL string // defaults to http://localhost:11434
	OpenAIAPIKey  string
}
