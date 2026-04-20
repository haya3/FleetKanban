// Kanban feature state: task listing, DnD mutations, and a bridge from the
// sidecar's WatchEvents stream into invalidation / live updates.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';

/// Kanban column identity. Five columns — AI Review and Human Review are
/// independent so the pipeline (Pending → 実行中 → AI Review → Human Review
/// → 完了) is visible step-by-step.
enum KanbanColumnId { pending, running, aiReview, humanReview, done }

/// Japanese label for each column header.
const Map<KanbanColumnId, String> kanbanColumnLabels = {
  KanbanColumnId.pending: 'Pending',
  KanbanColumnId.running: '実行中',
  KanbanColumnId.aiReview: 'AI Review',
  KanbanColumnId.humanReview: 'Human Review',
  KanbanColumnId.done: '完了',
};

/// Which task.status strings each column bucket contains. Values must match
/// internal/task/task.go exactly; the sidecar persists these strings
/// verbatim into SQLite and surfaces them on the wire.
///
/// aborted/failed land in the "完了" bucket alongside done/cancelled so the
/// user sees all terminal-ish states in one place. Re-run action pills on
/// those cards let users resume without dragging.
const Map<KanbanColumnId, Set<String>> kanbanColumnStatuses = {
  KanbanColumnId.pending: {'planning', 'queued'},
  KanbanColumnId.running: {'in_progress'},
  KanbanColumnId.aiReview: {'ai_review'},
  KanbanColumnId.humanReview: {'human_review'},
  KanbanColumnId.done: {'done', 'cancelled', 'aborted', 'failed'},
};

