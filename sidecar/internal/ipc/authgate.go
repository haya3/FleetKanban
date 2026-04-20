package ipc

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/FleetKanban/fleetkanban/internal/copilot"
)

// CopilotAuthChecker is the subset of copilot.Runtime that the gate needs.
// Accepting an interface keeps the ipc package independent of the runtime's
// concrete type and lets tests inject a stub.
type CopilotAuthChecker interface {
	CheckAuth(ctx context.Context) (copilot.AuthStatus, error)
}

// copilotGuardedMethods lists the fully-qualified gRPC method names that
// require an authenticated Copilot session before they will execute. The
// rule of thumb: any RPC that will (directly or transitively) spawn a
// Copilot SDK session must be listed here.
//
// Read-only RPCs (ListTasks, GetTask, ListRepositories, etc.) are safe
// without auth — they query the local DB only and do not reach out to
// Copilot. Settings/auth RPCs are obviously exempt so the user can
// initiate /login.
var copilotGuardedMethods = map[string]struct{}{
	"/fleetkanban.v1.TaskService/CreateTask":      {},
	"/fleetkanban.v1.SubtaskService/SubmitReview": {},
}

// copilotAuthGateUnary returns a unary interceptor that rejects guarded
// RPCs with FailedPrecondition when Copilot is not authenticated. The
// error code is intentionally distinct from Unauthenticated (which is
// already used by TokenInterceptors for handshake-token failures) so the
// UI can route the two conditions differently: handshake failure ⇒
// respawn sidecar, Copilot auth failure ⇒ show sign-in screen.
func copilotAuthGateUnary(checker CopilotAuthChecker) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
		if _, guarded := copilotGuardedMethods[info.FullMethod]; !guarded {
			return h(ctx, req)
		}
		auth, err := checker.CheckAuth(ctx)
		if err != nil {
			// Treat the status call itself failing as "not ready". We do
			// not want to pass the call through just because the check
			// errored — an in-flight session would fail opaquely.
			return nil, status.Errorf(codes.FailedPrecondition,
				"copilot auth check failed: %v", err)
		}
		if !auth.Authenticated {
			return nil, status.Error(codes.FailedPrecondition,
				"copilot_not_authenticated")
		}
		return h(ctx, req)
	}
}

// ChainUnary composes multiple unary interceptors left-to-right so that
// the first interceptor sees the raw request and hands off to the next
// via its handler. grpc.UnaryInterceptor accepts a single interceptor,
// and we want TokenInterceptors to run before copilotAuthGateUnary (no
// point doing a Copilot round-trip if the caller isn't even the
// handshake-verified UI process). grpc-go's ChainUnaryInterceptor would
// also do this but we avoid the extra import surface for two entries.
func ChainUnary(interceptors ...grpc.UnaryServerInterceptor) grpc.UnaryServerInterceptor {
	if len(interceptors) == 0 {
		return func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
			return h(ctx, req)
		}
	}
	if len(interceptors) == 1 {
		return interceptors[0]
	}
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
		// Build a chain where each interceptor's "handler" is the next
		// interceptor in the list, culminating in the real handler h.
		chain := h
		for i := len(interceptors) - 1; i >= 0; i-- {
			next := chain
			ic := interceptors[i]
			chain = func(ctx context.Context, req any) (any, error) {
				return ic(ctx, req, info, next)
			}
		}
		return chain(ctx, req)
	}
}

// CopilotAuthGateUnary is the exported name; main wires it after
// TokenInterceptors.
func CopilotAuthGateUnary(checker CopilotAuthChecker) grpc.UnaryServerInterceptor {
	return copilotAuthGateUnary(checker)
}
