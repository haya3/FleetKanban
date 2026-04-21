// TaskCard: richer Kanban card modeled after the reference mockup.
//
// Layout (top → bottom):
//   1. Title row       : goal first line (bold) + kebab (▸ detail dialog)
//   2. Subtitle        : branch name (monospace, secondary color)
//   3. Status chips    : e.g. "Aborted", "Needs recovery" for failed/aborted cases
//   4. Phase label     : "Planning" / "Running" / "Interrupted" / …
//   5. Stage stepper   : Plan — Code — Review — Done with the active stage
//                        drawn in accent and completed stages muted
//   6. Footer row      : relative time + context-aware action button
//
// Double-tap opens the detail dialog (tabs: Overview / Subtasks / Logs /
// Files). Single-tap toggles the Kanban selection.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/ui_utils.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'providers.dart';
import 'rework_dialog.dart';
import 'task_detail_dialog.dart';

// Keys match internal/task/task.go exactly.
const Map<String, String> _statusLabel = {
  'planning': 'Planning',
  'queued': 'Queued',
  'in_progress': 'In Progress',
  'ai_review': 'AI Review',
  'human_review': 'Awaiting Review',
  'done': 'Done',
  'cancelled': 'Cancelled',
  'aborted': 'Interrupted',
  'failed': 'Failed',
};

const Map<String, Color> _statusColor = {
  'planning': Color(0xFF8A8A8A),
  'queued': Color(0xFF8A8A8A),
  'in_progress': Color(0xFF0067C0),
  'ai_review': Color(0xFF4F8ACC),
  'human_review': Color(0xFFC29C00),
  'done': Color(0xFF107C10),
  'cancelled': Color(0xFF8A3B00),
  'aborted': Color(0xFFC29C00),
  'failed': Color(0xFFC42B1C),
};

Color statusColor(String status) =>
    _statusColor[status] ?? const Color(0xFF8A8A8A);

// Pipeline stages visualized on the card. The `matches` set defines which
// raw task.status values light up that stage; later stages are "done" once
// the task has moved past them.
enum _Stage { plan, code, review, done }

const Map<_Stage, Set<String>> _stageStatuses = {
  _Stage.plan: {'planning', 'queued'},
  _Stage.code: {'in_progress', 'aborted', 'failed'},
  _Stage.review: {'ai_review', 'human_review'},
  _Stage.done: {'done', 'cancelled'},
};

_Stage _stageFor(String status) {
  for (final e in _stageStatuses.entries) {
    if (e.value.contains(status)) return e.key;
  }
  return _Stage.plan;
}

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.isSelected = false,
    this.isDragging = false,
    this.onTap,
    this.onDoubleTap,
  });

  final pb.Task task;
  final bool isSelected;
  final bool isDragging;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = statusColor(task.status);
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final lines = task.goal.split('\n');
    final title = lines.first.isEmpty ? '(no goal)' : lines.first;
    final subtitle = lines.length > 1
        ? lines.sublist(1).join(' ').trim()
        : task.branch;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: isDragging ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: resources.cardBackgroundFillColorDefault,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.accentColor.defaultBrushFor(theme.brightness)
                  : resources.controlStrokeColorDefault,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TitleRow(task: task, title: title),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.typography.caption?.copyWith(
                                color: resources.textFillColorSecondary,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ],
                          if (_buildChips(task).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _buildChips(task),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _PhaseLabel(status: task.status, accent: accent),
                          const SizedBox(height: 6),
                          _StageStepper(task: task),
                          const SizedBox(height: 10),
                          _FooterRow(task: task),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.task, required this.title});
  final pb.Task task;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.bodyStrong,
          ),
        ),
        const SizedBox(width: 4),
        _KebabMenu(task: task),
      ],
    );
  }
}

