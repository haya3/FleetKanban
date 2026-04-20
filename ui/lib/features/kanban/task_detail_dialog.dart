// TaskDetailDialog: modal shown on TaskCard double-tap. Three tabs:
//
//   * Overview — static metadata (goal, branch, paths, timestamps, error).
//   * Subtasks — read-only view of the AI-produced execution DAG. The
//     planner decomposes the task on first run and the executor walks the
//     DAG; subtasks are not user-managed in Phase 3+.
//   * Files    — unified git diff between base branch and HEAD.

import 'dart:async';
import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../app/ui_utils.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';
import '../../infra/platform/shell_open.dart';
import '../review/diff_view.dart';
import '../review/providers.dart';
import 'providers.dart';
import 'subtask_dag_view.dart';
import 'subtask_summary_dialog.dart'
    show LogBucket, LogView, StageUsage, showSubtaskSummaryDialog;

Future<void> showTaskDetailDialog(
  BuildContext context, {
  required pb.Task task,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _TaskDetailDialog(task: task),
  );
}

class _TaskDetailDialog extends ConsumerStatefulWidget {
  const _TaskDetailDialog({required this.task});
  final pb.Task task;

  @override
  ConsumerState<_TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends ConsumerState<_TaskDetailDialog> {
  int _tabIndex = 0;

  Future<void> _finalizeMerge(BuildContext context, pb.Task task) async {
    try {
      await ref.read(finalizeMergeProvider.notifier).run(task.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      // Detect the specific "base branch is dirty in the main repo"
      // failure — the most common merge blocker and one FleetKanban
      // can unblock itself via `git stash push`. Any other merge
      // failure falls through to the generic copyable error dialog.
      if (_isDirtyBaseError('$e')) {
        final retried = await _offerStashAndRetry(context, task, '$e');
        if (retried) return;
      } else {
        await showErrorDialog(
          context,
          title: 'Failed to merge into base branch',
          message: '$e',
        );
      }
    }
  }

  bool _isDirtyBaseError(String msg) {
    return msg.contains('checked out in the main repository') &&
        msg.contains('uncommitted changes');
  }

  /// Show a "stash and retry" confirmation dialog. Returns true when
  /// the retry succeeded (task detail already popped by the caller) or
  /// the user cancelled; false when stash ran but the retry itself
  /// hit a different error (in which case the caller shows it).
  Future<bool> _offerStashAndRetry(
    BuildContext context,
    pb.Task task,
    String originalError,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Merge blocked by uncommitted changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The base branch is checked out in the main repository '
              'and has uncommitted changes. FleetKanban can stash them '
              'automatically and retry the merge.\n\n'
              'The stash is labelled "FleetKanban pre-merge stash <timestamp>" '
              'so you can restore it later with `git stash list` and '
              '`git stash pop`.',
            ),
            const SizedBox(height: 12),
            Text(
              'Original error:',
              style: FluentTheme.of(ctx).typography.bodyStrong,
            ),
            const SizedBox(height: 4),
            CopyableErrorText(
              text: originalError,
              reportTitle: 'Merge blocked by dirty base branch',
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Stash & retry merge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return true;

    final client = ref.read(ipcClientProvider);
    try {
      final stashResp = await client.repository.stashUncommitted(
        pb.IdRequest(id: task.repositoryId),
      );
      if (context.mounted) {
        await displayInfoBar(
          context,
          builder: (_, close) => InfoBar(
            title: Text(
              stashResp.stashed
                  ? 'Changes stashed'
                  : 'Working tree already clean',
            ),
            content: Text(stashResp.message),
            severity: InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e, st) {
      if (context.mounted) {
        await showErrorDialog(
          context,
          title: 'Stash failed',
          message: '$e\n\n$st',
        );
      }
      return true;
    }

    // Stash succeeded — retry the merge. If THAT also fails we fall
    // through to a generic error (the dirty check should no longer
    // trigger).
    if (!context.mounted) return true;
    try {
      await ref.read(finalizeMergeProvider.notifier).run(task.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e, st) {
      if (context.mounted) {
        await showErrorDialog(
          context,
          title: 'Merge retry failed',
          message: '$e\n\n$st',
        );
      }
    }
    return true;
  }

  Future<void> _confirmDelete(BuildContext context, pb.Task task) async {
    // Sidecar's DeleteTask rejects in_progress with FAILED_PRECONDITION. For
    // running tasks we ask for a combined Stop + Delete instead of bouncing
    // the user back to the card with a raw gRPC error.
    final running = task.status == 'in_progress';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(
          running ? 'Stop and delete this task?' : 'Delete this task?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goal: ${task.goal.isEmpty ? "(not set)" : task.goal}'),
            const SizedBox(height: 4),
            Text(
              'Branch: ${task.branch}',
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              running
                  ? 'This task is still running. The agent will be cancelled '
                        'first, then the worktree directory is removed. The git '
                        'branch is kept so any committed work survives. This '
                        'cannot be undone.'
                  : 'The worktree directory is removed but the git branch is kept,\n'
                        'so you can still inspect or recover it manually. This cannot be undone.',
            ),
          ],
        ),
        actions: [
          clickable(
            Button(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          clickable(
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  const Color(0xFFC42B1C).withValues(alpha: 0.9),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(running ? 'Stop & Delete' : 'Delete'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      if (running) {
        await ref.read(cancelTaskProvider.notifier).run(task.id);
        // orch.Cancel signals the running goroutine but the status flip to
        // aborted happens asynchronously. Poll GetTask for up to ~6s so the
        // follow-up DeleteTask doesn't hit ErrTaskStillRunning again.
        final client = ref.read(ipcClientProvider);
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          final fresh = await client.task.getTask(pb.IdRequest(id: task.id));
          if (fresh.status != 'in_progress') break;
        }
      }
      await ref.read(deleteTaskProvider.notifier).run(task.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      await showErrorDialog(context, title: 'Failed to delete', message: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    // Fill nearly the whole window so the diff / DAG have room to breathe.
    // Margins keep the dialog visually distinct from the Kanban backdrop
    // (a 100% edge-to-edge dialog feels like a hard screen swap rather
    // than an inspector overlay). Lower bounds protect against tiny
    // windows where the dialog would otherwise become unusable.
    final mq = MediaQuery.of(context).size;
    final dialogW = (mq.width - 48).clamp(640.0, double.infinity);
    final dialogH = (mq.height - 64).clamp(480.0, double.infinity);
    // Reserve room for the ContentDialog chrome (title, actions, padding).
    // Empirical ~150px keeps the TabView from overflowing the dialog.
    final contentH = (dialogH - 150).clamp(320.0, double.infinity);
    return ContentDialog(
      constraints: BoxConstraints(maxWidth: dialogW, maxHeight: dialogH),
      title: Row(
        children: [
          Expanded(
            child: Text(
              task.goal.isEmpty ? '(no goal)' : task.goal,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (task.worktreePath.isNotEmpty) ...[
            clickable(
              Tooltip(
                message: 'Open worktree in Explorer',
                child: IconButton(
                  icon: const Icon(FluentIcons.folder_open, size: 14),
                  onPressed: () => _openWorktree(
                    context,
                    task.worktreePath,
                    _OpenTool.explorer,
                  ),
                ),
              ),
            ),
            clickable(
              Tooltip(
                message: 'Open worktree in VSCode',
                child: IconButton(
                  icon: const Icon(FluentIcons.code, size: 14),
                  onPressed: () => _openWorktree(
                    context,
                    task.worktreePath,
                    _OpenTool.vscode,
                  ),
                ),
              ),
            ),
          ],
          clickable(
            IconButton(
              icon: const Icon(FluentIcons.delete, size: 14),
              onPressed: () => _confirmDelete(context, task),
            ),
          ),
          clickable(
            IconButton(
              icon: const Icon(FluentIcons.chrome_close, size: 14),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogW,
        height: contentH,
        child: TabView(
          tabs: [
            Tab(
              text: const Text('Overview'),
              icon: const Icon(FluentIcons.info),
              body: _OverviewTab(task: task),
            ),
            Tab(
              text: const Text('Subtasks'),
              icon: const Icon(FluentIcons.bulleted_list),
              body: _SubtasksTab(task: task),
            ),
            Tab(
              text: const Text('Files'),
              icon: const Icon(FluentIcons.diff_inline),
              body: _FilesTab(taskId: task.id),
            ),
          ],
          currentIndex: _tabIndex,
          onChanged: (i) => setState(() => _tabIndex = i),
          closeButtonVisibility: CloseButtonVisibilityMode.never,
          showScrollButtons: false,
          tabWidthBehavior: TabWidthBehavior.equal,
        ),
      ),
      actions: _canMerge(task.status, task.branchExists)
          ? [
              clickable(
                FilledButton(
                  onPressed: () => _finalizeMerge(context, task),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.branch_merge, size: 14),
                      SizedBox(width: 6),
                      Text('Merge into base'),
                    ],
                  ),
                ),
              ),
            ]
          : const [SizedBox.shrink()],
    );
  }

  Future<void> _openWorktree(
    BuildContext context,
    String path,
    _OpenTool tool,
  ) async {
    try {
      switch (tool) {
        case _OpenTool.explorer:
          await openInExplorer(path);
        case _OpenTool.vscode:
          await openInVSCode(path);
      }
    } catch (e) {
      if (!context.mounted) return;
      await showErrorDialog(
        context,
        title: 'Could not open worktree',
        message: '$e',
      );
    }
  }

  // Merge is valid from the states the orchestrator's Finalize accepts:
  //   - human_review (normal exit awaiting decision)
  //   - aborted      (user-cancelled in-progress)
  //   - done && branch_exists (Keep-finalized task whose fleetkanban/<id>
  //     branch is still around — user can come back later and merge it)
  // done tasks whose branch was already merged or discarded, and other
  // terminal statuses (cancelled / failed), show no merge button.
  static bool _canMerge(String status, bool branchExists) =>
      status == 'human_review' ||
      status == 'aborted' ||
      (status == 'done' && branchExists);
}

enum _OpenTool { explorer, vscode }

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final usageAsync = ref.watch(taskUsageProvider(task.id));
    final rows = <_Kv>[
      _Kv('ID', task.id),
      _Kv('Status', task.status),
      if (task.errorCode.isNotEmpty)
        _Kv('Error', '${task.errorCode}: ${task.errorMessage}'),
      if (task.reviewFeedback.isNotEmpty)
        _Kv('Review feedback', task.reviewFeedback),
      _Kv('Base branch', task.baseBranch),
      _Kv('Branch', task.branch),
      _Kv('Worktree', task.worktreePath),
      _Kv(
        'Model (Plan)',
        task.planModel.isEmpty ? '(not recorded)' : task.planModel,
      ),
      _Kv('Model (Code)', task.model.isEmpty ? '(default)' : task.model),
      _Kv(
        'Model (Review)',
        task.reviewModel.isEmpty ? '(not recorded)' : task.reviewModel,
      ),
      _Kv('Session ID', task.sessionId.isEmpty ? '—' : task.sessionId),
      _Kv(
        'Created',
        _fmtTimestamp(task.hasCreatedAt() ? task.createdAt : null),
      ),
      _Kv(
        'Started',
        _fmtTimestamp(task.hasStartedAt() ? task.startedAt : null),
      ),
      _Kv(
        'Finished',
        _fmtTimestamp(task.hasFinishedAt() ? task.finishedAt : null),
      ),
      _Kv(
        'Updated',
        _fmtTimestamp(task.hasUpdatedAt() ? task.updatedAt : null),
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(task.goal, style: theme.typography.bodyStrong),
          const SizedBox(height: 16),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      r.key,
                      style: theme.typography.caption?.copyWith(
                        color: theme.resources.textFillColorSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      r.value.isEmpty ? '—' : r.value,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _UsageSection(usageAsync: usageAsync, theme: theme),
        ],
      ),
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.usageAsync, required this.theme});

  final AsyncValue<TaskUsage> usageAsync;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    return usageAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(
        'Usage unavailable: $e',
        style: theme.typography.caption?.copyWith(
          color: theme.resources.textFillColorTertiary,
        ),
      ),
      data: (u) {
        if (u.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.resources.subtleFillColorTertiary,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.resources.controlStrokeColorDefault,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium request consumption',
                style: theme.typography.bodyStrong?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              _UsageRow('Plan', u.plan, theme),
              _UsageRow('Code (subtasks)', u.code, theme),
              _UsageRow('Review', u.review, theme),
              const Divider(),
              _UsageRow('Total', u.total, theme, bold: true),
            ],
          ),
        );
      },
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow(this.label, this.usage, this.theme, {this.bold = false});

  final String label;
  final StageUsage? usage;
  final FluentThemeData theme;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final has = usage != null;
    final text = has
        ? '${usage!.premiumRequests.toStringAsFixed(2)} premium · '
              'in ${_fmtTokens(usage!.inputTokens)} / out ${_fmtTokens(usage!.outputTokens)} · '
              '${usage!.calls} call${usage!.calls == 1 ? '' : 's'}'
        : '—';
    final style = TextStyle(
      fontFamily: 'Consolas',
      fontSize: 12,
      fontWeight: bold ? FontWeight.w600 : null,
      color: has ? null : theme.resources.textFillColorTertiary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
                fontWeight: bold ? FontWeight.w600 : null,
              ),
            ),
          ),
          Expanded(child: SelectableText(text, style: style)),
        ],
      ),
    );
  }

  static String _fmtTokens(int n) {
    if (n < 1000) return '$n';
    if (n < 1_000_000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1_000_000).toStringAsFixed(2)}M';
  }
}

class _Kv {
  const _Kv(this.key, this.value);
  final String key;
  final String value;
}

String _fmtTimestamp(dynamic ts) {
  if (ts == null) return '—';
  try {
    final dt = ts.toDateTime().toLocal();
    return dt.toString().substring(0, 19);
  } catch (_) {
    return '—';
  }
}

// ---------------------------------------------------------------------------
// Subtasks — read-only view of the AI-produced execution DAG.
// ---------------------------------------------------------------------------

enum _SubtasksViewMode { graph, list }

class _SubtasksTab extends ConsumerStatefulWidget {
  const _SubtasksTab({required this.task});
  final pb.Task task;

