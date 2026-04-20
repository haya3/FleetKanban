// Facts timeline tab — lists bi-temporal facts ordered by valid_from.
// Active facts rendered solid; expired facts muted.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/error_display.dart';
import '../../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../providers.dart';

class FactsTimelineTab extends ConsumerWidget {
  const FactsTimelineTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = ref.watch(contextFactsProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: facts.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(16),
          child: CopyableErrorText(
            text: '$e\n\n$st',
            reportTitle: 'Context / Facts load failed',
          ),
        ),
        data: (resp) {
          if (resp == null || resp.facts.isEmpty) {
            return const Center(
              child: Text(
                'No facts recorded yet. The analyzer and observer write facts '
                'for bi-temporal assertions like "auth: uses OAuth2 since 2026-03".',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            );
          }
          return ListView.separated(
            itemCount: resp.facts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _FactRow(fact: resp.facts[i]),
          );
        },
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});
  final pb.ContextFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final active = !fact.hasValidTo();
    final color = active
        ? theme.accentColor
        : theme.resources.textFillColorTertiary;
    return Card(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fact.predicate} ${fact.objectText}',
                  style: theme.typography.body?.copyWith(
                    color: active
                        ? null
                        : theme.resources.textFillColorSecondary,
                    decoration: active ? null : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  _range(fact),
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _range(pb.ContextFact f) {
    final from = f.validFrom.toDateTime().toLocal();
    final fromStr =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    if (!f.hasValidTo()) return 'since $fromStr';
    final to = f.validTo.toDateTime().toLocal();
    final toStr =
        '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
    return '$fromStr → $toStr';
  }
}
