// Kanban feature state: task listing, DnD mutations, and a bridge from the
// sidecar's WatchEvents stream into invalidation / live updates.

import 'dart:async';
import 'dart:convert';

import 'package:fixnum/fixnum.dart' show Int64;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/grpc_client.dart';
import '../../infra/ipc/providers.dart';
import 'subtask_summary_dialog.dart'
    show LogBucket, StageUsage, buildPlanLogForRound, buildReviewLogForRound;

part 'providers.g.dart';

/// Kanban column identity. Five columns — AI Review and Human Review are
/// independent so the pipeline (Pending → Running → AI Review → Human Review
/// → Done) is visible step-by-step.
enum KanbanColumnId { pending, running, aiReview, humanReview, done }

/// Display label for each column header.
const Map<KanbanColumnId, String> kanbanColumnLabels = {
  KanbanColumnId.pending: 'Pending',
  KanbanColumnId.running: 'Running',
  KanbanColumnId.aiReview: 'AI Review',
  KanbanColumnId.humanReview: 'Human Review',
  KanbanColumnId.done: 'Done',
};

/// Which task.status strings each column bucket contains. Values must match
/// internal/task/task.go exactly; the sidecar persists these strings
/// verbatim into SQLite and surfaces them on the wire.
///
/// aborted/failed land in the "Done" bucket alongside done/cancelled so the
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

// ---------------------------------------------------------------------------
// Subtask DAG font scale — persisted user preference for how large the
// node title / role / model text renders in the SubtaskDagView. Lives
// here so multiple dialog open cycles (and the new-task dialog
// preview, eventually) read the same value without each fetching
// SharedPreferences themselves.
// ---------------------------------------------------------------------------

const String _dagFontScalePrefKey = 'subtask_dag_font_scale';
const double dagFontScaleMin = 0.8;
const double dagFontScaleMax = 2.0;
const double dagFontScaleStep = 0.1;
const double dagFontScaleDefault = 1.0;

@Riverpod(keepAlive: true)
class DagFontScale extends _$DagFontScale {
  @override
  Future<double> build() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble(_dagFontScalePrefKey);
    return _clamp(v ?? dagFontScaleDefault);
  }

  Future<void> set(double value) async {
    final clamped = _clamp(value);
    state = AsyncData(clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dagFontScalePrefKey, clamped);
  }

  Future<void> increment() async =>
      set((state.value ?? dagFontScaleDefault) + dagFontScaleStep);
  Future<void> decrement() async =>
      set((state.value ?? dagFontScaleDefault) - dagFontScaleStep);

  static double _clamp(double v) {
    if (v < dagFontScaleMin) return dagFontScaleMin;
    if (v > dagFontScaleMax) return dagFontScaleMax;
    return (v * 10).roundToDouble() / 10;
  }
}

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
/// known on disk; `housekeeping.branch_gc` fires when the reaper detects a
/// branch disappearing externally, so the UI needs a fresh
/// `task.branchExists` flag to hide the "Delete branch" / "Merge" pill.
const _refetchKinds = {'status', 'session.start', 'housekeeping.branch_gc'};

/// WatchEvents stream connection state. Surfaced via
/// [eventStreamHealthProvider] so the app shell can render an InfoBar when
/// the sidecar event bus is unreachable — otherwise a broken stream just
/// leaves the Kanban looking "frozen" with no explanation.
enum StreamHealthState { connecting, connected, disconnected }

class StreamHealth {
  const StreamHealth({
    required this.state,
    this.error,
    this.nextRetryAt,
    this.attempt = 0,
  });

  final StreamHealthState state;
  final Object? error;
  final DateTime? nextRetryAt;
  final int attempt;

  bool get isConnected => state == StreamHealthState.connected;
  bool get isDisconnected => state == StreamHealthState.disconnected;
}

/// Live WatchEvents stream health. Updated by the [Tasks] notifier as the
/// subscription connects, receives events, or enters backoff after a
/// disconnect.
final eventStreamHealthProvider = StateProvider<StreamHealth>(
  (_) => const StreamHealth(state: StreamHealthState.connecting),
);

