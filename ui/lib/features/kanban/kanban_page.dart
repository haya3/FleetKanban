// Kanban page: repo picker header + KanbanBoard. Phase C hello-world.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import 'kanban_board.dart';
import 'new_task_dialog.dart';
import 'providers.dart';
import 'register_repo_dialog.dart';

class KanbanPage extends ConsumerWidget {
  const KanbanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositories = ref.watch(kanbanRepositoriesProvider);
    final selectedRepoId = ref.watch(selectedRepoIdProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Kanban'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('New task'),
              onPressed: selectedRepoId == null
                  ? null
                  : () => showNewTaskDialog(
                      context,
                      initialRepoId: selectedRepoId,
                    ),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.folder_horizontal),
              label: const Text('Register repository'),
              onPressed: () => showRegisterRepositoryDialog(context),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: selectedRepoId == null
                  ? null
                  : () => ref.invalidate(tasksProvider(selectedRepoId)),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Repo picker.
            repositories.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: ProgressBar(),
              ),
              error: (e, _) => ErrorInfoBar(
                title: 'Failed to load repositories',
                message: '$e',
              ),
              data: (repos) {
                if (repos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No repositories registered. Use "Register repository" in the top-right to add one.',
                    ),
                  );
                }
                // Default-select the first repo if none picked yet.
                if (selectedRepoId == null ||
                    !repos.any((r) => r.id == selectedRepoId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(selectedRepoIdProvider.notifier).state =
                        repos.first.id;
                  });
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(FluentIcons.repo, size: 14),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 320,
                        child: ComboBox<String>(
                          isExpanded: true,
                          value: selectedRepoId ?? repos.first.id,
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
                          onChanged: (id) =>
                              ref.read(selectedRepoIdProvider.notifier).state =
                                  id,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (selectedRepoId != null)
              Expanded(child: KanbanBoard(repoId: selectedRepoId)),
          ],
        ),
      ),
    );
  }
}
