// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/fleetkanban.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $2;

import 'fleetkanban.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'fleetkanban.pbenum.dart';

class IdRequest extends $pb.GeneratedMessage {
  factory IdRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  IdRequest._();

  factory IdRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IdRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IdRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdRequest copyWith(void Function(IdRequest) updates) =>
      super.copyWith((message) => updates(message as IdRequest)) as IdRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IdRequest create() => IdRequest._();
  @$core.override
  IdRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IdRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IdRequest>(create);
  static IdRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class BoolValue extends $pb.GeneratedMessage {
  factory BoolValue({
    $core.bool? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  BoolValue._();

  factory BoolValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BoolValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BoolValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoolValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BoolValue copyWith(void Function(BoolValue) updates) =>
      super.copyWith((message) => updates(message as BoolValue)) as BoolValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BoolValue create() => BoolValue._();
  @$core.override
  BoolValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BoolValue getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BoolValue>(create);
  static BoolValue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class IntValue extends $pb.GeneratedMessage {
  factory IntValue({
    $core.int? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  IntValue._();

  factory IntValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IntValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IntValue',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IntValue copyWith(void Function(IntValue) updates) =>
      super.copyWith((message) => updates(message as IntValue)) as IntValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IntValue create() => IntValue._();
  @$core.override
  IntValue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IntValue getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IntValue>(create);
  static IntValue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

/// VersionInfo is the payload of SystemService.GetVersion. protocol_version
/// mirrors internal/branding.ProtocolVersion and bumps whenever the gRPC
/// contract changes in a breaking way. app_version is a free-form
/// human-readable build string (empty unless the binary is ldflags-tagged).
class VersionInfo extends $pb.GeneratedMessage {
  factory VersionInfo({
    $core.int? protocolVersion,
    $core.String? appVersion,
    $core.String? copilotSdkVersion,
    $core.String? goVersion,
  }) {
    final result = create();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (appVersion != null) result.appVersion = appVersion;
    if (copilotSdkVersion != null) result.copilotSdkVersion = copilotSdkVersion;
    if (goVersion != null) result.goVersion = goVersion;
    return result;
  }

  VersionInfo._();

  factory VersionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VersionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VersionInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'protocolVersion')
    ..aOS(2, _omitFieldNames ? '' : 'appVersion')
    ..aOS(3, _omitFieldNames ? '' : 'copilotSdkVersion')
    ..aOS(4, _omitFieldNames ? '' : 'goVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionInfo copyWith(void Function(VersionInfo) updates) =>
      super.copyWith((message) => updates(message as VersionInfo))
          as VersionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VersionInfo create() => VersionInfo._();
  @$core.override
  VersionInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VersionInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VersionInfo>(create);
  static VersionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set protocolVersion($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get appVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set appVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAppVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppVersion() => $_clearField(2);

  /// Module version of github.com/github/copilot-sdk/go linked into the
  /// sidecar binary. Empty if the build info is not available (unusual —
  /// only happens for stripped test builds).
  @$pb.TagNumber(3)
  $core.String get copilotSdkVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set copilotSdkVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCopilotSdkVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearCopilotSdkVersion() => $_clearField(3);

  /// Go runtime version (e.g. "go1.24.0") the sidecar was compiled with.
  /// Useful for bug reports without asking the user to run `go version`.
  @$pb.TagNumber(4)
  $core.String get goVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set goVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGoVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearGoVersion() => $_clearField(4);
}

/// Precondition is one runtime dependency the sidecar requires. `kind`
/// is a stable identifier the UI can switch on (e.g. "pwsh"); the other
/// fields are human-readable text for the precondition banner.
/// `auto_installable` is true when the sidecar can resolve this
/// dependency via InstallPrecondition without user elevation; false
/// means the manual_command must be shown instead.
class Precondition extends $pb.GeneratedMessage {
  factory Precondition({
    $core.String? kind,
    $core.bool? satisfied,
    $core.String? description,
    $core.bool? autoInstallable,
    $core.String? detail,
    $core.String? manualCommand,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (satisfied != null) result.satisfied = satisfied;
    if (description != null) result.description = description;
    if (autoInstallable != null) result.autoInstallable = autoInstallable;
    if (detail != null) result.detail = detail;
    if (manualCommand != null) result.manualCommand = manualCommand;
    return result;
  }

  Precondition._();

  factory Precondition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Precondition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Precondition',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOB(2, _omitFieldNames ? '' : 'satisfied')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOB(4, _omitFieldNames ? '' : 'autoInstallable')
    ..aOS(5, _omitFieldNames ? '' : 'detail')
    ..aOS(6, _omitFieldNames ? '' : 'manualCommand')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Precondition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Precondition copyWith(void Function(Precondition) updates) =>
      super.copyWith((message) => updates(message as Precondition))
          as Precondition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Precondition create() => Precondition._();
  @$core.override
  Precondition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Precondition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Precondition>(create);
  static Precondition? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get satisfied => $_getBF(1);
  @$pb.TagNumber(2)
  set satisfied($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSatisfied() => $_has(1);
  @$pb.TagNumber(2)
  void clearSatisfied() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get autoInstallable => $_getBF(3);
  @$pb.TagNumber(4)
  set autoInstallable($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAutoInstallable() => $_has(3);
  @$pb.TagNumber(4)
  void clearAutoInstallable() => $_clearField(4);

  /// Free-form detail ("found on PATH", "pwsh.exe not found ...") —
  /// useful for debugging without dropping to logs.
  @$pb.TagNumber(5)
  $core.String get detail => $_getSZ(4);
  @$pb.TagNumber(5)
  set detail($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDetail() => $_has(4);
  @$pb.TagNumber(5)
  void clearDetail() => $_clearField(5);

  /// Shell command the user can run themselves if auto-install is
  /// unavailable or fails. Empty when no canonical manual path exists.
  @$pb.TagNumber(6)
  $core.String get manualCommand => $_getSZ(5);
  @$pb.TagNumber(6)
  set manualCommand($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasManualCommand() => $_has(5);
  @$pb.TagNumber(6)
  void clearManualCommand() => $_clearField(6);
}

class PreconditionsResponse extends $pb.GeneratedMessage {
  factory PreconditionsResponse({
    $core.Iterable<Precondition>? preconditions,
  }) {
    final result = create();
    if (preconditions != null) result.preconditions.addAll(preconditions);
    return result;
  }

  PreconditionsResponse._();

  factory PreconditionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreconditionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreconditionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<Precondition>(1, _omitFieldNames ? '' : 'preconditions',
        subBuilder: Precondition.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreconditionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreconditionsResponse copyWith(
          void Function(PreconditionsResponse) updates) =>
      super.copyWith((message) => updates(message as PreconditionsResponse))
          as PreconditionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreconditionsResponse create() => PreconditionsResponse._();
  @$core.override
  PreconditionsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreconditionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreconditionsResponse>(create);
  static PreconditionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Precondition> get preconditions => $_getList(0);
}

class InstallPreconditionRequest extends $pb.GeneratedMessage {
  factory InstallPreconditionRequest({
    $core.String? kind,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    return result;
  }

  InstallPreconditionRequest._();

  factory InstallPreconditionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallPreconditionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallPreconditionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallPreconditionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallPreconditionRequest copyWith(
          void Function(InstallPreconditionRequest) updates) =>
      super.copyWith(
              (message) => updates(message as InstallPreconditionRequest))
          as InstallPreconditionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallPreconditionRequest create() => InstallPreconditionRequest._();
  @$core.override
  InstallPreconditionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallPreconditionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallPreconditionRequest>(create);
  static InstallPreconditionRequest? _defaultInstance;

  /// Must match a kind returned by GetPreconditions; unknown kinds are
  /// rejected with InvalidArgument.
  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);
}

class InstallPreconditionResponse extends $pb.GeneratedMessage {
  factory InstallPreconditionResponse({
    Precondition? precondition,
    $core.String? error,
  }) {
    final result = create();
    if (precondition != null) result.precondition = precondition;
    if (error != null) result.error = error;
    return result;
  }

  InstallPreconditionResponse._();

  factory InstallPreconditionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallPreconditionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallPreconditionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOM<Precondition>(1, _omitFieldNames ? '' : 'precondition',
        subBuilder: Precondition.create)
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallPreconditionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallPreconditionResponse copyWith(
          void Function(InstallPreconditionResponse) updates) =>
      super.copyWith(
              (message) => updates(message as InstallPreconditionResponse))
          as InstallPreconditionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallPreconditionResponse create() =>
      InstallPreconditionResponse._();
  @$core.override
  InstallPreconditionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallPreconditionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallPreconditionResponse>(create);
  static InstallPreconditionResponse? _defaultInstance;

  /// Post-install snapshot of the precondition. satisfied=true on
  /// success; on failure the error field carries a short human message
  /// (the full installer output is logged server-side).
  @$pb.TagNumber(1)
  Precondition get precondition => $_getN(0);
  @$pb.TagNumber(1)
  set precondition(Precondition value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrecondition() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrecondition() => $_clearField(1);
  @$pb.TagNumber(1)
  Precondition ensurePrecondition() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

/// Task mirrors internal/task.Task. Status / error_code are kept as strings
/// (matching the DB representation) rather than enums, so adding new states
/// does not require a proto bump.
class Task extends $pb.GeneratedMessage {
  factory Task({
    $core.String? id,
    $core.String? repositoryId,
    $core.String? goal,
    $core.String? baseBranch,
    $core.String? branch,
    $core.String? worktreePath,
    $core.String? model,
    $core.String? status,
    $core.String? errorCode,
    $core.String? errorMessage,
    $core.String? sessionId,
    $core.bool? branchExists,
    $2.Timestamp? createdAt,
    $2.Timestamp? updatedAt,
    $2.Timestamp? startedAt,
    $2.Timestamp? finishedAt,
    $core.String? reviewFeedback,
    $core.int? reworkCount,
    $core.String? planModel,
    $core.String? reviewModel,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (repositoryId != null) result.repositoryId = repositoryId;
    if (goal != null) result.goal = goal;
    if (baseBranch != null) result.baseBranch = baseBranch;
    if (branch != null) result.branch = branch;
    if (worktreePath != null) result.worktreePath = worktreePath;
    if (model != null) result.model = model;
    if (status != null) result.status = status;
    if (errorCode != null) result.errorCode = errorCode;
    if (errorMessage != null) result.errorMessage = errorMessage;
    if (sessionId != null) result.sessionId = sessionId;
    if (branchExists != null) result.branchExists = branchExists;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (startedAt != null) result.startedAt = startedAt;
    if (finishedAt != null) result.finishedAt = finishedAt;
    if (reviewFeedback != null) result.reviewFeedback = reviewFeedback;
    if (reworkCount != null) result.reworkCount = reworkCount;
    if (planModel != null) result.planModel = planModel;
    if (reviewModel != null) result.reviewModel = reviewModel;
    return result;
  }

  Task._();

  factory Task.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Task.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Task',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'repositoryId')
    ..aOS(3, _omitFieldNames ? '' : 'goal')
    ..aOS(4, _omitFieldNames ? '' : 'baseBranch')
    ..aOS(5, _omitFieldNames ? '' : 'branch')
    ..aOS(6, _omitFieldNames ? '' : 'worktreePath')
    ..aOS(7, _omitFieldNames ? '' : 'model')
    ..aOS(8, _omitFieldNames ? '' : 'status')
    ..aOS(9, _omitFieldNames ? '' : 'errorCode')
    ..aOS(10, _omitFieldNames ? '' : 'errorMessage')
    ..aOS(11, _omitFieldNames ? '' : 'sessionId')
    ..aOB(12, _omitFieldNames ? '' : 'branchExists')
    ..aOM<$2.Timestamp>(13, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(14, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(15, _omitFieldNames ? '' : 'startedAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(16, _omitFieldNames ? '' : 'finishedAt',
        subBuilder: $2.Timestamp.create)
    ..aOS(17, _omitFieldNames ? '' : 'reviewFeedback')
    ..aI(18, _omitFieldNames ? '' : 'reworkCount')
    ..aOS(19, _omitFieldNames ? '' : 'planModel')
    ..aOS(20, _omitFieldNames ? '' : 'reviewModel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Task clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Task copyWith(void Function(Task) updates) =>
      super.copyWith((message) => updates(message as Task)) as Task;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Task create() => Task._();
  @$core.override
  Task createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Task getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Task>(create);
  static Task? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get repositoryId => $_getSZ(1);
  @$pb.TagNumber(2)
  set repositoryId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepositoryId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepositoryId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get goal => $_getSZ(2);
  @$pb.TagNumber(3)
  set goal($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGoal() => $_has(2);
  @$pb.TagNumber(3)
  void clearGoal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get baseBranch => $_getSZ(3);
  @$pb.TagNumber(4)
  set baseBranch($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBaseBranch() => $_has(3);
  @$pb.TagNumber(4)
  void clearBaseBranch() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get branch => $_getSZ(4);
  @$pb.TagNumber(5)
  set branch($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBranch() => $_has(4);
  @$pb.TagNumber(5)
  void clearBranch() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get worktreePath => $_getSZ(5);
  @$pb.TagNumber(6)
  set worktreePath($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWorktreePath() => $_has(5);
  @$pb.TagNumber(6)
  void clearWorktreePath() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get model => $_getSZ(6);
  @$pb.TagNumber(7)
  set model($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasModel() => $_has(6);
  @$pb.TagNumber(7)
  void clearModel() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get status => $_getSZ(7);
  @$pb.TagNumber(8)
  set status($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get errorCode => $_getSZ(8);
  @$pb.TagNumber(9)
  set errorCode($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasErrorCode() => $_has(8);
  @$pb.TagNumber(9)
  void clearErrorCode() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get errorMessage => $_getSZ(9);
  @$pb.TagNumber(10)
  set errorMessage($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasErrorMessage() => $_has(9);
  @$pb.TagNumber(10)
  void clearErrorMessage() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get sessionId => $_getSZ(10);
  @$pb.TagNumber(11)
  set sessionId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSessionId() => $_has(10);
  @$pb.TagNumber(11)
  void clearSessionId() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get branchExists => $_getBF(11);
  @$pb.TagNumber(12)
  set branchExists($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasBranchExists() => $_has(11);
  @$pb.TagNumber(12)
  void clearBranchExists() => $_clearField(12);

  @$pb.TagNumber(13)
  $2.Timestamp get createdAt => $_getN(12);
  @$pb.TagNumber(13)
  set createdAt($2.Timestamp value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasCreatedAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearCreatedAt() => $_clearField(13);
  @$pb.TagNumber(13)
  $2.Timestamp ensureCreatedAt() => $_ensure(12);

  @$pb.TagNumber(14)
  $2.Timestamp get updatedAt => $_getN(13);
  @$pb.TagNumber(14)
  set updatedAt($2.Timestamp value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasUpdatedAt() => $_has(13);
  @$pb.TagNumber(14)
  void clearUpdatedAt() => $_clearField(14);
  @$pb.TagNumber(14)
  $2.Timestamp ensureUpdatedAt() => $_ensure(13);

  @$pb.TagNumber(15)
  $2.Timestamp get startedAt => $_getN(14);
  @$pb.TagNumber(15)
  set startedAt($2.Timestamp value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasStartedAt() => $_has(14);
  @$pb.TagNumber(15)
  void clearStartedAt() => $_clearField(15);
  @$pb.TagNumber(15)
  $2.Timestamp ensureStartedAt() => $_ensure(14);

  @$pb.TagNumber(16)
  $2.Timestamp get finishedAt => $_getN(15);
  @$pb.TagNumber(16)
  set finishedAt($2.Timestamp value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasFinishedAt() => $_has(15);
  @$pb.TagNumber(16)
  void clearFinishedAt() => $_clearField(16);
  @$pb.TagNumber(16)
  $2.Timestamp ensureFinishedAt() => $_ensure(15);

  /// Most recent reviewer feedback. Populated whenever SubmitReview records
  /// a REWORK decision; shown in the Human Review UI so the user can see
  /// what the previous reviewer asked for.
  @$pb.TagNumber(17)
  $core.String get reviewFeedback => $_getSZ(16);
  @$pb.TagNumber(17)
  set reviewFeedback($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasReviewFeedback() => $_has(16);
  @$pb.TagNumber(17)
  void clearReviewFeedback() => $_clearField(17);

  /// Number of AI Review → queued rework cycles this task has been through
  /// since its last fresh run. Capped by orchestrator.MaxReworkCount; on
  /// overflow the task is escalated to human_review instead of re-queued.
  @$pb.TagNumber(18)
  $core.int get reworkCount => $_getIZ(17);
  @$pb.TagNumber(18)
  set reworkCount($core.int value) => $_setSignedInt32(17, value);
  @$pb.TagNumber(18)
  $core.bool hasReworkCount() => $_has(17);
  @$pb.TagNumber(18)
  void clearReworkCount() => $_clearField(18);

  /// Models actually used by the Plan and Review stages (Code stage uses
  /// `model` above). Empty when the stage has not run yet. Surfaced in the
  /// UI as per-stage badges so the user can tell which model produced each
  /// artifact without inspecting the event stream.
  @$pb.TagNumber(19)
  $core.String get planModel => $_getSZ(18);
  @$pb.TagNumber(19)
  set planModel($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasPlanModel() => $_has(18);
  @$pb.TagNumber(19)
  void clearPlanModel() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get reviewModel => $_getSZ(19);
  @$pb.TagNumber(20)
  set reviewModel($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasReviewModel() => $_has(19);
  @$pb.TagNumber(20)
  void clearReviewModel() => $_clearField(20);
}

/// Subtask mirrors internal/task.Subtask. Status is a 4-value string
/// (pending / doing / done / failed) rather than an enum so it can evolve
/// independently. agent_role is a planner-invented role name injected into
/// the subtask executor's system prompt; depends_on lists sibling subtask
/// IDs that must reach `done` before this subtask may start.
class Subtask extends $pb.GeneratedMessage {
  factory Subtask({
    $core.String? id,
    $core.String? taskId,
    $core.String? title,
    $core.String? status,
    $core.int? orderIdx,
    $2.Timestamp? createdAt,
    $2.Timestamp? updatedAt,
    $core.String? agentRole,
    $core.Iterable<$core.String>? dependsOn,
    $core.String? codeModel,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (taskId != null) result.taskId = taskId;
    if (title != null) result.title = title;
    if (status != null) result.status = status;
    if (orderIdx != null) result.orderIdx = orderIdx;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (agentRole != null) result.agentRole = agentRole;
    if (dependsOn != null) result.dependsOn.addAll(dependsOn);
    if (codeModel != null) result.codeModel = codeModel;
    return result;
  }

  Subtask._();

  factory Subtask.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Subtask.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Subtask',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'taskId')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'status')
    ..aI(5, _omitFieldNames ? '' : 'orderIdx')
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(7, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $2.Timestamp.create)
    ..aOS(8, _omitFieldNames ? '' : 'agentRole')
    ..pPS(9, _omitFieldNames ? '' : 'dependsOn')
    ..aOS(10, _omitFieldNames ? '' : 'codeModel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subtask clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subtask copyWith(void Function(Subtask) updates) =>
      super.copyWith((message) => updates(message as Subtask)) as Subtask;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Subtask create() => Subtask._();
  @$core.override
  Subtask createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Subtask getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Subtask>(create);
  static Subtask? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get taskId => $_getSZ(1);
  @$pb.TagNumber(2)
  set taskId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTaskId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get status => $_getSZ(3);
  @$pb.TagNumber(4)
  set status($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get orderIdx => $_getIZ(4);
  @$pb.TagNumber(5)
  set orderIdx($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOrderIdx() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrderIdx() => $_clearField(5);

  @$pb.TagNumber(6)
  $2.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(6)
  set createdAt($2.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Timestamp ensureCreatedAt() => $_ensure(5);

  @$pb.TagNumber(7)
  $2.Timestamp get updatedAt => $_getN(6);
  @$pb.TagNumber(7)
  set updatedAt($2.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.Timestamp ensureUpdatedAt() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.String get agentRole => $_getSZ(7);
  @$pb.TagNumber(8)
  set agentRole($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAgentRole() => $_has(7);
  @$pb.TagNumber(8)
  void clearAgentRole() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get dependsOn => $_getList(8);

  /// Model used to execute this subtask (Code stage). Empty until the
  /// executor actually runs the subtask.
  @$pb.TagNumber(10)
  $core.String get codeModel => $_getSZ(9);
  @$pb.TagNumber(10)
  set codeModel($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCodeModel() => $_has(9);
  @$pb.TagNumber(10)
  void clearCodeModel() => $_clearField(10);
}

class Repository extends $pb.GeneratedMessage {
  factory Repository({
    $core.String? id,
    $core.String? path,
    $core.String? displayName,
    $core.String? defaultBaseBranch,
    $2.Timestamp? createdAt,
    $2.Timestamp? lastUsedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (path != null) result.path = path;
    if (displayName != null) result.displayName = displayName;
    if (defaultBaseBranch != null) result.defaultBaseBranch = defaultBaseBranch;
    if (createdAt != null) result.createdAt = createdAt;
    if (lastUsedAt != null) result.lastUsedAt = lastUsedAt;
    return result;
  }

  Repository._();

  factory Repository.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Repository.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Repository',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aOS(4, _omitFieldNames ? '' : 'defaultBaseBranch')
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'lastUsedAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Repository clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Repository copyWith(void Function(Repository) updates) =>
      super.copyWith((message) => updates(message as Repository)) as Repository;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Repository create() => Repository._();
  @$core.override
  Repository createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Repository getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Repository>(create);
  static Repository? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  /// Empty = auto-detect mode (sidecar resolves origin/HEAD → main → master
  /// → current HEAD at CreateTask time). Non-empty = user-pinned; the
  /// sidecar uses it as-is and fails CreateTask loudly if the branch is
  /// missing (the user made an explicit choice).
  @$pb.TagNumber(4)
  $core.String get defaultBaseBranch => $_getSZ(3);
  @$pb.TagNumber(4)
  set defaultBaseBranch($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDefaultBaseBranch() => $_has(3);
  @$pb.TagNumber(4)
  void clearDefaultBaseBranch() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Timestamp get createdAt => $_getN(4);
  @$pb.TagNumber(5)
  set createdAt($2.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureCreatedAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $2.Timestamp get lastUsedAt => $_getN(5);
  @$pb.TagNumber(6)
  set lastUsedAt($2.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLastUsedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastUsedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Timestamp ensureLastUsedAt() => $_ensure(5);
}

/// AgentEvent mirrors internal/task.AgentEvent verbatim. Kind and Payload are
/// string-typed on purpose; see file header for rationale.
class AgentEvent extends $pb.GeneratedMessage {
  factory AgentEvent({
    $core.String? id,
    $core.String? taskId,
    $fixnum.Int64? seq,
    $core.String? kind,
    $core.String? payload,
    $2.Timestamp? occurredAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (taskId != null) result.taskId = taskId;
    if (seq != null) result.seq = seq;
    if (kind != null) result.kind = kind;
    if (payload != null) result.payload = payload;
    if (occurredAt != null) result.occurredAt = occurredAt;
    return result;
  }

  AgentEvent._();

  factory AgentEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AgentEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AgentEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'taskId')
    ..aInt64(3, _omitFieldNames ? '' : 'seq')
    ..aOS(4, _omitFieldNames ? '' : 'kind')
    ..aOS(5, _omitFieldNames ? '' : 'payload')
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'occurredAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentEvent copyWith(void Function(AgentEvent) updates) =>
      super.copyWith((message) => updates(message as AgentEvent)) as AgentEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgentEvent create() => AgentEvent._();
  @$core.override
  AgentEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AgentEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AgentEvent>(create);
  static AgentEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get taskId => $_getSZ(1);
  @$pb.TagNumber(2)
  set taskId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTaskId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get seq => $_getI64(2);
  @$pb.TagNumber(3)
  set seq($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSeq() => $_has(2);
  @$pb.TagNumber(3)
  void clearSeq() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get kind => $_getSZ(3);
  @$pb.TagNumber(4)
  set kind($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get payload => $_getSZ(4);
  @$pb.TagNumber(5)
  set payload($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPayload() => $_has(4);
  @$pb.TagNumber(5)
  void clearPayload() => $_clearField(5);

  @$pb.TagNumber(6)
  $2.Timestamp get occurredAt => $_getN(5);
  @$pb.TagNumber(6)
  set occurredAt($2.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOccurredAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearOccurredAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Timestamp ensureOccurredAt() => $_ensure(5);
}

class AuthStatus extends $pb.GeneratedMessage {
  factory AuthStatus({
    $core.bool? authenticated,
    $core.String? user,
    $core.String? message,
    $2.Timestamp? checkedAt,
  }) {
    final result = create();
    if (authenticated != null) result.authenticated = authenticated;
    if (user != null) result.user = user;
    if (message != null) result.message = message;
    if (checkedAt != null) result.checkedAt = checkedAt;
    return result;
  }

  AuthStatus._();

  factory AuthStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'authenticated')
    ..aOS(2, _omitFieldNames ? '' : 'user')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'checkedAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthStatus copyWith(void Function(AuthStatus) updates) =>
      super.copyWith((message) => updates(message as AuthStatus)) as AuthStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthStatus create() => AuthStatus._();
  @$core.override
  AuthStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthStatus>(create);
  static AuthStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get authenticated => $_getBF(0);
  @$pb.TagNumber(1)
  set authenticated($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAuthenticated() => $_has(0);
  @$pb.TagNumber(1)
  void clearAuthenticated() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get user => $_getSZ(1);
  @$pb.TagNumber(2)
  set user($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  @$pb.TagNumber(4)
  $2.Timestamp get checkedAt => $_getN(3);
  @$pb.TagNumber(4)
  set checkedAt($2.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCheckedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCheckedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureCheckedAt() => $_ensure(3);
}

class GitConfigStatus extends $pb.GeneratedMessage {
  factory GitConfigStatus({
    $core.bool? longPathsOk,
    $core.String? longPathsVal,
    $core.bool? autocrlfOk,
    $core.String? autocrlfVal,
  }) {
    final result = create();
    if (longPathsOk != null) result.longPathsOk = longPathsOk;
    if (longPathsVal != null) result.longPathsVal = longPathsVal;
    if (autocrlfOk != null) result.autocrlfOk = autocrlfOk;
    if (autocrlfVal != null) result.autocrlfVal = autocrlfVal;
    return result;
  }

  GitConfigStatus._();

  factory GitConfigStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GitConfigStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitConfigStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'longPathsOk')
    ..aOS(2, _omitFieldNames ? '' : 'longPathsVal')
    ..aOB(3, _omitFieldNames ? '' : 'autocrlfOk')
    ..aOS(4, _omitFieldNames ? '' : 'autocrlfVal')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitConfigStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitConfigStatus copyWith(void Function(GitConfigStatus) updates) =>
      super.copyWith((message) => updates(message as GitConfigStatus))
          as GitConfigStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GitConfigStatus create() => GitConfigStatus._();
  @$core.override
  GitConfigStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GitConfigStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GitConfigStatus>(create);
  static GitConfigStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get longPathsOk => $_getBF(0);
  @$pb.TagNumber(1)
  set longPathsOk($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLongPathsOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearLongPathsOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get longPathsVal => $_getSZ(1);
  @$pb.TagNumber(2)
  set longPathsVal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLongPathsVal() => $_has(1);
  @$pb.TagNumber(2)
  void clearLongPathsVal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get autocrlfOk => $_getBF(2);
  @$pb.TagNumber(3)
  set autocrlfOk($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAutocrlfOk() => $_has(2);
  @$pb.TagNumber(3)
  void clearAutocrlfOk() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get autocrlfVal => $_getSZ(3);
  @$pb.TagNumber(4)
  set autocrlfVal($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAutocrlfVal() => $_has(3);
  @$pb.TagNumber(4)
  void clearAutocrlfVal() => $_clearField(4);
}

class CreateTaskRequest extends $pb.GeneratedMessage {
  factory CreateTaskRequest({
    $core.String? repositoryId,
    $core.String? goal,
    $core.String? baseBranch,
    $core.String? model,
    $core.String? planModel,
    $core.String? reviewModel,
  }) {
    final result = create();
    if (repositoryId != null) result.repositoryId = repositoryId;
    if (goal != null) result.goal = goal;
    if (baseBranch != null) result.baseBranch = baseBranch;
    if (model != null) result.model = model;
    if (planModel != null) result.planModel = planModel;
    if (reviewModel != null) result.reviewModel = reviewModel;
    return result;
  }

  CreateTaskRequest._();

  factory CreateTaskRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateTaskRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateTaskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repositoryId')
    ..aOS(2, _omitFieldNames ? '' : 'goal')
    ..aOS(3, _omitFieldNames ? '' : 'baseBranch')
    ..aOS(4, _omitFieldNames ? '' : 'model')
    ..aOS(5, _omitFieldNames ? '' : 'planModel')
    ..aOS(6, _omitFieldNames ? '' : 'reviewModel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTaskRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateTaskRequest copyWith(void Function(CreateTaskRequest) updates) =>
      super.copyWith((message) => updates(message as CreateTaskRequest))
          as CreateTaskRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateTaskRequest create() => CreateTaskRequest._();
  @$core.override
  CreateTaskRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateTaskRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateTaskRequest>(create);
  static CreateTaskRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repositoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repositoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepositoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepositoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get goal => $_getSZ(1);
  @$pb.TagNumber(2)
  set goal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGoal() => $_has(1);
  @$pb.TagNumber(2)
  void clearGoal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get baseBranch => $_getSZ(2);
  @$pb.TagNumber(3)
  set baseBranch($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBaseBranch() => $_has(2);
  @$pb.TagNumber(3)
  void clearBaseBranch() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get model => $_getSZ(3);
  @$pb.TagNumber(4)
  set model($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearModel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get planModel => $_getSZ(4);
  @$pb.TagNumber(5)
  set planModel($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPlanModel() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlanModel() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get reviewModel => $_getSZ(5);
  @$pb.TagNumber(6)
  set reviewModel($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReviewModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearReviewModel() => $_clearField(6);
}

class ListTasksRequest extends $pb.GeneratedMessage {
  factory ListTasksRequest({
    $core.String? repoId,
    $core.Iterable<$core.String>? statuses,
    $core.int? limit,
    $core.bool? ascending,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (statuses != null) result.statuses.addAll(statuses);
    if (limit != null) result.limit = limit;
    if (ascending != null) result.ascending = ascending;
    return result;
  }

  ListTasksRequest._();

  factory ListTasksRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTasksRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTasksRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..pPS(2, _omitFieldNames ? '' : 'statuses')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..aOB(4, _omitFieldNames ? '' : 'ascending')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTasksRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTasksRequest copyWith(void Function(ListTasksRequest) updates) =>
      super.copyWith((message) => updates(message as ListTasksRequest))
          as ListTasksRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTasksRequest create() => ListTasksRequest._();
  @$core.override
  ListTasksRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTasksRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTasksRequest>(create);
  static ListTasksRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get statuses => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get ascending => $_getBF(3);
  @$pb.TagNumber(4)
  set ascending($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAscending() => $_has(3);
  @$pb.TagNumber(4)
  void clearAscending() => $_clearField(4);
}

class ListTasksResponse extends $pb.GeneratedMessage {
  factory ListTasksResponse({
    $core.Iterable<Task>? tasks,
  }) {
    final result = create();
    if (tasks != null) result.tasks.addAll(tasks);
    return result;
  }

  ListTasksResponse._();

  factory ListTasksResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTasksResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTasksResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<Task>(1, _omitFieldNames ? '' : 'tasks', subBuilder: Task.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTasksResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTasksResponse copyWith(void Function(ListTasksResponse) updates) =>
      super.copyWith((message) => updates(message as ListTasksResponse))
          as ListTasksResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTasksResponse create() => ListTasksResponse._();
  @$core.override
  ListTasksResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTasksResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTasksResponse>(create);
  static ListTasksResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Task> get tasks => $_getList(0);
}

class DiffResponse extends $pb.GeneratedMessage {
  factory DiffResponse({
    $core.String? unifiedDiff,
  }) {
    final result = create();
    if (unifiedDiff != null) result.unifiedDiff = unifiedDiff;
    return result;
  }

  DiffResponse._();

  factory DiffResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiffResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiffResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'unifiedDiff')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiffResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiffResponse copyWith(void Function(DiffResponse) updates) =>
      super.copyWith((message) => updates(message as DiffResponse))
          as DiffResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiffResponse create() => DiffResponse._();
  @$core.override
  DiffResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiffResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiffResponse>(create);
  static DiffResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get unifiedDiff => $_getSZ(0);
  @$pb.TagNumber(1)
  set unifiedDiff($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUnifiedDiff() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnifiedDiff() => $_clearField(1);
}

class FinalizeTaskRequest extends $pb.GeneratedMessage {
  factory FinalizeTaskRequest({
    $core.String? id,
    FinalizeAction? action,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (action != null) result.action = action;
    return result;
  }

  FinalizeTaskRequest._();

  factory FinalizeTaskRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FinalizeTaskRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FinalizeTaskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<FinalizeAction>(2, _omitFieldNames ? '' : 'action',
        enumValues: FinalizeAction.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinalizeTaskRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinalizeTaskRequest copyWith(void Function(FinalizeTaskRequest) updates) =>
      super.copyWith((message) => updates(message as FinalizeTaskRequest))
          as FinalizeTaskRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FinalizeTaskRequest create() => FinalizeTaskRequest._();
  @$core.override
  FinalizeTaskRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FinalizeTaskRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FinalizeTaskRequest>(create);
  static FinalizeTaskRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  FinalizeAction get action => $_getN(1);
  @$pb.TagNumber(2)
  set action(FinalizeAction value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearAction() => $_clearField(2);
}

class DeleteTaskRequest extends $pb.GeneratedMessage {
  factory DeleteTaskRequest({
    $core.String? id,
    $core.bool? deleteBranch,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (deleteBranch != null) result.deleteBranch = deleteBranch;
    return result;
  }

  DeleteTaskRequest._();

  factory DeleteTaskRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteTaskRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteTaskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'deleteBranch')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTaskRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTaskRequest copyWith(void Function(DeleteTaskRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteTaskRequest))
          as DeleteTaskRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteTaskRequest create() => DeleteTaskRequest._();
  @$core.override
  DeleteTaskRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteTaskRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteTaskRequest>(create);
  static DeleteTaskRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// When true, delete the fleetkanban/<id> branch alongside the worktree.
  /// Default is false (branch preserved, worktree removed) so reviewers can
  /// still inspect the commits post-delete if needed.
  @$pb.TagNumber(2)
  $core.bool get deleteBranch => $_getBF(1);
  @$pb.TagNumber(2)
  set deleteBranch($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeleteBranch() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeleteBranch() => $_clearField(2);
}

class SubmitReviewRequest extends $pb.GeneratedMessage {
  factory SubmitReviewRequest({
    $core.String? id,
    ReviewAction? action,
    $core.String? feedback,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (action != null) result.action = action;
    if (feedback != null) result.feedback = feedback;
    return result;
  }

  SubmitReviewRequest._();

  factory SubmitReviewRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubmitReviewRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitReviewRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aE<ReviewAction>(2, _omitFieldNames ? '' : 'action',
        enumValues: ReviewAction.values)
    ..aOS(3, _omitFieldNames ? '' : 'feedback')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitReviewRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitReviewRequest copyWith(void Function(SubmitReviewRequest) updates) =>
      super.copyWith((message) => updates(message as SubmitReviewRequest))
          as SubmitReviewRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmitReviewRequest create() => SubmitReviewRequest._();
  @$core.override
  SubmitReviewRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubmitReviewRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitReviewRequest>(create);
  static SubmitReviewRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ReviewAction get action => $_getN(1);
  @$pb.TagNumber(2)
  set action(ReviewAction value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearAction() => $_clearField(2);

  /// Free-form text — required for REWORK, optional for APPROVE/REJECT.
  /// Persisted on the task and added as a review.submitted event.
  @$pb.TagNumber(3)
  $core.String get feedback => $_getSZ(2);
  @$pb.TagNumber(3)
  set feedback($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFeedback() => $_has(2);
  @$pb.TagNumber(3)
  void clearFeedback() => $_clearField(3);
}

class TaskEventsRequest extends $pb.GeneratedMessage {
  factory TaskEventsRequest({
    $core.String? taskId,
    $fixnum.Int64? sinceSeq,
    $core.int? limit,
  }) {
    final result = create();
    if (taskId != null) result.taskId = taskId;
    if (sinceSeq != null) result.sinceSeq = sinceSeq;
    if (limit != null) result.limit = limit;
    return result;
  }

  TaskEventsRequest._();

  factory TaskEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TaskEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskEventsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'taskId')
    ..aInt64(2, _omitFieldNames ? '' : 'sinceSeq')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskEventsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskEventsRequest copyWith(void Function(TaskEventsRequest) updates) =>
      super.copyWith((message) => updates(message as TaskEventsRequest))
          as TaskEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskEventsRequest create() => TaskEventsRequest._();
  @$core.override
  TaskEventsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TaskEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskEventsRequest>(create);
  static TaskEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get taskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set taskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTaskId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sinceSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set sinceSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSinceSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSinceSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class TaskEventsResponse extends $pb.GeneratedMessage {
  factory TaskEventsResponse({
    $core.Iterable<AgentEvent>? events,
  }) {
    final result = create();
    if (events != null) result.events.addAll(events);
    return result;
  }

  TaskEventsResponse._();

  factory TaskEventsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TaskEventsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskEventsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<AgentEvent>(1, _omitFieldNames ? '' : 'events',
        subBuilder: AgentEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskEventsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskEventsResponse copyWith(void Function(TaskEventsResponse) updates) =>
      super.copyWith((message) => updates(message as TaskEventsResponse))
          as TaskEventsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskEventsResponse create() => TaskEventsResponse._();
  @$core.override
  TaskEventsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TaskEventsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskEventsResponse>(create);
  static TaskEventsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AgentEvent> get events => $_getList(0);
}

/// WatchEvents is a server-stream subscription that fires every persisted
/// AgentEvent across all tasks. Clients can optionally pass since_seq_by_task
/// to resume after reconnecting; events whose seq <= the mapped value are
/// suppressed by the server. A task id absent from the map means "send every
/// future event for this task" (no backfill — use TaskEvents for backfill).
class WatchEventsRequest extends $pb.GeneratedMessage {
  factory WatchEventsRequest({
    $core.Iterable<$core.MapEntry<$core.String, $fixnum.Int64>>? sinceSeqByTask,
  }) {
    final result = create();
    if (sinceSeqByTask != null)
      result.sinceSeqByTask.addEntries(sinceSeqByTask);
    return result;
  }

  WatchEventsRequest._();

  factory WatchEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchEventsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..m<$core.String, $fixnum.Int64>(1, _omitFieldNames ? '' : 'sinceSeqByTask',
        entryClassName: 'WatchEventsRequest.SinceSeqByTaskEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O6,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchEventsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchEventsRequest copyWith(void Function(WatchEventsRequest) updates) =>
      super.copyWith((message) => updates(message as WatchEventsRequest))
          as WatchEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchEventsRequest create() => WatchEventsRequest._();
  @$core.override
  WatchEventsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchEventsRequest>(create);
  static WatchEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $fixnum.Int64> get sinceSeqByTask => $_getMap(0);
}

class ListSubtasksRequest extends $pb.GeneratedMessage {
  factory ListSubtasksRequest({
    $core.String? taskId,
  }) {
    final result = create();
    if (taskId != null) result.taskId = taskId;
    return result;
  }

  ListSubtasksRequest._();

  factory ListSubtasksRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSubtasksRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSubtasksRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'taskId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubtasksRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubtasksRequest copyWith(void Function(ListSubtasksRequest) updates) =>
      super.copyWith((message) => updates(message as ListSubtasksRequest))
          as ListSubtasksRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSubtasksRequest create() => ListSubtasksRequest._();
  @$core.override
  ListSubtasksRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSubtasksRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSubtasksRequest>(create);
  static ListSubtasksRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get taskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set taskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTaskId() => $_clearField(1);
}

class ListSubtasksResponse extends $pb.GeneratedMessage {
  factory ListSubtasksResponse({
    $core.Iterable<Subtask>? subtasks,
  }) {
    final result = create();
    if (subtasks != null) result.subtasks.addAll(subtasks);
    return result;
  }

  ListSubtasksResponse._();

  factory ListSubtasksResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSubtasksResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSubtasksResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<Subtask>(1, _omitFieldNames ? '' : 'subtasks',
        subBuilder: Subtask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubtasksResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubtasksResponse copyWith(void Function(ListSubtasksResponse) updates) =>
      super.copyWith((message) => updates(message as ListSubtasksResponse))
          as ListSubtasksResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSubtasksResponse create() => ListSubtasksResponse._();
  @$core.override
  ListSubtasksResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSubtasksResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSubtasksResponse>(create);
  static ListSubtasksResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Subtask> get subtasks => $_getList(0);
}

class CreateSubtaskRequest extends $pb.GeneratedMessage {
  factory CreateSubtaskRequest({
    $core.String? taskId,
    $core.String? title,
    $core.String? status,
    $core.int? orderIdx,
    $core.String? agentRole,
    $core.Iterable<$core.String>? dependsOn,
  }) {
    final result = create();
    if (taskId != null) result.taskId = taskId;
    if (title != null) result.title = title;
    if (status != null) result.status = status;
    if (orderIdx != null) result.orderIdx = orderIdx;
    if (agentRole != null) result.agentRole = agentRole;
    if (dependsOn != null) result.dependsOn.addAll(dependsOn);
    return result;
  }

  CreateSubtaskRequest._();

  factory CreateSubtaskRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateSubtaskRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSubtaskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'taskId')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'status')
    ..aI(4, _omitFieldNames ? '' : 'orderIdx')
    ..aOS(5, _omitFieldNames ? '' : 'agentRole')
    ..pPS(6, _omitFieldNames ? '' : 'dependsOn')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSubtaskRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSubtaskRequest copyWith(void Function(CreateSubtaskRequest) updates) =>
      super.copyWith((message) => updates(message as CreateSubtaskRequest))
          as CreateSubtaskRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateSubtaskRequest create() => CreateSubtaskRequest._();
  @$core.override
  CreateSubtaskRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateSubtaskRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSubtaskRequest>(create);
  static CreateSubtaskRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get taskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set taskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTaskId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  /// Optional initial status (pending|doing|done|failed). Empty → "pending".
  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  /// Optional explicit order index. When 0/negative the server appends.
  @$pb.TagNumber(4)
  $core.int get orderIdx => $_getIZ(3);
  @$pb.TagNumber(4)
  set orderIdx($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOrderIdx() => $_has(3);
  @$pb.TagNumber(4)
  void clearOrderIdx() => $_clearField(4);

  /// Planner-invented agent role for execution; empty for legacy manual rows.
  @$pb.TagNumber(5)
  $core.String get agentRole => $_getSZ(4);
  @$pb.TagNumber(5)
  set agentRole($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAgentRole() => $_has(4);
  @$pb.TagNumber(5)
  void clearAgentRole() => $_clearField(5);

  /// Sibling subtask IDs that must reach `done` before this one may start.
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get dependsOn => $_getList(5);
}

class UpdateSubtaskRequest extends $pb.GeneratedMessage {
  factory UpdateSubtaskRequest({
    $core.String? id,
    $core.String? title,
    $core.String? status,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (status != null) result.status = status;
    return result;
  }

  UpdateSubtaskRequest._();

  factory UpdateSubtaskRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSubtaskRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSubtaskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubtaskRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubtaskRequest copyWith(void Function(UpdateSubtaskRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateSubtaskRequest))
          as UpdateSubtaskRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSubtaskRequest create() => UpdateSubtaskRequest._();
  @$core.override
  UpdateSubtaskRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateSubtaskRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSubtaskRequest>(create);
  static UpdateSubtaskRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Only non-empty fields are applied — title/status may be set
  /// independently so the UI can toggle a checkbox without re-sending
  /// the title.
  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);
}

class ReorderSubtasksRequest extends $pb.GeneratedMessage {
  factory ReorderSubtasksRequest({
    $core.String? taskId,
    $core.Iterable<$core.String>? ids,
  }) {
    final result = create();
    if (taskId != null) result.taskId = taskId;
    if (ids != null) result.ids.addAll(ids);
    return result;
  }

  ReorderSubtasksRequest._();

  factory ReorderSubtasksRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReorderSubtasksRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReorderSubtasksRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'taskId')
    ..pPS(2, _omitFieldNames ? '' : 'ids')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReorderSubtasksRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReorderSubtasksRequest copyWith(
          void Function(ReorderSubtasksRequest) updates) =>
      super.copyWith((message) => updates(message as ReorderSubtasksRequest))
          as ReorderSubtasksRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReorderSubtasksRequest create() => ReorderSubtasksRequest._();
  @$core.override
  ReorderSubtasksRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReorderSubtasksRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReorderSubtasksRequest>(create);
  static ReorderSubtasksRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get taskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set taskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTaskId() => $_clearField(1);

  /// Ordered list of subtask IDs belonging to task_id. The server persists
  /// order_idx as the position in this slice. IDs not present in the DB for
  /// the given task are rejected with InvalidArgument.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get ids => $_getList(1);
}

class RegisterRepositoryRequest extends $pb.GeneratedMessage {
  factory RegisterRepositoryRequest({
    $core.String? path,
    $core.String? displayName,
    $core.bool? initializeIfEmpty,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (displayName != null) result.displayName = displayName;
    if (initializeIfEmpty != null) result.initializeIfEmpty = initializeIfEmpty;
    return result;
  }

  RegisterRepositoryRequest._();

  factory RegisterRepositoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterRepositoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterRepositoryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOB(3, _omitFieldNames ? '' : 'initializeIfEmpty')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterRepositoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterRepositoryRequest copyWith(
          void Function(RegisterRepositoryRequest) updates) =>
      super.copyWith((message) => updates(message as RegisterRepositoryRequest))
          as RegisterRepositoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterRepositoryRequest create() => RegisterRepositoryRequest._();
  @$core.override
  RegisterRepositoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterRepositoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterRepositoryRequest>(create);
  static RegisterRepositoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  /// When true, the sidecar runs `git init --initial-branch=main` on the
  /// target directory before registering it. The UI sets this after the
  /// user confirms "Initialize this folder as a git repository?" — without
  /// it the call returns FAILED_PRECONDITION ("not a git repository").
  @$pb.TagNumber(3)
  $core.bool get initializeIfEmpty => $_getBF(2);
  @$pb.TagNumber(3)
  set initializeIfEmpty($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInitializeIfEmpty() => $_has(2);
  @$pb.TagNumber(3)
  void clearInitializeIfEmpty() => $_clearField(3);
}

class ListRepositoriesResponse extends $pb.GeneratedMessage {
  factory ListRepositoriesResponse({
    $core.Iterable<Repository>? repositories,
  }) {
    final result = create();
    if (repositories != null) result.repositories.addAll(repositories);
    return result;
  }

  ListRepositoriesResponse._();

  factory ListRepositoriesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListRepositoriesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRepositoriesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<Repository>(1, _omitFieldNames ? '' : 'repositories',
        subBuilder: Repository.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRepositoriesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRepositoriesResponse copyWith(
          void Function(ListRepositoriesResponse) updates) =>
      super.copyWith((message) => updates(message as ListRepositoriesResponse))
          as ListRepositoriesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListRepositoriesResponse create() => ListRepositoriesResponse._();
  @$core.override
  ListRepositoriesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListRepositoriesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListRepositoriesResponse>(create);
  static ListRepositoriesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Repository> get repositories => $_getList(0);
}

class ScanGitRepositoriesRequest extends $pb.GeneratedMessage {
  factory ScanGitRepositoriesRequest({
    $core.String? path,
    $core.int? maxDepth,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (maxDepth != null) result.maxDepth = maxDepth;
    return result;
  }

  ScanGitRepositoriesRequest._();

  factory ScanGitRepositoriesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanGitRepositoriesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanGitRepositoriesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aI(2, _omitFieldNames ? '' : 'maxDepth')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanGitRepositoriesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanGitRepositoriesRequest copyWith(
          void Function(ScanGitRepositoriesRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ScanGitRepositoriesRequest))
          as ScanGitRepositoriesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanGitRepositoriesRequest create() => ScanGitRepositoriesRequest._();
  @$core.override
  ScanGitRepositoriesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanGitRepositoriesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanGitRepositoriesRequest>(create);
  static ScanGitRepositoriesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  /// Maximum recursion depth from `path`. 0 → server default (3). Keep
  /// this small; NTFS traversals over thousands of node_modules children
  /// get expensive quickly.
  @$pb.TagNumber(2)
  $core.int get maxDepth => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxDepth($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxDepth() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxDepth() => $_clearField(2);
}

/// FoundRepository is one candidate from ScanGitRepositories. `already_registered`
/// is true when the path is case-insensitively equal to a path already in
/// the repositories table, so the UI can grey those out.
class FoundRepository extends $pb.GeneratedMessage {
  factory FoundRepository({
    $core.String? path,
    $core.String? defaultBranch,
    $core.bool? alreadyRegistered,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (defaultBranch != null) result.defaultBranch = defaultBranch;
    if (alreadyRegistered != null) result.alreadyRegistered = alreadyRegistered;
    return result;
  }

  FoundRepository._();

  factory FoundRepository.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FoundRepository.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FoundRepository',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'defaultBranch')
    ..aOB(3, _omitFieldNames ? '' : 'alreadyRegistered')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FoundRepository clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FoundRepository copyWith(void Function(FoundRepository) updates) =>
      super.copyWith((message) => updates(message as FoundRepository))
          as FoundRepository;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FoundRepository create() => FoundRepository._();
  @$core.override
  FoundRepository createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FoundRepository getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FoundRepository>(create);
  static FoundRepository? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get defaultBranch => $_getSZ(1);
  @$pb.TagNumber(2)
  set defaultBranch($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDefaultBranch() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultBranch() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get alreadyRegistered => $_getBF(2);
  @$pb.TagNumber(3)
  set alreadyRegistered($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlreadyRegistered() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlreadyRegistered() => $_clearField(3);
}

class ScanGitRepositoriesResponse extends $pb.GeneratedMessage {
  factory ScanGitRepositoriesResponse({
    $core.Iterable<FoundRepository>? repositories,
    $core.bool? rootIsRepo,
  }) {
    final result = create();
    if (repositories != null) result.repositories.addAll(repositories);
    if (rootIsRepo != null) result.rootIsRepo = rootIsRepo;
    return result;
  }

  ScanGitRepositoriesResponse._();

  factory ScanGitRepositoriesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanGitRepositoriesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanGitRepositoriesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<FoundRepository>(1, _omitFieldNames ? '' : 'repositories',
        subBuilder: FoundRepository.create)
    ..aOB(2, _omitFieldNames ? '' : 'rootIsRepo')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanGitRepositoriesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanGitRepositoriesResponse copyWith(
          void Function(ScanGitRepositoriesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ScanGitRepositoriesResponse))
          as ScanGitRepositoriesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanGitRepositoriesResponse create() =>
      ScanGitRepositoriesResponse._();
  @$core.override
  ScanGitRepositoriesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanGitRepositoriesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanGitRepositoriesResponse>(create);
  static ScanGitRepositoriesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<FoundRepository> get repositories => $_getList(0);

  /// True when the root path itself is already a git repo — UI should treat
  /// the scan as a single-repo registration path instead of a multi-select.
  @$pb.TagNumber(2)
  $core.bool get rootIsRepo => $_getBF(1);
  @$pb.TagNumber(2)
  set rootIsRepo($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRootIsRepo() => $_has(1);
  @$pb.TagNumber(2)
  void clearRootIsRepo() => $_clearField(2);
}

class UpdateDefaultBaseBranchRequest extends $pb.GeneratedMessage {
  factory UpdateDefaultBaseBranchRequest({
    $core.String? repositoryId,
    $core.String? defaultBaseBranch,
  }) {
    final result = create();
    if (repositoryId != null) result.repositoryId = repositoryId;
    if (defaultBaseBranch != null) result.defaultBaseBranch = defaultBaseBranch;
    return result;
  }

  UpdateDefaultBaseBranchRequest._();

  factory UpdateDefaultBaseBranchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateDefaultBaseBranchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateDefaultBaseBranchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repositoryId')
    ..aOS(2, _omitFieldNames ? '' : 'defaultBaseBranch')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateDefaultBaseBranchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateDefaultBaseBranchRequest copyWith(
          void Function(UpdateDefaultBaseBranchRequest) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateDefaultBaseBranchRequest))
          as UpdateDefaultBaseBranchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateDefaultBaseBranchRequest create() =>
      UpdateDefaultBaseBranchRequest._();
  @$core.override
  UpdateDefaultBaseBranchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateDefaultBaseBranchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateDefaultBaseBranchRequest>(create);
  static UpdateDefaultBaseBranchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repositoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repositoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepositoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepositoryId() => $_clearField(1);

  /// Empty clears the pin (returns the repo to auto-detection). Non-empty
  /// is the short branch name to pin (e.g. "main", "develop") — must exist
  /// in the repository's refs/heads/ namespace.
  @$pb.TagNumber(2)
  $core.String get defaultBaseBranch => $_getSZ(1);
  @$pb.TagNumber(2)
  set defaultBaseBranch($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDefaultBaseBranch() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultBaseBranch() => $_clearField(2);
}

class ListBranchesRequest extends $pb.GeneratedMessage {
  factory ListBranchesRequest({
    $core.String? repositoryId,
  }) {
    final result = create();
    if (repositoryId != null) result.repositoryId = repositoryId;
    return result;
  }

  ListBranchesRequest._();

  factory ListBranchesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBranchesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBranchesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repositoryId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBranchesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBranchesRequest copyWith(void Function(ListBranchesRequest) updates) =>
      super.copyWith((message) => updates(message as ListBranchesRequest))
          as ListBranchesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBranchesRequest create() => ListBranchesRequest._();
  @$core.override
  ListBranchesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListBranchesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBranchesRequest>(create);
  static ListBranchesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repositoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repositoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepositoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepositoryId() => $_clearField(1);
}

class ListBranchesResponse extends $pb.GeneratedMessage {
  factory ListBranchesResponse({
    $core.Iterable<$core.String>? branches,
    $core.String? defaultBranch,
    $core.bool? hasCommits,
  }) {
    final result = create();
    if (branches != null) result.branches.addAll(branches);
    if (defaultBranch != null) result.defaultBranch = defaultBranch;
    if (hasCommits != null) result.hasCommits = hasCommits;
    return result;
  }

  ListBranchesResponse._();

  factory ListBranchesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListBranchesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListBranchesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'branches')
    ..aOS(2, _omitFieldNames ? '' : 'defaultBranch')
    ..aOB(3, _omitFieldNames ? '' : 'hasCommits')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBranchesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListBranchesResponse copyWith(void Function(ListBranchesResponse) updates) =>
      super.copyWith((message) => updates(message as ListBranchesResponse))
          as ListBranchesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBranchesResponse create() => ListBranchesResponse._();
  @$core.override
  ListBranchesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListBranchesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListBranchesResponse>(create);
  static ListBranchesResponse? _defaultInstance;

  /// Short branch names (no refs/heads/ prefix). fleetkanban/* branches are
  /// filtered out. Ordered with the auto-detected default first, the pinned
  /// default (if any, and distinct) second, then the remainder in the order
  /// git for-each-ref returned them (sorted by committerdate descending).
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get branches => $_getList(0);

  /// Branch that ResolveDefaultBranch would return right now. Empty when
  /// the repo has no resolvable default (unborn HEAD / detached on a repo
  /// with no refs).
  @$pb.TagNumber(2)
  $core.String get defaultBranch => $_getSZ(1);
  @$pb.TagNumber(2)
  set defaultBranch($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDefaultBranch() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefaultBranch() => $_clearField(2);

  /// False when HEAD is unborn — i.e. the repo was only `git init`'d and
  /// has no commits yet. The UI surfaces this as a warning with a one-tap
  /// "Create initial commit" action that calls CreateInitialCommit.
  @$pb.TagNumber(3)
  $core.bool get hasCommits => $_getBF(2);
  @$pb.TagNumber(3)
  set hasCommits($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasCommits() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasCommits() => $_clearField(3);
}

class SetGitHubTokenRequest extends $pb.GeneratedMessage {
  factory SetGitHubTokenRequest({
    $core.String? token,
  }) {
    final result = create();
    if (token != null) result.token = token;
    return result;
  }

  SetGitHubTokenRequest._();

  factory SetGitHubTokenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetGitHubTokenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetGitHubTokenRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetGitHubTokenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetGitHubTokenRequest copyWith(
          void Function(SetGitHubTokenRequest) updates) =>
      super.copyWith((message) => updates(message as SetGitHubTokenRequest))
          as SetGitHubTokenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetGitHubTokenRequest create() => SetGitHubTokenRequest._();
  @$core.override
  SetGitHubTokenRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetGitHubTokenRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetGitHubTokenRequest>(create);
  static SetGitHubTokenRequest? _defaultInstance;

  /// Empty string clears the stored PAT.
  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);
}

/// CopilotLoginChallenge is returned by BeginCopilotLogin. The UI displays
/// user_code in a dialog and typically offers a button that opens
/// verification_uri in the default browser (the sidecar has already opened
/// it once; the button is a convenience for retry / manual control).
class CopilotLoginChallenge extends $pb.GeneratedMessage {
  factory CopilotLoginChallenge({
    $core.String? userCode,
    $core.String? verificationUri,
    $core.int? expiresInSeconds,
  }) {
    final result = create();
    if (userCode != null) result.userCode = userCode;
    if (verificationUri != null) result.verificationUri = verificationUri;
    if (expiresInSeconds != null) result.expiresInSeconds = expiresInSeconds;
    return result;
  }

  CopilotLoginChallenge._();

  factory CopilotLoginChallenge.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CopilotLoginChallenge.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CopilotLoginChallenge',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userCode')
    ..aOS(2, _omitFieldNames ? '' : 'verificationUri')
    ..aI(3, _omitFieldNames ? '' : 'expiresInSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotLoginChallenge clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotLoginChallenge copyWith(
          void Function(CopilotLoginChallenge) updates) =>
      super.copyWith((message) => updates(message as CopilotLoginChallenge))
          as CopilotLoginChallenge;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CopilotLoginChallenge create() => CopilotLoginChallenge._();
  @$core.override
  CopilotLoginChallenge createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CopilotLoginChallenge getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CopilotLoginChallenge>(create);
  static CopilotLoginChallenge? _defaultInstance;

  /// 8-character device code (formatted as "XXXX-XXXX") that the user types
  /// into the GitHub verification page. The sidecar also appends it to
  /// verification_uri as a query parameter so the user never has to copy it.
  @$pb.TagNumber(1)
  $core.String get userCode => $_getSZ(0);
  @$pb.TagNumber(1)
  set userCode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserCode() => $_clearField(1);

  /// Full URL the user should open — already includes ?user_code=...
  /// and any other query params GitHub accepts for this flow.
  @$pb.TagNumber(2)
  $core.String get verificationUri => $_getSZ(1);
  @$pb.TagNumber(2)
  set verificationUri($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVerificationUri() => $_has(1);
  @$pb.TagNumber(2)
  void clearVerificationUri() => $_clearField(2);

  /// How long the device code is valid. Informational; the sidecar owns
  /// the actual subprocess lifetime.
  @$pb.TagNumber(3)
  $core.int get expiresInSeconds => $_getIZ(2);
  @$pb.TagNumber(3)
  set expiresInSeconds($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresInSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresInSeconds() => $_clearField(3);
}

class CopilotLoginSessionInfo extends $pb.GeneratedMessage {
  factory CopilotLoginSessionInfo({
    CopilotLoginSessionState? state,
    $core.String? errorMessage,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  CopilotLoginSessionInfo._();

  factory CopilotLoginSessionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CopilotLoginSessionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CopilotLoginSessionInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aE<CopilotLoginSessionState>(1, _omitFieldNames ? '' : 'state',
        enumValues: CopilotLoginSessionState.values)
    ..aOS(2, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotLoginSessionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotLoginSessionInfo copyWith(
          void Function(CopilotLoginSessionInfo) updates) =>
      super.copyWith((message) => updates(message as CopilotLoginSessionInfo))
          as CopilotLoginSessionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CopilotLoginSessionInfo create() => CopilotLoginSessionInfo._();
  @$core.override
  CopilotLoginSessionInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CopilotLoginSessionInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CopilotLoginSessionInfo>(create);
  static CopilotLoginSessionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  CopilotLoginSessionState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(CopilotLoginSessionState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Populated when state == FAILED; empty otherwise.
  @$pb.TagNumber(2)
  $core.String get errorMessage => $_getSZ(1);
  @$pb.TagNumber(2)
  set errorMessage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrorMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrorMessage() => $_clearField(2);
}

/// Entry in ListGitHubTokensResponse. Tokens themselves are never surfaced to
/// the frontend; only label + metadata.
class GitHubTokenEntry extends $pb.GeneratedMessage {
  factory GitHubTokenEntry({
    $core.String? label,
    $core.bool? active,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (active != null) result.active = active;
    return result;
  }

  GitHubTokenEntry._();

  factory GitHubTokenEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GitHubTokenEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitHubTokenEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOB(2, _omitFieldNames ? '' : 'active')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitHubTokenEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitHubTokenEntry copyWith(void Function(GitHubTokenEntry) updates) =>
      super.copyWith((message) => updates(message as GitHubTokenEntry))
          as GitHubTokenEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GitHubTokenEntry create() => GitHubTokenEntry._();
  @$core.override
  GitHubTokenEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GitHubTokenEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GitHubTokenEntry>(create);
  static GitHubTokenEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get active => $_getBF(1);
  @$pb.TagNumber(2)
  set active($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActive() => $_has(1);
  @$pb.TagNumber(2)
  void clearActive() => $_clearField(2);
}

class ListGitHubTokensResponse extends $pb.GeneratedMessage {
  factory ListGitHubTokensResponse({
    $core.Iterable<GitHubTokenEntry>? tokens,
    $core.String? activeLabel,
  }) {
    final result = create();
    if (tokens != null) result.tokens.addAll(tokens);
    if (activeLabel != null) result.activeLabel = activeLabel;
    return result;
  }

  ListGitHubTokensResponse._();

  factory ListGitHubTokensResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListGitHubTokensResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListGitHubTokensResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<GitHubTokenEntry>(1, _omitFieldNames ? '' : 'tokens',
        subBuilder: GitHubTokenEntry.create)
    ..aOS(2, _omitFieldNames ? '' : 'activeLabel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGitHubTokensResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGitHubTokensResponse copyWith(
          void Function(ListGitHubTokensResponse) updates) =>
      super.copyWith((message) => updates(message as ListGitHubTokensResponse))
          as ListGitHubTokensResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListGitHubTokensResponse create() => ListGitHubTokensResponse._();
  @$core.override
  ListGitHubTokensResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListGitHubTokensResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListGitHubTokensResponse>(create);
  static ListGitHubTokensResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GitHubTokenEntry> get tokens => $_getList(0);

  /// Empty when no tokens exist. Matches the `active` flag on one of the
  /// entries when present.
  @$pb.TagNumber(2)
  $core.String get activeLabel => $_getSZ(1);
  @$pb.TagNumber(2)
  set activeLabel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActiveLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearActiveLabel() => $_clearField(2);
}

class AddGitHubTokenRequest extends $pb.GeneratedMessage {
  factory AddGitHubTokenRequest({
    $core.String? label,
    $core.String? token,
    $core.bool? setActive,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (token != null) result.token = token;
    if (setActive != null) result.setActive = setActive;
    return result;
  }

  AddGitHubTokenRequest._();

  factory AddGitHubTokenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddGitHubTokenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddGitHubTokenRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOB(3, _omitFieldNames ? '' : 'setActive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddGitHubTokenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddGitHubTokenRequest copyWith(
          void Function(AddGitHubTokenRequest) updates) =>
      super.copyWith((message) => updates(message as AddGitHubTokenRequest))
          as AddGitHubTokenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddGitHubTokenRequest create() => AddGitHubTokenRequest._();
  @$core.override
  AddGitHubTokenRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddGitHubTokenRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddGitHubTokenRequest>(create);
  static AddGitHubTokenRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get setActive => $_getBF(2);
  @$pb.TagNumber(3)
  set setActive($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSetActive() => $_has(2);
  @$pb.TagNumber(3)
  void clearSetActive() => $_clearField(3);
}

class GitHubTokenLabelRequest extends $pb.GeneratedMessage {
  factory GitHubTokenLabelRequest({
    $core.String? label,
  }) {
    final result = create();
    if (label != null) result.label = label;
    return result;
  }

  GitHubTokenLabelRequest._();

  factory GitHubTokenLabelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GitHubTokenLabelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitHubTokenLabelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitHubTokenLabelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitHubTokenLabelRequest copyWith(
          void Function(GitHubTokenLabelRequest) updates) =>
      super.copyWith((message) => updates(message as GitHubTokenLabelRequest))
          as GitHubTokenLabelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GitHubTokenLabelRequest create() => GitHubTokenLabelRequest._();
  @$core.override
  GitHubTokenLabelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GitHubTokenLabelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GitHubTokenLabelRequest>(create);
  static GitHubTokenLabelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);
}

/// GitHubAccountInfo mirrors a subset of the `/user` response. Copilot-plan
/// specific fields (premium_requests_remaining etc.) are not filled because
/// GitHub does not expose them on the public REST API; the UI surfaces a
/// static hint instead.
class GitHubAccountInfo extends $pb.GeneratedMessage {
  factory GitHubAccountInfo({
    $core.String? login,
    $core.String? name,
    $core.String? avatarUrl,
    $core.String? planName,
    $core.int? planPrivateRepos,
    $core.int? planCollaborators,
    $fixnum.Int64? planSpace,
    $core.bool? copilotEnabled,
    $core.String? rawMessage,
  }) {
    final result = create();
    if (login != null) result.login = login;
    if (name != null) result.name = name;
    if (avatarUrl != null) result.avatarUrl = avatarUrl;
    if (planName != null) result.planName = planName;
    if (planPrivateRepos != null) result.planPrivateRepos = planPrivateRepos;
    if (planCollaborators != null) result.planCollaborators = planCollaborators;
    if (planSpace != null) result.planSpace = planSpace;
    if (copilotEnabled != null) result.copilotEnabled = copilotEnabled;
    if (rawMessage != null) result.rawMessage = rawMessage;
    return result;
  }

  GitHubAccountInfo._();

  factory GitHubAccountInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GitHubAccountInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitHubAccountInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'login')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'avatarUrl')
    ..aOS(4, _omitFieldNames ? '' : 'planName')
    ..aI(5, _omitFieldNames ? '' : 'planPrivateRepos')
    ..aI(6, _omitFieldNames ? '' : 'planCollaborators')
    ..aInt64(7, _omitFieldNames ? '' : 'planSpace')
    ..aOB(8, _omitFieldNames ? '' : 'copilotEnabled')
    ..aOS(9, _omitFieldNames ? '' : 'rawMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitHubAccountInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitHubAccountInfo copyWith(void Function(GitHubAccountInfo) updates) =>
      super.copyWith((message) => updates(message as GitHubAccountInfo))
          as GitHubAccountInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GitHubAccountInfo create() => GitHubAccountInfo._();
  @$core.override
  GitHubAccountInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GitHubAccountInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GitHubAccountInfo>(create);
  static GitHubAccountInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get login => $_getSZ(0);
  @$pb.TagNumber(1)
  set login($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLogin() => $_has(0);
  @$pb.TagNumber(1)
  void clearLogin() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get avatarUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatarUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatarUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatarUrl() => $_clearField(3);

  /// `plan.name` from the REST response: "free" / "pro" / "team" / "enterprise".
  /// This reflects the GitHub account plan, which correlates with (but is not
  /// identical to) the Copilot tier.
  @$pb.TagNumber(4)
  $core.String get planName => $_getSZ(3);
  @$pb.TagNumber(4)
  set planName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPlanName() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlanName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get planPrivateRepos => $_getIZ(4);
  @$pb.TagNumber(5)
  set planPrivateRepos($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPlanPrivateRepos() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlanPrivateRepos() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get planCollaborators => $_getIZ(5);
  @$pb.TagNumber(6)
  set planCollaborators($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPlanCollaborators() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlanCollaborators() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get planSpace => $_getI64(6);
  @$pb.TagNumber(7)
  set planSpace($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPlanSpace() => $_has(6);
  @$pb.TagNumber(7)
  void clearPlanSpace() => $_clearField(7);

  /// Whether this account has Copilot enabled. Derived from the SDK auth
  /// state; false for users who authenticated without Copilot entitlement.
  @$pb.TagNumber(8)
  $core.bool get copilotEnabled => $_getBF(7);
  @$pb.TagNumber(8)
  set copilotEnabled($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCopilotEnabled() => $_has(7);
  @$pb.TagNumber(8)
  void clearCopilotEnabled() => $_clearField(8);

  /// Free-form summary string for the UI to fall back on when parsing fails.
  @$pb.TagNumber(9)
  $core.String get rawMessage => $_getSZ(8);
  @$pb.TagNumber(9)
  set rawMessage($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasRawMessage() => $_has(8);
  @$pb.TagNumber(9)
  void clearRawMessage() => $_clearField(9);
}

/// ModelInfo carries the per-model metadata the Settings picker needs to
/// surface billing impact (Free vs Premium request, multiplier ×N) so the
/// user can pick a model with full awareness of how many premium requests
/// each task will consume on their plan.
class ModelInfo extends $pb.GeneratedMessage {
  factory ModelInfo({
    $core.String? id,
    $core.String? name,
    $core.double? multiplier,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (multiplier != null) result.multiplier = multiplier;
    return result;
  }

  ModelInfo._();

  factory ModelInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModelInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aD(3, _omitFieldNames ? '' : 'multiplier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelInfo copyWith(void Function(ModelInfo) updates) =>
      super.copyWith((message) => updates(message as ModelInfo)) as ModelInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModelInfo create() => ModelInfo._();
  @$core.override
  ModelInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModelInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelInfo>(create);
  static ModelInfo? _defaultInstance;

  /// Stable model identifier, e.g. "claude-sonnet-4-5". Sent verbatim to
  /// SDK CreateSession and stored on Task.{plan,code,review}_model.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Human-friendly display name from the Copilot CLI catalog,
  /// e.g. "Claude Sonnet 4.5". Falls back to id when empty server-side.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// Premium-request multiplier the Copilot billing plan applies to each
  /// request against this model. 0 means "no premium request charged"
  /// (i.e. Free / unmetered for the user's plan); >=1 means each call
  /// counts as multiplier×1 premium request. Surfaced in the picker as a
  /// "Free" / "Premium ×N" badge.
  @$pb.TagNumber(3)
  $core.double get multiplier => $_getN(2);
  @$pb.TagNumber(3)
  set multiplier($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMultiplier() => $_has(2);
  @$pb.TagNumber(3)
  void clearMultiplier() => $_clearField(3);
}

class ListModelsResponse extends $pb.GeneratedMessage {
  factory ListModelsResponse({
    $core.Iterable<ModelInfo>? models,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    return result;
  }

  ListModelsResponse._();

  factory ListModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModelsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<ModelInfo>(1, _omitFieldNames ? '' : 'models',
        subBuilder: ModelInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsResponse copyWith(void Function(ListModelsResponse) updates) =>
      super.copyWith((message) => updates(message as ListModelsResponse))
          as ListModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListModelsResponse create() => ListModelsResponse._();
  @$core.override
  ListModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListModelsResponse>(create);
  static ListModelsResponse? _defaultInstance;

  /// Model catalog as advertised by the Copilot CLI server, ordered as
  /// returned. Order is treated as authoritative for "first match" picks
  /// (see copilot/runner.resolveModel).
  @$pb.TagNumber(1)
  $pb.PbList<ModelInfo> get models => $_getList(0);
}

/// WorktreeEntry is one row in the Worktrees pane. `task_id` is empty for
/// worktrees that are not under the fleetkanban/ branch namespace (primary
/// worktrees of registered repos are included so the pane can show them as
/// the "(main)" row). `path_exists` reflects whether the worktree directory
/// still exists on disk — false means the directory was deleted externally
/// and a `git worktree prune` is needed to clean the repo metadata.
class WorktreeEntry extends $pb.GeneratedMessage {
  factory WorktreeEntry({
    $core.String? repositoryId,
    $core.String? repositoryPath,
    $core.String? path,
    $core.String? branch,
    $core.bool? pathExists,
    $core.bool? isPrimary,
    $core.String? taskId,
    $core.String? taskStatus,
    $core.String? head,
  }) {
    final result = create();
    if (repositoryId != null) result.repositoryId = repositoryId;
    if (repositoryPath != null) result.repositoryPath = repositoryPath;
    if (path != null) result.path = path;
    if (branch != null) result.branch = branch;
    if (pathExists != null) result.pathExists = pathExists;
    if (isPrimary != null) result.isPrimary = isPrimary;
    if (taskId != null) result.taskId = taskId;
    if (taskStatus != null) result.taskStatus = taskStatus;
    if (head != null) result.head = head;
    return result;
  }

  WorktreeEntry._();

  factory WorktreeEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WorktreeEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WorktreeEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repositoryId')
    ..aOS(2, _omitFieldNames ? '' : 'repositoryPath')
    ..aOS(3, _omitFieldNames ? '' : 'path')
    ..aOS(4, _omitFieldNames ? '' : 'branch')
    ..aOB(5, _omitFieldNames ? '' : 'pathExists')
    ..aOB(6, _omitFieldNames ? '' : 'isPrimary')
    ..aOS(7, _omitFieldNames ? '' : 'taskId')
    ..aOS(8, _omitFieldNames ? '' : 'taskStatus')
    ..aOS(9, _omitFieldNames ? '' : 'head')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorktreeEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorktreeEntry copyWith(void Function(WorktreeEntry) updates) =>
      super.copyWith((message) => updates(message as WorktreeEntry))
          as WorktreeEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WorktreeEntry create() => WorktreeEntry._();
  @$core.override
  WorktreeEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WorktreeEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WorktreeEntry>(create);
  static WorktreeEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repositoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repositoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepositoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepositoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get repositoryPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set repositoryPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepositoryPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepositoryPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get path => $_getSZ(2);
  @$pb.TagNumber(3)
  set path($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get branch => $_getSZ(3);
  @$pb.TagNumber(4)
  set branch($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBranch() => $_has(3);
  @$pb.TagNumber(4)
  void clearBranch() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get pathExists => $_getBF(4);
  @$pb.TagNumber(5)
  set pathExists($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPathExists() => $_has(4);
  @$pb.TagNumber(5)
  void clearPathExists() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isPrimary => $_getBF(5);
  @$pb.TagNumber(6)
  set isPrimary($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsPrimary() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsPrimary() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get taskId => $_getSZ(6);
  @$pb.TagNumber(7)
  set taskId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTaskId() => $_has(6);
  @$pb.TagNumber(7)
  void clearTaskId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get taskStatus => $_getSZ(7);
  @$pb.TagNumber(8)
  set taskStatus($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTaskStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearTaskStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get head => $_getSZ(8);
  @$pb.TagNumber(9)
  set head($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHead() => $_has(8);
  @$pb.TagNumber(9)
  void clearHead() => $_clearField(9);
}

class ListWorktreesResponse extends $pb.GeneratedMessage {
  factory ListWorktreesResponse({
    $core.Iterable<WorktreeEntry>? worktrees,
  }) {
    final result = create();
    if (worktrees != null) result.worktrees.addAll(worktrees);
    return result;
  }

  ListWorktreesResponse._();

  factory ListWorktreesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListWorktreesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListWorktreesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<WorktreeEntry>(1, _omitFieldNames ? '' : 'worktrees',
        subBuilder: WorktreeEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListWorktreesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListWorktreesResponse copyWith(
          void Function(ListWorktreesResponse) updates) =>
      super.copyWith((message) => updates(message as ListWorktreesResponse))
          as ListWorktreesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListWorktreesResponse create() => ListWorktreesResponse._();
  @$core.override
  ListWorktreesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListWorktreesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListWorktreesResponse>(create);
  static ListWorktreesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<WorktreeEntry> get worktrees => $_getList(0);
}

class RemoveWorktreeRequest extends $pb.GeneratedMessage {
  factory RemoveWorktreeRequest({
    $core.String? repositoryId,
    $core.String? worktreePath,
    $core.bool? deleteBranch,
  }) {
    final result = create();
    if (repositoryId != null) result.repositoryId = repositoryId;
    if (worktreePath != null) result.worktreePath = worktreePath;
    if (deleteBranch != null) result.deleteBranch = deleteBranch;
    return result;
  }

  RemoveWorktreeRequest._();

  factory RemoveWorktreeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveWorktreeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveWorktreeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repositoryId')
    ..aOS(2, _omitFieldNames ? '' : 'worktreePath')
    ..aOB(3, _omitFieldNames ? '' : 'deleteBranch')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveWorktreeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveWorktreeRequest copyWith(
          void Function(RemoveWorktreeRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveWorktreeRequest))
          as RemoveWorktreeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveWorktreeRequest create() => RemoveWorktreeRequest._();
  @$core.override
  RemoveWorktreeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveWorktreeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveWorktreeRequest>(create);
  static RemoveWorktreeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repositoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repositoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepositoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepositoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get worktreePath => $_getSZ(1);
  @$pb.TagNumber(2)
  set worktreePath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorktreePath() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorktreePath() => $_clearField(2);

  /// When true, the fleetkanban/<task-id> branch is also deleted. Only honored
  /// for worktrees that live under the fleetkanban/ namespace.
  @$pb.TagNumber(3)
  $core.bool get deleteBranch => $_getBF(2);
  @$pb.TagNumber(3)
  set deleteBranch($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeleteBranch() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeleteBranch() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