  @override
  ConsumerState<_SubtasksTab> createState() => _SubtasksTabState();
}

class _SubtasksTabState extends ConsumerState<_SubtasksTab> {
  // Graph is the default: the Plan → parallel Code → Review shape makes
  // the plan easier to grasp at a glance. The list view is a fallback for
  // copying ID / title / model strings.
  _SubtasksViewMode _mode = _SubtasksViewMode.graph;

  StreamSubscription<pb.AgentEvent>? _sub;

  // Live planning transcript. Accumulated chronologically from the
  // task's event stream while the planner is thinking
  // (status == planning AND no subtasks have landed yet). The same
  // LogBucket / LogView pipeline the subtask detail uses drives this,
  // so the user sees reasoning → tool call → assistant text in one
  // unified feed instead of three disjoint columns.
  final LogBucket _planningLog = LogBucket();
  bool _planningBootstrapped = false;
  final ScrollController _planningScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _bootstrapPlanningTranscript();
    final client = ref.read(ipcClientProvider);
    _sub = client.task.watchEvents(pb.WatchEventsRequest()).listen((ev) {
      if (ev.taskId != widget.task.id) return;
      const refetchKinds = {
        'subtask.start',
        'subtask.end',
        'status',
        'plan.summary',
      };
      if (refetchKinds.contains(ev.kind)) {
        ref.invalidate(subtasksProvider(widget.task.id));
      }
      final at = ev.hasOccurredAt()
          ? ev.occurredAt.toDateTime().toLocal()
          : null;
      switch (ev.kind) {
        case 'assistant.delta':
          setState(() => _planningLog.addAssistant(ev.payload, at));
          _scrollPlanningToBottom();
        case 'assistant.reasoning.delta':
          setState(() => _planningLog.addReasoning(ev.payload, at));
          _scrollPlanningToBottom();
        case 'tool.start':
          final name = _readStringField(ev.payload, 'name');
          if (name == null || name.isEmpty) break;
          setState(() {
            _planningLog.addToolStart(
              name: name,
              args: _readStringField(ev.payload, 'args') ?? '',
              id: _readStringField(ev.payload, 'id'),
              at: at,
            );
          });
          _scrollPlanningToBottom();
        case 'tool.end':
          setState(() {
            _planningLog.applyToolEnd(
              id: _readStringField(ev.payload, 'id'),
              ok: _readBoolField(ev.payload, 'ok'),
              err: _readStringField(ev.payload, 'err'),
              result: _readStringField(ev.payload, 'result'),
              at: at,
            );
          });
        case 'subtask.start':
          // Planner done → reset so reopening the dialog later does
          // not replay the planning transcript alongside Code.
          setState(() {
            _planningLog
              ..entries.clear()
              ..tools.clear();
          });
      }
    }, onError: (_) {});
  }