/// Tasks scoped to a repository. Family key = repoId; an empty string means
/// "all repos" (mostly useful for diagnostics, not Kanban).
///
/// The WatchEvents subscription auto-reconnects with exponential backoff
/// (1 → 32 s, capped at 30 s) and keeps a per-task high-water-mark of
/// `seq` in [_sinceByTask] so the sidecar can suppress duplicates on
/// reconnect. Every successful reconnect triggers [ref.invalidateSelf]
/// so the post-disconnect state converges on the server-of-truth even if
/// some status events were missed during the gap.
@Riverpod(keepAlive: true)
class Tasks extends _$Tasks {
  StreamSubscription<pb.AgentEvent>? _sub;
  Timer? _reconnectTimer;
  final Map<String, Int64> _sinceByTask = {};
  int _attempt = 0;
  bool _disposed = false;

  @override
  Future<List<pb.Task>> build(String repoId) async {
    final client = ref.read(ipcClientProvider);

    ref.onDispose(() {
      _disposed = true;
      _reconnectTimer?.cancel();
      _sub?.cancel();
    });

    _connect(client);

    final resp = await client.task.listTasks(
      pb.ListTasksRequest(repoId: repoId),
    );
    return resp.tasks;
  }

  void _connect(IpcClient client) {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _setHealth(const StreamHealth(state: StreamHealthState.connecting));

    final req = pb.WatchEventsRequest();
    req.sinceSeqByTask.addAll(_sinceByTask);

    _sub = client.task.watchEvents(req).listen(
      _onEvent,
      onError: (Object err, StackTrace _) => _scheduleReconnect(client, err),
      onDone: () => _scheduleReconnect(client, null),
      cancelOnError: true,
    );
  }

  void _onEvent(pb.AgentEvent ev) {
    if (_disposed) return;
    final firstPacket = _attempt != 0;
    _attempt = 0;
    final prev = _sinceByTask[ev.taskId];
    if (prev == null || ev.seq > prev) {
      _sinceByTask[ev.taskId] = ev.seq;
    }
    _setHealth(const StreamHealth(state: StreamHealthState.connected));
    // After a reconnect, the sidecar suppresses events whose seq <= our
    // high-water-mark — but anything emitted while the UI was offline is
    // simply lost (no backfill on WatchEvents by design). Re-fetch the
    // task list once to resync, then fall back to incremental refresh.
    if (firstPacket || _refetchKinds.contains(ev.kind)) {
      ref.invalidateSelf();
    }
  }

  void _scheduleReconnect(IpcClient client, Object? error) {
    if (_disposed) return;
    _attempt++;
    final delay = _backoff(_attempt);
    final nextAt = DateTime.now().add(delay);
    _setHealth(StreamHealth(
      state: StreamHealthState.disconnected,
      error: error,
      nextRetryAt: nextAt,
      attempt: _attempt,
    ));
    _reconnectTimer = Timer(delay, () => _connect(client));
  }

  static Duration _backoff(int attempt) {
    const minSec = 1;
    const maxSec = 30;
    final shift = (attempt - 1).clamp(0, 5);
    final sec = (minSec << shift).clamp(minSec, maxSec);
    return Duration(seconds: sec);
  }

  void _setHealth(StreamHealth next) {
    ref.read(eventStreamHealthProvider.notifier).state = next;
  }
}

// ---------------------------------------------------------------------------
// Action error log — every mutation records its failure here so the app
// shell can surface an InfoBar instead of swallowing the error. Entries are
// id-addressable so the UI can dismiss them individually; the ring is
// capped at 8 so a runaway failure loop doesn't grow unbounded.
// ---------------------------------------------------------------------------

class ActionError {
  const ActionError({
    required this.id,
    required this.title,
    required this.message,
    required this.at,
  });

  final int id;
  final String title;
  final String message;
  final DateTime at;
}

final actionErrorLogProvider = StateProvider<List<ActionError>>(
  (_) => const [],
);

int _actionErrorSeq = 0;
const int _actionErrorRingCap = 8;

