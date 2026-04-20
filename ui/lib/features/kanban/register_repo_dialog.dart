// RegisterRepositoryDialog: pick a folder, then register it. Three flows:
//
//   1. The folder IS a git repo       — single-repo form, auto-fills name.
//   2. The folder contains nested repos — multi-select checklist so the
//      user can batch-register `C:\src\*` with one click.
//   3. The folder is not a repo, no children — offer `git init` inline.
//
// Flow (2) and (3) are detected in one round trip via
// RepositoryService.ScanGitRepositories, so the user never has to manually
// type a subfolder path or guess that the parent is not actually a repo.

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart' show GrpcError;

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';
import '../settings/providers.dart' show createInitialCommit;
import 'providers.dart';

Future<String?> showRegisterRepositoryDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (_) => const _RegisterRepoDialog(),
  );
}

class _RegisterRepoDialog extends ConsumerStatefulWidget {
  const _RegisterRepoDialog();

  @override
  ConsumerState<_RegisterRepoDialog> createState() =>
      _RegisterRepoDialogState();
}

class _RegisterRepoDialogState extends ConsumerState<_RegisterRepoDialog> {
  final _pathController = TextEditingController();
  final _nameController = TextEditingController();
  bool _submitting = false;
  bool _scanning = false;
  String? _error;

  // Populated after the user picks a folder that isn't itself a repo.
  pb.ScanGitRepositoriesResponse? _scan;
  final Set<String> _selectedPaths = <String>{};

  @override
  void dispose() {
    _pathController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final picked = await getDirectoryPath(
      confirmButtonText: 'Select',
      initialDirectory: _pathController.text.trim().isEmpty
          ? null
          : _pathController.text.trim(),
    );
    if (picked == null) return;
    setState(() {
      _pathController.text = picked;
      if (_nameController.text.trim().isEmpty) {
        final base = _basename(picked);
        if (base != null) _nameController.text = base;
      }
      _error = null;
      _scan = null;
      _selectedPaths.clear();
    });
    await _scanPath(picked);
  }

  Future<void> _scanPath(String path) async {
    setState(() => _scanning = true);
    try {
      final client = ref.read(ipcClientProvider);
      final resp = await client.repository.scanGitRepositories(
        pb.ScanGitRepositoriesRequest(path: path, maxDepth: 3),
      );
      if (!mounted) return;
      setState(() {
        _scan = resp;
        // Pre-select every not-yet-registered candidate.
        _selectedPaths
          ..clear()
          ..addAll(
            resp.repositories
                .where((r) => !r.alreadyRegistered)
                .map((r) => r.path),
          );
        _scanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _scan = null;
      });
    }
  }

