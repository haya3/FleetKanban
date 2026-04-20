package ipc

import (
	"context"
	"crypto/subtle"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// AuthMetadataKey is the metadata key the Flutter client attaches to every
// call. The value is the handshake token emitted by main on startup.
const AuthMetadataKey = "x-auth-token"

// TokenInterceptors returns unary + stream interceptors that reject calls
// whose x-auth-token metadata does not match the expected value. When
// expected is empty the interceptors are no-ops (used by tests).
//
// The comparison uses constant-time equality to avoid leaking token length
// via timing, even though this is loopback-only IPC.
func TokenInterceptors(expected string) (grpc.UnaryServerInterceptor, grpc.StreamServerInterceptor) {
	if expected == "" {
		return func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
				return h(ctx, req)
			},
			func(srv any, ss grpc.ServerStream, _ *grpc.StreamServerInfo, h grpc.StreamHandler) error {
				return h(srv, ss)
			}
	}

	check := func(ctx context.Context) error {
		md, ok := metadata.FromIncomingContext(ctx)
		if !ok {
			return status.Error(codes.Unauthenticated, "missing metadata")
		}
		values := md.Get(AuthMetadataKey)
		if len(values) == 0 {
			return status.Error(codes.Unauthenticated, "missing auth token")
		}
		if subtle.ConstantTimeCompare([]byte(values[0]), []byte(expected)) != 1 {
			return status.Error(codes.PermissionDenied, "invalid auth token")
		}
		return nil
	}

	unary := func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
		if err := check(ctx); err != nil {
			return nil, err
		}
		return h(ctx, req)
	}
	stream := func(srv any, ss grpc.ServerStream, _ *grpc.StreamServerInfo, h grpc.StreamHandler) error {
		if err := check(ss.Context()); err != nil {
			return err
		}
		return h(srv, ss)
	}
	return unary, stream
}
