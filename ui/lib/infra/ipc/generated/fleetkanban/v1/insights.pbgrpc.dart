// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/insights.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'insights.pb.dart' as $0;

export 'insights.pb.dart';

@$pb.GrpcServiceName('fleetkanban.v1.InsightsService')
class InsightsServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  InsightsServiceClient(super.channel, {super.options, super.interceptors});

  /// GetInsights returns a one-shot snapshot of the aggregate metrics for
  /// the given repository (or across all registered repositories when
  /// repository_id is empty). All counters are derived from the current
  /// tasks table — the call is read-only and safe to invoke repeatedly.
  $grpc.ResponseFuture<$0.InsightsSummary> getInsights(
    $0.GetInsightsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getInsights, request, options: options);
  }

  // method descriptors

  static final _$getInsights =
      $grpc.ClientMethod<$0.GetInsightsRequest, $0.InsightsSummary>(
          '/fleetkanban.v1.InsightsService/GetInsights',
          ($0.GetInsightsRequest value) => value.writeToBuffer(),
          $0.InsightsSummary.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.InsightsService')
abstract class InsightsServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.InsightsService';

  InsightsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetInsightsRequest, $0.InsightsSummary>(
        'GetInsights',
        getInsights_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetInsightsRequest.fromBuffer(value),
        ($0.InsightsSummary value) => value.writeToBuffer()));
  }

  $async.Future<$0.InsightsSummary> getInsights_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetInsightsRequest> $request) async {
    return getInsights($call, await $request);
  }

  $async.Future<$0.InsightsSummary> getInsights(
      $grpc.ServiceCall call, $0.GetInsightsRequest request);
}
