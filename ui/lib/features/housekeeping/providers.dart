// Housekeeping providers: Merged-sweep opt-in and stale branch audit.
//
// Surfaces the HousekeepingService RPCs to the Settings UI. All providers
// degrade gracefully: UNAVAILABLE (the sidecar has no reaper) is translated
// to an empty / disabled state so the user sees a clear explanation rather
// than a scary stack trace.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;

import '../../infra/ipc/generated/fleetkanban/v1/housekeeping.pb.dart' as hk;
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';

/// Current `worktree.auto_sweep_merged_days` setting. Days == 0 means the
/// feature is disabled; the UI should render the toggle in its off state.
final autoSweepDaysProvider = FutureProvider<hk.GetAutoSweepDaysResponse>((
  ref,
) async {
  final client = ref.watch(ipcClientProvider);
  return client.housekeeping.getAutoSweepDays(Empty());
});

/// Stale branches (Done/Aborted tasks older than the threshold). Lazy —
/// the Settings UI fetches this when the user opens the Housekeeping
/// expander so we don't pay for it on every Settings visit.
final staleBranchesProvider = FutureProvider<List<hk.StaleBranch>>((ref) async {
  final client = ref.watch(ipcClientProvider);
  final resp = await client.housekeeping.listStaleBranches(
    hk.ListStaleBranchesRequest(), // older_than_days=0 → server default (30)
  );
  return resp.branches;
});

/// Writes the Merged-sweep threshold and invalidates the getter so the
/// UI rebuilds with the new value.
Future<void> setAutoSweepDays(WidgetRef ref, int days) async {
  final client = ref.read(ipcClientProvider);
  await client.housekeeping.setAutoSweepDays(
    hk.SetAutoSweepDaysRequest(days: days),
  );
  ref.invalidate(autoSweepDaysProvider);
}

/// Triggers an immediate sweep. When [days] is null the server falls back
/// to the stored setting. Invalidates the stale branches list so the UI
/// refreshes automatically.
Future<hk.RunSweepNowResponse> runSweepNow(WidgetRef ref, {int? days}) async {
  final client = ref.read(ipcClientProvider);
  final resp = await client.housekeeping.runSweepNow(
    hk.RunSweepNowRequest(days: days ?? 0),
  );
  ref.invalidate(staleBranchesProvider);
  return resp;
}

/// Force-deletes the `fleetkanban/<id>` branch for the given task. Used by
/// the Stale list's Discard action. The task row is preserved so the audit
/// trail (events + state) survives. Callers should surface a confirmation
/// dialog first — this call is destructive and cannot be undone.
Future<void> deleteTaskBranch(WidgetRef ref, String taskId) async {
  final client = ref.read(ipcClientProvider);
  await client.task.deleteTaskBranch(pb.IdRequest(id: taskId));
  ref.invalidate(staleBranchesProvider);
}
