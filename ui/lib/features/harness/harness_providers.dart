// Riverpod providers for the NLAH harness editor. The sidecar surfaces
// five unary RPCs (GetActiveSkill / ListSkillVersions / ValidateSkill /
// UpdateSkill / RollbackSkill) via HarnessService; this file wraps each
// in the FutureProvider pattern already used by the Context and Settings
// features so the page widget stays narrowly focused on layout.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pbgrpc.dart'
    as pbgrpc;
import '../../infra/ipc/grpc_client.dart' show authMetadataKey;
import '../../infra/ipc/providers.dart';

/// Client stub for the harness RPCs. IpcClient does not expose the
/// HarnessServiceClient directly because the harness endpoints were
/// introduced after the shared gRPC wiring was locked down; we
/// reconstruct a stub against the existing auth-token-bearing channel
/// here so the rest of the page can stay stub-agnostic.
final harnessServiceProvider = Provider<pbgrpc.HarnessServiceClient>((ref) {
  final endpoint = ref.watch(sidecarEndpointProvider);
  // Do not keep an explicit reference to the channel: the sidecar
  // endpoint provider is stable for the lifetime of the app, so the
  // channel lives alongside ipcClientProvider and is torn down when
  // the IPC layer shuts down.
  final channel = ClientChannel(
    '127.0.0.1',
    port: endpoint.port,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
      idleTimeout: Duration(seconds: 30),
    ),
  );
  ref.onDispose(() {
    channel.shutdown();
  });
  final callOptions = CallOptions(metadata: {authMetadataKey: endpoint.token});
  return pbgrpc.HarnessServiceClient(channel, options: callOptions);
});

/// The currently active harness skill.
final activeSkillProvider = FutureProvider<pb.HarnessSkill>((ref) async {
  final client = ref.watch(harnessServiceProvider);
  return client.getActiveSkill(Empty());
});

/// All harness versions, newest first. Order is not explicitly
/// specified by the RPC, so the provider re-sorts by version
/// descending to make the left-pane timeline deterministic.
final skillVersionsProvider = FutureProvider<List<pb.HarnessSkill>>((
  ref,
) async {
  final client = ref.watch(harnessServiceProvider);
  final resp = await client.listSkillVersions(Empty());
  final versions = [...resp.versions];
  versions.sort((a, b) => b.version.compareTo(a.version));
  return versions;
});

/// Server-side validation for a proposed skill content_md. Returns
/// ok/errors/warnings exactly as the sidecar emits them.
final validateSkillProvider =
    FutureProvider.family<pb.ValidateSkillResponse, String>((
      ref,
      contentMd,
    ) async {
      final client = ref.watch(harnessServiceProvider);
      return client.validateSkill(
        pb.ValidateSkillRequest(contentMd: contentMd),
      );
    });

/// Currently selected version in the left timeline pane. null means
/// "follow the active version". The id is the artifact_id of the
/// HarnessSkill row, not the integer version, because the sidecar's
/// RollbackSkillRequest keys on artifact_id.
final selectedSkillArtifactIdProvider = StateProvider<String?>((_) => null);

// ---------------------------------------------------------------------------
// NLAH Phase C — HarnessAttempt proposals.
//
// The Proposals tab surfaces pending self-evolution attempts emitted by
// the NLAH analyzer. HarnessAttemptService is a separate RPC surface from
// HarnessService (skill editor), so it gets its own channel + stub to
// keep the two flows disentangled. The channel is insecure-local just
// like harnessServiceProvider — both stubs target the same loopback
// sidecar endpoint, they just can't share a ClientChannel because
// Riverpod disposes them independently.
// ---------------------------------------------------------------------------

/// Client stub for HarnessAttemptService (ListPending / ListForTask /
/// Approve / Reject). Constructed against the shared sidecar endpoint.
final harnessAttemptServiceProvider =
    Provider<pbgrpc.HarnessAttemptServiceClient>((ref) {
      final endpoint = ref.watch(sidecarEndpointProvider);
      final channel = ClientChannel(
        '127.0.0.1',
        port: endpoint.port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          idleTimeout: Duration(seconds: 30),
        ),
      );
      ref.onDispose(() {
        channel.shutdown();
      });
      final callOptions = CallOptions(
        metadata: {authMetadataKey: endpoint.token},
      );
      return pbgrpc.HarnessAttemptServiceClient(channel, options: callOptions);
    });

/// Pending HarnessAttempt rows — decision == 'pending', newest first.
/// autoDispose so the Proposals tab refreshes cleanly when reopened.
final pendingAttemptsProvider =
    FutureProvider.autoDispose<List<pb.HarnessAttempt>>((ref) async {
      final client = ref.watch(harnessAttemptServiceProvider);
      final resp = await client.listPending(Empty());
      final attempts = [...resp.attempts];
      attempts.sort((a, b) {
        final ac = a.hasCreatedAt() ? a.createdAt.toDateTime() : DateTime(0);
        final bc = b.hasCreatedAt() ? b.createdAt.toDateTime() : DateTime(0);
        return bc.compareTo(ac);
      });
      return attempts;
    });

/// Count of pending proposals. Driven off [pendingAttemptsProvider] so
/// the Kanban column-header badge and the Proposals list stay coherent
/// without a second round-trip. Not autoDispose — the Kanban page keeps
/// this alive while visible, which also transitively keeps the list
/// warm for instant open of the Proposals tab.
final pendingAttemptsCountProvider = Provider<AsyncValue<int>>((ref) {
  final async = ref.watch(pendingAttemptsProvider);
  return async.whenData((list) => list.length);
});

/// Currently selected attempt in the Proposals list (by HarnessAttempt.id).
/// null means "show empty-details placeholder".
final selectedAttemptIdProvider = StateProvider<String?>((_) => null);

/// Which mode the Harness page is currently showing. Persists only in
/// memory — Editor on app launch, switched by the page's segmented
/// control.
enum HarnessPageMode { editor, proposals }

final harnessPageModeProvider = StateProvider<HarnessPageMode>(
  (_) => HarnessPageMode.editor,
);
