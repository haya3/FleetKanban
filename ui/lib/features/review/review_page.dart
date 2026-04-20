// ReviewPage: diff + Keep/Merge/Discard actions for the selected task.
// Finalize buttons are only actionable while the task is in human_review;
// for other statuses the page becomes read-only.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../kanban/providers.dart'
    show selectedRepoIdProvider, selectedTaskIdProvider, tasksProvider;
import 'diff_view.dart';
import 'providers.dart';

class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskId = ref.watch(selectedTaskIdProvider);
    if (taskId == null) {
      return const ScaffoldPage(
        header: PageHeader(title: Text('Review')),
        content: Center(child: Text('Select a task')),
      );
    }

    final task = _findTask(ref, taskId);
    final diff = ref.watch(parsedDiffProvider(taskId));
    final canFinalize = task?.status == 'human_review';

    return ScaffoldPage(
      header: PageHeader(
        title: Text(task == null ? 'Review' : 'Review — ${task.goal}'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.check_mark),
              label: const Text('Keep'),
              onPressed: canFinalize
                  ? () => _finalize(
                      ref,
                      context,
                      taskId,
                      pb.FinalizeAction.FINALIZE_ACTION_KEEP,
                    )
                  : null,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.branch_merge),
              label: const Text('Merge'),
              onPressed: canFinalize
                  ? () => _finalize(
                      ref,
                      context,
                      taskId,
                      pb.FinalizeAction.FINALIZE_ACTION_MERGE,
                    )
                  : null,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.delete),
              label: const Text('Discard'),
              onPressed: canFinalize
                  ? () => _finalize(
                      ref,
                      context,
                      taskId,
                      pb.FinalizeAction.FINALIZE_ACTION_DISCARD,
                    )
                  : null,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: () => ref.invalidate(taskDiffProvider(taskId)),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: diff.when(
          loading: () => const Center(child: ProgressRing()),
          error: (e, _) => ErrorInfoBar(
            title: 'Failed to load diff',
            message: '$e',
            severity: InfoBarSeverity.error,
          ),
          data: (files) => DiffView(files: files),
        ),
      ),
    );
  }

  pb.Task? _findTask(WidgetRef ref, String id) {
    final repoId = ref.read(selectedRepoIdProvider);
    if (repoId == null) return null;
    final tasks = ref.read(tasksProvider(repoId)).valueOrNull;
    if (tasks == null) return null;
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _finalize(
    WidgetRef ref,
    BuildContext context,
    String taskId,
    pb.FinalizeAction action,
  ) async {
    try {
      await finalizeTask(ref, taskId: taskId, action: action);
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (_, close) {
            return InfoBar(
              title: Text('${_actionLabel(action)} complete'),
              severity: InfoBarSeverity.success,
              isLong: false,
              onClose: close,
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (_, close) {
            return InfoBar(
              title: Text('${_actionLabel(action)} failed'),
              content: CopyableErrorText(
                text: '$e',
                reportTitle: 'Review / ${_actionLabel(action)} failed',
              ),
              severity: InfoBarSeverity.error,
              onClose: close,
            );
          },
        );
      }
    }
  }

  String _actionLabel(pb.FinalizeAction action) {
    switch (action) {
      case pb.FinalizeAction.FINALIZE_ACTION_KEEP:
        return 'Keep';
      case pb.FinalizeAction.FINALIZE_ACTION_MERGE:
        return 'Merge';
      case pb.FinalizeAction.FINALIZE_ACTION_DISCARD:
        return 'Discard';
      default:
        return 'Finalize';
    }
  }
}
