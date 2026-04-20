// ContextPage — the user-facing entry point for the Graph Memory
// subsystem. Hosts six TabView tabs (Overview / Search / Browse /
// Scratchpad / Facts / Injection Preview) plus a repo selector in
// the header. Each tab reads a narrow slice of state through
// features/context/providers.dart so this widget stays focused on
// layout.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';
import 'providers.dart';
import 'tabs/browse_tab.dart';
import 'tabs/facts_timeline_tab.dart';
import 'tabs/injection_preview_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/scratchpad_tab.dart';
import 'tabs/search_tab.dart';

class ContextPage extends ConsumerStatefulWidget {
  const ContextPage({super.key});

  @override
  ConsumerState<ContextPage> createState() => _ContextPageState();
}

class _ContextPageState extends ConsumerState<ContextPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final repos = ref.watch(contextRepositoriesProvider);
    final pendingCount = ref
        .watch(contextScratchpadPendingProvider)
        .maybeWhen(data: (resp) => resp?.total ?? 0, orElse: () => 0);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Context'),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _RefreshButton(),
            const SizedBox(width: 8),
            const _AnalyzeButton(),
            const SizedBox(width: 8),
            _RepoPicker(repos: repos),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AnalyzerBanner(),
          Expanded(
            child: TabView(
              currentIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
              closeButtonVisibility: CloseButtonVisibilityMode.never,
              tabs: [
                Tab(
                  icon: const Icon(FluentIcons.b_i_dashboard),
                  text: const Text('Overview'),
                  body: const OverviewTab(),
                ),
                Tab(
                  icon: const Icon(FluentIcons.search),
                  text: const Text('Search'),
                  body: const SearchTab(),
                ),
                Tab(
                  icon: const Icon(FluentIcons.library),
                  text: const Text('Browse'),
                  body: const BrowseTab(),
                ),
                Tab(
                  icon: const Icon(FluentIcons.lightbulb),
                  text: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Scratchpad'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 8),
                        _Badge(count: pendingCount),
                      ],
                    ],
                  ),
                  body: const ScratchpadTab(),
                ),
                Tab(
                  icon: const Icon(FluentIcons.time_picker),
                  text: const Text('Facts'),
                  body: const FactsTimelineTab(),
                ),
                Tab(
                  icon: const Icon(FluentIcons.preview_link),
                  text: const Text('Injection Preview'),
                  body: const InjectionPreviewTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// _AnalyzerProgressLog is the rolling status log surfaced inside the
/// analyzer banner. Shows the last N timestamped lines with a fixed
/// max height so a chatty session doesn't push the rest of the page
/// around. Auto-scrolls to the bottom when new lines arrive.
class _AnalyzerProgressLog extends StatefulWidget {
  const _AnalyzerProgressLog({required this.lines});
  final List<AnalyzerProgressLine> lines;
  @override
  State<_AnalyzerProgressLog> createState() => _AnalyzerProgressLogState();
}

class _AnalyzerProgressLogState extends State<_AnalyzerProgressLog> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _AnalyzerProgressLog old) {
    super.didUpdateWidget(old);
    // Scroll to end on next frame when new lines have arrived.
    if (widget.lines.length > old.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    if (widget.lines.isEmpty) {
      return Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: ProgressRing(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Waiting for the first response from Copilot…',
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
        ],
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in widget.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  '${_formatTime(line.at)}  ${line.text}',
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime t) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
}

/// _AnalyzerBanner renders an InfoBar while the analyzer is running
/// and a transient success bar for a few seconds after completion.
/// Error state shows the copyable error message so the user can paste
/// it into an issue / AI chat without chasing the sidecar log.
class _AnalyzerBanner extends ConsumerWidget {
  const _AnalyzerBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(analyzerStateProvider);
    switch (status.phase) {
      case AnalyzerPhase.running:
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: InfoBar(
            title: const Text('Analyzer is running'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Copilot is reading the repository. Results will appear '
                  'in the Scratchpad tab when the session completes '
                  '(typically 30s – 3min).',
                ),
                const SizedBox(height: 8),
                _AnalyzerProgressLog(lines: status.progress),
              ],
            ),
            severity: InfoBarSeverity.info,
            isIconVisible: true,
          ),
        );
      case AnalyzerPhase.complete:
        return const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: InfoBar(
            title: Text('Analyzer finished'),
            content: Text(
              'Check the Scratchpad tab for proposed memory entries and '
              'promote the ones you want to keep.',
            ),
            severity: InfoBarSeverity.success,
            isIconVisible: true,
          ),
        );
      case AnalyzerPhase.error:
        final msg = status.message.isEmpty
            ? 'Analyzer failed — no message received from the sidecar. '
                  'Check %APPDATA%\\FleetKanban\\logs\\sidecar.log for '
                  'the full trace.'
            : status.message;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: InfoBar(
            title: const Text('Analyzer session failed'),
            content: CopyableErrorText(
              text: msg,
              reportTitle: 'Context / AnalyzeRepository',
            ),
            severity: InfoBarSeverity.error,
            isIconVisible: true,
          ),
        );
      case AnalyzerPhase.idle:
        return const SizedBox.shrink();
    }
  }
}