class _KebabMenu extends ConsumerWidget {
  const _KebabMenu({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return clickable(
      IconButton(
        icon: const Icon(FluentIcons.more_vertical, size: 14),
        onPressed: () => showTaskDetailDialog(context, task: task),
      ),
    );
  }
}

/// Small colored pill. FilledButton-like visual but non-interactive.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _buildChips(pb.Task task) {
  final chips = <Widget>[];
  switch (task.status) {
    case 'aborted':
      chips.add(
        const _Chip(
          label: 'Aborted',
          color: Color(0xFFC29C00),
          icon: FluentIcons.warning,
        ),
      );
      chips.add(const _Chip(label: 'Resumable', color: Color(0xFF8A5C00)));
    case 'failed':
      chips.add(
        _Chip(
          label: task.errorCode.isEmpty ? 'Failed' : task.errorCode,
          color: const Color(0xFFC42B1C),
          icon: FluentIcons.error,
        ),
      );
    case 'human_review':
      chips.add(
        const _Chip(
          label: 'Awaiting review',
          color: Color(0xFFC29C00),
          icon: FluentIcons.clock,
        ),
      );
    case 'in_progress':
      chips.add(
        const _Chip(
          label: 'Running',
          color: Color(0xFF0067C0),
          icon: FluentIcons.play_resume,
        ),
      );
    case 'done':
      chips.add(
        const _Chip(
          label: 'Done',
          color: Color(0xFF107C10),
          icon: FluentIcons.check_mark,
        ),
      );
    default:
      break;
  }
  if (task.branchExists && task.status != 'cancelled') {
    // Just the chip types above; don't spam more by default.
  }
  return chips;
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({required this.status, required this.accent});
  final String status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final label = _statusLabel[status] ?? status;
    return Row(
      children: [
        Text(
          label,
          style: theme.typography.caption?.copyWith(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Icon(
          FluentIcons.chevron_down,
          size: 10,
          color: theme.resources.textFillColorTertiary,
        ),
      ],
    );
  }
}

class _StageStepper extends StatelessWidget {
  const _StageStepper({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final status = task.status;
    final accent = statusColor(status);
    final current = _stageFor(status);
    // Each stage carries the model id that actually ran it. Done is a
    // summary row, not a sub-agent — no model to attribute.
    final stages = <(_Stage, String, String)>[
      (_Stage.plan, 'Plan', task.planModel),
      (_Stage.code, 'Code', task.model),
      (_Stage.review, 'Review', task.reviewModel),
      (_Stage.done, 'Done', ''),
    ];
    final children = <Widget>[];
    for (var i = 0; i < stages.length; i++) {
      final (stage, label, model) = stages[i];
      final isCurrent = stage == current;
      final isPast = stage.index < current.index;
      final color = isCurrent
          ? accent
          : isPast
          ? theme.resources.textFillColorSecondary
          : theme.resources.textFillColorDisabled;
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isCurrent
                ? accent.withValues(alpha: 0.12)
                : theme.resources.subtleFillColorTertiary,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Tooltip(
            message: model.isEmpty
                ? '$label: model not recorded'
                : '$label: $model',
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
      if (i < stages.length - 1) {
        children.add(
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 1,
              color: theme.resources.dividerStrokeColorDefault,
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: theme.resources.subtleFillColorTertiary,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressFraction(current),
            child: Container(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: children),
        const SizedBox(height: 4),
        _StageModelRow(task: task),
      ],
    );
  }

  double _progressFraction(_Stage s) {
    switch (s) {
      case _Stage.plan:
        return 0.1;
      case _Stage.code:
        return 0.45;
      case _Stage.review:
        return 0.8;
      case _Stage.done:
        return 1.0;
    }
  }
}

/// Stage → model id mapping shown under the stepper. Surfaces which model
/// actually produced each artifact. Empty values render as a dimmed "—" so
/// the row is consistent before every stage has run.
class _StageModelRow extends StatelessWidget {
  const _StageModelRow({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final dim = theme.resources.textFillColorTertiary;
    final text = theme.resources.textFillColorSecondary;
    Widget cell(String model) {
      final shown = model.isEmpty ? '—' : _shortModel(model);
      return Expanded(
        child: Tooltip(
          message: model.isEmpty ? 'Model not recorded' : model,
          child: Text(
            shown,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: model.isEmpty ? dim : text,
              fontFamily: 'Consolas',
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        cell(task.planModel),
        cell(task.model),
        cell(task.reviewModel),
        // Done column has no attributable model; keep the column so the
        // row aligns visually with the stepper above.
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  // Strip common vendor prefixes so a 20+ char id like
  // "github-copilot/gpt-4.1-2024-11-01" fits in the card width. Preserve
  // the tooltip so the user can still see the full id on hover.
  static String _shortModel(String model) {
    final slash = model.lastIndexOf('/');
    final trimmed = slash >= 0 ? model.substring(slash + 1) : model;
    if (trimmed.length > 14) return '${trimmed.substring(0, 13)}…';
    return trimmed;
  }
}

class _FooterRow extends ConsumerWidget {
  const _FooterRow({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    return Row(
      children: [
        Icon(
          FluentIcons.clock,
          size: 11,
          color: theme.resources.textFillColorTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          _relativeTime(task),
          style: theme.typography.caption?.copyWith(
            color: theme.resources.textFillColorTertiary,
          ),
        ),
        const Spacer(),
        _PrimaryAction(task: task),
      ],
    );
  }

  String _relativeTime(pb.Task task) {
    DateTime? t;
    try {
      if (task.hasFinishedAt()) {
        t = task.finishedAt.toDateTime();
      } else if (task.hasStartedAt()) {
        t = task.startedAt.toDateTime();
      } else if (task.hasUpdatedAt()) {
        t = task.updatedAt.toDateTime();
      } else if (task.hasCreatedAt()) {
        t = task.createdAt.toDateTime();
      }
    } catch (_) {}
    if (t == null) return '—';
    final diff = DateTime.now().toUtc().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PrimaryAction extends ConsumerWidget {
  const _PrimaryAction({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (task.status) {
      case 'queued':
        return _pill(
          icon: FluentIcons.play,
          label: 'Run',
          color: const Color(0xFF0067C0),
          onPressed: () => ref
              .read(runTaskProvider.notifier)
              .run(task.id),
        );
      case 'planning':
        // Planning is owned by the orchestrator — the AI planner is either
        // running or about to run. Surfacing a Run button here would hit
        // the sidecar's `cannot run a task in status planning` guard, so
        // pair the progress indicator with a Stop button that cancels the
        // planner goroutine (transitions the task to cancelled).
        return _PlanningActions(task: task);
      case 'in_progress':
        return _pill(
          icon: FluentIcons.stop,
          label: 'Abort',
          color: const Color(0xFF8A3B00),
          onPressed: () => ref
              .read(cancelTaskProvider.notifier)
              .run(task.id),
        );
      case 'aborted':
        // Aborted is non-terminal (phase1-spec §2-7): branch + worktree were
        // kept so the user can pick up where the run stopped. Surface the
        // same three-way post-processing UI as Human Review, plus Re-run to
        // re-queue the goal from scratch.
        return _AbortedActions(task: task);
      case 'failed':
        return _pill(
          icon: FluentIcons.refresh,
          label: 'Re-run',
          color: const Color(0xFFC29C00),
          onPressed: () => ref
              .read(runTaskProvider.notifier)
              .run(task.id),
        );
      case 'done':
        // After Keep finalize the branch lingers for the user's external
        // merge workflow. Once they're done with it (or the Merged-sweep
        // hasn't caught it yet), offer a one-click Discard branch.
        if (task.branchExists) {
          return _DiscardBranchAction(task: task);
        }
        return const SizedBox.shrink();
      case 'ai_review':
        // Approve via DnD to the Human Review column or via this pill —
        // both hit SubmitReview(APPROVE). Kept here so users don't have
        // to drag for a common action.
        return _pill(
          icon: FluentIcons.forward,
          label: 'Advance',
          color: const Color(0xFF4F8ACC),
          onPressed: () => ref
              .read(submitReviewProvider.notifier)
              .submit(
                taskId: task.id,
                action: pb.ReviewAction.REVIEW_ACTION_APPROVE,
              ),
        );
      case 'human_review':
        return _HumanReviewActions(task: task);
      default:
        return const SizedBox.shrink();
    }
  }
}

// _PlanningActions renders a non-interactive "Planning…" progress pill
// paired with a Stop button so the user can abort while the AI planner
// is still drafting the plan. Cancel transitions the task straight to
// cancelled (no worktree was created yet); the detail-dialog delete
// path additionally removes the row.
class _PlanningActions extends ConsumerWidget {
  const _PlanningActions({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const _PlanningPill(),
        _kanbanMiniPill(
          icon: FluentIcons.stop,
          label: 'Stop',
          color: const Color(0xFF8A3B00),
          onPressed: () => ref
              .read(cancelTaskProvider.notifier)
              .run(task.id),
        ),
      ],
    );
  }
}

class _PlanningPill extends StatelessWidget {
  const _PlanningPill();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8A8A8A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: ProgressRing(strokeWidth: 1.4),
          ),
          SizedBox(width: 6),
          Text(
            'Planning…',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// HumanReviewActions is the three-pill cluster (Keep / Re-run / Discard) shown
// on Human Review cards. Extracted because fitting three pills into the
// footer needs its own layout (wrap with tight spacing) that doesn't
// generalize to single-action cards.
class _HumanReviewActions extends ConsumerWidget {
  const _HumanReviewActions({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _miniPill(
          icon: FluentIcons.check_mark,
          label: 'Keep',
          color: const Color(0xFF107C10),
          onPressed: () => ref
              .read(finalizeKeepProvider.notifier)
              .run(task.id),
        ),
        _miniPill(
          icon: FluentIcons.refresh,
          label: 'Re-run',
          color: const Color(0xFFC29C00),
          onPressed: () => _rework(context, ref),
        ),
        _miniPill(
          icon: FluentIcons.delete,
          label: 'Discard',
          color: const Color(0xFFC42B1C),
          iconOnly: true,
          onPressed: () => ref
              .read(finalizeDiscardProvider.notifier)
              .run(task.id),
        ),
      ],
    );
  }

  Future<void> _rework(BuildContext context, WidgetRef ref) async {
    final feedback = await showReworkDialog(context, task: task);
    if (feedback == null || feedback.trim().isEmpty) return;
    await ref
        .read(submitReviewProvider.notifier)
        .submit(
          taskId: task.id,
          action: pb.ReviewAction.REVIEW_ACTION_REWORK,
          feedback: feedback,
        );
  }

  // Deprecated in-class alias → delegates to the top-level helper so the
  // shared Aborted / Human Review / Done clusters render identically.
  Widget _miniPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool iconOnly = false,
  }) {
    return _kanbanMiniPill(
      icon: icon,
      label: label,
      color: color,
      onPressed: onPressed,
      iconOnly: iconOnly,
    );
  }
}

// _kanbanMiniPill renders the small footer action pill used across Aborted /
// Human Review / Done clusters. Pass iconOnly: true to collapse to a square
// icon-only pill; the text label becomes a Tooltip so screen readers and
// hover discoverability still surface it. The destructive Discard branch
// actions use icon-only mode so all three pills (Keep / Re-run / Discard)
// fit on one row inside the narrow Kanban card width.
Widget _kanbanMiniPill({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onPressed,
  bool iconOnly = false,
}) {
  // fluent_ui's Button defers its mouse cursor to the parent, so pills look
  // identical to the surrounding card on hover. Force the pointer cursor so
  // users can tell the pill is clickable without trial-and-error.
  final button = clickable(
    Button(
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          iconOnly
              ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
        backgroundColor: WidgetStatePropertyAll(color.withValues(alpha: 0.12)),
        foregroundColor: WidgetStatePropertyAll(color),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.45)),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          if (!iconOnly) ...[
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    ),
  );
  if (!iconOnly) return button;
  return Tooltip(message: label, child: button);
}

// Top-level pill helper shared by _PrimaryAction and future single-action
// widgets. Kept outside any class because extension methods confused the
// analyzer when called from inside the same class that the extension
// targeted.
Widget _pill({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onPressed,
}) {
  return clickable(
    Button(
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        backgroundColor: WidgetStatePropertyAll(color.withValues(alpha: 0.12)),
        foregroundColor: WidgetStatePropertyAll(color),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withValues(alpha: 0.45)),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// _AbortedActions is the three-pill cluster for Aborted cards (phase1-spec
// §2-7). Keep and Discard drive FinalizeTask (Aborted → Done or Cancelled);
// Re-run re-queues the same goal via RunTask.
class _AbortedActions extends ConsumerWidget {
  const _AbortedActions({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _kanbanMiniPill(
          icon: FluentIcons.check_mark,
          label: 'Keep',
          color: const Color(0xFF107C10),
          onPressed: () => ref
              .read(finalizeKeepProvider.notifier)
              .run(task.id),
        ),
        _kanbanMiniPill(
          icon: FluentIcons.refresh,
          label: 'Re-run',
          color: const Color(0xFFC29C00),
          onPressed: () => ref
              .read(runTaskProvider.notifier)
              .run(task.id),
        ),
        _kanbanMiniPill(
          icon: FluentIcons.delete,
          label: 'Discard',
          color: const Color(0xFFC42B1C),
          iconOnly: true,
          onPressed: () => _confirmAndDiscard(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmAndDiscard(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Discard this task?'),
        content: Text(
          'Both the worktree and the branch ${task.branch} will be deleted '
          'and the task will move to Cancelled. This cannot be undone.',
        ),
        actions: [
          clickable(
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ),
          clickable(
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  FluentTheme.of(ctx).resources.systemFillColorCritical,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(finalizeDiscardProvider.notifier).run(task.id);
    }
  }
}

// _DiscardBranchAction is the single-pill cluster shown on Done cards when
// the fleetkanban/<id> branch still exists. The task row is preserved — only
// the branch is deleted (uses DeleteTaskBranch RPC, `git branch -D`).
class _DiscardBranchAction extends ConsumerWidget {
  const _DiscardBranchAction({required this.task});
  final pb.Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _kanbanMiniPill(
      icon: FluentIcons.delete,
      label: 'Delete branch',
      color: const Color(0xFFC42B1C),
      iconOnly: true,
      onPressed: () => _confirm(context, ref),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Delete branch?'),
        content: Text(
          'Branch ${task.branch} will be deleted (git branch -D). '
          'Any unmerged changes on it will be lost. Task history is preserved.',
        ),
        actions: [
          clickable(
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ),
          clickable(
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  FluentTheme.of(ctx).resources.systemFillColorCritical,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(deleteBranchProvider.notifier).run(task.id);
    }
  }
}
