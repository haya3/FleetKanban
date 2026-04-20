// Worktrees feature state: enumerate every git worktree the sidecar knows
// about (across all registered repos), and expose a Remove mutation.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';

/// Snapshot of every worktree across all registered repositories. The list is
/// re-fetched via `ref.invalidate(worktreesProvider)` — there is no streaming
/// source for worktree state (unlike task events).
final worktreesProvider = FutureProvider<List<pb.WorktreeEntry>>((ref) async {
  final client = ref.watch(ipcClientProvider);
  final resp = await client.worktree.listWorktrees(Empty());
  return resp.worktrees;
});

/// Remove mutation. Handles both fleetkanban/ worktrees (optionally deleting
/// the branch too) and orphan directories. Callers can `await` to block on
/// completion and surface errors.
class RemoveWorktreeNotifier extends AutoDisposeAsyncNotifier<void> {
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

final removeWorktreeProvider =
    AsyncNotifierProvider.autoDispose<RemoveWorktreeNotifier, void>(
      RemoveWorktreeNotifier.new,
    );
