// HarnessPage — NLAH harness skill editor + proposals review.
//
// Two modes, switched by a segmented control at the top of the page:
//
//   * Editor    — SKILL.md authoring and version timeline. Three-pane
//                 layout: left (280 px) ListSkillVersions timeline,
//                 centre flex Markdown editor (TextBox, Cascadia Code),
//                 right (320 px) TabView with Structure (parsed
//                 frontmatter) and Diff (unified diff vs the selected
//                 timeline version). Validate / Save / Rollback are
//                 top-bar actions; Save is gated by ValidateSkill.
//
//   * Proposals — NLAH self-evolution attempt queue. Pending
//                 HarnessAttempt rows on the left, selected-attempt
//                 detail on the right, Approve / Reject at the bottom.
//                 Implemented in proposals_tab.dart.
//
// The RPCs are plumbed through harness_providers.dart so this widget
// stays concerned with layout and state orchestration only.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'harness_providers.dart';
import 'proposals_tab.dart';
import 'widgets/diff_view.dart';
import 'widgets/frontmatter_panel.dart';

class HarnessPage extends ConsumerStatefulWidget {
  const HarnessPage({super.key});

  @override
  ConsumerState<HarnessPage> createState() => _HarnessPageState();
}

class _HarnessPageState extends ConsumerState<HarnessPage> {
  final _editor = TextEditingController();
  bool _dirty = false;
  bool _busy = false;
  String? _inlineError;
  // Populated on initial load and after every successful Save; used to
  // compute the editor's dirty-state indicator.
  String _originalContent = '';
  // The content_md of the currently-active skill as reported by the
  // sidecar; used as the Diff baseline when no timeline entry is
  // explicitly selected.
  String _activeContent = '';