void recordActionError(
  Ref ref, {
  required String title,
  required Object error,
}) {
  _actionErrorSeq++;
  final entry = ActionError(
    id: _actionErrorSeq,
    title: title,
    message: error.toString(),
    at: DateTime.now(),
  );
  final existing = ref.read(actionErrorLogProvider);
  final next = [...existing, entry];
  while (next.length > _actionErrorRingCap) {
    next.removeAt(0);
  }
  ref.read(actionErrorLogProvider.notifier).state = next;
}

/// Widget-side counterparts. `Ref` (provider) and `WidgetRef` (UI) share no
/// common supertype, so we expose the dismiss/clear affordances as
/// extensions on WidgetRef and keep the record helper on Ref for
/// notifier-internal use.
extension ActionErrorLogWidgetRef on WidgetRef {
  void dismissActionError(int id) {
    final existing = read(actionErrorLogProvider);
    read(actionErrorLogProvider.notifier).state =
        existing.where((e) => e.id != id).toList();
  }

  void clearActionErrors() {
    read(actionErrorLogProvider.notifier).state = const [];
  }
}

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

String _mutationTitle(Mutation kind) {
  switch (kind) {
    case Mutation.run:
      return 'Run task failed';
    case Mutation.cancel:
      return 'Cancel task failed';
    case Mutation.finalizeKeep:
      return 'Keep task failed';
    case Mutation.finalizeMerge:
      return 'Merge task failed';
    case Mutation.finalizeDiscard:
      return 'Discard task failed';
    case Mutation.delete:
      return 'Delete task failed';
    case Mutation.deleteBranch:
      return 'Delete branch failed';
  }
}

/// Generic mutation notifier. Records failures into the shared
/// [actionErrorLogProvider] so the app shell can surface them via an
/// InfoBar — callers should NOT wrap run() in .catchError((_) {}) any more,
/// the notifier owns the error lifecycle.
///
/// State transitions on the notifier are kept so per-card spinners still
/// work (watch state.isLoading). The old contract rethrew the error; we
/// stopped doing that because the caller typically couldn't do anything
/// useful with it and the surfacing now happens globally.
@riverpod
class TaskMutation extends _$TaskMutation {
  @override
  Future<void> build(Mutation kind) async {
    // Mutations do no work at build(); they execute on run(taskId).
  }

  Future<void> run(String taskId) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(ipcClientProvider);
      switch (kind) {
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
      // Sidecar emits a status event on every persisted transition; the
      // WatchEvents subscriber invalidates tasksProvider on receipt, so we
      // don't need to invalidate here and race the stream.
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      recordActionError(ref, title: _mutationTitle(kind), error: e);
    }
  }
}

/// RunTask mutation. Call `ref.read(runTaskProvider.notifier).run(id)`.
final runTaskProvider = taskMutationProvider(Mutation.run);

/// CancelTask mutation.
final cancelTaskProvider = taskMutationProvider(Mutation.cancel);

/// FinalizeTask with action=KEEP. Worktree removed, `fleetkanban/<id>` preserved.
final finalizeKeepProvider = taskMutationProvider(Mutation.finalizeKeep);

/// FinalizeTask with action=MERGE. Advances the task's base branch to the
/// task branch tip (fast-forward or --no-ff merge commit), then removes
/// both the worktree and `fleetkanban/<id>`. Surfaces merge conflicts and
/// dirty-base errors to the caller.
final finalizeMergeProvider = taskMutationProvider(Mutation.finalizeMerge);

/// FinalizeTask with action=DISCARD. Both worktree and `fleetkanban/<id>`
/// are removed, task transitions to cancelled.
final finalizeDiscardProvider = taskMutationProvider(Mutation.finalizeDiscard);

/// DeleteTask mutation — removes the task row + worktree (branch preserved).
/// The UI surfaces a confirmation dialog before calling this so accidental
/// clicks on a nearly-adjacent card pill don't nuke user work.
final deleteTaskProvider = taskMutationProvider(Mutation.delete);