  Future<void> _submitSingle({bool initializeIfEmpty = false}) async {
    final path = _pathController.text.trim();
    final name = _nameController.text.trim();
    if (path.isEmpty) {
      setState(() => _error = 'Enter a path');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Enter a display name');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final client = ref.read(ipcClientProvider);
      final created = await client.repository.registerRepository(
        pb.RegisterRepositoryRequest(
          path: path,
          displayName: name,
          initializeIfEmpty: initializeIfEmpty,
        ),
      );
      ref.invalidate(kanbanRepositoriesProvider);
      ref.read(selectedRepoIdProvider.notifier).state = created.id;
      // Freshly `git init`'d repos (either via initialize_if_empty above or
      // registered in that state by the user) have no commits yet — task
      // creation will fail with "could not determine a base branch" until
      // one exists. Offer to seed a FleetKanban-authored empty commit so
      // the user never hits that error at task-creation time.
      if (mounted) {
        await _maybeSeedInitialCommit(created.id);
      }
      if (mounted) Navigator.of(context).pop(created.id);
    } on GrpcError catch (e) {
      if (e.message != null && e.message!.startsWith('not_a_git_repo:')) {
        final go = await _askInitialize(path);
        if (!mounted) return;
        if (go == true) {
          await _submitSingle(initializeIfEmpty: true);
          return;
        }
        setState(() {
          _submitting = false;
          _error = 'This folder is not under git.';
        });
        return;
      }
      setState(() {
        _submitting = false;
        _error = '$e';
      });
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = '$e';
      });
    }
  }

  Future<void> _submitMulti() async {
    if (_selectedPaths.isEmpty) {
      setState(() => _error = 'Select repositories to register');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final client = ref.read(ipcClientProvider);
    final failures = <String>[];
    String? lastId;
    for (final path in _selectedPaths) {
      try {
        final created = await client.repository.registerRepository(
          pb.RegisterRepositoryRequest(
            path: path,
            displayName: _basename(path) ?? path,
          ),
        );
        lastId = created.id;
      } catch (e) {
        failures.add('$path: $e');
      }
    }
    ref.invalidate(kanbanRepositoriesProvider);
    if (lastId != null) {
      ref.read(selectedRepoIdProvider.notifier).state = lastId;
    }
    if (!mounted) return;
    if (failures.isEmpty) {
      Navigator.of(context).pop(lastId);
      return;
    }
    setState(() {
      _submitting = false;
      _error = '${failures.length} failed:\n${failures.join('\n')}';
    });
  }

  // Check the freshly-registered repo's HEAD state and, if it has no
  // commits, prompt the user to seed one via CreateInitialCommit. The
  // prompt is skipped silently on network / RPC failure — registration
  // already succeeded and the user can always seed later from Settings.
  Future<void> _maybeSeedInitialCommit(String repositoryId) async {
    try {
      final client = ref.read(ipcClientProvider);
      final resp = await client.repository.listBranches(
        pb.ListBranchesRequest(repositoryId: repositoryId),
      );
      if (resp.hasCommits || !mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => ContentDialog(
          title: const Text('Create an initial commit?'),
          content: const Text(
            'This repository has no commits yet, so a base branch cannot be '
            'resolved and tasks cannot be created.\n'
            'Press "Create" to seed an empty commit (--allow-empty) authored '
            'by FleetKanban.',
          ),
          actions: [
            Button(
              child: const Text('Later'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              child: const Text('Create'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
      await createInitialCommit(ref, repositoryId: repositoryId);
    } catch (_) {
      // Non-fatal: registration already succeeded. The Settings page still
      // surfaces the unborn-HEAD banner with the same action.
    }
  }

  Future<bool?> _askInitialize(String path) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Initialize as a git repository?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(path, style: FluentTheme.of(context).typography.bodyStrong),
            const SizedBox(height: 12),
            const Text(
              'This folder is not under git.\n'
              'Pressing "Initialize" runs the equivalent of '
              '`git init --initial-branch=main` and then registers it.',
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            child: const Text('Initialize'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  bool get _isMultiMode =>
      _scan != null && !_scan!.rootIsRepo && _scan!.repositories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(
        _isMultiMode
            ? 'Register repositories (${_selectedPaths.length}/${_scan!.repositories.length})'
            : 'Register repository',
      ),
      constraints: const BoxConstraints(maxWidth: 560),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoLabel(
            label: 'Root folder',
            child: Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _pathController,
                    placeholder: r'C:\Users\you\src',
                    enabled: !_submitting,
                    onSubmitted: (_) => _scanPath(_pathController.text.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: _submitting ? null : _pickDirectory,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.folder_open, size: 14),
                      SizedBox(width: 6),
                      Text('Browse…'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_scanning) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: ProgressRing(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Scanning for repositories…'),
              ],
            ),
          ] else if (_isMultiMode) ...[
            const SizedBox(height: 12),
            const Text(
              'The root folder is not itself a git repository, but the '
              'following were found in its subdirectories. Select the ones '
              'you want to register.',
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                border: Border.all(
                  color: FluentTheme.of(
                    context,
                  ).resources.controlStrokeColorDefault,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _scan!.repositories.length,
                separatorBuilder: (_, _) => Divider(
                  style: DividerThemeData(
                    decoration: BoxDecoration(
                      color: FluentTheme.of(
                        context,
                      ).resources.dividerStrokeColorDefault,
                    ),
                  ),
                ),
                itemBuilder: (_, i) => _RepoRow(
                  repo: _scan!.repositories[i],
                  checked: _selectedPaths.contains(_scan!.repositories[i].path),
                  onChanged: (v) => setState(() {
                    final p = _scan!.repositories[i].path;
                    if (v == true) {
                      _selectedPaths.add(p);
                    } else {
                      _selectedPaths.remove(p);
                    }
                  }),
                ),
              ),
            ),
          ] else if (_scan != null && _scan!.rootIsRepo) ...[
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Display name',
              child: TextBox(
                controller: _nameController,
                placeholder: 'my-repo',
                enabled: !_submitting,
              ),
            ),
          ] else if (_scan != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: const Text('No git repository found'),
              content: const Text(
                'This folder is not under git and no repositories were found '
                'in its subfolders. Press "Register" to be prompted to initialize one.',
              ),
              severity: InfoBarSeverity.warning,
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Display name',
              child: TextBox(
                controller: _nameController,
                placeholder: 'my-repo',
                enabled: !_submitting,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorInfoBar(title: 'Failed to register', message: _error!),
          ],
        ],
      ),
      actions: [
        Button(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting
              ? null
              : (_isMultiMode ? _submitMulti : _submitSingle),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: ProgressRing(strokeWidth: 2),
                )
              : Text(
                  _isMultiMode
                      ? 'Register ${_selectedPaths.length} selected'
                      : 'Register',
                ),
        ),
      ],
    );
  }
}

class _RepoRow extends StatelessWidget {
  const _RepoRow({
    required this.repo,
    required this.checked,
    required this.onChanged,
  });
  final pb.FoundRepository repo;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final disabled = repo.alreadyRegistered;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Checkbox(checked: checked, onChanged: disabled ? null : onChanged),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  repo.path,
                  style: theme.typography.body,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (repo.defaultBranch.isNotEmpty)
                      Text(
                        'branch: ${repo.defaultBranch}',
                        style: theme.typography.caption?.copyWith(
                          color: theme.resources.textFillColorSecondary,
                          fontFamily: 'Consolas',
                        ),
                      ),
                    if (disabled) ...[
                      if (repo.defaultBranch.isNotEmpty)
                        const SizedBox(width: 8),
                      Text(
                        'Already registered',
                        style: theme.typography.caption?.copyWith(
                          color: theme.resources.textFillColorTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _basename(String path) {
  final sep = path.contains('\\') ? '\\' : '/';
  final parts = path.split(sep).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  return parts.last;
}