  Future<void> _bootstrapPlanningTranscript() async {
    if (_planningBootstrapped) return;
    _planningBootstrapped = true;
    try {
      final client = ref.read(ipcClientProvider);
      final resp = await client.task.taskEvents(
        pb.TaskEventsRequest(taskId: widget.task.id),
      );
      final bucket = LogBucket();
      for (final ev in resp.events) {
        final at = ev.hasOccurredAt()
            ? ev.occurredAt.toDateTime().toLocal()
            : null;
        if (ev.kind == 'subtask.start') {
          // Planner done for the latest round; drop accumulated state
          // so subsequent Plan re-runs (post-rework) start fresh.
          bucket.entries.clear();
          bucket.tools.clear();
          continue;
        }
        switch (ev.kind) {
          case 'assistant.delta':
            bucket.addAssistant(ev.payload, at);
          case 'assistant.reasoning.delta':
            bucket.addReasoning(ev.payload, at);
          case 'tool.start':
            final name = _readStringField(ev.payload, 'name');
            if (name == null || name.isEmpty) break;
            bucket.addToolStart(
              name: name,
              args: _readStringField(ev.payload, 'args') ?? '',
              id: _readStringField(ev.payload, 'id'),
              at: at,
            );
          case 'tool.end':
            bucket.applyToolEnd(
              id: _readStringField(ev.payload, 'id'),
              ok: _readBoolField(ev.payload, 'ok'),
              err: _readStringField(ev.payload, 'err'),
              result: _readStringField(ev.payload, 'result'),
              at: at,
            );
        }
      }
      if (!mounted) return;
      setState(() {
        _planningLog.entries.addAll(bucket.entries);
        _planningLog.tools.addAll(bucket.tools);
      });
      _scrollPlanningToBottom();
    } catch (_) {
      // Bootstrap is best-effort; live events fill in eventually.
    }
  }

