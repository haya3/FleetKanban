// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/housekeeping.proto.

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
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $0;

import 'housekeeping.pb.dart' as $1;

export 'housekeeping.pb.dart';

@$pb.GrpcServiceName('fleetkanban.v1.HousekeepingService')
class HousekeepingServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HousekeepingServiceClient(super.channel, {super.options, super.interceptors});

  /// GetAutoSweepDays returns the current Merged-sweep threshold in days
  /// (0 = disabled). Always succeeds — an unset setting reports 0.
  $grpc.ResponseFuture<$1.GetAutoSweepDaysResponse> getAutoSweepDays(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAutoSweepDays, request, options: options);
  }

  /// SetAutoSweepDays updates the Merged-sweep threshold. Pass 0 to disable.
  /// Values are clamped to [0, 365].
  $grpc.ResponseFuture<$1.SetAutoSweepDaysResponse> setAutoSweepDays(
    $1.SetAutoSweepDaysRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setAutoSweepDays, request, options: options);
  }

  /// ListStaleBranches returns tasks whose fleetkanban/<id> branch is still
  /// present and whose FinishedAt is older than `older_than_days`. Used by
  /// the Housekeeping UI so the user can review / cleanup manually. When
  /// `older_than_days` is 0 the server uses a 30-day default.
  $grpc.ResponseFuture<$1.ListStaleBranchesResponse> listStaleBranches(
    $1.ListStaleBranchesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listStaleBranches, request, options: options);
  }

  /// RunSweepNow triggers one Merged-sweep pass using `days` as the age
  /// threshold (or the current setting when `days` is 0). Returns the same
  /// stats the background ticker logs.
  $grpc.ResponseFuture<$1.RunSweepNowResponse> runSweepNow(
    $1.RunSweepNowRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$runSweepNow, request, options: options);
  }

  // method descriptors

  static final _$getAutoSweepDays =
      $grpc.ClientMethod<$0.Empty, $1.GetAutoSweepDaysResponse>(
          '/fleetkanban.v1.HousekeepingService/GetAutoSweepDays',
          ($0.Empty value) => value.writeToBuffer(),
          $1.GetAutoSweepDaysResponse.fromBuffer);
  static final _$setAutoSweepDays = $grpc.ClientMethod<
          $1.SetAutoSweepDaysRequest, $1.SetAutoSweepDaysResponse>(
      '/fleetkanban.v1.HousekeepingService/SetAutoSweepDays',
      ($1.SetAutoSweepDaysRequest value) => value.writeToBuffer(),
      $1.SetAutoSweepDaysResponse.fromBuffer);
  static final _$listStaleBranches = $grpc.ClientMethod<
          $1.ListStaleBranchesRequest, $1.ListStaleBranchesResponse>(
      '/fleetkanban.v1.HousekeepingService/ListStaleBranches',
      ($1.ListStaleBranchesRequest value) => value.writeToBuffer(),
      $1.ListStaleBranchesResponse.fromBuffer);
  static final _$runSweepNow =
      $grpc.ClientMethod<$1.RunSweepNowRequest, $1.RunSweepNowResponse>(
          '/fleetkanban.v1.HousekeepingService/RunSweepNow',
          ($1.RunSweepNowRequest value) => value.writeToBuffer(),
          $1.RunSweepNowResponse.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.HousekeepingService')
abstract class HousekeepingServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.HousekeepingService';

  HousekeepingServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.GetAutoSweepDaysResponse>(
        'GetAutoSweepDays',
        getAutoSweepDays_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.GetAutoSweepDaysResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SetAutoSweepDaysRequest,
            $1.SetAutoSweepDaysResponse>(
        'SetAutoSweepDays',
        setAutoSweepDays_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.SetAutoSweepDaysRequest.fromBuffer(value),
        ($1.SetAutoSweepDaysResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ListStaleBranchesRequest,
            $1.ListStaleBranchesResponse>(
        'ListStaleBranches',
        listStaleBranches_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.ListStaleBranchesRequest.fromBuffer(value),
        ($1.ListStaleBranchesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.RunSweepNowRequest, $1.RunSweepNowResponse>(
            'RunSweepNow',
            runSweepNow_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.RunSweepNowRequest.fromBuffer(value),
            ($1.RunSweepNowResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetAutoSweepDaysResponse> getAutoSweepDays_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getAutoSweepDays($call, await $request);
  }

  $async.Future<$1.GetAutoSweepDaysResponse> getAutoSweepDays(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.SetAutoSweepDaysResponse> setAutoSweepDays_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.SetAutoSweepDaysRequest> $request) async {
    return setAutoSweepDays($call, await $request);
  }

  $async.Future<$1.SetAutoSweepDaysResponse> setAutoSweepDays(
      $grpc.ServiceCall call, $1.SetAutoSweepDaysRequest request);

  $async.Future<$1.ListStaleBranchesResponse> listStaleBranches_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.ListStaleBranchesRequest> $request) async {
    return listStaleBranches($call, await $request);
  }

  $async.Future<$1.ListStaleBranchesResponse> listStaleBranches(
      $grpc.ServiceCall call, $1.ListStaleBranchesRequest request);

  $async.Future<$1.RunSweepNowResponse> runSweepNow_Pre($grpc.ServiceCall $call,
      $async.Future<$1.RunSweepNowRequest> $request) async {
    return runSweepNow($call, await $request);
  }

  $async.Future<$1.RunSweepNowResponse> runSweepNow(
      $grpc.ServiceCall call, $1.RunSweepNowRequest request);
}
