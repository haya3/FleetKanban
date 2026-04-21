// Insights feature state: one provider per dashboard scope (all repos or a
// specific repo). The summary is a snapshot — the user pulls-to-refresh via
// the header action rather than live-updating, because the underlying data
// only changes on task-completion boundaries and a constant-refetch stream
// would be wasteful.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../infra/ipc/generated/fleetkanban/v1/insights.pb.dart' as ins_pb;
import '../../infra/ipc/providers.dart';

/// Repository filter for the Insights page. null = aggregate across every
/// registered repository (which also populates the per-repo breakdown
/// table). A non-null value scopes the snapshot to that repository.
final insightsScopeProvider = StateProvider<String?>((_) => null);

/// Insights snapshot for the current scope. autoDispose so switching scope
/// discards the previous result and a fresh fetch kicks off cleanly.
final insightsSummaryProvider =
    FutureProvider.autoDispose<ins_pb.InsightsSummary>((ref) async {
      final client = ref.watch(ipcClientProvider);
      final scope = ref.watch(insightsScopeProvider);
      return client.insights.getInsights(
        ins_pb.GetInsightsRequest(repositoryId: scope ?? ''),
      );
    });
