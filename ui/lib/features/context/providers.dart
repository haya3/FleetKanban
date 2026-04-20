// Riverpod providers for the Context feature. Each sub-tab reads its
// slice of state through one of these so callers do not have to know
// which gRPC client method maps to which tab.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';

/// Currently selected repository. The Context page scopes all its
/// queries to this id. Empty string = "no selection"; in that case the
/// tabs render an empty state rather than issuing RPCs.
final selectedContextRepoProvider = StateProvider<String>((_) => '');

/// Repository dropdown options. Shares the existing repositoriesProvider
/// under the hood so the list matches the Kanban header's dropdown.
final contextRepositoriesProvider = FutureProvider<List<pb.Repository>>((ref) {
  return ref.watch(repositoriesProvider.future);
});

/// Overview aggregator for the selected repo.
final contextOverviewProvider = FutureProvider.autoDispose<pb.ContextOverview?>(
  (ref) async {
    final repoId = ref.watch(selectedContextRepoProvider);
    if (repoId.isEmpty) return null;
    final client = ref.watch(ipcClientProvider);
    return client.context.getOverview(pb.RepoIdRequest(repoId: repoId));
  },
);

/// Memory settings for the selected repo. The Settings tab reads this
/// to drive the enable toggle + provider pickers.
final contextMemorySettingsProvider =
    FutureProvider.autoDispose<pb.MemorySettings?>((ref) async {
      final repoId = ref.watch(selectedContextRepoProvider);
      if (repoId.isEmpty) return null;
      final client = ref.watch(ipcClientProvider);
      return client.context.getMemorySettings(pb.RepoIdRequest(repoId: repoId));
    });

// ----- Search --------------------------------------------------------------

/// Raw search input. Debouncing is applied at the tab level.
final contextSearchQueryProvider = StateProvider<String>((_) => '');

/// Hybrid search results for the current query + repo.
final contextSearchResultsProvider =
    FutureProvider.autoDispose<pb.SearchContextResponse?>((ref) async {
      final repoId = ref.watch(selectedContextRepoProvider);
      final query = ref.watch(contextSearchQueryProvider);
      if (repoId.isEmpty || query.trim().isEmpty) return null;
      final client = ref.watch(ipcClientProvider);
      return client.context.searchContext(
        pb.SearchContextRequest(
          repoId: repoId,
          query: query,
          limit: 20,
          onlyEnabled: true,
        ),
      );
    });

// ----- Browse --------------------------------------------------------------

/// Kind filter for the Browse tab. Empty = all kinds.
final contextBrowseKindFilterProvider = StateProvider<Set<String>>((_) => {});

/// Browse-tab node list. Filtered by kind + selected repo.
final contextBrowseNodesProvider =
    FutureProvider.autoDispose<pb.ListNodesResponse?>((ref) async {
      final repoId = ref.watch(selectedContextRepoProvider);
      if (repoId.isEmpty) return null;
      final kinds = ref.watch(contextBrowseKindFilterProvider);
      final client = ref.watch(ipcClientProvider);
      return client.context.listNodes(
        pb.ListNodesRequest(
          repoId: repoId,
          kinds: kinds.toList(),
          limit: 200,
          sort: 'updated_at',
        ),
      );
    });

/// Selected node id in the Browse tab. Drives the right-pane detail view.
final contextSelectedNodeIdProvider = StateProvider<String>((_) => '');

/// Full detail for the selected node.
final contextNodeDetailProvider =
    FutureProvider.autoDispose<pb.ContextNodeDetail?>((ref) async {
      final id = ref.watch(contextSelectedNodeIdProvider);
      if (id.isEmpty) return null;
      final client = ref.watch(ipcClientProvider);
      return client.context.getNode(pb.NodeIdRequest(nodeId: id));
    });

// ----- Scratchpad ----------------------------------------------------------

/// Pending scratchpad entries for the selected repo.
final contextScratchpadPendingProvider =
    FutureProvider.autoDispose<pb.ListPendingResponse?>((ref) async {
      final repoId = ref.watch(selectedContextRepoProvider);
      if (repoId.isEmpty) return null;
      final client = ref.watch(ipcClientProvider);
      return client.scratchpad.listPending(
        pb.ListPendingRequest(repoId: repoId, statuses: ['pending'], limit: 50),
      );
    });

// ----- Facts Timeline ------------------------------------------------------

/// Facts list for the selected repo.
final contextFactsProvider = FutureProvider.autoDispose<pb.ListFactsResponse?>((
  ref,
) async {
  final repoId = ref.watch(selectedContextRepoProvider);
  if (repoId.isEmpty) return null;
  final client = ref.watch(ipcClientProvider);
  return client.context.listFacts(
    pb.ListFactsRequest(repoId: repoId, includeExpired: true, limit: 100),
  );
});

// ----- Injection Preview ---------------------------------------------------

/// Draft prompt text the user types into the Injection Preview tab.
final injectionPreviewDraftProvider = StateProvider<String>((_) => '');

/// Resolved preview for the current draft prompt + repo.
final contextInjectionPreviewProvider =
    FutureProvider.autoDispose<pb.InjectionPreview?>((ref) async {
      final repoId = ref.watch(selectedContextRepoProvider);
      final draft = ref.watch(injectionPreviewDraftProvider);
      if (repoId.isEmpty || draft.trim().isEmpty) return null;
      final client = ref.watch(ipcClientProvider);
      return client.context.previewInjection(
        pb.PreviewInjectionRequest(
          repoId: repoId,
          rawPrompt: draft,
          tier: 'passive',
        ),
      );
    });

