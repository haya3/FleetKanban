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
          Text('お掃除（Merged-sweep）', style: theme.typography.subtitle),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Keep 完了または Aborted のタスクブランチのうち、ベースブランチへ取り込み済み '
              'かつ一定日数以上経過したものを `git branch -d`（fast-forward 確認付き）で自動削除します。'
              '既定は無効。未マージのブランチは絶対に削除されません。',
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
        title: Text('お掃除は利用できません'),
        content: Text('sidecar の reaper が未初期化です。ログを確認してください。'),
        severity: InfoBarSeverity.warning,
        isLong: true,
      );
    }
    return CopyableErrorText(text: '$e', reportTitle: 'Housekeeping / 設定の取得');
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
              content: Text(_enabled ? '自動掃除: 有効' : '自動掃除: 無効'),
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
              const Text('経過日数の閾値: '),
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
              const Text('日'),
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
                  : const Text('今すぐ実行'),
            ),
            const SizedBox(width: 12),
            if (_lastSweepResult != null)
              Expanded(
                child: Text(
                  '前回: 対象 ${_lastSweepResult!.considered} / '
                  '削除 ${_lastSweepResult!.deleted} / '
                  'スキップ ${_lastSweepResult!.skipped}',
                  style: FluentTheme.of(context).typography.caption,
                ),
              ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ErrorInfoBar(title: 'お掃除の操作に失敗', message: _error!),
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
        loading: () => const Text('古いブランチ一覧を取得中...'),
        error: (e, _) {
          if (e is GrpcError && e.code == StatusCode.unavailable) {
            return const Text('古いブランチ一覧は利用できません');
          }
          return Text('古いブランチ一覧の取得に失敗: $e');
        },
        data: (list) => Text(
          list.isEmpty
              ? '古いブランチ: 0 件（30 日以上経過した Done/Aborted なし）'
              : '古いブランチ: ${list.length} 件',
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
            ? const Text('該当ブランチはありません。')
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
        title: const Text('ブランチを削除しますか？'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '対象: ${b.branch}',
              style: const TextStyle(fontFamily: 'Consolas'),
            ),
            const SizedBox(height: 6),
            if (!b.merged)
              const Text(
                '⚠ このブランチは base へマージされていません。'
                '削除すると未マージの差分は失われます（git branch -D で強制削除）。',
              )
            else
              const Text(
                'このブランチは base へ取り込み済みです。'
                '差分は base に残るため、削除しても作業は失われません。',
              ),
          ],
        ),
        actions: [
          Button(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                FluentTheme.of(ctx).resources.systemFillColorCritical,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除する'),
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
                        '${b.status} · ${b.ageDays} 日前 · base ${b.baseBranch} · ${b.repoPath}',
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
              child: ErrorInfoBar(title: '削除に失敗', message: _error!),
            ),
        ],
      ),
    );
  }
}
