// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/housekeeping.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class GetAutoSweepDaysResponse extends $pb.GeneratedMessage {
  factory GetAutoSweepDaysResponse({
    $core.int? days,
    $core.bool? present,
  }) {
    final result = create();
    if (days != null) result.days = days;
    if (present != null) result.present = present;
    return result;
  }

  GetAutoSweepDaysResponse._();

  factory GetAutoSweepDaysResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetAutoSweepDaysResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAutoSweepDaysResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'days')
    ..aOB(2, _omitFieldNames ? '' : 'present')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAutoSweepDaysResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAutoSweepDaysResponse copyWith(
          void Function(GetAutoSweepDaysResponse) updates) =>
      super.copyWith((message) => updates(message as GetAutoSweepDaysResponse))
          as GetAutoSweepDaysResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAutoSweepDaysResponse create() => GetAutoSweepDaysResponse._();
  @$core.override
  GetAutoSweepDaysResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetAutoSweepDaysResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAutoSweepDaysResponse>(create);
  static GetAutoSweepDaysResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get days => $_getIZ(0);
  @$pb.TagNumber(1)
  set days($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearDays() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get present => $_getBF(1);
  @$pb.TagNumber(2)
  set present($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPresent() => $_has(1);
  @$pb.TagNumber(2)
  void clearPresent() => $_clearField(2);
}

class SetAutoSweepDaysRequest extends $pb.GeneratedMessage {
  factory SetAutoSweepDaysRequest({
    $core.int? days,
  }) {
    final result = create();
    if (days != null) result.days = days;
    return result;
  }

  SetAutoSweepDaysRequest._();

  factory SetAutoSweepDaysRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetAutoSweepDaysRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetAutoSweepDaysRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'days')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAutoSweepDaysRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAutoSweepDaysRequest copyWith(
          void Function(SetAutoSweepDaysRequest) updates) =>
      super.copyWith((message) => updates(message as SetAutoSweepDaysRequest))
          as SetAutoSweepDaysRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetAutoSweepDaysRequest create() => SetAutoSweepDaysRequest._();
  @$core.override
  SetAutoSweepDaysRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetAutoSweepDaysRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetAutoSweepDaysRequest>(create);
  static SetAutoSweepDaysRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get days => $_getIZ(0);
  @$pb.TagNumber(1)
  set days($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearDays() => $_clearField(1);
}

class SetAutoSweepDaysResponse extends $pb.GeneratedMessage {
  factory SetAutoSweepDaysResponse({
    $core.int? effectiveDays,
  }) {
    final result = create();
    if (effectiveDays != null) result.effectiveDays = effectiveDays;
    return result;
  }

  SetAutoSweepDaysResponse._();

  factory SetAutoSweepDaysResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetAutoSweepDaysResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetAutoSweepDaysResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'effectiveDays')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAutoSweepDaysResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAutoSweepDaysResponse copyWith(
          void Function(SetAutoSweepDaysResponse) updates) =>
      super.copyWith((message) => updates(message as SetAutoSweepDaysResponse))
          as SetAutoSweepDaysResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetAutoSweepDaysResponse create() => SetAutoSweepDaysResponse._();
  @$core.override
  SetAutoSweepDaysResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetAutoSweepDaysResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetAutoSweepDaysResponse>(create);
  static SetAutoSweepDaysResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get effectiveDays => $_getIZ(0);
  @$pb.TagNumber(1)
  set effectiveDays($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEffectiveDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearEffectiveDays() => $_clearField(1);
}

class ListStaleBranchesRequest extends $pb.GeneratedMessage {
  factory ListStaleBranchesRequest({
    $core.int? olderThanDays,
  }) {
    final result = create();
    if (olderThanDays != null) result.olderThanDays = olderThanDays;
    return result;
  }

  ListStaleBranchesRequest._();

  factory ListStaleBranchesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListStaleBranchesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListStaleBranchesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'olderThanDays')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListStaleBranchesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListStaleBranchesRequest copyWith(
          void Function(ListStaleBranchesRequest) updates) =>
      super.copyWith((message) => updates(message as ListStaleBranchesRequest))
          as ListStaleBranchesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListStaleBranchesRequest create() => ListStaleBranchesRequest._();
  @$core.override
  ListStaleBranchesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListStaleBranchesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListStaleBranchesRequest>(create);
  static ListStaleBranchesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get olderThanDays => $_getIZ(0);
  @$pb.TagNumber(1)
  set olderThanDays($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOlderThanDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearOlderThanDays() => $_clearField(1);
}

/// StaleBranch is one row in the Stale-branch audit. It mirrors the minimal
/// task fields the UI needs; callers can fetch full Task records via
/// TaskService.GetTask when the user drills in.
class StaleBranch extends $pb.GeneratedMessage {
  factory StaleBranch({
    $core.String? taskId,
    $core.String? repoId,
    $core.String? repoPath,
    $core.String? branch,
    $core.String? baseBranch,
    $core.String? goal,
    $core.String? status,
    $2.Timestamp? finishedAt,
    $core.int? ageDays,
    $core.bool? merged,
  }) {
    final result = create();
    if (taskId != null) result.taskId = taskId;
    if (repoId != null) result.repoId = repoId;
    if (repoPath != null) result.repoPath = repoPath;
    if (branch != null) result.branch = branch;
    if (baseBranch != null) result.baseBranch = baseBranch;
    if (goal != null) result.goal = goal;
    if (status != null) result.status = status;
    if (finishedAt != null) result.finishedAt = finishedAt;
    if (ageDays != null) result.ageDays = ageDays;
    if (merged != null) result.merged = merged;
    return result;
  }

  StaleBranch._();

  factory StaleBranch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StaleBranch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StaleBranch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'taskId')
    ..aOS(2, _omitFieldNames ? '' : 'repoId')
    ..aOS(3, _omitFieldNames ? '' : 'repoPath')
    ..aOS(4, _omitFieldNames ? '' : 'branch')
    ..aOS(5, _omitFieldNames ? '' : 'baseBranch')
    ..aOS(6, _omitFieldNames ? '' : 'goal')
    ..aOS(7, _omitFieldNames ? '' : 'status')
    ..aOM<$2.Timestamp>(8, _omitFieldNames ? '' : 'finishedAt',
        subBuilder: $2.Timestamp.create)
    ..aI(9, _omitFieldNames ? '' : 'ageDays')
    ..aOB(10, _omitFieldNames ? '' : 'merged')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StaleBranch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StaleBranch copyWith(void Function(StaleBranch) updates) =>
      super.copyWith((message) => updates(message as StaleBranch))
          as StaleBranch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StaleBranch create() => StaleBranch._();
  @$core.override
  StaleBranch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StaleBranch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StaleBranch>(create);
  static StaleBranch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get taskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set taskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTaskId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get repoId => $_getSZ(1);
  @$pb.TagNumber(2)
  set repoId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepoId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepoId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get repoPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set repoPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRepoPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearRepoPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get branch => $_getSZ(3);
  @$pb.TagNumber(4)
  set branch($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBranch() => $_has(3);
  @$pb.TagNumber(4)
  void clearBranch() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get baseBranch => $_getSZ(4);
  @$pb.TagNumber(5)
  set baseBranch($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBaseBranch() => $_has(4);
  @$pb.TagNumber(5)
  void clearBaseBranch() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get goal => $_getSZ(5);
  @$pb.TagNumber(6)
  set goal($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGoal() => $_has(5);
  @$pb.TagNumber(6)
  void clearGoal() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get status => $_getSZ(6);
  @$pb.TagNumber(7)
  set status($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStatus() => $_has(6);
  @$pb.TagNumber(7)
  void clearStatus() => $_clearField(7);

  @$pb.TagNumber(8)
  $2.Timestamp get finishedAt => $_getN(7);
  @$pb.TagNumber(8)
  set finishedAt($2.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasFinishedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearFinishedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $2.Timestamp ensureFinishedAt() => $_ensure(7);

  @$pb.TagNumber(9)
  $core.int get ageDays => $_getIZ(8);
  @$pb.TagNumber(9)
  set ageDays($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAgeDays() => $_has(8);
  @$pb.TagNumber(9)
  void clearAgeDays() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get merged => $_getBF(9);
  @$pb.TagNumber(10)
  set merged($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMerged() => $_has(9);
  @$pb.TagNumber(10)
  void clearMerged() => $_clearField(10);
}

class ListStaleBranchesResponse extends $pb.GeneratedMessage {
  factory ListStaleBranchesResponse({
    $core.Iterable<StaleBranch>? branches,
  }) {
    final result = create();
    if (branches != null) result.branches.addAll(branches);
    return result;
  }

  ListStaleBranchesResponse._();

  factory ListStaleBranchesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListStaleBranchesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListStaleBranchesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<StaleBranch>(1, _omitFieldNames ? '' : 'branches',
        subBuilder: StaleBranch.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListStaleBranchesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListStaleBranchesResponse copyWith(
          void Function(ListStaleBranchesResponse) updates) =>
      super.copyWith((message) => updates(message as ListStaleBranchesResponse))
          as ListStaleBranchesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListStaleBranchesResponse create() => ListStaleBranchesResponse._();
  @$core.override
  ListStaleBranchesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListStaleBranchesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListStaleBranchesResponse>(create);
  static ListStaleBranchesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<StaleBranch> get branches => $_getList(0);
}

class RunSweepNowRequest extends $pb.GeneratedMessage {
  factory RunSweepNowRequest({
    $core.int? days,
  }) {
    final result = create();
    if (days != null) result.days = days;
    return result;
  }

  RunSweepNowRequest._();

  factory RunSweepNowRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RunSweepNowRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RunSweepNowRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'days')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunSweepNowRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunSweepNowRequest copyWith(void Function(RunSweepNowRequest) updates) =>
      super.copyWith((message) => updates(message as RunSweepNowRequest))
          as RunSweepNowRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RunSweepNowRequest create() => RunSweepNowRequest._();
  @$core.override
  RunSweepNowRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RunSweepNowRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RunSweepNowRequest>(create);
  static RunSweepNowRequest? _defaultInstance;

  /// days overrides the configured threshold for this invocation only; pass
  /// 0 to use the currently configured setting. If the setting is also 0
  /// (disabled) the server returns FAILED_PRECONDITION.
  @$pb.TagNumber(1)
  $core.int get days => $_getIZ(0);
  @$pb.TagNumber(1)
  set days($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearDays() => $_clearField(1);
}

class RunSweepNowResponse extends $pb.GeneratedMessage {
  factory RunSweepNowResponse({
    $core.int? considered,
    $core.int? deleted,
    $core.int? skipped,
  }) {
    final result = create();
    if (considered != null) result.considered = considered;
    if (deleted != null) result.deleted = deleted;
    if (skipped != null) result.skipped = skipped;
    return result;
  }

  RunSweepNowResponse._();

  factory RunSweepNowResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RunSweepNowResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RunSweepNowResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'considered')
    ..aI(2, _omitFieldNames ? '' : 'deleted')
    ..aI(3, _omitFieldNames ? '' : 'skipped')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunSweepNowResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunSweepNowResponse copyWith(void Function(RunSweepNowResponse) updates) =>
      super.copyWith((message) => updates(message as RunSweepNowResponse))
          as RunSweepNowResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RunSweepNowResponse create() => RunSweepNowResponse._();
  @$core.override
  RunSweepNowResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RunSweepNowResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RunSweepNowResponse>(create);
  static RunSweepNowResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get considered => $_getIZ(0);
  @$pb.TagNumber(1)
  set considered($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConsidered() => $_has(0);
  @$pb.TagNumber(1)
  void clearConsidered() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get deleted => $_getIZ(1);
  @$pb.TagNumber(2)
  set deleted($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeleted() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeleted() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get skipped => $_getIZ(2);
  @$pb.TagNumber(3)
  set skipped($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSkipped() => $_has(2);
  @$pb.TagNumber(3)
  void clearSkipped() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