/// DeleteTaskBranch mutation — force-removes the `fleetkanban/<id>` branch of
/// a finalized (Done/Aborted) task while preserving the task row for audit.
/// Callers must show a confirmation dialog; this call is destructive.
final deleteBranchProvider = taskMutationProvider(Mutation.deleteBranch);

// ---------------------------------------------------------------------------
// Review submission
// ---------------------------------------------------------------------------

/// Wraps SubmitReview in a stateful Notifier. Errors are recorded into the
/// shared [actionErrorLogProvider] and the notifier's state.error; callers
/// no longer need to .catchError because the app shell surfaces failures
/// globally via an InfoBar.
///
/// Feedback is a required field when action == rework (enforced by sidecar).
@riverpod
class SubmitReview extends _$SubmitReview {
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
      // Rely on the WatchEvents status event to invalidate tasksProvider.
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      recordActionError(ref, title: _reviewTitle(action), error: e);
    }
  }
}

String _reviewTitle(pb.ReviewAction action) {
  switch (action) {
    case pb.ReviewAction.REVIEW_ACTION_APPROVE:
      return 'Approve review failed';
    case pb.ReviewAction.REVIEW_ACTION_REWORK:
      return 'Rework request failed';
    case pb.ReviewAction.REVIEW_ACTION_REJECT:
      return 'Reject review failed';
    default:
      return 'Submit review failed';
  }
}

// ---------------------------------------------------------------------------
// Drag & drop transition logic
// ---------------------------------------------------------------------------

