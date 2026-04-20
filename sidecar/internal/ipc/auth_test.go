package ipc

import (
	"context"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// fakeStream is the minimum ServerStream surface our stream interceptor uses.
type fakeStream struct {
	grpc.ServerStream
	ctx context.Context
}

func (f *fakeStream) Context() context.Context { return f.ctx }

func TestTokenInterceptors_NoopWhenExpectedEmpty(t *testing.T) {
	u, s := TokenInterceptors("")

	callCount := 0
	handler := func(ctx context.Context, req any) (any, error) {
		callCount++
		return "ok", nil
	}
	_, err := u(context.Background(), nil, &grpc.UnaryServerInfo{}, handler)
	if err != nil {
		t.Fatalf("unary noop: unexpected error: %v", err)
	}

	streamCalled := 0
	streamHandler := func(srv any, ss grpc.ServerStream) error {
		streamCalled++
		return nil
	}
	if err := s(nil, &fakeStream{ctx: context.Background()}, &grpc.StreamServerInfo{}, streamHandler); err != nil {
		t.Fatalf("stream noop: unexpected error: %v", err)
	}
	if callCount != 1 || streamCalled != 1 {
		t.Fatalf("handlers not invoked: unary=%d stream=%d", callCount, streamCalled)
	}
}

func TestTokenInterceptors_UnaryRejectsMissing(t *testing.T) {
	u, _ := TokenInterceptors("secret")
	handler := func(ctx context.Context, req any) (any, error) { return "ok", nil }

	_, err := u(context.Background(), nil, &grpc.UnaryServerInfo{}, handler)
	if code := status.Code(err); code != codes.Unauthenticated {
		t.Fatalf("expected Unauthenticated, got %v (%v)", code, err)
	}
}

func TestTokenInterceptors_UnaryRejectsMismatch(t *testing.T) {
	u, _ := TokenInterceptors("secret")
	ctx := metadata.NewIncomingContext(context.Background(),
		metadata.Pairs(AuthMetadataKey, "wrong"))
	handler := func(ctx context.Context, req any) (any, error) { return "ok", nil }

	_, err := u(ctx, nil, &grpc.UnaryServerInfo{}, handler)
	if code := status.Code(err); code != codes.PermissionDenied {
		t.Fatalf("expected PermissionDenied, got %v (%v)", code, err)
	}
}

func TestTokenInterceptors_UnaryAcceptsMatch(t *testing.T) {
	u, _ := TokenInterceptors("secret")
	ctx := metadata.NewIncomingContext(context.Background(),
		metadata.Pairs(AuthMetadataKey, "secret"))
	want := "ok"
	handler := func(ctx context.Context, req any) (any, error) { return want, nil }

	got, err := u(ctx, nil, &grpc.UnaryServerInfo{}, handler)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != want {
		t.Fatalf("unexpected result: got %v, want %v", got, want)
	}
}

func TestTokenInterceptors_StreamRejectsMismatch(t *testing.T) {
	_, s := TokenInterceptors("secret")
	ctx := metadata.NewIncomingContext(context.Background(),
		metadata.Pairs(AuthMetadataKey, "wrong"))
	handler := func(srv any, ss grpc.ServerStream) error {
		t.Fatal("handler should not be invoked")
		return nil
	}
	err := s(nil, &fakeStream{ctx: ctx}, &grpc.StreamServerInfo{}, handler)
	if code := status.Code(err); code != codes.PermissionDenied {
		t.Fatalf("expected PermissionDenied, got %v (%v)", code, err)
	}
}
