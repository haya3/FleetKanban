// ProposalsTab — NLAH self-evolution approval UI.
//
// Two-pane layout:
//
//   * left (360 px): pending HarnessAttempt list, newest first. Each row
//                    shows failure_class, rework round, relative age, a
//                    shortened task id, and the first 60 characters of
//                    observation_md.
//   * centre (flex): selected attempt's detail — header (task id / class /
//                    created at / decision), observation_md block, the
//                    proposed_patch block (or a placeholder when the LLM
//                    hasn't produced one yet), and the Approve / Reject
//                    action bar.
//
// Approve / Reject both confirm via ContentDialog before touching the
// sidecar, and reload the list on success. decided_by is hard-coded to
// "user" for Phase C — a proper identity model arrives when we wire
// OIDC into the harness flow.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'harness_providers.dart';

class ProposalsTab extends ConsumerStatefulWidget {
  const ProposalsTab({super.key});

  @override
  ConsumerState<ProposalsTab> createState() => _ProposalsTabState();
}

class _ProposalsTabState extends ConsumerState<ProposalsTab> {
  bool _busy = false;
  String? _inlineError;

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onApprove(pb.HarnessAttempt attempt) async {
    final ok = await _confirm(
      title: 'Approve harness proposal?',
      body:
          'Approve this NLAH self-evolution attempt and apply the proposed '
          'SKILL.md patch to the active harness. A new harness version row '
          'is appended so the change is auditable and rollback-safe.',
      confirmLabel: 'Approve',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _inlineError = null;
    });
    try {
      final client = ref.read(harnessAttemptServiceProvider);
      await client.approve(
        pb.ApproveHarnessAttemptRequest(id: attempt.id, decidedBy: 'user'),
      );
      if (!mounted) return;
      ref.invalidate(pendingAttemptsProvider);
      ref.read(selectedAttemptIdProvider.notifier).state = null;
      // The Editor's version timeline / active skill will have changed on
      // approve, so hint those caches to refetch on next visit.
      ref.invalidate(activeSkillProvider);
      ref.invalidate(skillVersionsProvider);
    } catch (e) {
      if (mounted) setState(() => _inlineError = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onReject(pb.HarnessAttempt attempt) async {
    final ok = await _confirm(
      title: 'Reject harness proposal?',
      body:
          'Reject this NLAH attempt. The observation is kept for audit, but '
          'no change is applied to SKILL.md. Rejected attempts will not be '
          'retried automatically for the same failure class in this round.',
      confirmLabel: 'Reject',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _inlineError = null;
    });
    try {
      final client = ref.read(harnessAttemptServiceProvider);
      await client.reject(
        pb.RejectHarnessAttemptRequest(id: attempt.id, decidedBy: 'user'),
      );
      if (!mounted) return;
      ref.invalidate(pendingAttemptsProvider);
      ref.read(selectedAttemptIdProvider.notifier).state = null;
    } catch (e) {
      if (mounted) setState(() => _inlineError = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attempts = ref.watch(pendingAttemptsProvider);
    final selectedId = ref.watch(selectedAttemptIdProvider);
    final theme = FluentTheme.of(context);

    return Column(
      children: [
        if (_inlineError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: ErrorInfoBar(
              title: 'Harness proposal action failed',
              message: _inlineError!,
              severity: InfoBarSeverity.error,
            ),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 360,
                child: _ProposalsList(
                  attempts: attempts,
                  selectedId: selectedId,
                  onSelect: (id) =>
                      ref.read(selectedAttemptIdProvider.notifier).state = id,
                  onRefresh: () => ref.invalidate(pendingAttemptsProvider),
                ),
              ),
              Container(
                width: 1,
                color: theme.resources.controlStrokeColorDefault,
              ),
              Expanded(
                child: _AttemptDetail(
                  attempts: attempts,
                  selectedId: selectedId,
                  busy: _busy,
                  onApprove: _onApprove,
                  onReject: _onReject,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProposalsList extends StatelessWidget {
  const _ProposalsList({
    required this.attempts,
    required this.selectedId,
    required this.onSelect,
    required this.onRefresh,
  });

  final AsyncValue<List<pb.HarnessAttempt>> attempts;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onRefresh;

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
            child: Row(
              children: [
                Text('Proposals', style: theme.typography.bodyStrong),
                const Spacer(),
                IconButton(
                  icon: const Icon(FluentIcons.refresh),
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          Expanded(
            child: attempts.when(
              loading: () => const Center(child: ProgressRing(strokeWidth: 2)),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: ErrorInfoBar(
                  title: 'Failed to load pending proposals',
                  message: '$e',
                  severity: InfoBarSeverity.error,
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: InfoBar(
                      title: Text('No pending harness improvement proposals'),
                      content: Text(
                        'NLAH will emit attempts when rework rounds reveal a '
                        'reproducible failure class. Nothing to review yet.',
                      ),
                      severity: InfoBarSeverity.info,
                      isIconVisible: true,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final a = list[i];
                    final selected = a.id == selectedId;
                    return _ProposalRow(
                      attempt: a,
                      selected: selected,
                      onTap: () => onSelect(selected ? null : a.id),
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

class _ProposalRow extends StatelessWidget {
  const _ProposalRow({
    required this.attempt,
    required this.selected,
    required this.onTap,
  });

  final pb.HarnessAttempt attempt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final failureClass = attempt.failureClass.isEmpty
        ? 'unknown'
        : attempt.failureClass;
    final observation = _firstLine(attempt.observationMd);
    final shortTask = _shortId(attempt.taskId);
    final created = attempt.hasCreatedAt()
        ? _relativeTime(attempt.createdAt.toDateTime().toLocal())
        : '';
    return HoverButton(
      onPressed: onTap,
      builder: (ctx, states) {
        final bg = selected
            ? theme.accentColor.normal.withValues(alpha: 0.15)
            : states.isHovered
            ? theme.resources.subtleFillColorTertiary
            : Colors.transparent;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Chip(
                    text: failureClass,
                    color: _failureClassColor(theme, failureClass),
                  ),
                  const SizedBox(width: 6),
                  _Chip(
                    text: 'r${attempt.reworkRound}',
                    color: theme.resources.subtleFillColorTertiary,
                  ),
                  const Spacer(),
                  Text(
                    created,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Task $shortTask',
                style: theme.typography.bodyStrong,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                observation,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.resources.textFillColorSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttemptDetail extends StatelessWidget {
  const _AttemptDetail({
    required this.attempts,
    required this.selectedId,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final AsyncValue<List<pb.HarnessAttempt>> attempts;
  final String? selectedId;
  final bool busy;
  final Future<void> Function(pb.HarnessAttempt) onApprove;
  final Future<void> Function(pb.HarnessAttempt) onReject;

  pb.HarnessAttempt? _selected() {
    final list = attempts.asData?.value;
    if (list == null || selectedId == null) return null;
    for (final a in list) {
      if (a.id == selectedId) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final attempt = _selected();
    if (attempt == null) {
      return Center(
        child: Text(
          'Select a proposal to review.',
          style: TextStyle(color: theme.resources.textFillColorSecondary),
        ),
      );
    }
    final created = attempt.hasCreatedAt()
        ? attempt.createdAt.toDateTime().toLocal().toString()
        : '—';
    final decision = attempt.decision.isEmpty ? 'pending' : attempt.decision;
    final failureClass = attempt.failureClass.isEmpty
        ? 'unknown'
        : attempt.failureClass;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO(nlah): clicking the task id should deep-link to
                    // the Kanban task-detail dialog. Tracked as a Phase D
                    // polish item — needs a cross-feature nav primitive
                    // we don't have yet.
                    Text(
                      'Task ${attempt.taskId}',
                      style: theme.typography.subtitle,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          text: failureClass,
                          color: _failureClassColor(theme, failureClass),
                        ),
                        const SizedBox(width: 6),
                        _Chip(
                          text: 'rework round ${attempt.reworkRound}',
                          color: theme.resources.subtleFillColorTertiary,
                        ),
                        const SizedBox(width: 6),
                        _Chip(
                          text: decision,
                          color: theme.resources.subtleFillColorTertiary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'created $created',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.resources.textFillColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message:
                    'On-device LLM patch generation (Phi Silica) — coming soon',
                child: Button(
                  onPressed: null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(FluentIcons.processing, size: 14),
                      SizedBox(width: 6),
                      Text('Draft with Phi Silica'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Observation', style: theme.typography.bodyStrong),
          const SizedBox(height: 4),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.resources.subtleFillColorSecondary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.resources.controlStrokeColorDefault,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  attempt.observationMd.isEmpty
                      ? '(no observation recorded)'
                      : attempt.observationMd,
                  style: const TextStyle(
                    fontFamily: 'Cascadia Code',
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Proposed patch', style: theme.typography.bodyStrong),
          const SizedBox(height: 4),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.resources.subtleFillColorSecondary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.resources.controlStrokeColorDefault,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  attempt.proposedPatch.isEmpty
                      ? 'LLM patch generation pending — observation is the '
                            'user-facing signal for now.'
                      : attempt.proposedPatch,
                  style: TextStyle(
                    fontFamily: 'Cascadia Code',
                    fontSize: 12.5,
                    height: 1.45,
                    color: attempt.proposedPatch.isEmpty
                        ? theme.resources.textFillColorSecondary
                        : theme.resources.textFillColorPrimary,
                    fontStyle: attempt.proposedPatch.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: ProgressRing(strokeWidth: 2),
                  ),
                ),
              Button(
                onPressed: busy ? null : () => onReject(attempt),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: busy ? null : () => onApprove(attempt),
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: theme.resources.textFillColorPrimary,
        ),
      ),
    );
  }
}

// Lightly tint the failure-class chip so the common classes are
// visually distinct at a glance. Unknown / novel classes fall through
// to the subtle fill so they still render without a custom palette.
Color _failureClassColor(FluentThemeData theme, String failureClass) {
  switch (failureClass) {
    case 'test_failure':
      return const Color(0xFFFDE7E9); // blush
    case 'build_failure':
      return const Color(0xFFFFF4CE); // amber
    case 'review_rejection':
      return const Color(0xFFDFF6DD); // mint
    case 'timeout':
      return const Color(0xFFE5E5E5); // grey
    default:
      return theme.resources.subtleFillColorTertiary;
  }
}

String _firstLine(String md) {
  if (md.isEmpty) return '(no observation)';
  final trimmed = md.trim();
  if (trimmed.length <= 60) return trimmed.replaceAll('\n', ' ');
  return '${trimmed.substring(0, 60).replaceAll('\n', ' ')}…';
}

String _shortId(String id) {
  if (id.length <= 12) return id;
  return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
}

String _relativeTime(DateTime t) {
  final delta = DateTime.now().difference(t);
  if (delta.inSeconds < 60) return '${delta.inSeconds}s ago';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