/// Routes a task status to its kanban column, or null when unknown.
KanbanColumnId? columnForStatus(String status) {
  for (final entry in kanbanColumnStatuses.entries) {
    if (entry.value.contains(status)) return entry.key;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Selection state
// ---------------------------------------------------------------------------

/// Currently selected repository. null until the user picks / registers one.
final selectedRepoIdProvider = StateProvider<String?>((_) => null);

/// Currently selected task for the right-hand side Terminal / Review panes.
final selectedTaskIdProvider = StateProvider<String?>((_) => null);

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

/// Events that warrant an immediate tasks re-fetch. `status` is emitted by
/// the sidecar on every persisted transition (both orchestrator and
/// SubmitReview); `session.start` marks the moment the worktree becomes
/// known on disk.
const _refetchKinds = {'status', 'session.start'};

class TasksNotifier extends FamilyAsyncNotifier<List<pb.Task>, String> {
  StreamSubscription<pb.AgentEvent>? _sub;

  @override
  Future<List<pb.Task>> build(String repoId) async {
    final client = ref.read(ipcClientProvider);

    // Subscribe to live events and invalidate on status-carrying kinds.
    // autoDispose is not used on purpose: the kanban board always lives as
    // long as a repo is selected, so we want the subscription to persist.
    _sub = client.task
        .watchEvents(pb.WatchEventsRequest())
        .listen(
          (ev) {
            if (_refetchKinds.contains(ev.kind)) {
              // ref.invalidateSelf will re-run build() including a new gRPC call.
              ref.invalidateSelf();
            }
          },
          onError: (_) {
            // Sidecar closed the stream — let the next user action surface the
            // error via the mutation path. Silent here to avoid spam.
          },
        );
    ref.onDispose(() {
      _sub?.cancel();
    });

    final resp = await client.task.listTasks(
      pb.ListTasksRequest(repoId: repoId),
    );
    return resp.tasks;
  }
}

/// Tasks scoped to a repository. Family key = repoId; an empty string means
/// "all repos" (mostly useful for diagnostics, not Kanban).
final tasksProvider =
    AsyncNotifierProvider.family<TasksNotifier, List<pb.Task>, String>(
      TasksNotifier.new,
    );

// ---------------------------------------------------------------------------
// Mutations
// ---------------------------------------------------------------------------

/// Discriminator for the generic mutation notifier. Public because it's
/// used as the family key of an AutoDisposeFamilyAsyncNotifier — Dart
/// requires family type arguments to be part of the public API surface.
enum Mutation {
  run,
  cancel,
  finalizeKeep,
  finalizeMerge,
  finalizeDiscard,
  delete,
  deleteBranch,
}

/// Generic mutation notifier. Keeps error state so the UI can surface it.
class TaskMutationNotifier
    extends AutoDisposeFamilyAsyncNotifier<void, Mutation> {
  @override
  Future<void> build(Mutation kind) async {
    // Mutations do no work at build(); they execute on run(taskId).
  }

  Future<void> run(String taskId) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(ipcClientProvider);
      switch (arg) {
        case Mutation.run:
          await client.task.runTask(pb.IdRequest(id: taskId));
        case Mutation.cancel:
          await client.task.cancelTask(pb.IdRequest(id: taskId));
        case Mutation.finalizeKeep:
          await client.task.finalizeTask(
            pb.FinalizeTaskRequest(
              id: taskId,
              action: pb.FinalizeAction.FINALIZE_ACTION_KEEP,
            ),
          );
        case Mutation.finalizeMerge:
          await client.task.finalizeTask(
            pb.FinalizeTaskRequest(
              id: taskId,
              action: pb.FinalizeAction.FINALIZE_ACTION_MERGE,
            ),
          );
        case Mutation.finalizeDiscard:
          await client.task.finalizeTask(
            pb.FinalizeTaskRequest(
              id: taskId,
              action: pb.FinalizeAction.FINALIZE_ACTION_DISCARD,
            ),
          );
        case Mutation.delete:
          await client.task.deleteTask(pb.DeleteTaskRequest(id: taskId));
        case Mutation.deleteBranch:
          await client.task.deleteTaskBranch(pb.IdRequest(id: taskId));
      }
      state = const AsyncValue.data(null);

      // Trigger a re-list. We can't target a specific repoId without walking
      // every active family instance, so invalidate the whole family.
      ref.invalidate(tasksProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final _mutationProvider = AsyncNotifierProvider.autoDispose
    .family<TaskMutationNotifier, void, Mutation>(TaskMutationNotifier.new);

/// RunTask mutation. Call `ref.read(runTaskProvider.notifier).run(id)`.
final runTaskProvider = _mutationProvider(Mutation.run);

/// CancelTask mutation.
final cancelTaskProvider = _mutationProvider(Mutation.cancel);

/// FinalizeTask with action=KEEP. Worktree removed, `fleetkanban/<id>` preserved.
final finalizeKeepProvider = _mutationProvider(Mutation.finalizeKeep);

/// FinalizeTask with action=MERGE. Advances the task's base branch to the
/// task branch tip (fast-forward or --no-ff merge commit), then removes
/// both the worktree and `fleetkanban/<id>`. Surfaces merge conflicts and
/// dirty-base errors to the caller.
final finalizeMergeProvider = _mutationProvider(Mutation.finalizeMerge);

/// FinalizeTask with action=DISCARD. Both worktree and `fleetkanban/<id>`
/// are removed, task transitions to cancelled.
final finalizeDiscardProvider = _mutationProvider(Mutation.finalizeDiscard);

/// DeleteTask mutation — removes the task row + worktree (branch preserved).
/// The UI surfaces a confirmation dialog before calling this so accidental
/// clicks on a nearly-adjacent card pill don't nuke user work.
final deleteTaskProvider = _mutationProvider(Mutation.delete);

/// DeleteTaskBranch mutation — force-removes the `fleetkanban/<id>` branch of
/// a finalized (Done/Aborted) task while preserving the task row for audit.
/// Callers must show a confirmation dialog; this call is destructive.
final deleteBranchProvider = _mutationProvider(Mutation.deleteBranch);

// ---------------------------------------------------------------------------
// Review submission
// ---------------------------------------------------------------------------

/// Wraps SubmitReview in a stateful Notifier so the UI can surface errors.
/// Feedback is a required field when action == rework (enforced by sidecar).
class SubmitReviewNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String taskId,
    required pb.ReviewAction action,
    String feedback = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(ipcClientProvider);
      await client.task.submitReview(
        pb.SubmitReviewRequest(id: taskId, action: action, feedback: feedback),
      );
      state = const AsyncValue.data(null);
      ref.invalidate(tasksProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final submitReviewProvider =
    AsyncNotifierProvider.autoDispose<SubmitReviewNotifier, void>(
      SubmitReviewNotifier.new,
    );

// ---------------------------------------------------------------------------
// Drag & drop transition logic
// ---------------------------------------------------------------------------

/// Whether a task card can be dragged at all. Draggable states are those
/// whose card can be moved to a *different* column via performTransition.
/// Terminal / pending states (done, cancelled, aborted, failed) are pinned:
/// the user interacts with them via the per-card action pills (再実行,
/// Keep, Discard) instead of DnD.
bool canDrag(String status) {
  switch (status) {
    case 'queued':
    case 'planning':
    case 'in_progress':
    case 'ai_review':
    case 'human_review':
      return true;
    default:
      return false;
  }
}

/// Whether a column transition is legal for the given task. Used by
/// DragTarget.onWillAccept to dim invalid columns during drag.
///
/// Mirrors (a subset of) the sidecar's transition graph — every entry here
/// must be a legal edge server-side or the transition will fail at commit
/// time. Edges that require extra input (e.g. rework needs feedback text)
/// are handled by dedicated action buttons on the card instead of DnD.
bool canTransition({
  required String currentStatus,
  required KanbanColumnId target,
}) {
  switch (target) {
    case KanbanColumnId.running:
      // queued → in_progress via RunTask.
      return currentStatus == 'queued' || currentStatus == 'planning';
    case KanbanColumnId.aiReview:
      // No user-initiated path lands a task in ai_review directly; the
      // orchestrator enters that state automatically on runner success.
      return false;
    case KanbanColumnId.humanReview:
      // ai_review → human_review is the Approve action; kept as an explicit
      // DnD edge so users can advance a stuck pass-through manually.
      return currentStatus == 'ai_review';
    case KanbanColumnId.done:
      // Dropping into 完了 = Keep (for human_review / aborted) or Cancel
      // (for in_progress / queued).
      return currentStatus == 'in_progress' ||
          currentStatus == 'queued' ||
          currentStatus == 'human_review' ||
          currentStatus == 'aborted';
    case KanbanColumnId.pending:
      // No transition ends in pending; explicit rework moves ai_review /
      // human_review / aborted back to queued, but that is its own flow.
      return false;
  }
}

/// Applies the column transition by invoking the right mutation.
Future<void> performTransition(
  WidgetRef ref, {
  required pb.Task task,
  required KanbanColumnId target,
}) async {
  if (!canTransition(currentStatus: task.status, target: target)) return;
  switch (target) {
    case KanbanColumnId.running:
      await ref.read(runTaskProvider.notifier).run(task.id);
    case KanbanColumnId.humanReview:
      // ai_review → human_review. Approve with no feedback.
      await ref
          .read(submitReviewProvider.notifier)
          .submit(
            taskId: task.id,
            action: pb.ReviewAction.REVIEW_ACTION_APPROVE,
          );
    case KanbanColumnId.done:
      switch (task.status) {
        case 'human_review':
        case 'aborted':
          // Default-Keep semantics: completion on drag-to-done preserves the
          // branch (user memory: ブランチ運用ポリシー "完了既定は Keep").
          await ref.read(finalizeKeepProvider.notifier).run(task.id);
        case 'in_progress':
        case 'queued':
          await ref.read(cancelTaskProvider.notifier).run(task.id);
        default:
          break;
      }
    case KanbanColumnId.pending:
    case KanbanColumnId.aiReview:
      break;
  }
}

/// Repository list for the header picker. Overrides the placeholder in
/// infra/ipc/providers.dart with a caching layer that survives across screens.
final kanbanRepositoriesProvider = FutureProvider<List<pb.Repository>>((
  ref,
) async {
  final client = ref.watch(ipcClientProvider);
  final resp = await client.repository.listRepositories(Empty());
  return resp.repositories;
});

/// Pickable branches for a repository, used by the new-task dialog's base-
/// branch ComboBox. autoDispose so each dialog open re-fetches — branches
/// drift between sessions and we want the list to be fresh.
final repositoryBranchesProvider = FutureProvider.autoDispose
    .family<pb.ListBranchesResponse, String>((ref, repoId) async {
      final client = ref.watch(ipcClientProvider);
      return client.repository.listBranches(
        pb.ListBranchesRequest(repositoryId: repoId),
      );
    });

// ---------------------------------------------------------------------------
// Subtasks — AI-produced execution DAG, read-only in the UI.
// ---------------------------------------------------------------------------

/// Subtask list for a parent task. Family key = parent task id.
///
/// The planner writes the plan once on task first-run; the executor mutates
/// per-subtask status as it walks the DAG. The UI subscribes via this
/// provider and refetches whenever an event stream tick would invalidate
/// the parent task (see WatchEvents handling).
final subtasksProvider = FutureProvider.family
    .autoDispose<List<pb.Subtask>, String>((ref, taskId) async {
      final client = ref.watch(ipcClientProvider);
      final resp = await client.subtask.listSubtasks(
        pb.ListSubtasksRequest(taskId: taskId),
      );
      return resp.subtasks;
    });
