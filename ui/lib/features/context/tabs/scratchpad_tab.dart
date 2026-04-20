// Scratchpad tab — the trust gate. Pending entries are shown one per
// card with Promote / Reject / Edit / Snooze actions.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/error_display.dart';
import '../../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../../infra/ipc/providers.dart';
import '../providers.dart';

class ScratchpadTab extends ConsumerWidget {
  const ScratchpadTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(contextScratchpadPendingProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: pending.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(16),
          child: CopyableErrorText(
            text: '$e\n\n$st',
            reportTitle: 'Context / Scratchpad load failed',
          ),
        ),
        data: (resp) {
          if (resp == null || resp.entries.isEmpty) {
            return const Center(
              child: Text(
                'No pending entries. New candidates will appear here after '
                'Analyze or Observer runs.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${resp.entries.length} pending',
                    style: FluentTheme.of(context).typography.caption,
                  ),
                  const SizedBox(width: 12),
                  _RejectAllButton(count: resp.entries.length),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: resp.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _EntryCard(entry: resp.entries[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RejectAllButton extends ConsumerStatefulWidget {
  const _RejectAllButton({required this.count});
  final int count;
  @override
  ConsumerState<_RejectAllButton> createState() => _RejectAllButtonState();
}

class _RejectAllButtonState extends ConsumerState<_RejectAllButton> {
  bool _running = false;

  Future<void> _run() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Reject all pending entries?'),
        content: Text(
          'This will mark all ${widget.count} pending scratchpad entries '
          'as rejected. You cannot un-reject them, but you can re-run '
          'Analyze to generate fresh candidates.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject all'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _running = true);
    try {
      final client = ref.read(ipcClientProvider);
      final pending = ref.read(contextScratchpadPendingProvider).value;
      if (pending == null) return;
      for (final entry in pending.entries) {
        await client.scratchpad.rejectEntry(
          pb.RejectEntryRequest(
            entryId: entry.id,
            reason: 'bulk-reject: off-target analyzer output',
          ),
        );
      }
      ref.invalidate(contextScratchpadPendingProvider);
      ref.invalidate(contextOverviewProvider);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: _running ? null : _run,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_running)
            const SizedBox(
              width: 12,
              height: 12,
              child: ProgressRing(strokeWidth: 2),
            )
          else
            const Icon(FluentIcons.clear, size: 12),
          const SizedBox(width: 4),
          const Text('Reject all'),
        ],
      ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});
  final pb.ScratchpadEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.proposedKind,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.proposedLabel,
                  style: theme.typography.bodyStrong,
                ),
              ),
              Text(
                'conf ${entry.confidence.toStringAsFixed(2)}',
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'via ${entry.sourceKind}${entry.sourceRef.isEmpty ? '' : ' · ${entry.sourceRef}'}',
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorTertiary,
            ),
          ),
          if (entry.proposedContentMd.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(entry.proposedContentMd),
          ],
          if (entry.signals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in entry.signals)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.resources.subtleFillColorSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                onPressed: () async {
                  final client = ref.read(ipcClientProvider);
                  await client.scratchpad.rejectEntry(
                    pb.RejectEntryRequest(entryId: entry.id),
                  );
                  ref.invalidate(contextScratchpadPendingProvider);
                },
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: () async {
                  final client = ref.read(ipcClientProvider);
                  await client.scratchpad.snoozeEntry(
                    pb.SnoozeRequest(entryId: entry.id, days: 7),
                  );
                  ref.invalidate(contextScratchpadPendingProvider);
                },
                child: const Text('Snooze 7d'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  final client = ref.read(ipcClientProvider);
                  await client.scratchpad.promoteEntry(
                    pb.EntryIdRequest(entryId: entry.id),
                  );
                  ref.invalidate(contextScratchpadPendingProvider);
                  ref.invalidate(contextOverviewProvider);
                },
                child: const Text('Promote'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
