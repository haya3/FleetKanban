// Preconditions: sidecar-reported runtime dependencies (e.g. PowerShell 7).
// The UI polls GetPreconditions on app startup and, when anything unmet is
// reported, shows a one-shot dialog offering the canonical auto-install
// path (InstallPrecondition). Kept separate from AuthGate because a
// missing precondition does not block the UI — tasks just can't execute
// until it's resolved — so the dialog is non-blocking.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';

/// Current list of precondition states from the sidecar. Family-free: the
/// server returns every known precondition in one call. Autodispose so
/// the next invalidate triggers a fresh check (used by the install flow
/// to re-fetch after winget finishes).
final preconditionsProvider = FutureProvider.autoDispose<List<pb.Precondition>>(
  (ref) async {
    final client = ref.watch(ipcClientProvider);
    final resp = await client.system.getPreconditions(Empty());
    return resp.preconditions;
  },
);

/// Runs the sidecar-side auto-install for [kind]. The RPC blocks until
/// winget (or the equivalent installer) finishes, which can take 1–3
/// minutes — callers must not race with other provider invalidations
/// over that window.
class InstallPreconditionNotifier
    extends AutoDisposeAsyncNotifier<pb.Precondition?> {
  @override
  Future<pb.Precondition?> build() async => null;

  Future<pb.InstallPreconditionResponse> run(String kind) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(ipcClientProvider);
      final resp = await client.system.installPrecondition(
        pb.InstallPreconditionRequest(kind: kind),
      );
      state = AsyncValue.data(resp.precondition);
      // Invalidate so any banner / dialog subscribers see the post-install
      // snapshot without needing their own refetch plumbing.
      ref.invalidate(preconditionsProvider);
      return resp;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final installPreconditionProvider =
    AsyncNotifierProvider.autoDispose<
      InstallPreconditionNotifier,
      pb.Precondition?
    >(InstallPreconditionNotifier.new);