// ----- Ollama onboarding ---------------------------------------------------

// ----- WatchContextChanges stream + analyzer state tracker --------------

/// Raw change-event stream for the selected repo. Broadcast so multiple
/// listeners (Overview auto-refresh, analyzer state tracker) can share
/// one gRPC subscription without each paying for a sidecar stream.
final contextChangesStreamProvider =
    StreamProvider.autoDispose<pb.ContextChangeEvent>((ref) async* {
      final repoId = ref.watch(selectedContextRepoProvider);
      if (repoId.isEmpty) return;
      final client = ref.watch(ipcClientProvider);
      final stream = client.context.watchContextChanges(
        pb.WatchContextRequest(repoId: repoId),
      );
      await for (final evt in stream) {
        yield evt;
      }
    });

/// AnalyzerPhase is the lifecycle the UI cares about. idle → running →
/// complete (auto-resets to idle after a short delay) / error (reset on
/// next run).
enum AnalyzerPhase { idle, running, complete, error }

/// AnalyzerStateNotifier tracks AnalyzerPhase from local button taps
/// AND incoming "analyzer" change events. The notifier is the single
/// source of truth the AnalyzeButton + banner read from.
/// AnalyzerProgressLine is one timestamped log entry accumulated
/// during a running analyzer session. Rendered in the banner as a
/// rolling log so the user can see the analyzer is alive.
class AnalyzerProgressLine {
  const AnalyzerProgressLine({required this.at, required this.text});
  final DateTime at;
  final String text;
}

/// AnalyzerStatus bundles the AnalyzerPhase with the latest error
/// message (populated for AnalyzerPhase.error events via the change
/// stream) and the rolling progress log.
class AnalyzerStatus {
  const AnalyzerStatus({
    required this.phase,
    this.message = '',
    this.progress = const [],
  });
  final AnalyzerPhase phase;
  final String message;
  final List<AnalyzerProgressLine> progress;

  AnalyzerStatus copyWith({
    AnalyzerPhase? phase,
    String? message,
    List<AnalyzerProgressLine>? progress,
  }) => AnalyzerStatus(
    phase: phase ?? this.phase,
    message: message ?? this.message,
    progress: progress ?? this.progress,
  );
}

class AnalyzerStateNotifier extends AutoDisposeNotifier<AnalyzerStatus> {
  /// Maximum rolling log size. Enough to visualise a lively session
  /// without consuming unbounded memory on a stuck analyzer.
  static const int _maxProgressLines = 100;

  @override
  AnalyzerStatus build() {
    // Listen for analyzer lifecycle events on the change stream.
    ref.listen<AsyncValue<pb.ContextChangeEvent>>(
      contextChangesStreamProvider,
      (_, next) {
        next.whenData((evt) {
          if (evt.kind != 'analyzer') return;
          switch (evt.op) {
            case 'start':
              state = const AnalyzerStatus(phase: AnalyzerPhase.running);
              break;
            case 'progress':
              if (state.phase != AnalyzerPhase.running) return;
              final line = AnalyzerProgressLine(
                at: evt.hasOccurredAt()
                    ? evt.occurredAt.toDateTime().toLocal()
                    : DateTime.now(),
                text: evt.message,
              );
              final next = [...state.progress, line];
              if (next.length > _maxProgressLines) {
                next.removeRange(0, next.length - _maxProgressLines);
              }
              state = state.copyWith(progress: next);
              break;
            case 'complete':
              state = const AnalyzerStatus(phase: AnalyzerPhase.complete);
              ref.invalidate(contextOverviewProvider);
              ref.invalidate(contextScratchpadPendingProvider);
              Future.delayed(const Duration(seconds: 6), () {
                if (state.phase == AnalyzerPhase.complete) {
                  state = const AnalyzerStatus(phase: AnalyzerPhase.idle);
                }
              });
              break;
            case 'error':
              state = AnalyzerStatus(
                phase: AnalyzerPhase.error,
                message: evt.message,
                progress: state.progress,
              );
              break;
          }
        });
      },
      fireImmediately: false,
    );
    return const AnalyzerStatus(phase: AnalyzerPhase.idle);
  }

  /// markRunning is called by the AnalyzeButton immediately after the
  /// RPC returns so the UI flips into "running" before the first
  /// start event lands (the sidecar publishes start synchronously,
  /// but the RPC return + stream dispatch race can briefly leave us
  /// in idle). Also clears any previous progress log.
  void markRunning() =>
      state = const AnalyzerStatus(phase: AnalyzerPhase.running);

  /// markError lets the button record local RPC failures that never
  /// reach the server-side broker.
  void markError(String message) =>
      state = AnalyzerStatus(phase: AnalyzerPhase.error, message: message);
}

final analyzerStateProvider =
    AutoDisposeNotifierProvider<AnalyzerStateNotifier, AnalyzerStatus>(
      AnalyzerStateNotifier.new,
    );

final ollamaStatusProvider = FutureProvider.autoDispose<pb.OllamaStatus>((
  ref,
) async {
  final client = ref.watch(ipcClientProvider);
  return client.ollama.getOllamaStatus(Empty());
});

final ollamaRecommendedProvider =
    FutureProvider.autoDispose<pb.OllamaListRecommendedResponse>((ref) async {
      final client = ref.watch(ipcClientProvider);
      return client.ollama.getRecommendedModels(Empty());
    });
