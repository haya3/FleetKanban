// GrpcClient bundles the generated gRPC stubs and attaches the
// x-auth-token handshake metadata to every call.
//
// Connection topology: always loopback (127.0.0.1) with the port emitted by
// the sidecar's READY handshake. TLS is disabled — there is no
// over-the-wire attacker model because the socket is bound to the loopback
// interface and protected by a per-session token.

import 'package:grpc/grpc.dart';

import 'generated/fleetkanban/v1/housekeeping.pbgrpc.dart' as housekeeping_pb;
import 'generated/fleetkanban/v1/insights.pbgrpc.dart' as insights_pb;
import 'generated/fleetkanban/v1/fleetkanban.pbgrpc.dart' as pb;
import 'sidecar_supervisor.dart';

/// The gRPC metadata key that carries the handshake token.
const String authMetadataKey = 'x-auth-token';

class IpcClient {
  IpcClient._({
    required ClientChannel channel,
    required this.task,
    required this.subtask,
    required this.repository,
    required this.auth,
    required this.system,
    required this.worktree,
    required this.model,
    required this.housekeeping,
    required this.insights,
  }) : _channel = channel;

  final ClientChannel _channel;

  // Generated service stubs. Each stub call picks up the x-auth-token
  // metadata via the CallOptions we inject at construction time.
  final pb.TaskServiceClient task;
  final pb.SubtaskServiceClient subtask;
  final pb.RepositoryServiceClient repository;
  final pb.AuthServiceClient auth;
  final pb.SystemServiceClient system;
  final pb.WorktreeServiceClient worktree;
  final pb.ModelServiceClient model;
  // Housekeeping service (phase1-spec §3.1). Surfaces the opt-in
  // Merged-sweep setting, stale branch audit, and manual sweep trigger.
  // Returns UNAVAILABLE when the reaper failed to initialise.
  final housekeeping_pb.HousekeepingServiceClient housekeeping;
  // Insights service — aggregate dashboard metrics (completion rate,
  // rework/failure histograms, per-repository throughput) derived from
  // the tasks table. Read-only.
  final insights_pb.InsightsServiceClient insights;

  /// Connects to the sidecar described by [endpoint].
  static IpcClient connect(SidecarEndpoint endpoint) {
    final channel = ClientChannel(
      '127.0.0.1',
      port: endpoint.port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        // Keep-alive pings so mid-stream disconnects surface quickly instead
        // of stalling the UI when the sidecar crashes.
        idleTimeout: Duration(seconds: 30),
      ),
    );
    final callOptions = CallOptions(
      metadata: {authMetadataKey: endpoint.token},
    );
    return IpcClient._(
      channel: channel,
      task: pb.TaskServiceClient(channel, options: callOptions),
      subtask: pb.SubtaskServiceClient(channel, options: callOptions),
      repository: pb.RepositoryServiceClient(channel, options: callOptions),
      auth: pb.AuthServiceClient(channel, options: callOptions),
      system: pb.SystemServiceClient(channel, options: callOptions),
      worktree: pb.WorktreeServiceClient(channel, options: callOptions),
      model: pb.ModelServiceClient(channel, options: callOptions),
      housekeeping: housekeeping_pb.HousekeepingServiceClient(
        channel,
        options: callOptions,
      ),
      insights: insights_pb.InsightsServiceClient(
        channel,
        options: callOptions,
      ),
    );
  }

  /// Closes the underlying channel. Pending RPCs receive UNAVAILABLE.
  Future<void> shutdown() async {
    await _channel.shutdown();
  }
}
