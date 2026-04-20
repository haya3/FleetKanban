// TaskDetailDialog: modal shown on TaskCard double-tap. Three tabs:
//
//   * Overview — static metadata (goal, branch, paths, timestamps, error).
//   * Subtasks — read-only view of the AI-produced execution DAG. The
//     planner decomposes the task on first run and the executor walks the
//     DAG; subtasks are not user-managed in Phase 3+.
//   * Files    — unified git diff between base branch and HEAD.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../review/diff_view.dart';
import '../review/providers.dart';
import 'providers.dart';
import 'subtask_dag_view.dart';

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
      await showErrorDialog(context, title: '元のブランチへの統合に失敗しました', message: '$e');
    }
  }

  Future<void> _confirmDelete(BuildContext context, pb.Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('タスクを削除しますか?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ゴール: ${task.goal.isEmpty ? "(未設定)" : task.goal}'),
            const SizedBox(height: 4),
            Text(
              'ブランチ: ${task.branch}',
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'worktree ディレクトリは削除されますが、git ブランチは残るので\n'
              '後から手動で確認・復旧できます。この操作は取り消せません。',
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                const Color(0xFFC42B1C).withValues(alpha: 0.9),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(deleteTaskProvider.notifier).run(task.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      await showErrorDialog(context, title: '削除に失敗しました', message: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 640),
      title: Row(
        children: [
          Expanded(
            child: Text(
              task.goal.isEmpty ? '(ゴール未設定)' : task.goal,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(FluentIcons.delete, size: 14),
            onPressed: () => _confirmDelete(context, task),
          ),
          IconButton(
            icon: const Icon(FluentIcons.chrome_close, size: 14),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        height: 500,
        width: 840,
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
              FilledButton(
                onPressed: () => _finalizeMerge(context, task),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.branch_merge, size: 14),
                    SizedBox(width: 6),
                    Text('元のブランチへ戻す'),
                  ],
                ),
              ),
            ]
          : const [SizedBox.shrink()],
    );
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

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
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
      _Kv('Model (Plan)', task.planModel.isEmpty ? '(未記録)' : task.planModel),
      _Kv('Model (Code)', task.model.isEmpty ? '(default)' : task.model),
      _Kv(
        'Model (Review)',
        task.reviewModel.isEmpty ? '(未記録)' : task.reviewModel,
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
        ],
      ),
    );
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
  // DAG をデフォルトに。Plan → 並列 Code 群 → Review の流れが一目で
  // 読めるほうがプラン理解には効く。リストは ID/タイトル/モデル文字列を
  // コピーしたいときの保険。
  _SubtasksViewMode _mode = _SubtasksViewMode.graph;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final subtasksAsync = ref.watch(subtasksProvider(widget.task.id));

    return subtasksAsync.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: CopyableErrorText(
          text: '取得に失敗: $e',
          reportTitle: 'Task 詳細 / Subtasks 取得',
        ),
      ),
      data: (subs) {
        // planning 中で subtask ゼロのときだけは「AI がプラン作成中」表示。
        // それ以外（実 subtask が空でも）は Plan/Review の合成 DAG を出す。
        if (subs.isEmpty && widget.task.status == 'planning') {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ProgressRing(),
                const SizedBox(height: 12),
                Text('AI がプランを作成中…', style: theme.typography.caption),
              ],
            ),
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
                _SubtasksViewMode.list => subs.isEmpty
                    ? Center(
                        child: Text(
                          'プランはまだ作成されていません。',
                          style: theme.typography.caption,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: subs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) =>
                            _SubtaskRow(subtask: subs[i], allSubs: subs),
                      ),
              },
            ),
          ],
        );
      },
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({required this.subtask, required this.allSubs});
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

    return Container(
      decoration: BoxDecoration(
        color: theme.resources.layerOnMicaBaseAltFillColorDefault,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.resources.controlStrokeColorDefault,
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
                          decoration: done ? TextDecoration.lineThrough : null,
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Files (unified diff)
// ---------------------------------------------------------------------------

class _FilesTab extends ConsumerWidget {
  const _FilesTab({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diff = ref.watch(parsedDiffProvider(taskId));
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
                reportTitle: 'Task 詳細 / Files (diff) 取得',
              ),
            ),
          ],
        ),
      ),
      data: (files) {
        if (files.isEmpty) {
          return const Center(child: Text('差分はありません'));
        }
        return DiffView(files: files);
      },
    );
  }
}
