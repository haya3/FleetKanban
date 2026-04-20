// KanbanBoard: Row of 4 KanbanColumns. Reads tasksProvider for the current
// repo, filters them into column buckets, and renders DragTargets.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'kanban_column.dart';
import 'providers.dart';

class KanbanBoard extends ConsumerWidget {
  const KanbanBoard({super.key, required this.repoId});
  final String repoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider(repoId));
    return tasks.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) =>
          ErrorInfoBar(title: 'Failed to load tasks', message: '$e'),
      data: (list) => _Board(tasks: list),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.tasks});
  final List<pb.Task> tasks;

  @override
  Widget build(BuildContext context) {
    final buckets = <KanbanColumnId, List<pb.Task>>{
      for (final c in KanbanColumnId.values) c: <pb.Task>[],
    };
    for (final t in tasks) {
      final col = columnForStatus(t.status);
      if (col != null) buckets[col]!.add(t);
    }
    // Sort by updatedAt descending inside each column.
    for (final list in buckets.values) {
      list.sort((a, b) {
        final av = a.updatedAt.seconds * 1000 + (a.updatedAt.nanos ~/ 1000000);
        final bv = b.updatedAt.seconds * 1000 + (b.updatedAt.nanos ~/ 1000000);
        return bv.compareTo(av);
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            children: [
              for (final col in KanbanColumnId.values)
                KanbanColumn(columnId: col, tasks: buckets[col]!),
            ],
          ),
        ),
      ),
    );
  }
}
