package app

import (
	"context"

	"github.com/haya3/fleetkanban/internal/orchestrator"
	"github.com/haya3/fleetkanban/internal/store"
)

// RepositoryAdapter exposes *store.RepositoryStore through the narrower
// orchestrator.RepositoryRepo interface. It lives in internal/app because
// it is the composition layer that knows about both packages.
type RepositoryAdapter struct {
	Store *store.RepositoryStore
}

var _ orchestrator.RepositoryRepo = (*RepositoryAdapter)(nil)

// Path returns the repository's registered filesystem path.
func (a *RepositoryAdapter) Path(ctx context.Context, id string) (string, error) {
	r, err := a.Store.Get(ctx, id)
	if err != nil {
		return "", err
	}
	return r.Path, nil
}

// TouchLastUsed records that a task just consumed the repository.
func (a *RepositoryAdapter) TouchLastUsed(ctx context.Context, id string) error {
	return a.Store.TouchLastUsed(ctx, id)
}
