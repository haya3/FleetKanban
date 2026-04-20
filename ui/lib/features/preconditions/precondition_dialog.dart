// PreconditionDialog: one-shot modal shown on app startup when the sidecar
// reports a missing runtime dependency (today: PowerShell 7). Offers
// winget-backed auto-install, a manual-command copy fallback, and a
// "後で" dismiss. The dialog is re-shown on next launch if the user
// dismissed it; there's no persistent suppression.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'providers.dart';

/// Host widget that watches preconditionsProvider and opens the dialog
/// exactly once per mount when something unmet is reported. Designed to
/// be dropped inside the app shell; it renders only the [child] and
/// owns zero visible state of its own.
class PreconditionHost extends ConsumerStatefulWidget {
  const PreconditionHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PreconditionHost> createState() => _PreconditionHostState();
}

class _PreconditionHostState extends ConsumerState<PreconditionHost> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<pb.Precondition>>>(preconditionsProvider, (
      _,
      next,
    ) {
      if (_shown) return;
      next.whenData((list) {
        final unmet = list.where((p) => !p.satisfied).toList();
        if (unmet.isEmpty) return;
        _shown = true;
        // addPostFrameCallback so the dialog is pushed onto the Navigator
        // after the current frame — avoids "setState or markNeedsBuild
        // called during build" when the provider resolves synchronously.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _PreconditionDialog(items: unmet),
          );
        });
      });
    });
    return widget.child;
  }
}

class _PreconditionDialog extends ConsumerStatefulWidget {
  const _PreconditionDialog({required this.items});
  final List<pb.Precondition> items;

  @override
  ConsumerState<_PreconditionDialog> createState() =>
      _PreconditionDialogState();
}

class _PreconditionDialogState extends ConsumerState<_PreconditionDialog> {
  bool _installing = false;
  String? _lastError;
  pb.Precondition? _active;

  Future<void> _install(pb.Precondition p) async {
    setState(() {
      _installing = true;
      _active = p;
      _lastError = null;
    });
    try {
      final resp = await ref
          .read(installPreconditionProvider.notifier)
          .run(p.kind);
      if (!mounted) return;
      if (resp.precondition.satisfied) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _installing = false;
        _lastError = resp.error.isNotEmpty
            ? resp.error
            : 'インストールは完了しましたが pwsh が検出できませんでした。';
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
    // Phase 1 ships only the pwsh precondition; the dialog renders one
    // item at a time. If additional kinds land later, switch to a list.
    final item = widget.items.first;

    return ContentDialog(
      title: const Text('セットアップが必要です'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description, style: theme.typography.body),
            const SizedBox(height: 8),
            Text(
              item.detail,
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorTertiary,
              ),
            ),
            if (item.autoInstallable) ...[
              const SizedBox(height: 16),
              Text(
                '自動インストール: winget で per-user インストールします。\n'
                'UAC 不要、所要時間は 1〜3 分ほどです。',
                style: theme.typography.body,
              ),
            ],
            if (_installing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: ProgressRing(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_active?.kind ?? ""} をインストール中…',
                      style: theme.typography.caption,
                    ),
                  ),
                ],
              ),
            ],
            if (_lastError != null) ...[
              const SizedBox(height: 12),
              InfoBar(
                title: const Text('インストール失敗'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_lastError!),
                    if (item.manualCommand.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('手動インストールコマンド:'),
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
        ),
      ),
      actions: [
        Button(
          onPressed: _installing ? null : () => Navigator.of(context).pop(),
          child: const Text('後で'),
        ),
        if (item.autoInstallable)
          FilledButton(
            onPressed: _installing ? null : () => _install(item),
            child: const Text('自動インストール'),
          ),
      ],
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
