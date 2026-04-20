// Overview tab — aggregate counts per node kind / edge rel, fact
// activity, scratchpad backlog, and the Memory on/off state. One-shot
// read of ContextService.GetOverview, pull-to-refresh via the Command
// Bar's Refresh button.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/error_display.dart';
import '../../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../../infra/ipc/providers.dart';
import '../providers.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(contextOverviewProvider);
    final repoId = ref.watch(selectedContextRepoProvider);

    if (repoId.isEmpty) {
      return const _EmptyRepo();
    }

    return overview.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(16),
        child: CopyableErrorText(
          text: '$e\n\n$st',
          reportTitle: 'Context / Overview load failed',
        ),
      ),
      data: (o) {
        if (o == null) {
          return const _EmptyRepo();
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MemoryStatusCard(overview: o),
              const SizedBox(height: 16),
              _CodeGraphCard(repoId: o.repoId),
              const SizedBox(height: 16),
              _CountsGrid(overview: o),
              const SizedBox(height: 16),
              _EdgesCard(overview: o),
              const SizedBox(height: 16),
              _ScratchpadCard(overview: o),
              const SizedBox(height: 16),
              _StorageCard(overview: o),
            ],
          ),
        );
      },
    );
  }
}

class _MemoryStatusCard extends ConsumerStatefulWidget {
  const _MemoryStatusCard({required this.overview});
  final pb.ContextOverview overview;

  @override
  ConsumerState<_MemoryStatusCard> createState() => _MemoryStatusCardState();
}

class _MemoryStatusCardState extends ConsumerState<_MemoryStatusCard> {
  bool _toggling = false;

  Future<void> _toggle(bool enabled) async {
    setState(() => _toggling = true);
    try {
      final client = ref.read(ipcClientProvider);
      // Load current settings so we preserve provider / model / budget
      // values the user may have customised in the Settings page.
      final current = await client.context.getMemorySettings(
        pb.RepoIdRequest(repoId: widget.overview.repoId),
      );
      final next = current.deepCopy()..enabled = enabled;
      await client.context.updateMemorySettings(
        pb.UpdateMemorySettingsRequest(settings: next),
      );
      ref.invalidate(contextOverviewProvider);
      ref.invalidate(contextMemorySettingsProvider);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final enabled = widget.overview.enabled;
    return Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            enabled ? FluentIcons.lightbulb : FluentIcons.lightbulb_solid,
            size: 32,
            color: enabled
                ? theme.accentColor
                : theme.resources.textFillColorTertiary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? 'Memory is active' : 'Memory is disabled',
                  style: theme.typography.subtitle,
                ),
                const SizedBox(height: 4),
                Text(
                  enabled
                      ? 'Copilot sessions on this repository receive Passive '
                            'injection assembled from the graph below.'
                      : 'Toggle below to enable Memory for this repository. '
                            'Embedding / LLM provider can be tuned in Settings → Memory.',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_toggling)
            const SizedBox(
              width: 16,
              height: 16,
              child: ProgressRing(strokeWidth: 2),
            )
          else
            ToggleSwitch(
              checked: enabled,
              onChanged: _toggle,
              content: Text(enabled ? 'Enabled' : 'Disabled'),
            ),
        ],
      ),
    );
  }
}

class _CodeGraphCard extends ConsumerStatefulWidget {
  const _CodeGraphCard({required this.repoId});
  final String repoId;
  @override
  ConsumerState<_CodeGraphCard> createState() => _CodeGraphCardState();
}

class _CodeGraphCardState extends ConsumerState<_CodeGraphCard> {
  bool _running = false;
  String? _message;
  String? _errorDump; // non-null → render CopyableErrorText

  Future<void> _run() async {
    setState(() {
      _running = true;
      _message = null;
      _errorDump = null;
    });
    try {
      final client = ref.read(ipcClientProvider);
      final resp = await client.context.rebuildCodeGraph(
        pb.RepoIdRequest(repoId: widget.repoId),
      );
      if (mounted) {
        setState(
          () => _message =
              'Scanned ${resp.filesScanned} files — '
              'created ${resp.nodesCreated} new / refreshed ${resp.nodesUpdated} existing File nodes, '
              'added ${resp.edgesCreated} import edges.',
        );
      }
      ref.invalidate(contextOverviewProvider);
      ref.invalidate(contextBrowseNodesProvider);
    } catch (e, st) {
      if (mounted) {
        setState(() => _errorDump = '$e\n\n$st');
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(FluentIcons.code, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code graph (static analysis)',
                  style: theme.typography.bodyStrong,
                ),
                Text(
                  'Walks the repository filesystem and creates File nodes + '
                  'imports edges. Cheap — no LLM calls. Re-run whenever '
                  'you\'ve added new files.',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _message!,
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ],
                if (_errorDump != null) ...[
                  const SizedBox(height: 8),
                  CopyableErrorText(
                    text: _errorDump!,
                    reportTitle: 'Context / RebuildCodeGraph',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _running ? null : _run,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_running)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: ProgressRing(strokeWidth: 2),
                  )
                else
                  const Icon(FluentIcons.refresh, size: 14),
                const SizedBox(width: 6),
                Text(_running ? 'Scanning…' : 'Rebuild code graph'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountsGrid extends StatelessWidget {
  const _CountsGrid({required this.overview});
  final pb.ContextOverview overview;

  @override
  Widget build(BuildContext context) {
    final entries = overview.nodeCountsByKind.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nodes by kind',
            style: FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'No nodes yet — run Analyze in Settings to seed the graph.',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in entries)
                  _KindChip(label: e.key, count: e.value),
              ],
            ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.count});
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.typography.body),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.typography.bodyStrong?.copyWith(
              color: theme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgesCard extends StatelessWidget {
  const _EdgesCard({required this.overview});
  final pb.ContextOverview overview;
  @override
  Widget build(BuildContext context) {
    final entries = overview.edgeCountsByRel.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edges by relationship',
            style: FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text(
              'No edges.',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in entries)
                  _KindChip(label: e.key, count: e.value),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScratchpadCard extends StatelessWidget {
  const _ScratchpadCard({required this.overview});
  final pb.ContextOverview overview;
  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scratchpad',
            style: FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _KindChip(
                label: 'Pending',
                count: overview.pendingScratchpadCount,
              ),
              const SizedBox(width: 12),
              _KindChip(
                label: 'Promoted',
                count: overview.promotedScratchpadCount,
              ),
              const SizedBox(width: 12),
              _KindChip(
                label: 'Rejected',
                count: overview.rejectedScratchpadCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.overview});
  final pb.ContextOverview overview;

  @override
  Widget build(BuildContext context) {
    final mb = (overview.vectorBytes.toInt() / 1024 / 1024).toStringAsFixed(2);
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Storage', style: FluentTheme.of(context).typography.bodyStrong),
          const SizedBox(height: 8),
          Text(
            '${overview.vectorCount} embeddings × ${overview.vectorDim} dim — $mb MB',
          ),
          Text(
            '${overview.activeFactCount} active facts, '
            '${overview.expiredFactCount} expired',
          ),
        ],
      ),
    );
  }
}

class _EmptyRepo extends StatelessWidget {
  const _EmptyRepo();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.library,
              size: 48,
              color: FluentTheme.of(context).resources.textFillColorTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Select a repository',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick a repository in the header to load its context graph, '
              'search memory, review scratchpad entries, or preview the '
              'injection block Copilot sees.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
