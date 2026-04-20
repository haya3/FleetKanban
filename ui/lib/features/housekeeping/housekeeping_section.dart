// Housekeeping section for the Settings page: Merged-sweep opt-in toggle,
// age threshold input, manual "run now" button, and a collapsible list of
// stale fleetkanban/<id> branches. See phase1-spec §3.1.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart' show GrpcError, StatusCode;

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/housekeeping.pb.dart' as hk;
import 'providers.dart';

class HousekeepingSection extends ConsumerWidget {
  const HousekeepingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final days = ref.watch(autoSweepDaysProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cleanup (Merged-sweep)', style: theme.typography.subtitle),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Automatically deletes Keep-completed or Aborted task branches that are already '
              'merged into their base branch and older than a threshold, using `git branch -d` '
              '(fast-forward verified). Disabled by default. Unmerged branches are never deleted.',
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          days.when(
            loading: () => const SizedBox(height: 40, child: ProgressBar()),
            error: (e, _) => _unavailableOrError(e),
            data: (resp) => _SweepControls(current: resp),
          ),
          const SizedBox(height: 16),
          const _StaleBranchesExpander(),
        ],
      ),
    );
  }

  Widget _unavailableOrError(Object e) {
    if (e is GrpcError && e.code == StatusCode.unavailable) {
      return const InfoBar(
        title: Text('Cleanup is unavailable'),
        content: Text('The sidecar reaper has not been initialized. Check the logs.'),
        severity: InfoBarSeverity.warning,
        isLong: true,
      );
    }
    return CopyableErrorText(text: '$e', reportTitle: 'Housekeeping / settings fetch');
  }
}

class _SweepControls extends ConsumerStatefulWidget {
  const _SweepControls({required this.current});
  final hk.GetAutoSweepDaysResponse current;

  @override
  ConsumerState<_SweepControls> createState() => _SweepControlsState();
}

class _SweepControlsState extends ConsumerState<_SweepControls> {
  late bool _enabled;
  late int _days;
  bool _saving = false;
  bool _runningSweep = false;
  String? _error;
  hk.RunSweepNowResponse? _lastSweepResult;

  @override
  void initState() {
    super.initState();
    _enabled = widget.current.days > 0;
    _days = widget.current.days > 0 ? widget.current.days : 30;
  }

  Future<void> _commit({required int days}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await setAutoSweepDays(ref, days);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runSweep() async {
    setState(() {
      _runningSweep = true;
      _error = null;
    });
    try {
      final resp = await runSweepNow(ref, days: _enabled ? _days : null);
      if (!mounted) return;
      setState(() => _lastSweepResult = resp);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _runningSweep = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ToggleSwitch(
              checked: _enabled,
              onChanged: _saving
                  ? null
                  : (v) {
                      setState(() => _enabled = v);
                      _commit(days: v ? _days : 0);
                    },
              content: Text(_enabled ? 'Auto cleanup: on' : 'Auto cleanup: off'),
            ),
            const Spacer(),
            if (_saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: ProgressRing(strokeWidth: 2),
              ),
          ],
        ),
        if (_enabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Age threshold: '),
              SizedBox(
                width: 110,
                child: NumberBox<int>(
                  value: _days,
                  min: 1,
                  max: 365,
                  mode: SpinButtonPlacementMode.inline,
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _days = v);
                          _commit(days: v);
                        },
                ),
              ),
              const SizedBox(width: 8),
              const Text('days'),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Button(
              onPressed: _runningSweep ? null : _runSweep,
              child: _runningSweep
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: ProgressRing(strokeWidth: 2),
                    )
                  : const Text('Run now'),
            ),
            const SizedBox(width: 12),
            if (_lastSweepResult != null)
              Expanded(
                child: Text(
                  'Last run: considered ${_lastSweepResult!.considered} / '
                  'deleted ${_lastSweepResult!.deleted} / '
                  'skipped ${_lastSweepResult!.skipped}',
                  style: FluentTheme.of(context).typography.caption,
                ),
              ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ErrorInfoBar(title: 'Cleanup action failed', message: _error!),
          ),
      ],
    );
  }
}

class _StaleBranchesExpander extends ConsumerWidget {
  const _StaleBranchesExpander();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stale = ref.watch(staleBranchesProvider);
    final theme = FluentTheme.of(context);
    return Expander(
      header: stale.when(
        loading: () => const Text('Loading stale branches…'),
        error: (e, _) {
          if (e is GrpcError && e.code == StatusCode.unavailable) {
            return const Text('Stale branches are unavailable');
          }
          return Text('Failed to load stale branches: $e');
        },
        data: (list) => Text(
          list.isEmpty
              ? 'Stale branches: 0 (no Done/Aborted older than 30 days)'
              : 'Stale branches: ${list.length}',
          style: theme.typography.bodyStrong,
        ),
      ),
      content: stale.when(
        loading: () => const SizedBox(height: 40, child: ProgressBar()),
        error: (e, _) => CopyableErrorText(
          text: '$e',
          reportTitle: 'Housekeeping / Stale branches',
        ),
        data: (list) => list.isEmpty
            ? const Text('No matching branches.')
            : _StaleBranchesList(branches: list),
      ),
    );
  }
}

class _StaleBranchesList extends StatelessWidget {
  const _StaleBranchesList({required this.branches});
  final List<hk.StaleBranch> branches;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: branches.map((b) => _StaleBranchRow(branch: b)).toList(),
    );
  }
}

class _StaleBranchRow extends ConsumerStatefulWidget {
  const _StaleBranchRow({required this.branch});
  final hk.StaleBranch branch;

  @override
  ConsumerState<_StaleBranchRow> createState() => _StaleBranchRowState();
}

class _StaleBranchRowState extends ConsumerState<_StaleBranchRow> {
  bool _busy = false;
  String? _error;

  Future<void> _discard() async {
    final confirmed = await _confirm();
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await deleteTaskBranch(ref, widget.branch.taskId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirm() {
    final b = widget.branch;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Delete branch?'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Target: ${b.branch}',
              style: const TextStyle(fontFamily: 'Consolas'),
            ),
            const SizedBox(height: 6),
            if (!b.merged)
              const Text(
                'Warning: this branch is not merged into its base. '
                'Deleting it discards the unmerged changes (force-delete via git branch -D).',
              )
            else
              const Text(
                'This branch is already merged into its base. '
                'The changes live on the base branch, so deleting this branch loses no work.',
              ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                FluentTheme.of(ctx).resources.systemFillColorCritical,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final b = widget.branch;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                    Row(
                      children: [
                        Icon(
                          b.merged
                              ? FluentIcons.check_mark
                              : FluentIcons.warning,
                          size: 14,
                          color: b.merged
                              ? theme.resources.systemFillColorSuccess
                              : theme.resources.systemFillColorCaution,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            b.branch,
                            style: theme.typography.bodyStrong?.copyWith(
                              fontFamily: 'Consolas',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${b.status} · ${b.ageDays}d ago · base ${b.baseBranch} · ${b.repoPath}',
                        style: theme.typography.caption?.copyWith(
                          color: theme.resources.textFillColorSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (b.goal.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          b.goal,
                          style: theme.typography.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: _busy ? null : _discard,
                child: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: ProgressRing(strokeWidth: 2),
                      )
                    : const Text('Discard'),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ErrorInfoBar(title: 'Delete failed', message: _error!),
            ),
        ],
      ),
    );
  }
}
