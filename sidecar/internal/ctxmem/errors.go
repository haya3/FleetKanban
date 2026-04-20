package ctxmem

import "errors"

// Domain errors returned by the ctxmem subsystem. Callers match with
// errors.Is; the ipc layer translates these into gRPC status codes.
var (
	ErrNotFound       = errors.New("ctxmem: not found")
	ErrMemoryDisabled = errors.New("ctxmem: memory is disabled for this repository")
	ErrInvalidArg     = errors.New("ctxmem: invalid argument")
	ErrProviderConfig = errors.New("ctxmem: embedding provider misconfigured")
	ErrDimMismatch    = errors.New("ctxmem: embedding dimension mismatch")
)
