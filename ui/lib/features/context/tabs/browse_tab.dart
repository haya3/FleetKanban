// Browse tab — paginated node list on the left, detail pane on the
// right. Filter chips across the top swap the active kind subset.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/error_display.dart';
import '../../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../../infra/ipc/providers.dart';
import '../providers.dart';
import '../widgets/create_node_dialog.dart';

class BrowseTab extends ConsumerWidget {
  const BrowseTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: _KindFilterChips()),
              const SizedBox(width: 8),
              Button(
                onPressed: () => showCreateNodeDialog(context, ref),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.add, size: 14),
                    SizedBox(width: 4),
                    Text('New node'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 1, child: _NodeList()),
                SizedBox(width: 12),
                Expanded(flex: 2, child: _NodeDetailPane()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _kAllKinds = [
  'File',
  'Module',
  'Function',
  'Class',
  'Concept',
  'Decision',
  'Constraint',
];

class _KindFilterChips extends ConsumerWidget {
  const _KindFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(contextBrowseKindFilterProvider);
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in _kAllKinds)
          GestureDetector(
            onTap: () {
              final next = Set<String>.from(selected);
              if (next.contains(k)) {
                next.remove(k);
              } else {
                next.add(k);
              }
              ref.read(contextBrowseKindFilterProvider.notifier).state = next;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected.contains(k)
                    ? theme.accentColor
                    : theme.resources.subtleFillColorSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                k,
                style: TextStyle(
                  color: selected.contains(k) ? Colors.white : null,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NodeList extends ConsumerWidget {
  const _NodeList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(contextBrowseNodesProvider);
    final selected = ref.watch(contextSelectedNodeIdProvider);
    return Card(
      padding: const EdgeInsets.all(8),
      child: nodes.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(12),
          child: CopyableErrorText(
            text: '$e\n\n$st',
            reportTitle: 'Context / Browse load failed',
          ),
        ),
        data: (resp) {
          if (resp == null || resp.nodes.isEmpty) {
            return const Center(
              child: Text(
                'No nodes',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            );
          }
          return ListView.separated(
            itemCount: resp.nodes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final n = resp.nodes[i];
              return ListTile.selectable(
                selected: n.id == selected,
                onSelectionChange: (_) {
                  ref.read(contextSelectedNodeIdProvider.notifier).state = n.id;
                },
                leading: Icon(_iconForKind(n.kind), size: 18),
                title: Text(
                  n.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Text(
                  '${n.kind} · ${n.sourceKind}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: n.pinned
                    ? const Icon(FluentIcons.pinned, size: 14)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

IconData _iconForKind(String kind) {
  switch (kind) {
    case 'File':
      return FluentIcons.file_code;
    case 'Module':
      return FluentIcons.cube_shape;
    case 'Function':
      return FluentIcons.variable2;
    case 'Class':
      return FluentIcons.code;
    case 'Concept':
      return FluentIcons.lightbulb;
    case 'Decision':
      return FluentIcons.branch_merge;
    case 'Constraint':
      return FluentIcons.lock;
    default:
      return FluentIcons.tag;
  }
}

class _NodeDetailPane extends ConsumerWidget {
  const _NodeDetailPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(contextNodeDetailProvider);
    return Card(
      padding: const EdgeInsets.all(16),
      child: detail.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(12),
          child: CopyableErrorText(
            text: '$e\n\n$st',
            reportTitle: 'Context / Browse load failed',
          ),
        ),
        data: (d) {
          if (d == null) {
            return const Center(
              child: Text(
                'Select a node on the left to see its details.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            );
          }
          return _NodeDetailView(detail: d);
        },
      ),
    );
  }
}

class _NodeDetailView extends ConsumerWidget {
  const _NodeDetailView({required this.detail});
  final pb.ContextNodeDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final n = detail.node;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForKind(n.kind)),
              const SizedBox(width: 8),
              Expanded(child: Text(n.label, style: theme.typography.subtitle)),
              ToggleSwitch(
                checked: n.enabled,
                onChanged: (v) async {
                  final client = ref.read(ipcClientProvider);
                  await client.context.updateNode(
                    pb.UpdateNodeRequest(nodeId: n.id, enabledOp: v ? 1 : 2),
                  );
                  ref.invalidate(contextNodeDetailProvider);
                  ref.invalidate(contextBrowseNodesProvider);
                },
                content: Text(n.enabled ? 'Enabled' : 'Disabled'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _DetailChip(label: n.kind),
              _DetailChip(label: 'source: ${n.sourceKind}'),
              _DetailChip(
                label: 'confidence: ${n.confidence.toStringAsFixed(2)}',
              ),
              if (n.pinned) const _DetailChip(label: 'pinned'),
            ],
          ),
          const Divider(),
          if (n.contentMd.isNotEmpty) ...[
            Text('Content', style: theme.typography.bodyStrong),
            const SizedBox(height: 8),
            SelectableText(n.contentMd),
            const Divider(),
          ],
          if (detail.neighbors.isNotEmpty) ...[
            Text(
              'Neighbors (${detail.neighbors.length})',
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final neighbor in detail.neighbors)
                  _DetailChip(label: '${neighbor.kind}: ${neighbor.label}'),
              ],
            ),
            const Divider(),
          ],
          if (detail.facts.isNotEmpty) ...[
            Text(
              'Facts (${detail.facts.length})',
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            for (final f in detail.facts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${f.predicate} ${f.objectText}'),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
