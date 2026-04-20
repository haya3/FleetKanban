// ReworkDialog — modal shown when the reviewer chooses Re-run from a Human
// Review card. Collects free-form feedback that the sidecar will prepend to
// the next Copilot prompt. Returns the trimmed feedback string on submit,
// or null on cancel.

import 'package:fluent_ui/fluent_ui.dart';

import '../../app/ui_utils.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;

Future<String?> showReworkDialog(
  BuildContext context, {
  required pb.Task task,
}) {
  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ReworkDialog(task: task),
  );
}

class _ReworkDialog extends StatefulWidget {
  const _ReworkDialog({required this.task});
  final pb.Task task;

  @override
  State<_ReworkDialog> createState() => _ReworkDialogState();
}

class _ReworkDialogState extends State<_ReworkDialog> {
  // Intentionally starts empty instead of pre-filling with the task's
  // previous reviewFeedback: pre-fill would invite the reviewer to submit
  // stale feedback unchanged, re-running the agent with the exact same
  // instructions. The previous feedback is still visible on the Overview
  // tab of the detail dialog for reference.
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Enter feedback');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ContentDialog(
      title: const Text('Rework feedback'),
      constraints: const BoxConstraints(maxWidth: 520),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This task will be returned to queued and the feedback below '
            'will be injected at the top of the next Copilot prompt.',
            style: theme.typography.caption,
          ),
          const SizedBox(height: 8),
          TextBox(
            controller: _controller,
            placeholder: 'e.g. Use English for commit messages',
            maxLines: 6,
            minLines: 4,
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              _error!,
              style: TextStyle(color: theme.resources.systemFillColorCritical),
            ),
          ],
        ],
      ),
      actions: [
        clickable(
          Button(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ),
        clickable(
          FilledButton(
            onPressed: _submit,
            child: const Text('Send for rework'),
          ),
        ),
      ],
    );
  }
}
