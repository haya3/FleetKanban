// Search tab — runs hybrid retrieval against the selected repo and
// displays the three channels (Semantic / Keyword / Fused) side by
// side. The Fused view is the production ranking; the two raw
// channels are there for trust / debug.

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/error_display.dart';
import '../../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../providers.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
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
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(contextSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(contextSearchResultsProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextBox(
            controller: _controller,
            placeholder: 'Search memory (e.g. "rate limit", "auth middleware")',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(FluentIcons.search, size: 16),
            ),
            onChanged: _onChanged,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.when(
              loading: () => const Center(child: ProgressRing()),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16),
                child: CopyableErrorText(
                  text: '$e\n\n$st',
                  reportTitle: 'Context / Search failed',
                ),
              ),
              data: (resp) {
                if (resp == null) {
                  return const Center(
                    child: Text(
                      'Type a query above to search.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ChannelColumn(
                        title: 'Fused (RRF + graph boost)',
                        description:
                            'Production ranking — what the agent will see.',
                        hits: resp.channels['fused']?.hits ?? const [],
                        highlight: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ChannelColumn(
                        title: 'Semantic',
                        description: 'Vector cosine similarity alone.',
                        hits: resp.channels['semantic']?.hits ?? const [],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ChannelColumn(
                        title: 'Keyword (BM25)',
                        description: 'FTS5 literal match alone.',
                        hits: resp.channels['keyword']?.hits ?? const [],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelColumn extends StatelessWidget {
  const _ChannelColumn({
    required this.title,
    required this.description,
    required this.hits,
    this.highlight = false,
  });

  final String title;
  final String description;
  final List<pb.SearchHit> hits;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      padding: const EdgeInsets.all(12),
      backgroundColor: highlight
          ? theme.accentColor.lightest.withValues(alpha: 0.15)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.typography.bodyStrong),
          Text(
            description,
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (hits.isEmpty)
            const Text(
              '— no results —',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: hits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _HitCard(hit: hits[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _HitCard extends StatelessWidget {
  const _HitCard({required this.hit});
  final pb.SearchHit hit;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.resources.controlStrokeColorDefault),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${hit.rank}',
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorTertiary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hit.node.kind,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hit.node.label,
                  style: theme.typography.bodyStrong,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (hit.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              hit.reason,
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