  @override
  void initState() {
    super.initState();
    _editor.addListener(() {
      final nowDirty = _editor.text != _originalContent;
      if (nowDirty != _dirty) setState(() => _dirty = nowDirty);
    });
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  void _hydrate(pb.HarnessSkill active) {
    if (_originalContent.isEmpty && _editor.text.isEmpty) {
      _originalContent = active.contentMd;
      _activeContent = active.contentMd;
      _editor.text = active.contentMd;
    } else {
      _activeContent = active.contentMd;
    }
  }

  Future<void> _onValidate() async {
    setState(() {
      _busy = true;
      _inlineError = null;
    });
    try {
      final client = ref.read(harnessServiceProvider);
      final resp = await client.validateSkill(
        pb.ValidateSkillRequest(contentMd: _editor.text),
      );
      if (!mounted) return;
      await _showValidationDialog(resp);
    } catch (e) {
      if (mounted) setState(() => _inlineError = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onSave() async {
    setState(() {
      _busy = true;
      _inlineError = null;
    });
    try {
      final client = ref.read(harnessServiceProvider);
      final resp = await client.validateSkill(
        pb.ValidateSkillRequest(contentMd: _editor.text),
      );
      if (!resp.ok) {
        if (!mounted) return;
        await _showValidationDialog(resp);
        return;
      }
      final updated = await client.updateSkill(
        pb.UpdateSkillRequest(contentMd: _editor.text),
      );
      if (!mounted) return;
      setState(() {
        _originalContent = updated.contentMd;
        _activeContent = updated.contentMd;
        _editor.text = updated.contentMd;
        _dirty = false;
      });
      // Refresh dependent lists so the timeline picks up the new row.
      ref.invalidate(activeSkillProvider);
      ref.invalidate(skillVersionsProvider);
    } catch (e) {
      if (mounted) setState(() => _inlineError = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRollback(pb.HarnessSkill target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Rollback harness skill?'),
        content: Text(
          'Restore Version ${target.version} as the new active harness. '
          'A new version row is appended so the audit trail is preserved. '
          'Unsaved edits in the central editor will be discarded.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Rollback'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _inlineError = null;
    });
    try {
      final client = ref.read(harnessServiceProvider);
      final restored = await client.rollbackSkill(
        pb.RollbackSkillRequest(artifactId: target.artifactId),
      );
      if (!mounted) return;
      setState(() {
        _originalContent = restored.contentMd;
        _activeContent = restored.contentMd;
        _editor.text = restored.contentMd;
        _dirty = false;
      });
      ref.invalidate(activeSkillProvider);
      ref.invalidate(skillVersionsProvider);
      ref.read(selectedSkillArtifactIdProvider.notifier).state = null;
    } catch (e) {
      if (mounted) setState(() => _inlineError = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showValidationDialog(pb.ValidateSkillResponse resp) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(resp.ok ? 'Validation passed' : 'Validation failed'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (resp.errors.isNotEmpty) ...[
                  const Text(
                    'Errors',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  for (final e in resp.errors)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SelectableText('• $e'),
                    ),
                  const SizedBox(height: 12),
                ],
                if (resp.warnings.isNotEmpty) ...[
                  const Text(
                    'Warnings',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  for (final w in resp.warnings)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SelectableText('• $w'),
                    ),
                ],
                if (resp.errors.isEmpty && resp.warnings.isEmpty)
                  const Text('No issues reported.'),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeSkillProvider);
    final versions = ref.watch(skillVersionsProvider);
    final selectedArtifact = ref.watch(selectedSkillArtifactIdProvider);
    final mode = ref.watch(harnessPageModeProvider);
    final pendingCount =
        ref.watch(pendingAttemptsCountProvider).asData?.value ?? 0;

    // Keep the editor in sync with the active skill exactly once.
    active.whenData(_hydrate);

    final isEditor = mode == HarnessPageMode.editor;

    return ScaffoldPage(
      header: PageHeader(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Harness'),
            const SizedBox(width: 16),
            _ModeSegment(
              mode: mode,
              pendingCount: pendingCount,
              onChanged: (m) =>
                  ref.read(harnessPageModeProvider.notifier).state = m,
            ),
          ],
        ),
        commandBar: isEditor
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: ProgressRing(strokeWidth: 2),
                      ),
                    ),
                  Button(
                    onPressed: _busy ? null : _onValidate,
                    child: const Text('Validate'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_busy || !_dirty) ? null : _onSave,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: (_busy || selectedArtifact == null)
                        ? null
                        : () {
                            final list = versions.asData?.value ?? const [];
                            final target = list.firstWhere(
                              (s) => s.artifactId == selectedArtifact,
                              orElse: pb.HarnessSkill.new,
                            );
                            if (target.artifactId.isNotEmpty) {
                              _onRollback(target);
                            }
                          },
                    child: const Text('Rollback...'),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
      content: isEditor
          ? _buildEditor(active, versions, selectedArtifact)
          : const ProposalsTab(),
    );
  }

  Widget _buildEditor(
    AsyncValue<pb.HarnessSkill> active,
    AsyncValue<List<pb.HarnessSkill>> versions,
    String? selectedArtifact,
  ) {
    return Column(
      children: [
        if (_inlineError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: ErrorInfoBar(
              title: 'Harness operation failed',
              message: _inlineError!,
              severity: InfoBarSeverity.error,
            ),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 280,
                child: _VersionTimeline(
                  versions: versions,
                  selectedArtifactId: selectedArtifact,
                  onSelect: (id) =>
                      ref.read(selectedSkillArtifactIdProvider.notifier).state =
                          id,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _Editor(controller: _editor, active: active),
              ),
              const _VerticalDivider(),
              SizedBox(
                width: 320,
                child: _RightPanel(
                  editor: _editor,
                  activeContent: _activeContent,
                  selectedArtifactId: selectedArtifact,
                  versions: versions,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Segmented control for switching between Editor and Proposals modes.
/// Rendered as a pair of ToggleButtons so keyboard focus + accent
/// treatment follow the existing Fluent patterns used on the Kanban
/// column filter. Pending count shown as a small badge inside the
/// Proposals segment when > 0 so the user can see there is review
/// work even from the Editor side.
class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.mode,
    required this.pendingCount,
    required this.onChanged,
  });

  final HarnessPageMode mode;
  final int pendingCount;
  final ValueChanged<HarnessPageMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToggleButton(
          checked: mode == HarnessPageMode.editor,
          onChanged: (v) {
            if (v) onChanged(HarnessPageMode.editor);
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('Editor'),
          ),
        ),
        const SizedBox(width: 4),
        ToggleButton(
          checked: mode == HarnessPageMode.proposals,
          onChanged: (v) {
            if (v) onChanged(HarnessPageMode.proposals);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Proposals'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  _PendingCountBadge(count: pendingCount),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingCountBadge extends StatelessWidget {
  const _PendingCountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.accentColor.normal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: FluentTheme.of(context).resources.controlStrokeColorDefault,
    );
  }
}

class _VersionTimeline extends StatelessWidget {
  const _VersionTimeline({
    required this.versions,
    required this.selectedArtifactId,
    required this.onSelect,
  });

  final AsyncValue<List<pb.HarnessSkill>> versions;
  final String? selectedArtifactId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      color: theme.resources.subtleFillColorSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text('Versions', style: theme.typography.bodyStrong),
          ),
          Expanded(
            child: versions.when(
              loading: () => const Center(child: ProgressRing(strokeWidth: 2)),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: ErrorInfoBar(
                  title: 'Failed to load versions',
                  message: '$e',
                  severity: InfoBarSeverity.error,
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No versions yet.'),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final v = list[i];
                    final selected = v.artifactId == selectedArtifactId;
                    final created = v.hasCreatedAt()
                        ? v.createdAt.toDateTime().toLocal().toString()
                        : '';
                    return HoverButton(
                      onPressed: () => onSelect(selected ? null : v.artifactId),
                      builder: (ctx, states) {
                        final bg = selected
                            ? theme.accentColor.normal.withValues(alpha: 0.15)
                            : states.isHovered
                            ? theme.resources.subtleFillColorTertiary
                            : Colors.transparent;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: bg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Version ${v.version}'
                                '${i == 0 ? '  (active)' : ''}',
                                style: TextStyle(
                                  fontWeight: i == 0
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                created,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.resources.textFillColorSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.controller, required this.active});

  final TextEditingController controller;
  final AsyncValue<pb.HarnessSkill> active;

  @override
  Widget build(BuildContext context) {
    return active.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: ErrorInfoBar(
          title: 'Failed to load active skill',
          message: '$e',
          severity: InfoBarSeverity.error,
        ),
      ),
      data: (_) => Padding(
        padding: const EdgeInsets.all(12),
        child: TextBox(
          controller: controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(
            fontFamily: 'Cascadia Code',
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _RightPanel extends StatefulWidget {
  const _RightPanel({
    required this.editor,
    required this.activeContent,
    required this.selectedArtifactId,
    required this.versions,
  });

  final TextEditingController editor;
  final String activeContent;
  final String? selectedArtifactId;
  final AsyncValue<List<pb.HarnessSkill>> versions;

  @override
  State<_RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<_RightPanel> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever the editor text changes so the diff tab updates
    // in near-real-time as the user types.
    widget.editor.addListener(_onEditorChanged);
  }

  @override
  void dispose() {
    widget.editor.removeListener(_onEditorChanged);
    super.dispose();
  }

  void _onEditorChanged() {
    if (mounted) setState(() {});
  }

  String _diffBaseline() {
    final list = widget.versions.asData?.value ?? const [];
    if (widget.selectedArtifactId != null) {
      for (final v in list) {
        if (v.artifactId == widget.selectedArtifactId) return v.contentMd;
      }
    }
    return widget.activeContent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      color: theme.resources.subtleFillColorSecondary,
      child: TabView(
        currentIndex: _tab,
        onChanged: (i) => setState(() => _tab = i),
        closeButtonVisibility: CloseButtonVisibilityMode.never,
        tabs: [
          Tab(
            text: const Text('Structure'),
            icon: const Icon(FluentIcons.bulleted_list),
            body: FrontmatterPanel(contentMd: widget.editor.text),
          ),
          Tab(
            text: const Text('Diff'),
            icon: const Icon(FluentIcons.diff_inline),
            body: DiffView(before: _diffBaseline(), after: widget.editor.text),
          ),
        ],
      ),
    );
  }
}