  void _scrollPlanningToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_planningScroll.hasClients) return;
      _planningScroll.jumpTo(_planningScroll.position.maxScrollExtent);
    });
  }

  static String? _readStringField(String payload, String key) {
    try {
      final m = jsonDecode(payload);
      if (m is Map<String, dynamic>) {
        final v = m[key];
        return v is String ? v : null;
      }
    } catch (_) {}
    return null;
  }

  static bool? _readBoolField(String payload, String key) {
    try {
      final m = jsonDecode(payload);
      if (m is Map<String, dynamic>) {
        final v = m[key];
        return v is bool ? v : null;
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _planningScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final subtasksAsync = ref.watch(subtasksProvider(widget.task.id));

    return subtasksAsync.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: CopyableErrorText(
          text: 'Fetch failed: $e',
          reportTitle: 'Task detail / Subtasks fetch',
        ),
      ),
      data: (subs) {
        // When status is planning and there are zero subtasks, show the
        // live planning transcript (what the agent is thinking) with a
        // spinner on top. Otherwise render the composed Plan/Review DAG.
        if (subs.isEmpty && widget.task.status == 'planning') {
          return _PlanningLiveView(
            bucket: _planningLog,
            scroll: _planningScroll,
            theme: theme,
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${subs.length} subtasks',
                      style: theme.typography.caption?.copyWith(
                        color: theme.resources.textFillColorSecondary,
                      ),
                    ),
                  ),
                  if (_mode == _SubtasksViewMode.graph) ...[
                    const SubtaskDagFontControls(),
                    const SizedBox(width: 12),
                  ],
                  ToggleSwitch(
                    checked: _mode == _SubtasksViewMode.graph,
                    onChanged: (v) => setState(() {
                      _mode = v
                          ? _SubtasksViewMode.graph
                          : _SubtasksViewMode.list;
                    }),
                    content: Text(
                      _mode == _SubtasksViewMode.graph ? 'Graph' : 'List',
                      style: theme.typography.caption,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (_mode) {
                _SubtasksViewMode.graph => Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: SubtaskDagView(
                    key: ValueKey('subtask-dag-${widget.task.id}'),
                    task: widget.task,
                    subtasks: subs,
                  ),
                ),
                _SubtasksViewMode.list =>
                  subs.isEmpty
                      ? Center(
                          child: Text(
                            'No plan has been generated yet.',
                            style: theme.typography.caption,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: subs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (_, i) => _SubtaskRow(
                            taskId: widget.task.id,
                            subtask: subs[i],
                            allSubs: subs,
                          ),
                        ),
              },
            ),
          ],
        );
      },
    );
  }
}

