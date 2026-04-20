// InsightsPage: aggregate dashboard over the tasks history. Read-only — the
// page composes completion rate, duration percentiles, rework/failure
// histograms, per-repository throughput, and a 30-day completion sparkline
// into one scrollable surface.
//
// Metrics are derived server-side (store.InsightsStore) in a single RPC; the
// UI just paints them. A scope ComboBox at the top restricts the snapshot to
// a single repository when the user picks one, otherwise the page shows the
// aggregate across every registered repository.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ipc/generated/fleetkanban/v1/insights.pb.dart' as ins_pb;
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../kanban/providers.dart' show kanbanRepositoriesProvider;
import 'providers.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(insightsSummaryProvider);
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Insights'),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ScopePicker(),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(FluentIcons.refresh),
              onPressed: () => ref.invalidate(insightsSummaryProvider),
            ),
          ],
        ),
      ),
      content: summaryAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: InfoBar(
            title: const Text('Failed to load'),
            content: Text('$e'),
            severity: InfoBarSeverity.error,
            isLong: true,
          ),
        ),
        data: (s) {
          if (s.totalTasks == 0) {
            return const _EmptyState();
          }
          final showRepoTable = s.repositories.isNotEmpty;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(
                  title: 'Summary',
                  child: _SummaryCard(s: s),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Duration',
                  child: _DurationCard(s: s),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: '30-day throughput',
                  child: _ThroughputCard(s: s),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Rework distribution',
                  child: _ReworkCard(s: s),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Failure breakdown',
                  child: _FailureCard(s: s),
                ),
                if (showRepoTable) ...[
                  const SizedBox(height: 16),
                  _Section(
                    title: 'By repository',
                    child: _RepositoryTable(s: s),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scope picker
// ---------------------------------------------------------------------------

class _ScopePicker extends ConsumerWidget {
  const _ScopePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reposAsync = ref.watch(kanbanRepositoriesProvider);
    final scope = ref.watch(insightsScopeProvider);
    return reposAsync.when(
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: ProgressRing(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (repos) {
        final items = <ComboBoxItem<String?>>[
          const ComboBoxItem(value: null, child: Text('All repositories')),
          for (final pb.Repository r in repos)
            ComboBoxItem(value: r.id, child: Text(r.displayName)),
        ];
        return SizedBox(
          width: 220,
          child: ComboBox<String?>(
            value: scope,
            items: items,
            onChanged: (v) =>
                ref.read(insightsScopeProvider.notifier).state = v,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.s});
  final ins_pb.InsightsSummary s;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final rate = (s.completionRate * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(label: 'Total tasks', value: '${s.totalTasks}'),
            ),
            Expanded(
              child: _Metric(label: 'In progress', value: '${s.activeTasks}'),
            ),
            Expanded(
              child: _Metric(
                label: 'Done',
                value: '${s.doneTasks}',
                valueColor: const Color(0xFF107C10),
              ),
            ),
            Expanded(
              child: _Metric(
                label: 'Failed',
                value: '${s.failedTasks}',
                valueColor: s.failedTasks == 0 ? null : const Color(0xFFC42B1C),
              ),
            ),
            Expanded(
              child: _Metric(
                label: 'Aborted / cancelled',
                value: '${s.abortedTasks + s.cancelledTasks}',
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Completion rate', style: theme.typography.bodyStrong),
            const SizedBox(width: 12),
            Expanded(
              child: ProgressBar(value: s.completionRate * 100, strokeWidth: 6),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Text(
                '$rate %',
                textAlign: TextAlign.right,
                style: theme.typography.bodyStrong,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({required this.s});
  final ins_pb.InsightsSummary s;

  @override
  Widget build(BuildContext context) {
    if (s.completedSamples == 0) {
      return const Text('No completed tasks yet.');
    }
    return Row(
      children: [
        Expanded(
          child: _Metric(label: 'Samples', value: '${s.completedSamples}'),
        ),
        Expanded(
          child: _Metric(
            label: 'Mean',
            value: _formatDuration(s.avgDurationSeconds),
          ),
        ),
        Expanded(
          child: _Metric(
            label: 'Median',
            value: _formatDuration(s.medianDurationSeconds),
          ),
        ),
        Expanded(
          child: _Metric(
            label: 'P90',
            value: _formatDuration(s.p90DurationSeconds),
          ),
        ),
      ],
    );
  }
}

class _ReworkCard extends StatelessWidget {
  const _ReworkCard({required this.s});
  final ins_pb.InsightsSummary s;

  @override
  Widget build(BuildContext context) {
    final buckets = s.reworkBuckets;
    if (buckets.isEmpty) {
      return const Text('No data.');
    }
    int maxCount = 0;
    for (final b in buckets) {
      if (b.taskCount > maxCount) maxCount = b.taskCount;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in buckets)
          _HistogramRow(
            label: b.reworkCount == 0 ? 'First-pass' : 'Rework x${b.reworkCount}',
            value: b.taskCount,
            maxValue: maxCount,
          ),
      ],
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.s});
  final ins_pb.InsightsSummary s;

  @override
  Widget build(BuildContext context) {
    final buckets = s.failureBuckets;
    if (buckets.isEmpty) {
      return const Text('No failed tasks.');
    }
    int maxCount = 0;
    for (final b in buckets) {
      if (b.count > maxCount) maxCount = b.count;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in buckets)
          _HistogramRow(
            label: b.errorCode,
            value: b.count,
            maxValue: maxCount,
            barColor: const Color(0xFFC42B1C),
          ),
      ],
    );
  }
}

class _ThroughputCard extends StatelessWidget {
  const _ThroughputCard({required this.s});
  final ins_pb.InsightsSummary s;

  @override
  Widget build(BuildContext context) {
    final days = s.dailyThroughput;
    if (days.isEmpty) {
      return const Text('No data.');
    }
    int totalDone = 0;
    int totalFailed = 0;
    int peak = 0;
    for (final d in days) {
      totalDone += d.completed;
      totalFailed += d.failed;
      final sum = d.completed + d.failed;
      if (sum > peak) peak = sum;
    }
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(label: 'Done (30d)', value: '$totalDone'),
            ),
            Expanded(
              child: _Metric(label: 'Failed (30d)', value: '$totalFailed'),
            ),
            Expanded(
              child: _Metric(label: 'Peak / day', value: '$peak'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: _DailyBars(days: days, peak: peak),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              days.first.date,
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorTertiary,
              ),
            ),
            Text(
              days.last.date,
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.days, required this.peak});
  final List<ins_pb.DailyThroughput> days;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (d.failed > 0)
                    Container(
                      height: peak == 0 ? 0 : 72 * d.failed / peak,
                      color: const Color(0xFFC42B1C).withValues(alpha: 0.7),
                    ),
                  if (d.completed > 0)
                    Container(
                      height: peak == 0 ? 0 : 72 * d.completed / peak,
                      color: theme.accentColor.defaultBrushFor(
                        theme.brightness,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RepositoryTable extends StatelessWidget {
  const _RepositoryTable({required this.s});
  final ins_pb.InsightsSummary s;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final rows = s.repositories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Repository',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorTertiary,
                  ),
                ),
              ),
              _headerCell(theme, 'Total'),
              _headerCell(theme, 'Done'),
              _headerCell(theme, 'Failed'),
              _headerCell(theme, 'Rate'),
              _headerCell(theme, 'Mean'),
            ],
          ),
        ),
        const Divider(),
        for (int i = 0; i < rows.length; i++) ...[
          _RepositoryRow(row: rows[i]),
          if (i < rows.length - 1)
            Container(
              height: 1,
              color: theme.resources.dividerStrokeColorDefault,
            ),
        ],
      ],
    );
  }

  Widget _headerCell(FluentThemeData theme, String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: theme.typography.caption?.copyWith(
          color: theme.resources.textFillColorTertiary,
        ),
      ),
    );
  }
}

