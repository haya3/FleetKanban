// Riverpod providers that expose the sidecar IPC layer to the rest of the
// app. Keep this file small and provider-only; feature state belongs in
// features/<area>/providers.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;

import 'generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'grpc_client.dart';
import 'sidecar_supervisor.dart';

/// Supplied in ProviderScope overrides in main.dart after the handshake
/// completes. Reading it before that override is wired is a programmer
/// error and throws.
final sidecarEndpointProvider = Provider<SidecarEndpoint>((_) {
  throw UnimplementedError(
    'sidecarEndpointProvider must be overridden in ProviderScope',
  );
});

/// The supervisor controlling the child sidecar process. Overridden in
/// main.dart so UI code (e.g. a future settings "restart sidecar" button)
/// can request kill() without reaching into main.
final supervisorProvider = Provider<SidecarSupervisor>((_) {
  throw UnimplementedError('supervisorProvider must be overridden');
});

/// The singleton gRPC client. Lives for the lifetime of the app — channel
/// shutdown is handled by the root app widget's dispose hook.
final ipcClientProvider = Provider<IpcClient>((ref) {
  final endpoint = ref.watch(sidecarEndpointProvider);
  final client = IpcClient.connect(endpoint);
  ref.onDispose(() => client.shutdown());
  return client;
});

/// Minimal repositories query for Phase B hello-world. Richer Riverpod
/// providers land in Phase C under features/kanban/providers.dart.
final repositoriesProvider = FutureProvider<List<pb.Repository>>((ref) async {
  final client = ref.watch(ipcClientProvider);
  final resp = await client.repository.listRepositories(Empty());
  return resp.repositories;
});

/// Copilot auth status for the header banner.
final copilotAuthProvider = FutureProvider<pb.AuthStatus>((ref) async {
  final client = ref.watch(ipcClientProvider);
  return client.auth.checkCopilotAuth(Empty());
});

/// GitHub account + plan info fetched via /user. Returns null when no PAT
/// is configured (the UI then prompts to add one in Settings instead of
/// showing a scary error).
final githubAccountInfoProvider = FutureProvider<pb.GitHubAccountInfo?>((
  ref,
) async {
  final client = ref.watch(ipcClientProvider);
  try {
    return await client.auth.getGitHubAccountInfo(Empty());
  } catch (_) {
    return null;
  }
});

/// Sidecar version info (protocol version, Copilot SDK version, Go
/// runtime). Used by the Status page to render an at-a-glance build
/// summary for support threads.
final versionInfoProvider = FutureProvider<pb.VersionInfo>((ref) async {
  final client = ref.watch(ipcClientProvider);
  return client.system.getVersion(Empty());
});
