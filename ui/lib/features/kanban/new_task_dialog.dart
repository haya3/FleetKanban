// NewTaskDialog: modal for creating a Pending task.

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../app/ui_utils.dart';
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
  Timer? _suggestTimer;
  pb.SuggestForNewTaskResponse? _suggestions;
  bool _suggestLoading = false;

  @override
  void initState() {
    super.initState();
    _goalController.addListener(_onGoalChanged);
  }

  @override
  void dispose() {
    _suggestTimer?.cancel();
    _goalController.dispose();
    super.dispose();
  }

  // _onGoalChanged debounces the Goal TextBox and calls
  // ContextService.SuggestForNewTask once typing has paused for 400ms.
  // The sidecar returns an empty bundle when Memory is disabled, which
  // renders as a collapsed (and visually absent) Expander — so wiring
  // this unconditionally is safe for Memory-off repos.
  void _onGoalChanged() {
    _suggestTimer?.cancel();
    final text = _goalController.text.trim();
    if (text.length < 4) {
      if (_suggestions != null) setState(() => _suggestions = null);
      return;
    }
    _suggestTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _suggestLoading = true);
      try {
        final client = ref.read(ipcClientProvider);
        final r = await client.context.suggestForNewTask(
          pb.SuggestForNewTaskRequest(
            repoId: _repoId,
            draftGoal: text,
            limit: 5,
          ),
        );
        if (!mounted) return;
        setState(() {
          _suggestions = r;
          _suggestLoading = false;
        });
      } catch (_) {
        if (mounted) setState(() => _suggestLoading = false);
      }
    });
  }

  Future<void> _submit() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) {
      setState(() => _error = 'Enter a goal');
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
        _error = 'Failed to create task: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repositories = ref.watch(kanbanRepositoriesProvider);

    return ContentDialog(
      title: const Text('New task'),
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
      content: repositories.when(
        loading: () =>
            const SizedBox(height: 120, child: Center(child: ProgressRing())),
        error: (e, _) => CopyableErrorText(
          text: 'Failed to load repositories: $e',
          reportTitle: 'Kanban / new task / repository fetch',
        ),
        data: (repos) {
          if (repos.isEmpty) {
            return const Text(
              'No repositories registered. Register one from the Kanban header.',
            );
          }
          if (!repos.any((r) => r.id == _repoId)) {
            _repoId = repos.first.id;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoLabel(
                label: 'Repository',
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
                label: 'Goal (natural language)',
                child: TextBox(
                  controller: _goalController,
                  placeholder:
                      'e.g. Translate README to Japanese and normalize heading levels',
                  maxLines: 5,
                  minLines: 4,
                  enabled: !_submitting,
                ),
              ),
              const SizedBox(height: 12),
              _SimilarSuggestions(
                suggestions: _suggestions,
                loading: _suggestLoading,
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
                ErrorInfoBar(title: 'Could not create task', message: _error!),
              ],
            ],
          );
        },
      ),
      actions: [
        clickable(
          Button(
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ),
        clickable(
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: ProgressRing(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ),
      ],
    );
  }
}

/// Collapsible panel that surfaces past similar tasks and applicable
/// Decisions / Constraints from Graph Memory as the user types a goal.
/// Hidden entirely when the suggestion bundle is empty — either Memory
/// is disabled for this repo, the draft is too short, or the repo has
/// no prior tasks to match against.
class _SimilarSuggestions extends StatelessWidget {
  const _SimilarSuggestions({
    required this.suggestions,
    required this.loading,
  });

  final pb.SuggestForNewTaskResponse? suggestions;
  final bool loading;

  bool get _hasContent {
    final s = suggestions;
    if (s == null) return false;
    return s.similarTasks.isNotEmpty ||
        s.relatedDecisions.isNotEmpty ||
        s.relatedConstraints.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContent && !loading) return const SizedBox.shrink();
    final theme = FluentTheme.of(context);
    final s = suggestions;
    return Expander(
      header: Row(
        children: [
          const Icon(FluentIcons.lightbulb, size: 14),
          const SizedBox(width: 6),
          Text(
            loading
                ? 'Looking for similar tasks…'
                : 'Similar tasks & prior decisions',
          ),
          if (loading) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: ProgressRing(strokeWidth: 2),
            ),
          ],
        ],
      ),
      content: s == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.similarTasks.isNotEmpty)
                  _SuggestionGroup(
                    title: 'Similar past tasks',
                    items: [
                      for (final t in s.similarTasks)
                        _SuggestionItem(
                          label: t.label,
                          score: t.score,
                          preview: t.summaryMd,
                        ),
                    ],
                  ),
                if (s.relatedDecisions.isNotEmpty)
                  _SuggestionGroup(
                    title: 'Applicable decisions',
                    items: [
                      for (final d in s.relatedDecisions)
                        _SuggestionItem(
                          label: d.label,
                          score: d.score,
                          preview: d.contentMd,
                        ),
                    ],
                  ),
                if (s.relatedConstraints.isNotEmpty)
                  _SuggestionGroup(
                    title: 'Binding constraints',
                    items: [
                      for (final c in s.relatedConstraints)
                        _SuggestionItem(
                          label: c.label,
                          score: c.score,
                          preview: c.contentMd,
                        ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Pulled from the repository Graph Memory. '
                    'Edit or remove entries from Settings → Context.',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SuggestionGroup extends StatelessWidget {
  const _SuggestionGroup({required this.title, required this.items});
  final String title;
  final List<_SuggestionItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 4),
          ...items,
        ],
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({
    required this.label,
    required this.score,
    required this.preview,
  });
  final String label;
  final double score;
  final String preview;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final snippet = preview.length > 160 ? '${preview.substring(0, 160)}…' : preview;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              score.toStringAsFixed(2),
              style: theme.typography.caption,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.typography.body),
                if (snippet.isNotEmpty)
                  Text(
                    snippet,
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorSecondary,
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

/// ComboBox backed by the sidecar's ListBranches RPC. The first item is
/// always `(auto-detect: RESOLVED)` and maps to the empty string on the
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
      label: 'Base branch',
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
              Text('Loading branches…'),
            ],
          ),
        ),
        error: (e, _) =>
            ErrorInfoBar(title: 'Failed to load branches', message: '$e'),
        data: (resp) {
          final autoLabel = resp.defaultBranch.isEmpty
              ? '(auto-detect)'
              : '(auto-detect: ${resp.defaultBranch})';
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