class _RepositoryRow extends StatelessWidget {
  const _RepositoryRow({required this.row});
  final ins_pb.RepositoryInsight row;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body,
            ),
          ),
          _valueCell(theme, '${row.total}'),
          _valueCell(theme, '${row.done}', color: const Color(0xFF107C10)),
          _valueCell(
            theme,
            '${row.failed}',
            color: row.failed == 0 ? null : const Color(0xFFC42B1C),
          ),
          _valueCell(
            theme,
            '${(row.completionRate * 100).toStringAsFixed(0)} %',
          ),
          _valueCell(
            theme,
            row.avgDurationSeconds == 0
                ? '-'
                : _formatDuration(row.avgDurationSeconds),
          ),
        ],
      ),
    );
  }

  Widget _valueCell(FluentThemeData theme, String text, {Color? color}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: theme.typography.body?.copyWith(color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.typography.caption?.copyWith(
            color: theme.resources.textFillColorTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.typography.subtitle?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HistogramRow extends StatelessWidget {
  const _HistogramRow({
    required this.label,
    required this.value,
    required this.maxValue,
    this.barColor,
  });
  final String label;
  final int value;
  final int maxValue;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final fraction = maxValue == 0 ? 0.0 : value / maxValue;
    final color =
        barColor ?? theme.accentColor.defaultBrushFor(theme.brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.typography.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.resources.subtleFillColorSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: theme.typography.bodyStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.b_i_dashboard,
              size: 48,
              color: theme.resources.textFillColorTertiary,
            ),
            const SizedBox(height: 16),
            Text('No task history yet.', style: theme.typography.bodyLarge),
            const SizedBox(height: 4),
            Text(
              'Create and run tasks from the Kanban page — aggregates show up here.',
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

String _formatDuration(double seconds) {
  if (seconds <= 0) return '-';
  final total = seconds.round();
  if (total < 60) return '${total}s';
  final m = total ~/ 60;
  final s = total % 60;
  if (m < 60) return '${m}m ${s}s';
  final h = m ~/ 60;
  final mm = m % 60;
  return '${h}h ${mm}m';
}