/// Whether a task card can be dragged at all. Draggable states are those
/// whose card can be moved to a *different* column via performTransition.
/// Terminal / pending states (done, cancelled, aborted, failed) are pinned:
/// the user interacts with them via the per-card action pills (Re-run,
/// Keep, Discard) instead of DnD.
///
/// The draggable list is the UI-side mirror of
/// `shared/kanban_dnd_edges.json::draggable_statuses`. The Go test
/// `sidecar/internal/task/dnd_edges_test.go::TestDnDEdgesMatchSidecarGraph`
/// validates the JSON contract against the authoritative state machine in
/// `sidecar/internal/task/transition.go`, so any drift between this code
/// and the DnD edges declared there fails CI.
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
/// This is the UI-side mirror of `shared/kanban_dnd_edges.json::edges`.
/// Each (currentStatus → target column) entry below MUST correspond to a
/// row in that file, and each row's sidecar_to MUST be a legal edge under
/// `sidecar/internal/task/transition.go::allowedTransitions` — both are
/// enforced by the `TestDnDEdgesMatchSidecarGraph` Go test so drift
/// cannot slip through review.
///
/// Edges that require extra input (e.g. rework needs feedback text) are
/// handled by dedicated action buttons on the card instead of DnD.
bool canTransition({
  required String currentStatus,
  required KanbanColumnId target,
}) {
  switch (target) {
    case KanbanColumnId.running:
      // queued → in_progress via RunTask. planning is owned by the planner
      // goroutine and cannot be promoted by RunTask — the orchestrator moves
      // planning → in_progress automatically once the plan is persisted.
      return currentStatus == 'queued';
    case KanbanColumnId.aiReview:
      // No user-initiated path lands a task in ai_review directly; the
      // orchestrator enters that state automatically on runner success.
      return false;
    case KanbanColumnId.humanReview:
      // ai_review → human_review is the Approve action; kept as an explicit
      // DnD edge so users can advance a stuck pass-through manually.
      return currentStatus == 'ai_review';
    case KanbanColumnId.done:
      // Dropping into Done = Keep (for human_review / aborted) or Cancel
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
          // branch (policy: "completion default is Keep").
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

/// Aggregated session.usage events for a task, grouped by stage. Plan
/// and Review surface as single-bucket entries; Code is summed across
/// every subtask. Refetched when tasks invalidate so reworks (which
/// re-emit per-stage usage) are visible without a manual refresh.
final taskUsageProvider = FutureProvider.autoDispose.family<TaskUsage, String>((
  ref,
  taskId,
) async {
  final client = ref.watch(ipcClientProvider);
  final resp = await client.task.taskEvents(
    pb.TaskEventsRequest(taskId: taskId),
  );
  StageUsage? plan;
  StageUsage? code;
  StageUsage? review;
  for (final ev in resp.events) {
    if (ev.kind != 'session.usage') continue;
    final u = StageUsage.fromPayload(ev.payload);
    if (u == null) continue;
    final stage = _readStage(ev.payload);
    switch (stage) {
      case 'plan':
        // Reworks re-emit plan usage; sum across passes so the user
        // sees the cumulative cost of every planning attempt.
        plan = plan == null ? u : plan.plus(u);
      case 'code':
        code = code == null ? u : code.plus(u);
      case 'review':
        review = review == null ? u : review.plus(u);
    }
  }
  return TaskUsage(plan: plan, code: code, review: review);
});

class TaskUsage {
  TaskUsage({this.plan, this.code, this.review});
  final StageUsage? plan;
  final StageUsage? code;
  final StageUsage? review;

  bool get isEmpty => plan == null && code == null && review == null;

  StageUsage get total {
    StageUsage acc = StageUsage(
      model: '',
      premiumRequests: 0,
      inputTokens: 0,
      outputTokens: 0,
      cacheReadTokens: 0,
      durationMs: 0,
      calls: 0,
    );
    if (plan != null) acc = acc.plus(plan!);
    if (code != null) acc = acc.plus(code!);
    if (review != null) acc = acc.plus(review!);
    return acc;
  }
}

String _readStage(String payload) {
  if (payload.isEmpty) return '';
  try {
    final m = jsonDecode(payload);
    if (m is Map<String, dynamic>) {
      final s = m['stage'];
      if (s is String) return s;
    }
  } catch (_) {}
  return '';
}

/// Per-round plan.summary text for a task.
///
/// Post-2026-04 the sidecar emits plan.summary as JSON `{round, text}`
/// so each Plan node in the subtask DAG can display the summary from
/// its own round — previously the UI showed the latest summary on
/// every Plan node, which made Re-Run rounds indistinguishable.
/// Legacy plain-text payloads fall back to round 1.
///
/// Returns an empty map when the planner never emitted a summary.
final taskPlanSummaryProvider = FutureProvider.autoDispose
    .family<Map<int, String>, String>((ref, taskId) async {
      final client = ref.watch(ipcClientProvider);
      final resp = await client.task.taskEvents(
        pb.TaskEventsRequest(taskId: taskId),
      );
      final out = <int, String>{};
      for (final ev in resp.events) {
        if (ev.kind != 'plan.summary') continue;
        final (round, text) = _decodePlanSummaryPayload(ev.payload);
        if (text.isEmpty) continue;
        out[round] = text;
      }
      return out;
    });

/// Chronological log of planner-session events for a specific round.
/// Drives the Plan node's stage-detail log view so the user sees the
/// planner's reasoning + tool calls + final output in sequence.
final taskPlanLogProvider = FutureProvider.autoDispose
    .family<LogBucket, ({String taskId, int round})>((ref, key) async {
      final client = ref.watch(ipcClientProvider);
      final resp = await client.task.taskEvents(
        pb.TaskEventsRequest(taskId: key.taskId),
      );
      return buildPlanLogForRound(resp.events, key.round);
    });

/// Chronological log of reviewer-session events for a specific round.
/// Events are bracketed by `ai_review.start` / `ai_review.decision`
/// (same round).
final taskReviewLogProvider = FutureProvider.autoDispose
    .family<LogBucket, ({String taskId, int round})>((ref, key) async {
      final client = ref.watch(ipcClientProvider);
      final resp = await client.task.taskEvents(
        pb.TaskEventsRequest(taskId: key.taskId),
      );
      return buildReviewLogForRound(resp.events, key.round);
    });

(int, String) _decodePlanSummaryPayload(String payload) {
  if (payload.isEmpty) return (1, '');
  try {
    final v = jsonDecode(payload);
    if (v is Map<String, dynamic>) {
      final round = (v['round'] as num?)?.toInt() ?? 1;
      final text = (v['text'] as String?) ?? '';
      return (round < 1 ? 1 : round, text);
    }
  } catch (_) {}
  return (1, payload);
}

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