// _PlanningLiveView renders the planner's live assistant transcript +
// tools-invoked summary while the task sits in status==planning. The
// header keeps the spinner / "AI is drafting the plan…" affordance so
// the user still has a clear "something is happening" signal; the
// scrollable body is the running thought stream. _planningLines is a
// line-buffered list so long reasoning passes don't smear together,
// and tool invocations land in a collapsed pill row above.
class _PlanningLiveView extends StatelessWidget {
  const _PlanningLiveView({
    required this.bucket,
    required this.scroll,
    required this.theme,
  });

  final LogBucket bucket;
  final ScrollController scroll;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Snapshot the bucket so the placeholder check and the LogView
    // see the same list even if a live event lands mid-build.
    bucket.finalize();
    final entries = List.of(bucket.entries);
    final placeholder = entries.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: ProgressRing(strokeWidth: 1.6),
              ),
              const SizedBox(width: 8),
              Text('AI is drafting the plan…', style: theme.typography.caption),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.resources.subtleFillColorTertiary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.resources.controlStrokeColorDefault,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: placeholder
                  ? Center(
                      child: Text(
                        'Waiting for the planner to produce output…',
                        style: theme.typography.caption?.copyWith(
                          color: theme.resources.textFillColorTertiary,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: scroll,
                      child: LogView(entries: entries, theme: theme),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.taskId,
    required this.subtask,
    required this.allSubs,
  });
  final String taskId;
  final pb.Subtask subtask;
  final List<pb.Subtask> allSubs;

  (IconData, Color) _statusVisual(String status, FluentThemeData theme) {
    switch (status) {
      case 'doing':
        return (FluentIcons.play_resume, const Color(0xFF0067C0));
      case 'done':
        return (FluentIcons.check_mark, const Color(0xFF107C10));
      case 'failed':
        return (FluentIcons.error_badge, const Color(0xFFC42B1C));
      case 'pending':
      default:
        return (FluentIcons.circle_ring, theme.resources.textFillColorTertiary);
    }
  }

  // depsLabel returns a short human label like "→ design, build" listing
  // the titles of this subtask's dependencies. Titles beat raw IDs for
  // readability since ULIDs are opaque.
  String _depsLabel() {
    if (subtask.dependsOn.isEmpty) return '';
    final byID = {for (final s in allSubs) s.id: s.title};
    final titles = subtask.dependsOn
        .map((id) => byID[id] ?? id)
        .toList(growable: false);
    return '← ${titles.join(", ")}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final (icon, color) = _statusVisual(subtask.status, theme);
    final done = subtask.status == 'done';
    final depsLabel = _depsLabel();

    return HoverButton(
      onPressed: () =>
          showSubtaskSummaryDialog(context, taskId: taskId, subtask: subtask),
      cursor: SystemMouseCursors.click,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          decoration: BoxDecoration(
            color: hovered
                ? theme.resources.subtleFillColorSecondary
                : theme.resources.layerOnMicaBaseAltFillColorDefault,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: hovered
                  ? theme.accentColor.normal.withValues(alpha: 0.6)
                  : theme.resources.controlStrokeColorDefault,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (subtask.agentRole.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.accentColor.normal.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              subtask.agentRole,
                              style: theme.typography.caption?.copyWith(
                                color: theme.accentColor.normal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            subtask.title,
                            style: theme.typography.body?.copyWith(
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: done
                                  ? theme.resources.textFillColorTertiary
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (depsLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          depsLabel,
                          style: theme.typography.caption?.copyWith(
                            color: theme.resources.textFillColorTertiary,
                          ),
                        ),
                      ),
                    if (subtask.codeModel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Code model: ${subtask.codeModel}',
                          style: theme.typography.caption?.copyWith(
                            color: theme.resources.textFillColorTertiary,
                            fontFamily: 'Consolas',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                FluentIcons.chevron_right,
                size: 12,
                color: theme.resources.textFillColorTertiary,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Files (unified diff)
// ---------------------------------------------------------------------------

// _FilesTab subscribes to the sidecar's WatchEvents stream and invalidates
// taskDiffProvider whenever the worktree watcher reports a file mutation
// for this task. Without this the diff would only refresh after a manual
// reopen of the dialog or a status transition. The subscription is scoped
// to the dialog: it starts on initState and tears down on dispose so we
// don't leak streams across repeated dialog opens.
class _FilesTab extends ConsumerStatefulWidget {
  const _FilesTab({required this.taskId});
  final String taskId;

  @override
  ConsumerState<_FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<_FilesTab> {
  StreamSubscription<pb.AgentEvent>? _sub;

  @override
  void initState() {
    super.initState();
    final client = ref.read(ipcClientProvider);
    _sub = client.task
        .watchEvents(pb.WatchEventsRequest())
        .listen(
          (ev) {
            if (ev.taskId != widget.taskId) return;
            if (ev.kind == 'file.changed' || ev.kind == 'status') {
              ref.invalidate(taskDiffProvider(widget.taskId));
            }
          },
          onError: (_) {
            // Stream closed by the sidecar; the dialog reopen will reconnect.
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = ref.watch(parsedDiffProvider(widget.taskId));
    return diff.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(FluentIcons.error, size: 24),
            const SizedBox(height: 8),
            Expanded(
              child: CopyableErrorText(
                text: '$e',
                reportTitle: 'Task detail / Files (diff) fetch',
              ),
            ),
          ],
        ),
      ),
      data: (files) {
        if (files.isEmpty) {
          return const Center(child: Text('No diff'));
        }
        return DiffView(files: files);
      },
    );
  }
}
