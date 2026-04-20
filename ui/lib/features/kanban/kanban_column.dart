// KanbanColumn: droppable column with a coloured header and a list of
// Draggable<Task> cards.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'providers.dart';
import 'task_card.dart';
import 'task_detail_dialog.dart';

class KanbanColumn extends ConsumerWidget {
  const KanbanColumn({super.key, required this.columnId, required this.tasks});

  final KanbanColumnId columnId;
  final List<pb.Task> tasks;

  Color get _accent {
    switch (columnId) {
      case KanbanColumnId.pending:
        return const Color(0xFF8A8A8A);
      case KanbanColumnId.running:
        return const Color(0xFF0067C0);
      case KanbanColumnId.aiReview:
        return const Color(0xFF4F8ACC);
      case KanbanColumnId.humanReview:
        return const Color(0xFFC29C00);
      case KanbanColumnId.done:
        return const Color(0xFF107C10);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedTaskIdProvider);
    final theme = FluentTheme.of(context);

    return DragTarget<pb.Task>(
      onWillAcceptWithDetails: (details) =>
          canTransition(currentStatus: details.data.status, target: columnId),
      onAcceptWithDetails: (details) =>
          performTransition(ref, task: details.data, target: columnId),
      builder: (context, candidate, rejected) {
        final isActive = candidate.isNotEmpty;
        return Container(
          width: 260,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: theme.resources.layerFillColorDefault.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? _accent
                  : theme.resources.controlStrokeColorDefault,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      kanbanColumnLabels[columnId]!,
                      style: theme.typography.bodyStrong,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.resources.subtleFillColorSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: theme.typography.caption,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                style: DividerThemeData(
                  thickness: 1,
                  decoration: BoxDecoration(
                    color: theme.resources.dividerStrokeColorDefault,
                  ),
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text('タスクなし', style: theme.typography.caption),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        itemBuilder: (_, i) => _DraggableCard(
                          task: tasks[i],
                          selected: tasks[i].id == selectedId,
                          onTap: () =>
                              ref
                                  .read(selectedTaskIdProvider.notifier)
                                  .state = tasks[i].id == selectedId
                              ? null
                              : tasks[i].id,
                          onDoubleTap: () =>
                              showTaskDetailDialog(context, task: tasks[i]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    required this.task,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });
  final pb.Task task;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    // Single source of truth for draggable states lives in providers.dart so
    // kanban_column and canTransition agree on what can move.
    if (!canDrag(task.status)) {
      return TaskCard(
        task: task,
        isSelected: selected,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
      );
    }
    return Draggable<pb.Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        elevation: 12,
        child: SizedBox(
          width: 244, // column width minus padding
          child: TaskCard(task: task, isSelected: false, isDragging: false),
        ),
      ),
      childWhenDragging: TaskCard(task: task, isDragging: true),
      child: TaskCard(
        task: task,
        isSelected: selected,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
      ),
    );
  }
}
