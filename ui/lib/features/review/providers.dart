// Review feature state: diff fetch + parse + finalize mutation.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';
import '../kanban/providers.dart' show tasksProvider;
import 'unified_diff_parser.dart';

/// Raw `git diff --unified` output for a task. Refetched whenever the
/// tasksProvider family invalidates (e.g. after Finalize).
final taskDiffProvider = FutureProvider.autoDispose.family<String, String>((
  ref,
  taskId,
) async {
  final client = ref.watch(ipcClientProvider);
  final resp = await client.task.getTaskDiff(pb.IdRequest(id: taskId));
  return resp.unifiedDiff;
});

/// Parsed structure for the same diff — a plain function of the raw string.
final parsedDiffProvider = Provider.autoDispose
    .family<AsyncValue<List<DiffFile>>, String>((ref, taskId) {
      final raw = ref.watch(taskDiffProvider(taskId));
      return raw.whenData(UnifiedDiffParser.parse);
    });

/// Finalize mutation. `action` picks between Keep / Merge / Discard per the
/// sidecar's FinalizeAction enum. The orchestrator tears the worktree down
/// for all three outcomes; Merge additionally advances the base branch,
/// Discard additionally removes `fleetkanban/<id>`. After the call resolves
/// we invalidate tasksProvider so the Kanban reflects the final status.
Future<void> finalizeTask(
  WidgetRef ref, {
  required String taskId,
  required pb.FinalizeAction action,
}) async {
  final client = ref.read(ipcClientProvider);
  await client.task.finalizeTask(
    pb.FinalizeTaskRequest(id: taskId, action: action),
  );
  ref.invalidate(tasksProvider);
  ref.invalidate(taskDiffProvider(taskId));
}
