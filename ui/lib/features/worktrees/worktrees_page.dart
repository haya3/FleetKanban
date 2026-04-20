// Worktrees pane: every `%APPDATA%\FleetKanban\worktrees\` entry the sidecar
// can see, joined with the tasks table. Surfaces three failure modes the user
// would otherwise need a shell to spot:
//
//   - orphan (fleetkanban/ branch but no DB task row)
//   - externally deleted (path missing on disk → git prune needed)
//   - leftover completed tasks (branch preserved by default; user can reclaim
//     disk by removing)
//
// Primary repo worktrees are listed too but rendered read-only so the user
// knows where each repository lives on disk.

import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'providers.dart';

class WorktreesPage extends ConsumerWidget {
  const WorktreesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(worktreesProvider);
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Worktrees'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('再取得'),
              onPressed: () => ref.invalidate(worktreesProvider),
            ),
          ],
        ),
      ),
      content: entries.when(
        loading: () =>
            const Padding(padding: EdgeInsets.all(24), child: ProgressBar()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorInfoBar(
            title: 'worktree 一覧の取得に失敗しました',
            message: '$e',
            severity: InfoBarSeverity.error,
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'worktree は一つもありません。リポジトリ登録とタスク作成を行うと\n'
                'ここに fleetkanban/<task-id> の worktree が並びます。',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _WorktreeRow(entry: list[i]),
          );
        },
      ),
    );
  }
}

class _WorktreeRow extends ConsumerWidget {
  const _WorktreeRow({required this.entry});
  final pb.WorktreeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final status = _classify(entry);
    return Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconFor(status),
            color: _colorFor(status, resources, theme.accentColor),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.path.isEmpty ? '(path unavailable)' : entry.path,
                        style: theme.typography.bodyStrong,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitleFor(entry),
                  style: theme.typography.caption?.copyWith(
                    color: resources.textFillColorSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RowActions(entry: entry, status: status),
        ],
      ),
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions({required this.entry, required this.status});
  final pb.WorktreeEntry entry;
  final _RowStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canOpen = entry.pathExists && entry.path.isNotEmpty;
    final canRemove = !entry.isPrimary;
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.folder_open),
          onPressed: canOpen
              ? () async {
                  try {
                    await Process.start('explorer', [
                      entry.path,
                    ], runInShell: false);
                  } catch (_) {}
                }
              : null,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(FluentIcons.delete),
          onPressed: canRemove
              ? () => _confirmAndRemove(context, ref, entry, status)
              : null,
        ),
      ],
    );
  }
}

Future<void> _confirmAndRemove(
  BuildContext context,
  WidgetRef ref,
  pb.WorktreeEntry entry,
  _RowStatus status,
) async {
  var deleteBranch = false;
  final isFleetkanban = entry.taskId.isNotEmpty;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => ContentDialog(
        title: const Text('worktree を削除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.path, style: FluentTheme.of(ctx).typography.bodyStrong),
            const SizedBox(height: 12),
            Text(
              status == _RowStatus.missing
                  ? 'このディレクトリは外部で削除されています。git worktree prune も併せて実行されます。'
                  : 'worktree ディレクトリを撤去します。未コミットの変更も破棄されます。',
            ),
            if (isFleetkanban) ...[
              const SizedBox(height: 16),
              Checkbox(
                checked: deleteBranch,
                onChanged: (v) => setLocal(() => deleteBranch = v ?? false),
                content: Text('fleetkanban/${entry.taskId} ブランチも削除する'),
              ),
            ],
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    ),
  );
  if (result != true) return;
  try {
    await ref
        .read(removeWorktreeProvider.notifier)
        .remove(
          repositoryId: entry.repositoryId,
          worktreePath: entry.path,
          deleteBranch: deleteBranch,
        );
  } catch (e) {
    if (!context.mounted) return;
    await displayInfoBar(
      context,
      builder: (_, close) => InfoBar(
        title: const Text('削除に失敗しました'),
        content: CopyableErrorText(
          text: '$e',
          reportTitle: 'Worktrees / 削除に失敗しました',
        ),
        severity: InfoBarSeverity.error,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }
}

/// Row status categorises the visual treatment of a single entry.
enum _RowStatus { primary, active, keep, aborted, orphan, missing }

_RowStatus _classify(pb.WorktreeEntry e) {
  if (e.isPrimary) return _RowStatus.primary;
  if (!e.pathExists) return _RowStatus.missing;
  if (e.taskId.isEmpty) return _RowStatus.orphan;
  switch (e.taskStatus) {
    case 'planning':
    case 'queued':
    case 'in_progress':
    case 'ai_review':
    case 'human_review':
      return _RowStatus.active;
    case 'aborted':
      return _RowStatus.aborted;
    default:
      return _RowStatus.keep;
  }
}

String _subtitleFor(pb.WorktreeEntry e) {
  final parts = <String>[];
  parts.add(_repoLabel(e));
  if (e.branch.isNotEmpty) {
    final shortBranch = e.branch.replaceFirst('refs/heads/', '');
    parts.add('branch: $shortBranch');
  }
  if (e.taskId.isNotEmpty) {
    final st = e.taskStatus.isEmpty ? 'orphan' : e.taskStatus;
    parts.add('task: ${e.taskId} ($st)');
  }
  if (e.head.isNotEmpty) {
    parts.add('HEAD: ${e.head.substring(0, e.head.length.clamp(0, 10))}');
  }
  return parts.join(' · ');
}

String _repoLabel(pb.WorktreeEntry e) {
  final p = e.repositoryPath;
  if (p.isEmpty) return 'repo: (unknown)';
  return 'repo: $p';
}

IconData _iconFor(_RowStatus s) {
  switch (s) {
    case _RowStatus.primary:
      return FluentIcons.open_folder_horizontal;
    case _RowStatus.active:
      return FluentIcons.play_resume;
    case _RowStatus.keep:
      return FluentIcons.accept;
    case _RowStatus.aborted:
      return FluentIcons.stop_solid;
    case _RowStatus.orphan:
      return FluentIcons.warning;
    case _RowStatus.missing:
      return FluentIcons.error;
  }
}

Color _colorFor(_RowStatus s, ResourceDictionary r, AccentColor accent) {
  switch (s) {
    case _RowStatus.primary:
    case _RowStatus.active:
      return accent;
    case _RowStatus.keep:
      return r.textFillColorSecondary;
    case _RowStatus.aborted:
      return r.systemFillColorCaution;
    case _RowStatus.orphan:
    case _RowStatus.missing:
      return r.systemFillColorCritical;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _RowStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final color = _colorFor(status, theme.resources, theme.accentColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labelFor(status),
        style: theme.typography.caption?.copyWith(color: color),
      ),
    );
  }

  String _labelFor(_RowStatus s) {
    switch (s) {
      case _RowStatus.primary:
        return 'primary';
      case _RowStatus.active:
        return 'active';
      case _RowStatus.keep:
        return 'keep';
      case _RowStatus.aborted:
        return 'aborted';
      case _RowStatus.orphan:
        return 'orphan';
      case _RowStatus.missing:
        return 'missing';
    }
  }
}