class _RefreshButton extends ConsumerWidget {
  const _RefreshButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(FluentIcons.refresh),
      onPressed: () {
        // Invalidate every autoDispose provider so tabs re-fetch.
        ref.invalidate(contextOverviewProvider);
        ref.invalidate(contextSearchResultsProvider);
        ref.invalidate(contextBrowseNodesProvider);
        ref.invalidate(contextNodeDetailProvider);
        ref.invalidate(contextScratchpadPendingProvider);
        ref.invalidate(contextFactsProvider);
        ref.invalidate(contextInjectionPreviewProvider);
        ref.invalidate(contextMemorySettingsProvider);
      },
    );
  }
}

class _AnalyzeButton extends ConsumerWidget {
  const _AnalyzeButton();

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    final repoId = ref.read(selectedContextRepoProvider);
    if (repoId.isEmpty) return;
    final notifier = ref.read(analyzerStateProvider.notifier);
    final client = ref.read(ipcClientProvider);
    // Optimistic flip — the server's "analyzer/start" event will also
    // arrive via WatchContextChanges and keep us there.
    notifier.markRunning();
    try {
      await client.context.analyzeRepository(
        pb.AnalyzeRepoRequest(repoId: repoId),
      );
    } catch (e, st) {
      notifier.markError('$e\n\n$st');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoId = ref.watch(selectedContextRepoProvider);
    // Ensure the change stream is kept alive so analyzer events land.
    ref.watch(contextChangesStreamProvider);
    final status = ref.watch(analyzerStateProvider);
    final running = status.phase == AnalyzerPhase.running;
    final disabled = repoId.isEmpty || running;
    return FilledButton(
      onPressed: disabled ? null : () => _run(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (running)
            const SizedBox(
              width: 14,
              height: 14,
              child: ProgressRing(strokeWidth: 2),
            )
          else
            const Icon(FluentIcons.search, size: 14),
          const SizedBox(width: 6),
          Text(running ? 'Analyzing…' : 'Analyze this repository'),
        ],
      ),
    );
  }
}

class _RepoPicker extends ConsumerWidget {
  const _RepoPicker({required this.repos});
  final AsyncValue<List<pb.Repository>> repos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return repos.when(
      loading: () => const ProgressRing(),
      error: (e, st) => CopyableErrorText(
        text: '$e\n\n$st',
        reportTitle: 'Context / repo list',
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Text(
            'No repositories registered yet',
            style: TextStyle(fontStyle: FontStyle.italic),
          );
        }
        final selected = ref.watch(selectedContextRepoProvider);
        // Auto-select the first repo when nothing is chosen yet so the
        // tabs do something meaningful on first visit.
        final effective = selected.isEmpty ? list.first.id : selected;
        if (selected.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedContextRepoProvider.notifier).state = effective;
          });
        }
        return ComboBox<String>(
          placeholder: const Text('Select repository'),
          value: list.any((r) => r.id == effective) ? effective : null,
          onChanged: (v) {
            if (v != null) {
              ref.read(selectedContextRepoProvider.notifier).state = v;
            }
          },
          items: [
            for (final r in list)
              ComboBoxItem<String>(value: r.id, child: Text(r.displayName)),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.accentColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
