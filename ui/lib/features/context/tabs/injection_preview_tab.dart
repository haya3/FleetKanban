// Injection Preview tab — type a prompt, see the assembled Passive
// injection block and the sources that contributed to it. The key
// trust-building affordance: FleetKanban never injects memory behind
// the user's back.

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/error_display.dart';
import '../../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../providers.dart';

class InjectionPreviewTab extends ConsumerStatefulWidget {
  const InjectionPreviewTab({super.key});

  @override
  ConsumerState<InjectionPreviewTab> createState() =>
      _InjectionPreviewTabState();
}

class _InjectionPreviewTabState extends ConsumerState<InjectionPreviewTab> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(injectionPreviewDraftProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(contextInjectionPreviewProvider);
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Task draft prompt', style: theme.typography.bodyStrong),
                const SizedBox(height: 8),
                Expanded(
                  child: TextBox(
                    controller: _controller,
                    onChanged: _onChanged,
                    maxLines: null,
                    expands: true,
                    placeholder:
                        'Paste the task goal you plan to send to Copilot.\n\n'
                        'Example: "Refactor the rate limiter to use a token '
                        'bucket instead of a fixed window."',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Card(
              padding: const EdgeInsets.all(12),
              child: preview.when(
                loading: () => const Center(child: ProgressRing()),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: CopyableErrorText(
                    text: '$e\n\n$st',
                    reportTitle: 'Context / Injection Preview failed',
                  ),
                ),
                data: (p) {
                  if (p == null) {
                    return const Center(
                      child: Text(
                        'Start typing on the left to see the assembled '
                        'injection block.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return _PreviewView(preview: p);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.preview});
  final pb.InjectionPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Assembled block', style: theme.typography.bodyStrong),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${preview.estimatedTokens} tokens',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: preview.systemPrompt.isEmpty
              ? const Center(
                  child: Text(
                    'Memory is disabled for this repository or no relevant '
                    'entries matched the draft prompt.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  child: SelectableText(
                    preview.systemPrompt,
                    style: const TextStyle(fontFamily: 'Consolas'),
                  ),
                ),
        ),
        if (preview.sources.isNotEmpty) ...[
          const Divider(),
          Text(
            'Sources (${preview.sources.length})',
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 4),
          for (final src in preview.sources)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• ${src.sourceType}: ${src.label}  '
                '(${src.tokens}t, rel=${src.relevance.toStringAsFixed(2)})',
                style: theme.typography.caption,
              ),
            ),
        ],
      ],
    );
  }
}
