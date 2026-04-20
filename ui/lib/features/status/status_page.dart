// StatusPage: at-a-glance view of the runtime environment. Three sections:
//
//   * アカウント — Copilot auth state and GitHub account/plan info.
//   * 前提条件 — runtime dependencies (pwsh). Inline install button for
//     anything unmet; mirrors the startup ContentDialog so the user can
//     resolve missing deps without waiting for the next launch.
//   * バージョン — sidecar protocol, Copilot SDK module, Go runtime.
//
// Read-only; state mutations happen via the relevant feature providers
// (installPreconditionProvider) so the rest of the app sees the same
// post-install snapshot.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';
import '../preconditions/providers.dart';

class StatusPage extends ConsumerWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Status')),
      content: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(title: 'アカウント', child: _AccountCard()),
            SizedBox(height: 16),
            _Section(title: '前提条件', child: _PreconditionsCard()),
            SizedBox(height: 16),
            _Section(title: 'バージョン', child: _VersionCard()),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            title,
            style: theme.typography.bodyStrong?.copyWith(fontSize: 14),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.resources.layerOnMicaBaseAltFillColorDefault,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.resources.controlStrokeColorDefault,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

class _AccountCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(copilotAuthProvider);
    final account = ref.watch(githubAccountInfoProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        auth.when(
          loading: () => const _LoadingRow(label: 'Copilot 認証確認中…'),
          error: (e, _) => _KVRow(
            label: 'Copilot',
            value: 'エラー: $e',
            severity: InfoBarSeverity.error,
          ),
          data: (s) => _KVRow(
            label: 'Copilot',
            value: s.authenticated
                ? '認証済み（${s.user.isEmpty ? "ユーザー不明" : s.user}）'
                : (s.message.isEmpty ? '未認証' : s.message),
            severity: s.authenticated
                ? InfoBarSeverity.success
                : InfoBarSeverity.warning,
          ),
        ),
        const Divider(),
        account.when(
          loading: () => const _LoadingRow(label: 'GitHub アカウント情報取得中…'),
          error: (e, _) => _KVRow(
            label: 'GitHub',
            value: 'エラー: $e',
            severity: InfoBarSeverity.error,
          ),
          data: (info) => info == null
              ? const _KVRow(
                  label: 'GitHub',
                  value: 'PAT 未設定 — 設定で追加してください',
                  severity: InfoBarSeverity.warning,
                )
              : _GitHubAccountDetails(info: info),
        ),
      ],
    );
  }
}

class _GitHubAccountDetails extends StatelessWidget {
  const _GitHubAccountDetails({required this.info});
  final pb.GitHubAccountInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KVRow(label: 'login', value: info.login),
        if (info.name.isNotEmpty) _KVRow(label: '名前', value: info.name),
        _KVRow(
          label: 'プラン',
          value: info.planName.isEmpty ? '-' : info.planName,
        ),
        _KVRow(
          label: 'Copilot',
          value: info.copilotEnabled ? '有効' : '未確認',
          severity: info.copilotEnabled
              ? InfoBarSeverity.success
              : InfoBarSeverity.warning,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preconditions
// ---------------------------------------------------------------------------

class _PreconditionsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(preconditionsProvider);
    return async.when(
      loading: () => const _LoadingRow(label: '確認中…'),
      error: (e, _) =>
          _KVRow(label: 'エラー', value: '$e', severity: InfoBarSeverity.error),
      data: (list) {
        if (list.isEmpty) {
          return const Text('対象の前提条件はありません。');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < list.length; i++) ...[
              _PreconditionRow(item: list[i]),
              if (i < list.length - 1) const Divider(),
            ],
          ],
        );
      },
    );
  }
}

class _PreconditionRow extends ConsumerStatefulWidget {
  const _PreconditionRow({required this.item});
  final pb.Precondition item;

  @override
  ConsumerState<_PreconditionRow> createState() => _PreconditionRowState();
}

class _PreconditionRowState extends ConsumerState<_PreconditionRow> {
  bool _installing = false;
  String? _lastError;

  Future<void> _install() async {
    setState(() {
      _installing = true;
      _lastError = null;
    });
    try {
      final resp = await ref
          .read(installPreconditionProvider.notifier)
          .run(widget.item.kind);
      if (!mounted) return;
      setState(() {
        _installing = false;
        if (!resp.precondition.satisfied) {
          _lastError = resp.error.isNotEmpty
              ? resp.error
              : 'インストール後も pwsh を検出できませんでした。';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _installing = false;
        _lastError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final item = widget.item;
    final badgeColor = item.satisfied
        ? const Color(0xFF107C10)
        : const Color(0xFFC42B1C);
    final badgeLabel = item.satisfied ? 'OK' : '未充足';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                badgeLabel,
                style: theme.typography.caption?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.description, style: theme.typography.body),
                  const SizedBox(height: 2),
                  Text(
                    item.detail,
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.satisfied && item.autoInstallable)
              FilledButton(
                onPressed: _installing ? null : _install,
                child: _installing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: ProgressRing(strokeWidth: 2),
                      )
                    : const Text('インストール'),
              ),
          ],
        ),
        if (_lastError != null) ...[
          const SizedBox(height: 10),
          InfoBar(
            title: const Text('インストール失敗'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_lastError!),
                if (item.manualCommand.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text('手動コマンド:'),
                  const SizedBox(height: 4),
                  _CommandBlock(command: item.manualCommand),
                ],
              ],
            ),
            severity: InfoBarSeverity.error,
            isLong: true,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Version
// ---------------------------------------------------------------------------

class _VersionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(versionInfoProvider);
    return async.when(
      loading: () => const _LoadingRow(label: '取得中…'),
      error: (e, _) =>
          _KVRow(label: 'エラー', value: '$e', severity: InfoBarSeverity.error),
      data: (v) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KVRow(
            label: 'Protocol version',
            value: v.protocolVersion.toString(),
          ),
          _KVRow(
            label: 'Copilot SDK',
            value: v.copilotSdkVersion.isEmpty ? '-' : v.copilotSdkVersion,
          ),
          _KVRow(
            label: 'Go runtime',
            value: v.goVersion.isEmpty ? '-' : v.goVersion,
          ),
          if (v.appVersion.isNotEmpty)
            _KVRow(label: 'App', value: v.appVersion),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

class _KVRow extends StatelessWidget {
  const _KVRow({required this.label, required this.value, this.severity});
  final String label;
  final String value;
  final InfoBarSeverity? severity;

  Color? _valueColor(FluentThemeData theme) {
    switch (severity) {
      case InfoBarSeverity.success:
        return const Color(0xFF107C10);
      case InfoBarSeverity.warning:
        return const Color(0xFFB97A00);
      case InfoBarSeverity.error:
        return const Color(0xFFC42B1C);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorTertiary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.typography.body?.copyWith(color: _valueColor(theme)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: ProgressRing(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

class _CommandBlock extends StatelessWidget {
  const _CommandBlock({required this.command});
  final String command;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              command,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.copy, size: 14),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: command));
            },
          ),
        ],
      ),
    );
  }
}
