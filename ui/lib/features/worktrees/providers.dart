// Worktrees feature state: enumerate every git worktree the sidecar knows
// about (across all registered repos), and expose a Remove mutation.

import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';

part 'providers.g.dart';

/// Snapshot of every worktree across all registered repositories. The list is
/// re-fetched via `ref.invalidate(worktreesProvider)` — there is no streaming
/// source for worktree state (unlike task events).
@riverpod
Future<List<pb.WorktreeEntry>> worktrees(Ref ref) async {
  final client = ref.watch(ipcClientProvider);
  final resp = await client.worktree.listWorktrees(Empty());
  return resp.worktrees;
}

/// Remove mutation. Handles both fleetkanban/ worktrees (optionally deleting
/// the branch too) and orphan directories. Callers can `await` to block on
/// completion and surface errors.
@riverpod
class RemoveWorktree extends _$RemoveWorktree {
  @override
  Future<void> build() async {}

  Future<void> remove({
    required String repositoryId,
    required String worktreePath,
    bool deleteBranch = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(ipcClientProvider);
      await client.worktree.removeWorktree(
        pb.RemoveWorktreeRequest(
          repositoryId: repositoryId,
          worktreePath: worktreePath,
          deleteBranch: deleteBranch,
        ),
      );
      state = const AsyncValue.data(null);
      ref.invalidate(worktreesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
