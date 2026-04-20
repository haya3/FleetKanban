// CreateNodeDialog lets the user add a manual Context node — the
// low-friction path for capturing a decision / constraint before
// Analyzer or Observer surface it automatically.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/error_display.dart';
import '../../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../../infra/ipc/providers.dart';
import '../providers.dart';

/// Shows the Create Node dialog and returns true when a node was
/// created (caller can invalidate Browse provider). Returns false on
/// dismiss / cancel.
Future<bool> showCreateNodeDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => const _CreateNodeDialog(),
  );
  return result ?? false;
}

class _CreateNodeDialog extends ConsumerStatefulWidget {
  const _CreateNodeDialog();
  @override
  ConsumerState<_CreateNodeDialog> createState() => _CreateNodeDialogState();
}

class _CreateNodeDialogState extends ConsumerState<_CreateNodeDialog> {
  String _kind = 'Concept';
  final _labelCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  static const _kindChoices = [
    'Concept',
    'Decision',
    'Constraint',
    'Module',
    'Class',
    'Function',
    'File',
    'Tag',
  ];

  @override
  void dispose() {
    _labelCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repoId = ref.read(selectedContextRepoProvider);
    if (repoId.isEmpty) {
      setState(() => _error = 'No repository selected.');
      return;
    }
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Label is required.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final client = ref.read(ipcClientProvider);
      await client.context.createNode(
        pb.CreateNodeRequest(
          repoId: repoId,
          kind: _kind,
          label: label,
          contentMd: _contentCtrl.text,
          sourceKind: 'manual',
          confidence: 1.0,
        ),
      );
      ref.invalidate(contextBrowseNodesProvider);
      ref.invalidate(contextOverviewProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e\n\n$st';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: const Text('New Context node'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Kind'),
            const SizedBox(height: 4),
            ComboBox<String>(
              value: _kind,
              items: [
                for (final k in _kindChoices)
                  ComboBoxItem<String>(value: k, child: Text(k)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _kind = v);
              },
            ),
            const SizedBox(height: 12),
            const Text('Label'),
            const SizedBox(height: 4),
            TextBox(
              controller: _labelCtrl,
              placeholder:
                  'Short, descriptive (e.g. "Session tokens are DB-backed, not JWT")',
            ),
            const SizedBox(height: 12),
            const Text('Content (Markdown)'),
            const SizedBox(height: 4),
            TextBox(
              controller: _contentCtrl,
              placeholder:
                  'Optional body. Supports Markdown. Becomes the rendered '
                  'block that Copilot sees during Passive injection.',
              maxLines: 8,
              minLines: 4,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              CopyableErrorText(
                text: _error!,
                reportTitle: 'CreateNode failed',
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: ProgressRing(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
