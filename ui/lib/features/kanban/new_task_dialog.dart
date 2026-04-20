// NewTaskDialog: modal for creating a Pending task.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';
import '../settings/providers.dart';
import 'providers.dart';

/// Sentinel stored in `_selectedBranch` to mean "empty — let the sidecar
/// auto-detect". Using a sentinel rather than null keeps the ComboBox's
/// value non-nullable so the item-list lookup stays straightforward.
const _autoDetectValue = '';

/// Opens the new-task dialog. Returns the created task id on success.
Future<String?> showNewTaskDialog(
  BuildContext context, {
  required String initialRepoId,
}) {
  return showDialog<String?>(
    context: context,
    builder: (_) => _NewTaskDialog(initialRepoId: initialRepoId),
  );
}

class _NewTaskDialog extends ConsumerStatefulWidget {
  const _NewTaskDialog({required this.initialRepoId});
  final String initialRepoId;

  @override
  ConsumerState<_NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends ConsumerState<_NewTaskDialog> {
  late String _repoId = widget.initialRepoId;
  final _goalController = TextEditingController();
  String _selectedBranch = _autoDetectValue;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) {
      setState(() => _error = 'ゴールを入力してください');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final client = ref.read(ipcClientProvider);
      // Per-stage model picks come from Settings (SharedPreferences). Empty
      // strings mean "let the sidecar pick its default" — the server
      // resolves and records the chosen model back onto the task.
      final planModel = await ref.read(
        modelForStageProvider(ModelStage.plan).future,
      );
      final codeModel = await ref.read(
        modelForStageProvider(ModelStage.code).future,
      );
      final reviewModel = await ref.read(
        modelForStageProvider(ModelStage.review).future,
      );
      final created = await client.task.createTask(
        pb.CreateTaskRequest(
          repositoryId: _repoId,
          goal: goal,
          baseBranch: _selectedBranch,
          model: codeModel,
          planModel: planModel,
          reviewModel: reviewModel,
        ),
      );
      ref.invalidate(tasksProvider(_repoId));
      if (mounted) Navigator.of(context).pop(created.id);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'タスク作成に失敗: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repositories = ref.watch(kanbanRepositoriesProvider);

    return ContentDialog(
      title: const Text('新規タスク'),
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
      content: repositories.when(
        loading: () =>
            const SizedBox(height: 120, child: Center(child: ProgressRing())),
        error: (e, _) => CopyableErrorText(
          text: 'リポジトリの取得に失敗: $e',
          reportTitle: 'Kanban / 新規タスク / リポジトリの取得',
        ),
        data: (repos) {
          if (repos.isEmpty) {
            return const Text('リポジトリが登録されていません。Kanban ヘッダから登録してください。');
          }
          if (!repos.any((r) => r.id == _repoId)) {
            _repoId = repos.first.id;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoLabel(
                label: 'リポジトリ',
                child: ComboBox<String>(
                  value: _repoId,
                  isExpanded: true,
                  items: [
                    for (final r in repos)
                      ComboBoxItem(
                        value: r.id,
                        child: Text(
                          r.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (v) => setState(() {
                          _repoId = v ?? _repoId;
                          // Branches differ per repo; reset selection
                          // so we don't carry a pick from a repo that
                          // may not contain that branch name.
                          _selectedBranch = _autoDetectValue;
                        }),
                ),
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'ゴール (自然言語)',
                child: TextBox(
                  controller: _goalController,
                  placeholder: '例: README を日本語訳して、見出しレベルを整える',
                  maxLines: 5,
                  minLines: 4,
                  enabled: !_submitting,
                ),
              ),
              const SizedBox(height: 12),
              _BaseBranchPicker(
                repoId: _repoId,
                selected: _selectedBranch,
                enabled: !_submitting,
                onChanged: (v) =>
                    setState(() => _selectedBranch = v ?? _autoDetectValue),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorInfoBar(title: '作成できませんでした', message: _error!),
              ],
            ],
          );
        },
      ),
      actions: [
        Button(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(null),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: ProgressRing(strokeWidth: 2),
                )
              : const Text('作成'),
        ),
      ],
    );
  }
}

/// ComboBox backed by the sidecar's ListBranches RPC. The first item is
/// always `(自動検出: RESOLVED)` and maps to the empty string on the
/// wire; subsequent items are the repo's real branches. Selection can
/// only be a branch the server confirmed exists, so the old failure
/// mode where the user typed a non-existent name ("master" in a main-
/// only repo) is structurally impossible.
class _BaseBranchPicker extends ConsumerWidget {
  const _BaseBranchPicker({
    required this.repoId,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String repoId;
  final String selected;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(repositoryBranchesProvider(repoId));
    return InfoLabel(
      label: 'ベースブランチ',
      child: branches.when(
        loading: () => const SizedBox(
          height: 32,
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: ProgressRing(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('ブランチを取得中...'),
            ],
          ),
        ),
        error: (e, _) => ErrorInfoBar(title: 'ブランチ一覧の取得に失敗', message: '$e'),
        data: (resp) {
          final autoLabel = resp.defaultBranch.isEmpty
              ? '(自動検出)'
              : '(自動検出: ${resp.defaultBranch})';
          // Defensive: if the currently-selected branch disappeared from
          // the list (branch deleted between dialog opens and submit),
          // fall back to auto-detect instead of rendering an invalid
          // ComboBox state.
          final effective = selected.isEmpty || resp.branches.contains(selected)
              ? selected
              : _autoDetectValue;
          return ComboBox<String>(
            value: effective,
            isExpanded: true,
            items: [
              ComboBoxItem(value: _autoDetectValue, child: Text(autoLabel)),
              for (final b in resp.branches)
                ComboBoxItem(value: b, child: Text(b)),
            ],
            onChanged: enabled ? onChanged : null,
          );
        },
      ),
    );
  }
}
