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

class StashUncommittedResponse extends $pb.GeneratedMessage {
  factory StashUncommittedResponse({
    $core.bool? stashed,
    $core.String? message,
  }) {
    final result = create();
    if (stashed != null) result.stashed = stashed;
    if (message != null) result.message = message;
    return result;
  }

  StashUncommittedResponse._();

  factory StashUncommittedResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StashUncommittedResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StashUncommittedResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'stashed')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StashUncommittedResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StashUncommittedResponse copyWith(
          void Function(StashUncommittedResponse) updates) =>
      super.copyWith((message) => updates(message as StashUncommittedResponse))
          as StashUncommittedResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StashUncommittedResponse create() => StashUncommittedResponse._();
  @$core.override
  StashUncommittedResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StashUncommittedResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StashUncommittedResponse>(create);
  static StashUncommittedResponse? _defaultInstance;

  /// True when git actually created a stash entry; false when the
  /// working tree was already clean.
  @$pb.TagNumber(1)
  $core.bool get stashed => $_getBF(0);
  @$pb.TagNumber(1)
  set stashed($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStashed() => $_has(0);
  @$pb.TagNumber(1)
  void clearStashed() => $_clearField(1);

  /// Git's own message (e.g. "Saved working directory and index state ...").
  /// Surfaced in the UI toast so the user sees the stash label and can
  /// match it later via `git stash list`.
  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

/// AgentSettings carries the free-form output-language directive
/// (e.g. "Japanese", "Spanish", "casual English") the agent uses when
/// choosing the language of its summaries / explanations / feedback.
/// Empty means "no language hint"; the agent falls back to the
/// model's default.
class AgentSettings extends $pb.GeneratedMessage {
  factory AgentSettings({
    $core.String? outputLanguage,
  }) {
    final result = create();
    if (outputLanguage != null) result.outputLanguage = outputLanguage;
    return result;
  }

  AgentSettings._();

  factory AgentSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AgentSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AgentSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(4, _omitFieldNames ? '' : 'outputLanguage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentSettings copyWith(void Function(AgentSettings) updates) =>
      super.copyWith((message) => updates(message as AgentSettings))
          as AgentSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgentSettings create() => AgentSettings._();
  @$core.override
  AgentSettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AgentSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AgentSettings>(create);
  static AgentSettings? _defaultInstance;

  /// Free-form natural-language identifier the agent uses to choose
  /// the language of its summaries / explanations / feedback. The
  /// sidecar passes this verbatim — the AI is expected to recognise
  /// values like "日本語", "Japanese", "Português brasileiro", etc.
  @$pb.TagNumber(4)
  $core.String get outputLanguage => $_getSZ(0);
  @$pb.TagNumber(4)
  set outputLanguage($core.String value) => $_setString(0, value);
  @$pb.TagNumber(4)
  $core.bool hasOutputLanguage() => $_has(0);
  @$pb.TagNumber(4)
  void clearOutputLanguage() => $_clearField(4);
}

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
    $core.int? harnessVersion,
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
    if (harnessVersion != null) result.harnessVersion = harnessVersion;
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
    ..aI(21, _omitFieldNames ? '' : 'harnessVersion')
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

  /// harness_version is the HarnessSkill version active when this task was
  /// last run. 0 means the task predates NLAH Phase A or no harness was
  /// loaded. Populated by the orchestrator at run-time; read-only from the UI.
  @$pb.TagNumber(21)
  $core.int get harnessVersion => $_getIZ(20);
  @$pb.TagNumber(21)
  set harnessVersion($core.int value) => $_setSignedInt32(20, value);
  @$pb.TagNumber(21)
  $core.bool hasHarnessVersion() => $_has(20);
  @$pb.TagNumber(21)
  void clearHarnessVersion() => $_clearField(21);
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
    $core.int? round,
    $core.String? prompt,
    $core.Iterable<$core.String>? writePaths,
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
    if (round != null) result.round = round;
    if (prompt != null) result.prompt = prompt;
    if (writePaths != null) result.writePaths.addAll(writePaths);
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
    ..aI(11, _omitFieldNames ? '' : 'round')
    ..aOS(12, _omitFieldNames ? '' : 'prompt')
    ..pPS(13, _omitFieldNames ? '' : 'writePaths')
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

  /// Round is the 1-based iteration counter within the parent task.
  /// Round 1 is the planner's first decomposition; AI / Human REWORK and
  /// User Re-run each create a fresh round at max+1, with the previous
  /// round's subtasks left in place as history. The orchestrator only
  /// executes the latest round; the UI stacks earlier rounds above as
  /// visual context for the rework loop.
  @$pb.TagNumber(11)
  $core.int get round => $_getIZ(10);
  @$pb.TagNumber(11)
  set round($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasRound() => $_has(10);
  @$pb.TagNumber(11)
  void clearRound() => $_clearField(11);

  /// Prompt is the concrete instruction the planner wrote for this
  /// subtask — multi-sentence, naming specific files/behaviour/verification
  /// steps. BuildSubtaskPrompt folds it into the Coder's session prompt so
  /// the executor has precise intent instead of guessing from the Title.
  /// Empty for legacy / manual subtasks; BuildSubtaskPrompt falls back to
  /// a title-only template.
  @$pb.TagNumber(12)
  $core.String get prompt => $_getSZ(11);
  @$pb.TagNumber(12)
  set prompt($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPrompt() => $_has(11);
  @$pb.TagNumber(12)
  void clearPrompt() => $_clearField(12);

  /// Write paths the planner declared this subtask will modify (file
  /// globs or exact paths relative to the worktree root). The
  /// orchestrator batches subtasks with disjoint write_paths for
  /// parallel execution; overlapping sets are serialised. An empty list
  /// is treated as "**" (conservatively conflicts with every other
  /// subtask) so legacy / hand-written plans fall back to serial order.
  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get writePaths => $_getList(12);
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

/// GetSubtaskContextRequest identifies one (subtask_id, round) row in
/// subtask_context.
///
/// Semantics of the round field:
///   * round >  0 — exact lookup, equivalent to
///                  `SELECT * FROM subtask_context WHERE subtask_id=? AND round=?`.
///                  Missing rows return not_recorded=true, not an error.
///   * round <= 0 — "latest": resolves to MAX(round) for this subtask via
///                  `ORDER BY round DESC LIMIT 1`. Zero and negative values
///                  behave identically; the UI passes 0 on the first open
///                  and the specific round when the user steps back through
///                  rework history.
///
/// Rounds are monotonic per subtask (see v11 migration); a new round is
/// created each time the orchestrator re-executes after an AI Review
/// rework. There is no "round=0" row on disk — 0 is purely a wire shorthand.
class GetSubtaskContextRequest extends $pb.GeneratedMessage {
  factory GetSubtaskContextRequest({
    $core.String? subtaskId,
    $core.int? round,
  }) {
    final result = create();
    if (subtaskId != null) result.subtaskId = subtaskId;
    if (round != null) result.round = round;
    return result;
  }

  GetSubtaskContextRequest._();

  factory GetSubtaskContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSubtaskContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSubtaskContextRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subtaskId')
    ..aI(2, _omitFieldNames ? '' : 'round')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSubtaskContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSubtaskContextRequest copyWith(
          void Function(GetSubtaskContextRequest) updates) =>
      super.copyWith((message) => updates(message as GetSubtaskContextRequest))
          as GetSubtaskContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSubtaskContextRequest create() => GetSubtaskContextRequest._();
  @$core.override
  GetSubtaskContextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSubtaskContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSubtaskContextRequest>(create);
  static GetSubtaskContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get subtaskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set subtaskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubtaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubtaskId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get round => $_getIZ(1);
  @$pb.TagNumber(2)
  set round($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRound() => $_has(1);
  @$pb.TagNumber(2)
  void clearRound() => $_clearField(2);
}

/// CopilotSubtaskContext mirrors store.SubtaskContext plus the harness
/// SKILL.md content resolved via harness_skill_version_id so the UI
/// only needs one RPC round-trip to render every tab of the Subtask
/// Summary dialog.
class CopilotSubtaskContext extends $pb.GeneratedMessage {
  factory CopilotSubtaskContext({
    $core.String? subtaskId,
    $core.int? round,
    $core.String? systemPrompt,
    $core.String? userPrompt,
    $core.String? stagePromptTemplate,
    $core.String? planSummary,
    $core.Iterable<$core.String>? priorSummaries,
    $core.String? memoryBlock,
    $core.String? outputLanguage,
    $core.String? harnessSkillVersionId,
    $core.String? harnessSkillMd,
    $core.bool? notRecorded,
  }) {
    final result = create();
    if (subtaskId != null) result.subtaskId = subtaskId;
    if (round != null) result.round = round;
    if (systemPrompt != null) result.systemPrompt = systemPrompt;
    if (userPrompt != null) result.userPrompt = userPrompt;
    if (stagePromptTemplate != null)
      result.stagePromptTemplate = stagePromptTemplate;
    if (planSummary != null) result.planSummary = planSummary;
    if (priorSummaries != null) result.priorSummaries.addAll(priorSummaries);
    if (memoryBlock != null) result.memoryBlock = memoryBlock;
    if (outputLanguage != null) result.outputLanguage = outputLanguage;
    if (harnessSkillVersionId != null)
      result.harnessSkillVersionId = harnessSkillVersionId;
    if (harnessSkillMd != null) result.harnessSkillMd = harnessSkillMd;
    if (notRecorded != null) result.notRecorded = notRecorded;
    return result;
  }

  CopilotSubtaskContext._();

  factory CopilotSubtaskContext.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CopilotSubtaskContext.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CopilotSubtaskContext',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subtaskId')
    ..aI(2, _omitFieldNames ? '' : 'round')
    ..aOS(3, _omitFieldNames ? '' : 'systemPrompt')
    ..aOS(4, _omitFieldNames ? '' : 'userPrompt')
    ..aOS(5, _omitFieldNames ? '' : 'stagePromptTemplate')
    ..aOS(6, _omitFieldNames ? '' : 'planSummary')
    ..pPS(7, _omitFieldNames ? '' : 'priorSummaries')
    ..aOS(8, _omitFieldNames ? '' : 'memoryBlock')
    ..aOS(9, _omitFieldNames ? '' : 'outputLanguage')
    ..aOS(10, _omitFieldNames ? '' : 'harnessSkillVersionId')
    ..aOS(11, _omitFieldNames ? '' : 'harnessSkillMd')
    ..aOB(12, _omitFieldNames ? '' : 'notRecorded')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotSubtaskContext clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotSubtaskContext copyWith(
          void Function(CopilotSubtaskContext) updates) =>
      super.copyWith((message) => updates(message as CopilotSubtaskContext))
          as CopilotSubtaskContext;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CopilotSubtaskContext create() => CopilotSubtaskContext._();
  @$core.override
  CopilotSubtaskContext createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CopilotSubtaskContext getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CopilotSubtaskContext>(create);
  static CopilotSubtaskContext? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get subtaskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set subtaskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubtaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubtaskId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get round => $_getIZ(1);
  @$pb.TagNumber(2)
  set round($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRound() => $_has(1);
  @$pb.TagNumber(2)
  void clearRound() => $_clearField(2);

  /// Full SDK SystemMessage content (DefaultCodePrompt + output-language
  /// addendum).
  @$pb.TagNumber(3)
  $core.String get systemPrompt => $_getSZ(2);
  @$pb.TagNumber(3)
  set systemPrompt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSystemPrompt() => $_has(2);
  @$pb.TagNumber(3)
  void clearSystemPrompt() => $_clearField(3);

  /// Full SDK user MessageOptions.Prompt (memory block + BuildSubtask
  /// PromptWithContext composition).
  @$pb.TagNumber(4)
  $core.String get userPrompt => $_getSZ(3);
  @$pb.TagNumber(4)
  set userPrompt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUserPrompt() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserPrompt() => $_clearField(4);

  /// Raw stage template (DefaultCodePrompt) before language addendum.
  @$pb.TagNumber(5)
  $core.String get stagePromptTemplate => $_getSZ(4);
  @$pb.TagNumber(5)
  set stagePromptTemplate($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStagePromptTemplate() => $_has(4);
  @$pb.TagNumber(5)
  void clearStagePromptTemplate() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get planSummary => $_getSZ(5);
  @$pb.TagNumber(6)
  set planSummary($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPlanSummary() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlanSummary() => $_clearField(6);

  /// Already formatted display lines, one per prior subtask, in DAG order.
  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get priorSummaries => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get memoryBlock => $_getSZ(7);
  @$pb.TagNumber(8)
  set memoryBlock($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMemoryBlock() => $_has(7);
  @$pb.TagNumber(8)
  void clearMemoryBlock() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get outputLanguage => $_getSZ(8);
  @$pb.TagNumber(9)
  set outputLanguage($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOutputLanguage() => $_has(8);
  @$pb.TagNumber(9)
  void clearOutputLanguage() => $_clearField(9);

  /// Active harness version at run time. id is empty when the embedded
  /// fallback was used (no user-authored SKILL.md yet).
  @$pb.TagNumber(10)
  $core.String get harnessSkillVersionId => $_getSZ(9);
  @$pb.TagNumber(10)
  set harnessSkillVersionId($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHarnessSkillVersionId() => $_has(9);
  @$pb.TagNumber(10)
  void clearHarnessSkillVersionId() => $_clearField(10);

  /// SKILL.md content as of run time. Empty when harness_skill_version_id
  /// is empty or the row has since been purged.
  @$pb.TagNumber(11)
  $core.String get harnessSkillMd => $_getSZ(10);
  @$pb.TagNumber(11)
  set harnessSkillMd($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHarnessSkillMd() => $_has(10);
  @$pb.TagNumber(11)
  void clearHarnessSkillMd() => $_clearField(11);

  /// True when no subtask_context row exists (legacy subtasks executed
  /// before the v18 schema, or not yet executed). All other fields are
  /// zero values in that case.
  @$pb.TagNumber(12)
  $core.bool get notRecorded => $_getBF(11);
  @$pb.TagNumber(12)
  set notRecorded($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasNotRecorded() => $_has(11);
  @$pb.TagNumber(12)
  void clearNotRecorded() => $_clearField(12);
}

class CreateSubtaskRequest extends $pb.GeneratedMessage {
  factory CreateSubtaskRequest({
    $core.String? taskId,
    $core.String? title,
    $core.String? status,
    $core.int? orderIdx,
    $core.String? agentRole,
    $core.Iterable<$core.String>? dependsOn,
    $core.Iterable<$core.String>? writePaths,
  }) {
    final result = create();
    if (taskId != null) result.taskId = taskId;
    if (title != null) result.title = title;
    if (status != null) result.status = status;
    if (orderIdx != null) result.orderIdx = orderIdx;
    if (agentRole != null) result.agentRole = agentRole;
    if (dependsOn != null) result.dependsOn.addAll(dependsOn);
    if (writePaths != null) result.writePaths.addAll(writePaths);
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
    ..pPS(7, _omitFieldNames ? '' : 'writePaths')
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

  /// Write paths declared by the planner (globs / exact paths). Enables
  /// path-disjoint parallel batching; empty = conservative serial fallback.
  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get writePaths => $_getList(6);
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

/// CopilotQuotaInfo carries every quota snapshot the SDK's account.getQuota
/// RPC returns, keyed by quota type ("premium_interactions", "chat",
/// "completions", …). The UI surfaces whichever key it finds interesting —
/// "premium_interactions" is the headline number for the account-card panel.
class CopilotQuotaInfo extends $pb.GeneratedMessage {
  factory CopilotQuotaInfo({
    $core.Iterable<$core.MapEntry<$core.String, CopilotQuotaSnapshot>>?
        snapshots,
  }) {
    final result = create();
    if (snapshots != null) result.snapshots.addEntries(snapshots);
    return result;
  }

  CopilotQuotaInfo._();

  factory CopilotQuotaInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CopilotQuotaInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CopilotQuotaInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..m<$core.String, CopilotQuotaSnapshot>(
        1, _omitFieldNames ? '' : 'snapshots',
        entryClassName: 'CopilotQuotaInfo.SnapshotsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: CopilotQuotaSnapshot.create,
        valueDefaultOrMaker: CopilotQuotaSnapshot.getDefault,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotQuotaInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotQuotaInfo copyWith(void Function(CopilotQuotaInfo) updates) =>
      super.copyWith((message) => updates(message as CopilotQuotaInfo))
          as CopilotQuotaInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CopilotQuotaInfo create() => CopilotQuotaInfo._();
  @$core.override
  CopilotQuotaInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CopilotQuotaInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CopilotQuotaInfo>(create);
  static CopilotQuotaInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, CopilotQuotaSnapshot> get snapshots => $_getMap(0);
}

/// CopilotQuotaSnapshot mirrors SDK rpc.QuotaSnapshot. All counts are
/// "number of requests" (not tokens); billing multiplier is applied upstream
/// in the Copilot CLI before snapshots are exposed, so one used_requests
/// unit equals one premium-request charge on the user's plan.
class CopilotQuotaSnapshot extends $pb.GeneratedMessage {
  factory CopilotQuotaSnapshot({
    $core.double? entitlementRequests,
    $core.double? usedRequests,
    $core.double? remainingPercentage,
    $core.double? overage,
    $core.bool? overageAllowedWithExhaustedQuota,
    $core.String? resetDate,
  }) {
    final result = create();
    if (entitlementRequests != null)
      result.entitlementRequests = entitlementRequests;
    if (usedRequests != null) result.usedRequests = usedRequests;
    if (remainingPercentage != null)
      result.remainingPercentage = remainingPercentage;
    if (overage != null) result.overage = overage;
    if (overageAllowedWithExhaustedQuota != null)
      result.overageAllowedWithExhaustedQuota =
          overageAllowedWithExhaustedQuota;
    if (resetDate != null) result.resetDate = resetDate;
    return result;
  }

  CopilotQuotaSnapshot._();

  factory CopilotQuotaSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CopilotQuotaSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CopilotQuotaSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'entitlementRequests')
    ..aD(2, _omitFieldNames ? '' : 'usedRequests')
    ..aD(3, _omitFieldNames ? '' : 'remainingPercentage')
    ..aD(4, _omitFieldNames ? '' : 'overage')
    ..aOB(5, _omitFieldNames ? '' : 'overageAllowedWithExhaustedQuota')
    ..aOS(6, _omitFieldNames ? '' : 'resetDate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotQuotaSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CopilotQuotaSnapshot copyWith(void Function(CopilotQuotaSnapshot) updates) =>
      super.copyWith((message) => updates(message as CopilotQuotaSnapshot))
          as CopilotQuotaSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CopilotQuotaSnapshot create() => CopilotQuotaSnapshot._();
  @$core.override
  CopilotQuotaSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CopilotQuotaSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CopilotQuotaSnapshot>(create);
  static CopilotQuotaSnapshot? _defaultInstance;

  /// Number of premium requests included in the user's plan for the current
  /// billing period.
  @$pb.TagNumber(1)
  $core.double get entitlementRequests => $_getN(0);
  @$pb.TagNumber(1)
  set entitlementRequests($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntitlementRequests() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntitlementRequests() => $_clearField(1);

  /// Number of premium requests already consumed this billing period.
  @$pb.TagNumber(2)
  $core.double get usedRequests => $_getN(1);
  @$pb.TagNumber(2)
  set usedRequests($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsedRequests() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsedRequests() => $_clearField(2);

  /// Percentage of entitlement remaining, on a 0-100 scale. The SDK
  /// supplies this directly; clients should prefer it over dividing
  /// used/entitlement to match the server's rounding rules. Note: the
  /// upstream SDK doc comment claims "0.0 to 1.0" but empirically the
  /// Copilot CLI returns 0-100 (verified against CLI 1.0.21 / SDK v0.2.2).
  @$pb.TagNumber(3)
  $core.double get remainingPercentage => $_getN(2);
  @$pb.TagNumber(3)
  set remainingPercentage($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRemainingPercentage() => $_has(2);
  @$pb.TagNumber(3)
  void clearRemainingPercentage() => $_clearField(3);

  /// Requests charged against pay-per-request overage after the entitlement
  /// was exhausted. Zero for users who haven't exceeded their plan.
  @$pb.TagNumber(4)
  $core.double get overage => $_getN(3);
  @$pb.TagNumber(4)
  set overage($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOverage() => $_has(3);
  @$pb.TagNumber(4)
  void clearOverage() => $_clearField(4);

  /// When true, the account is configured to keep serving requests beyond
  /// the entitlement (billing the user for each) instead of hard-stopping.
  @$pb.TagNumber(5)
  $core.bool get overageAllowedWithExhaustedQuota => $_getBF(4);
  @$pb.TagNumber(5)
  set overageAllowedWithExhaustedQuota($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOverageAllowedWithExhaustedQuota() => $_has(4);
  @$pb.TagNumber(5)
  void clearOverageAllowedWithExhaustedQuota() => $_clearField(5);

  /// ISO-8601 timestamp of the next quota reset, or empty when the SDK did
  /// not provide one (e.g. unmetered plans).
  @$pb.TagNumber(6)
  $core.String get resetDate => $_getSZ(5);
  @$pb.TagNumber(6)
  set resetDate($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasResetDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearResetDate() => $_clearField(6);
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

/// ContextNode is one entity in the property graph. kind / source_kind
/// are strings; see service-level comment. content_md is Markdown that
/// is rendered directly in the Browse tab and serialized into injected
/// prompts. attrs is a free-form map for kind-specific metadata (e.g.
/// File nodes may carry "path" and "language"; Decision nodes may carry
/// "decision_id" and "rationale_url").
class ContextNode extends $pb.GeneratedMessage {
  factory ContextNode({
    $core.String? id,
    $core.String? repoId,
    $core.String? kind,
    $core.String? label,
    $core.String? contentMd,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? attrs,
    $core.String? sourceKind,
    $core.double? confidence,
    $core.bool? enabled,
    $core.bool? pinned,
    $2.Timestamp? createdAt,
    $2.Timestamp? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (repoId != null) result.repoId = repoId;
    if (kind != null) result.kind = kind;
    if (label != null) result.label = label;
    if (contentMd != null) result.contentMd = contentMd;
    if (attrs != null) result.attrs.addEntries(attrs);
    if (sourceKind != null) result.sourceKind = sourceKind;
    if (confidence != null) result.confidence = confidence;
    if (enabled != null) result.enabled = enabled;
    if (pinned != null) result.pinned = pinned;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  ContextNode._();

  factory ContextNode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextNode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextNode',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'repoId')
    ..aOS(3, _omitFieldNames ? '' : 'kind')
    ..aOS(4, _omitFieldNames ? '' : 'label')
    ..aOS(5, _omitFieldNames ? '' : 'contentMd')
    ..m<$core.String, $core.String>(6, _omitFieldNames ? '' : 'attrs',
        entryClassName: 'ContextNode.AttrsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..aOS(7, _omitFieldNames ? '' : 'sourceKind')
    ..aD(8, _omitFieldNames ? '' : 'confidence', fieldType: $pb.PbFieldType.OF)
    ..aOB(9, _omitFieldNames ? '' : 'enabled')
    ..aOB(10, _omitFieldNames ? '' : 'pinned')
    ..aOM<$2.Timestamp>(11, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(12, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextNode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextNode copyWith(void Function(ContextNode) updates) =>
      super.copyWith((message) => updates(message as ContextNode))
          as ContextNode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextNode create() => ContextNode._();
  @$core.override
  ContextNode createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextNode getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextNode>(create);
  static ContextNode? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get repoId => $_getSZ(1);
  @$pb.TagNumber(2)
  set repoId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepoId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepoId() => $_clearField(2);

  /// File | Module | Function | Class | Concept | Decision | Constraint | Tag
  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get label => $_getSZ(3);
  @$pb.TagNumber(4)
  set label($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get contentMd => $_getSZ(4);
  @$pb.TagNumber(5)
  set contentMd($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContentMd() => $_has(4);
  @$pb.TagNumber(5)
  void clearContentMd() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbMap<$core.String, $core.String> get attrs => $_getMap(5);

  /// manual | observer | analyzer | static-analysis | session-summary
  @$pb.TagNumber(7)
  $core.String get sourceKind => $_getSZ(6);
  @$pb.TagNumber(7)
  set sourceKind($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSourceKind() => $_has(6);
  @$pb.TagNumber(7)
  void clearSourceKind() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get confidence => $_getN(7);
  @$pb.TagNumber(8)
  set confidence($core.double value) => $_setFloat(7, value);
  @$pb.TagNumber(8)
  $core.bool hasConfidence() => $_has(7);
  @$pb.TagNumber(8)
  void clearConfidence() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get enabled => $_getBF(8);
  @$pb.TagNumber(9)
  set enabled($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasEnabled() => $_has(8);
  @$pb.TagNumber(9)
  void clearEnabled() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get pinned => $_getBF(9);
  @$pb.TagNumber(10)
  set pinned($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPinned() => $_has(9);
  @$pb.TagNumber(10)
  void clearPinned() => $_clearField(10);

  @$pb.TagNumber(11)
  $2.Timestamp get createdAt => $_getN(10);
  @$pb.TagNumber(11)
  set createdAt($2.Timestamp value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasCreatedAt() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreatedAt() => $_clearField(11);
  @$pb.TagNumber(11)
  $2.Timestamp ensureCreatedAt() => $_ensure(10);

  @$pb.TagNumber(12)
  $2.Timestamp get updatedAt => $_getN(11);
  @$pb.TagNumber(12)
  set updatedAt($2.Timestamp value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasUpdatedAt() => $_has(11);
  @$pb.TagNumber(12)
  void clearUpdatedAt() => $_clearField(12);
  @$pb.TagNumber(12)
  $2.Timestamp ensureUpdatedAt() => $_ensure(11);
}

/// ContextEdge is one directed relationship between two nodes. `rel`
/// values the sidecar recognises today:
///   imports | calls | contains | dependsOn | relatedTo
///   conflictsWith | coAccessedWith | supersedes | tagged
/// Additional rels can be added without a proto bump — the UI renders
/// unknown rels as a plain chip labelled with the string.
class ContextEdge extends $pb.GeneratedMessage {
  factory ContextEdge({
    $core.String? id,
    $core.String? repoId,
    $core.String? srcNodeId,
    $core.String? dstNodeId,
    $core.String? rel,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? attrs,
    $2.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (repoId != null) result.repoId = repoId;
    if (srcNodeId != null) result.srcNodeId = srcNodeId;
    if (dstNodeId != null) result.dstNodeId = dstNodeId;
    if (rel != null) result.rel = rel;
    if (attrs != null) result.attrs.addEntries(attrs);
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  ContextEdge._();

  factory ContextEdge.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextEdge.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextEdge',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'repoId')
    ..aOS(3, _omitFieldNames ? '' : 'srcNodeId')
    ..aOS(4, _omitFieldNames ? '' : 'dstNodeId')
    ..aOS(5, _omitFieldNames ? '' : 'rel')
    ..m<$core.String, $core.String>(6, _omitFieldNames ? '' : 'attrs',
        entryClassName: 'ContextEdge.AttrsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..aOM<$2.Timestamp>(7, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextEdge clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextEdge copyWith(void Function(ContextEdge) updates) =>
      super.copyWith((message) => updates(message as ContextEdge))
          as ContextEdge;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextEdge create() => ContextEdge._();
  @$core.override
  ContextEdge createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextEdge getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextEdge>(create);
  static ContextEdge? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get repoId => $_getSZ(1);
  @$pb.TagNumber(2)
  set repoId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepoId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepoId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get srcNodeId => $_getSZ(2);
  @$pb.TagNumber(3)
  set srcNodeId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSrcNodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSrcNodeId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get dstNodeId => $_getSZ(3);
  @$pb.TagNumber(4)
  set dstNodeId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDstNodeId() => $_has(3);
  @$pb.TagNumber(4)
  void clearDstNodeId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get rel => $_getSZ(4);
  @$pb.TagNumber(5)
  set rel($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRel() => $_has(4);
  @$pb.TagNumber(5)
  void clearRel() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbMap<$core.String, $core.String> get attrs => $_getMap(5);

  @$pb.TagNumber(7)
  $2.Timestamp get createdAt => $_getN(6);
  @$pb.TagNumber(7)
  set createdAt($2.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.Timestamp ensureCreatedAt() => $_ensure(6);
}

/// ContextFact is a bi-temporal predicate anchored on a subject node.
/// valid_from / valid_to bracket the wall-clock interval during which
/// the fact is considered true; valid_to nil means "still active".
/// `supersedes` links to the id of the fact this one replaces so the
/// Facts Timeline can render succession chains (e.g. "SendGrid → Resend").
class ContextFact extends $pb.GeneratedMessage {
  factory ContextFact({
    $core.String? id,
    $core.String? repoId,
    $core.String? subjectNodeId,
    $core.String? predicate,
    $core.String? objectText,
    $2.Timestamp? validFrom,
    $2.Timestamp? validTo,
    $core.String? supersedes,
    $2.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (repoId != null) result.repoId = repoId;
    if (subjectNodeId != null) result.subjectNodeId = subjectNodeId;
    if (predicate != null) result.predicate = predicate;
    if (objectText != null) result.objectText = objectText;
    if (validFrom != null) result.validFrom = validFrom;
    if (validTo != null) result.validTo = validTo;
    if (supersedes != null) result.supersedes = supersedes;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  ContextFact._();

  factory ContextFact.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextFact.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextFact',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'repoId')
    ..aOS(3, _omitFieldNames ? '' : 'subjectNodeId')
    ..aOS(4, _omitFieldNames ? '' : 'predicate')
    ..aOS(5, _omitFieldNames ? '' : 'objectText')
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'validFrom',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(7, _omitFieldNames ? '' : 'validTo',
        subBuilder: $2.Timestamp.create)
    ..aOS(8, _omitFieldNames ? '' : 'supersedes')
    ..aOM<$2.Timestamp>(9, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextFact clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextFact copyWith(void Function(ContextFact) updates) =>
      super.copyWith((message) => updates(message as ContextFact))
          as ContextFact;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextFact create() => ContextFact._();
  @$core.override
  ContextFact createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextFact getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextFact>(create);
  static ContextFact? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get repoId => $_getSZ(1);
  @$pb.TagNumber(2)
  set repoId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepoId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepoId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get subjectNodeId => $_getSZ(2);
  @$pb.TagNumber(3)
  set subjectNodeId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubjectNodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubjectNodeId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get predicate => $_getSZ(3);
  @$pb.TagNumber(4)
  set predicate($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPredicate() => $_has(3);
  @$pb.TagNumber(4)
  void clearPredicate() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get objectText => $_getSZ(4);
  @$pb.TagNumber(5)
  set objectText($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasObjectText() => $_has(4);
  @$pb.TagNumber(5)
  void clearObjectText() => $_clearField(5);

  @$pb.TagNumber(6)
  $2.Timestamp get validFrom => $_getN(5);
  @$pb.TagNumber(6)
  set validFrom($2.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasValidFrom() => $_has(5);
  @$pb.TagNumber(6)
  void clearValidFrom() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Timestamp ensureValidFrom() => $_ensure(5);

  @$pb.TagNumber(7)
  $2.Timestamp get validTo => $_getN(6);
  @$pb.TagNumber(7)
  set validTo($2.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasValidTo() => $_has(6);
  @$pb.TagNumber(7)
  void clearValidTo() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.Timestamp ensureValidTo() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.String get supersedes => $_getSZ(7);
  @$pb.TagNumber(8)
  set supersedes($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSupersedes() => $_has(7);
  @$pb.TagNumber(8)
  void clearSupersedes() => $_clearField(8);

  @$pb.TagNumber(9)
  $2.Timestamp get createdAt => $_getN(8);
  @$pb.TagNumber(9)
  set createdAt($2.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $2.Timestamp ensureCreatedAt() => $_ensure(8);
}

/// ContextNodeDetail is the full-fidelity payload returned by GetNode.
/// Neighbors is the 1-hop closure of the node (both in- and out-edges
/// resolved to ContextNode summaries) so the detail pane does not need
/// a second round-trip to render "related items".
class ContextNodeDetail extends $pb.GeneratedMessage {
  factory ContextNodeDetail({
    ContextNode? node,
    $core.Iterable<ContextEdge>? outEdges,
    $core.Iterable<ContextEdge>? inEdges,
    $core.Iterable<ContextNode>? neighbors,
    $core.Iterable<ContextFact>? facts,
    $core.String? sourceTaskId,
    $core.String? sourceSessionId,
  }) {
    final result = create();
    if (node != null) result.node = node;
    if (outEdges != null) result.outEdges.addAll(outEdges);
    if (inEdges != null) result.inEdges.addAll(inEdges);
    if (neighbors != null) result.neighbors.addAll(neighbors);
    if (facts != null) result.facts.addAll(facts);
    if (sourceTaskId != null) result.sourceTaskId = sourceTaskId;
    if (sourceSessionId != null) result.sourceSessionId = sourceSessionId;
    return result;
  }

  ContextNodeDetail._();

  factory ContextNodeDetail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextNodeDetail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextNodeDetail',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOM<ContextNode>(1, _omitFieldNames ? '' : 'node',
        subBuilder: ContextNode.create)
    ..pPM<ContextEdge>(2, _omitFieldNames ? '' : 'outEdges',
        subBuilder: ContextEdge.create)
    ..pPM<ContextEdge>(3, _omitFieldNames ? '' : 'inEdges',
        subBuilder: ContextEdge.create)
    ..pPM<ContextNode>(4, _omitFieldNames ? '' : 'neighbors',
        subBuilder: ContextNode.create)
    ..pPM<ContextFact>(5, _omitFieldNames ? '' : 'facts',
        subBuilder: ContextFact.create)
    ..aOS(6, _omitFieldNames ? '' : 'sourceTaskId')
    ..aOS(7, _omitFieldNames ? '' : 'sourceSessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextNodeDetail clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextNodeDetail copyWith(void Function(ContextNodeDetail) updates) =>
      super.copyWith((message) => updates(message as ContextNodeDetail))
          as ContextNodeDetail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextNodeDetail create() => ContextNodeDetail._();
  @$core.override
  ContextNodeDetail createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextNodeDetail getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextNodeDetail>(create);
  static ContextNodeDetail? _defaultInstance;

  @$pb.TagNumber(1)
  ContextNode get node => $_getN(0);
  @$pb.TagNumber(1)
  set node(ContextNode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNode() => $_has(0);
  @$pb.TagNumber(1)
  void clearNode() => $_clearField(1);
  @$pb.TagNumber(1)
  ContextNode ensureNode() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<ContextEdge> get outEdges => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<ContextEdge> get inEdges => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<ContextNode> get neighbors => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<ContextFact> get facts => $_getList(4);

  /// Provenance — which session / task introduced this node. Empty when
  /// source_kind == manual.
  @$pb.TagNumber(6)
  $core.String get sourceTaskId => $_getSZ(5);
  @$pb.TagNumber(6)
  set sourceTaskId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSourceTaskId() => $_has(5);
  @$pb.TagNumber(6)
  void clearSourceTaskId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get sourceSessionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set sourceSessionId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSourceSessionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearSourceSessionId() => $_clearField(7);
}

/// ContextOverview is the Overview tab's aggregate view. Counts are
/// filtered by repo_id. byte_size fields approximate on-disk storage
/// for the Overview storage card (vectors dominate).
class ContextOverview extends $pb.GeneratedMessage {
  factory ContextOverview({
    $core.String? repoId,
    $core.Iterable<$core.MapEntry<$core.String, $core.int>>? nodeCountsByKind,
    $core.Iterable<$core.MapEntry<$core.String, $core.int>>? edgeCountsByRel,
    $core.int? activeFactCount,
    $core.int? expiredFactCount,
    $core.int? pendingScratchpadCount,
    $core.int? promotedScratchpadCount,
    $core.int? rejectedScratchpadCount,
    $core.int? vectorCount,
    $core.int? vectorDim,
    $fixnum.Int64? vectorBytes,
    $core.int? observedSessionCount,
    $core.bool? enabled,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (nodeCountsByKind != null)
      result.nodeCountsByKind.addEntries(nodeCountsByKind);
    if (edgeCountsByRel != null)
      result.edgeCountsByRel.addEntries(edgeCountsByRel);
    if (activeFactCount != null) result.activeFactCount = activeFactCount;
    if (expiredFactCount != null) result.expiredFactCount = expiredFactCount;
    if (pendingScratchpadCount != null)
      result.pendingScratchpadCount = pendingScratchpadCount;
    if (promotedScratchpadCount != null)
      result.promotedScratchpadCount = promotedScratchpadCount;
    if (rejectedScratchpadCount != null)
      result.rejectedScratchpadCount = rejectedScratchpadCount;
    if (vectorCount != null) result.vectorCount = vectorCount;
    if (vectorDim != null) result.vectorDim = vectorDim;
    if (vectorBytes != null) result.vectorBytes = vectorBytes;
    if (observedSessionCount != null)
      result.observedSessionCount = observedSessionCount;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  ContextOverview._();

  factory ContextOverview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextOverview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextOverview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..m<$core.String, $core.int>(2, _omitFieldNames ? '' : 'nodeCountsByKind',
        entryClassName: 'ContextOverview.NodeCountsByKindEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O3,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..m<$core.String, $core.int>(3, _omitFieldNames ? '' : 'edgeCountsByRel',
        entryClassName: 'ContextOverview.EdgeCountsByRelEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O3,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..aI(4, _omitFieldNames ? '' : 'activeFactCount')
    ..aI(5, _omitFieldNames ? '' : 'expiredFactCount')
    ..aI(6, _omitFieldNames ? '' : 'pendingScratchpadCount')
    ..aI(7, _omitFieldNames ? '' : 'promotedScratchpadCount')
    ..aI(8, _omitFieldNames ? '' : 'rejectedScratchpadCount')
    ..aI(9, _omitFieldNames ? '' : 'vectorCount')
    ..aI(10, _omitFieldNames ? '' : 'vectorDim')
    ..aInt64(11, _omitFieldNames ? '' : 'vectorBytes')
    ..aI(12, _omitFieldNames ? '' : 'observedSessionCount')
    ..aOB(13, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextOverview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextOverview copyWith(void Function(ContextOverview) updates) =>
      super.copyWith((message) => updates(message as ContextOverview))
          as ContextOverview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextOverview create() => ContextOverview._();
  @$core.override
  ContextOverview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextOverview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextOverview>(create);
  static ContextOverview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  /// Per-kind node counts, keyed by kind string (e.g. "File", "Concept").
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.int> get nodeCountsByKind => $_getMap(1);

  /// Per-rel edge counts, keyed by rel string (e.g. "imports", "calls").
  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.int> get edgeCountsByRel => $_getMap(2);

  @$pb.TagNumber(4)
  $core.int get activeFactCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set activeFactCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActiveFactCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearActiveFactCount() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get expiredFactCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set expiredFactCount($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExpiredFactCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpiredFactCount() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get pendingScratchpadCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set pendingScratchpadCount($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPendingScratchpadCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearPendingScratchpadCount() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get promotedScratchpadCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set promotedScratchpadCount($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPromotedScratchpadCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearPromotedScratchpadCount() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get rejectedScratchpadCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set rejectedScratchpadCount($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRejectedScratchpadCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearRejectedScratchpadCount() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get vectorCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set vectorCount($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasVectorCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearVectorCount() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get vectorDim => $_getIZ(9);
  @$pb.TagNumber(10)
  set vectorDim($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasVectorDim() => $_has(9);
  @$pb.TagNumber(10)
  void clearVectorDim() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get vectorBytes => $_getI64(10);
  @$pb.TagNumber(11)
  set vectorBytes($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasVectorBytes() => $_has(10);
  @$pb.TagNumber(11)
  void clearVectorBytes() => $_clearField(11);

  /// Number of tasks / sessions the observer has processed for this
  /// repo. Surfaced in the Overview as "28 sessions of learning".
  @$pb.TagNumber(12)
  $core.int get observedSessionCount => $_getIZ(11);
  @$pb.TagNumber(12)
  set observedSessionCount($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasObservedSessionCount() => $_has(11);
  @$pb.TagNumber(12)
  void clearObservedSessionCount() => $_clearField(12);

  /// Whether memory is currently enabled for this repo — mirrors
  /// MemorySettings.enabled so the Overview card does not need a
  /// second call.
  @$pb.TagNumber(13)
  $core.bool get enabled => $_getBF(12);
  @$pb.TagNumber(13)
  set enabled($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasEnabled() => $_has(12);
  @$pb.TagNumber(13)
  void clearEnabled() => $_clearField(13);
}

class RepoIdRequest extends $pb.GeneratedMessage {
  factory RepoIdRequest({
    $core.String? repoId,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    return result;
  }

  RepoIdRequest._();

  factory RepoIdRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RepoIdRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RepoIdRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RepoIdRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RepoIdRequest copyWith(void Function(RepoIdRequest) updates) =>
      super.copyWith((message) => updates(message as RepoIdRequest))
          as RepoIdRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RepoIdRequest create() => RepoIdRequest._();
  @$core.override
  RepoIdRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RepoIdRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RepoIdRequest>(create);
  static RepoIdRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);
}

class NodeIdRequest extends $pb.GeneratedMessage {
  factory NodeIdRequest({
    $core.String? nodeId,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    return result;
  }

  NodeIdRequest._();

  factory NodeIdRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NodeIdRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeIdRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeIdRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeIdRequest copyWith(void Function(NodeIdRequest) updates) =>
      super.copyWith((message) => updates(message as NodeIdRequest))
          as NodeIdRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NodeIdRequest create() => NodeIdRequest._();
  @$core.override
  NodeIdRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NodeIdRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeIdRequest>(create);
  static NodeIdRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);
}

class EdgeIdRequest extends $pb.GeneratedMessage {
  factory EdgeIdRequest({
    $core.String? edgeId,
  }) {
    final result = create();
    if (edgeId != null) result.edgeId = edgeId;
    return result;
  }

  EdgeIdRequest._();

  factory EdgeIdRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EdgeIdRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EdgeIdRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'edgeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EdgeIdRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EdgeIdRequest copyWith(void Function(EdgeIdRequest) updates) =>
      super.copyWith((message) => updates(message as EdgeIdRequest))
          as EdgeIdRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EdgeIdRequest create() => EdgeIdRequest._();
  @$core.override
  EdgeIdRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EdgeIdRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EdgeIdRequest>(create);
  static EdgeIdRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get edgeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set edgeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEdgeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEdgeId() => $_clearField(1);
}

class EntryIdRequest extends $pb.GeneratedMessage {
  factory EntryIdRequest({
    $core.String? entryId,
  }) {
    final result = create();
    if (entryId != null) result.entryId = entryId;
    return result;
  }

  EntryIdRequest._();

  factory EntryIdRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EntryIdRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EntryIdRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'entryId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntryIdRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EntryIdRequest copyWith(void Function(EntryIdRequest) updates) =>
      super.copyWith((message) => updates(message as EntryIdRequest))
          as EntryIdRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EntryIdRequest create() => EntryIdRequest._();
  @$core.override
  EntryIdRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EntryIdRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EntryIdRequest>(create);
  static EntryIdRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set entryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntryId() => $_clearField(1);
}

class SearchContextRequest extends $pb.GeneratedMessage {
  factory SearchContextRequest({
    $core.String? repoId,
    $core.String? query,
    $core.String? mode,
    $core.int? limit,
    $core.Iterable<$core.String>? kinds,
    $core.bool? onlyEnabled,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (query != null) result.query = query;
    if (mode != null) result.mode = mode;
    if (limit != null) result.limit = limit;
    if (kinds != null) result.kinds.addAll(kinds);
    if (onlyEnabled != null) result.onlyEnabled = onlyEnabled;
    return result;
  }

  SearchContextRequest._();

  factory SearchContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchContextRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOS(2, _omitFieldNames ? '' : 'query')
    ..aOS(3, _omitFieldNames ? '' : 'mode')
    ..aI(4, _omitFieldNames ? '' : 'limit')
    ..pPS(5, _omitFieldNames ? '' : 'kinds')
    ..aOB(6, _omitFieldNames ? '' : 'onlyEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchContextRequest copyWith(void Function(SearchContextRequest) updates) =>
      super.copyWith((message) => updates(message as SearchContextRequest))
          as SearchContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchContextRequest create() => SearchContextRequest._();
  @$core.override
  SearchContextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchContextRequest>(create);
  static SearchContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => $_clearField(2);

  /// Which retrieval channel(s) to return. Fused is the default and
  /// represents the production hybrid pipeline; the other three are
  /// exposed so the Search tab can show why results differ (debug
  /// view). Empty → all four populated.
  ///   "semantic" | "keyword" | "fused" | "all"
  @$pb.TagNumber(3)
  $core.String get mode => $_getSZ(2);
  @$pb.TagNumber(3)
  set mode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMode() => $_clearField(3);

  /// Limit per channel. 0 → server default (20).
  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);

  /// Optional filter on node kind (AND across entries).
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get kinds => $_getList(4);

  /// Optional filter on enabled flag. Unset → include both.
  @$pb.TagNumber(6)
  $core.bool get onlyEnabled => $_getBF(5);
  @$pb.TagNumber(6)
  set onlyEnabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOnlyEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearOnlyEnabled() => $_clearField(6);
}

/// SearchHit is one result with its channel-specific score and the
/// reason it surfaced (for the debug / trust view).
class SearchHit extends $pb.GeneratedMessage {
  factory SearchHit({
    ContextNode? node,
    $core.double? score,
    $core.int? rank,
    $core.String? channel,
    $core.String? reason,
  }) {
    final result = create();
    if (node != null) result.node = node;
    if (score != null) result.score = score;
    if (rank != null) result.rank = rank;
    if (channel != null) result.channel = channel;
    if (reason != null) result.reason = reason;
    return result;
  }

  SearchHit._();

  factory SearchHit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchHit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchHit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOM<ContextNode>(1, _omitFieldNames ? '' : 'node',
        subBuilder: ContextNode.create)
    ..aD(2, _omitFieldNames ? '' : 'score', fieldType: $pb.PbFieldType.OF)
    ..aI(3, _omitFieldNames ? '' : 'rank')
    ..aOS(4, _omitFieldNames ? '' : 'channel')
    ..aOS(5, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchHit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchHit copyWith(void Function(SearchHit) updates) =>
      super.copyWith((message) => updates(message as SearchHit)) as SearchHit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchHit create() => SearchHit._();
  @$core.override
  SearchHit createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchHit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchHit>(create);
  static SearchHit? _defaultInstance;

  @$pb.TagNumber(1)
  ContextNode get node => $_getN(0);
  @$pb.TagNumber(1)
  set node(ContextNode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNode() => $_has(0);
  @$pb.TagNumber(1)
  void clearNode() => $_clearField(1);
  @$pb.TagNumber(1)
  ContextNode ensureNode() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.double get score => $_getN(1);
  @$pb.TagNumber(2)
  set score($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasScore() => $_has(1);
  @$pb.TagNumber(2)
  void clearScore() => $_clearField(2);

  /// Best rank across channels (1-based). 0 when the node was only
  /// introduced via graph-neighborhood boost.
  @$pb.TagNumber(3)
  $core.int get rank => $_getIZ(2);
  @$pb.TagNumber(3)
  set rank($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRank() => $_has(2);
  @$pb.TagNumber(3)
  void clearRank() => $_clearField(3);

  /// "semantic" | "keyword" | "graph-boost" | "fused"
  @$pb.TagNumber(4)
  $core.String get channel => $_getSZ(3);
  @$pb.TagNumber(4)
  set channel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChannel() => $_has(3);
  @$pb.TagNumber(4)
  void clearChannel() => $_clearField(4);

  /// Free-form reason for debug UI ("matched 'auth' in label",
  /// "cosine 0.83 against query embedding", "1-hop from decision-08").
  @$pb.TagNumber(5)
  $core.String get reason => $_getSZ(4);
  @$pb.TagNumber(5)
  set reason($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReason() => $_has(4);
  @$pb.TagNumber(5)
  void clearReason() => $_clearField(5);
}

class SearchContextResponse extends $pb.GeneratedMessage {
  factory SearchContextResponse({
    $core.Iterable<$core.MapEntry<$core.String, SearchHitList>>? channels,
    $core.int? totalUnique,
  }) {
    final result = create();
    if (channels != null) result.channels.addEntries(channels);
    if (totalUnique != null) result.totalUnique = totalUnique;
    return result;
  }

  SearchContextResponse._();

  factory SearchContextResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchContextResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchContextResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..m<$core.String, SearchHitList>(1, _omitFieldNames ? '' : 'channels',
        entryClassName: 'SearchContextResponse.ChannelsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: SearchHitList.create,
        valueDefaultOrMaker: SearchHitList.getDefault,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..aI(2, _omitFieldNames ? '' : 'totalUnique')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchContextResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchContextResponse copyWith(
          void Function(SearchContextResponse) updates) =>
      super.copyWith((message) => updates(message as SearchContextResponse))
          as SearchContextResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchContextResponse create() => SearchContextResponse._();
  @$core.override
  SearchContextResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchContextResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchContextResponse>(create);
  static SearchContextResponse? _defaultInstance;

  /// One bucket per channel requested. Channel string mirrors
  /// SearchHit.channel so callers can pattern-match.
  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, SearchHitList> get channels => $_getMap(0);

  /// Total unique nodes across all channels (the Fused bucket's
  /// deduplicated count after RRF).
  @$pb.TagNumber(2)
  $core.int get totalUnique => $_getIZ(1);
  @$pb.TagNumber(2)
  set totalUnique($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalUnique() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalUnique() => $_clearField(2);
}

class SearchHitList extends $pb.GeneratedMessage {
  factory SearchHitList({
    $core.Iterable<SearchHit>? hits,
  }) {
    final result = create();
    if (hits != null) result.hits.addAll(hits);
    return result;
  }

  SearchHitList._();

  factory SearchHitList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchHitList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchHitList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<SearchHit>(1, _omitFieldNames ? '' : 'hits',
        subBuilder: SearchHit.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchHitList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchHitList copyWith(void Function(SearchHitList) updates) =>
      super.copyWith((message) => updates(message as SearchHitList))
          as SearchHitList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchHitList create() => SearchHitList._();
  @$core.override
  SearchHitList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchHitList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchHitList>(create);
  static SearchHitList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SearchHit> get hits => $_getList(0);
}

class ListNodesRequest extends $pb.GeneratedMessage {
  factory ListNodesRequest({
    $core.String? repoId,
    $core.Iterable<$core.String>? kinds,
    $core.int? limit,
    $core.int? offset,
    $core.String? sort,
    $core.Iterable<$core.String>? sourceKinds,
    $core.String? labelContains,
    $core.int? pinnedFilter,
    $core.int? enabledFilter,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (kinds != null) result.kinds.addAll(kinds);
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    if (sort != null) result.sort = sort;
    if (sourceKinds != null) result.sourceKinds.addAll(sourceKinds);
    if (labelContains != null) result.labelContains = labelContains;
    if (pinnedFilter != null) result.pinnedFilter = pinnedFilter;
    if (enabledFilter != null) result.enabledFilter = enabledFilter;
    return result;
  }

  ListNodesRequest._();

  factory ListNodesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListNodesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNodesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..pPS(2, _omitFieldNames ? '' : 'kinds')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..aI(4, _omitFieldNames ? '' : 'offset')
    ..aOS(5, _omitFieldNames ? '' : 'sort')
    ..pPS(6, _omitFieldNames ? '' : 'sourceKinds')
    ..aOS(7, _omitFieldNames ? '' : 'labelContains')
    ..aI(8, _omitFieldNames ? '' : 'pinnedFilter')
    ..aI(9, _omitFieldNames ? '' : 'enabledFilter')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesRequest copyWith(void Function(ListNodesRequest) updates) =>
      super.copyWith((message) => updates(message as ListNodesRequest))
          as ListNodesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListNodesRequest create() => ListNodesRequest._();
  @$core.override
  ListNodesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListNodesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNodesRequest>(create);
  static ListNodesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  /// Optional filter — empty = all kinds.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get kinds => $_getList(1);

  /// Optional pagination. 0 → server default (200).
  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);

  /// Sort: "updated_at" (default, desc) | "label" (asc) | "confidence" (desc)
  @$pb.TagNumber(5)
  $core.String get sort => $_getSZ(4);
  @$pb.TagNumber(5)
  set sort($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSort() => $_has(4);
  @$pb.TagNumber(5)
  void clearSort() => $_clearField(5);

  /// Optional filter on source_kind.
  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get sourceKinds => $_getList(5);

  /// When set, only nodes that include the substring in label OR
  /// content_md are returned. Use SearchContext for ranked search;
  /// this is for simple Browse-tab filtering.
  @$pb.TagNumber(7)
  $core.String get labelContains => $_getSZ(6);
  @$pb.TagNumber(7)
  set labelContains($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLabelContains() => $_has(6);
  @$pb.TagNumber(7)
  void clearLabelContains() => $_clearField(7);

  /// Filter on pinned / enabled flags. Unset → include both.
  /// Tri-state encoded via int32: 0=either, 1=only true, 2=only false.
  @$pb.TagNumber(8)
  $core.int get pinnedFilter => $_getIZ(7);
  @$pb.TagNumber(8)
  set pinnedFilter($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPinnedFilter() => $_has(7);
  @$pb.TagNumber(8)
  void clearPinnedFilter() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get enabledFilter => $_getIZ(8);
  @$pb.TagNumber(9)
  set enabledFilter($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasEnabledFilter() => $_has(8);
  @$pb.TagNumber(9)
  void clearEnabledFilter() => $_clearField(9);
}

class ListNodesResponse extends $pb.GeneratedMessage {
  factory ListNodesResponse({
    $core.Iterable<ContextNode>? nodes,
    $core.int? total,
  }) {
    final result = create();
    if (nodes != null) result.nodes.addAll(nodes);
    if (total != null) result.total = total;
    return result;
  }

  ListNodesResponse._();

  factory ListNodesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListNodesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListNodesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<ContextNode>(1, _omitFieldNames ? '' : 'nodes',
        subBuilder: ContextNode.create)
    ..aI(2, _omitFieldNames ? '' : 'total')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListNodesResponse copyWith(void Function(ListNodesResponse) updates) =>
      super.copyWith((message) => updates(message as ListNodesResponse))
          as ListNodesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListNodesResponse create() => ListNodesResponse._();
  @$core.override
  ListNodesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListNodesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListNodesResponse>(create);
  static ListNodesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ContextNode> get nodes => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);
}

class CreateNodeRequest extends $pb.GeneratedMessage {
  factory CreateNodeRequest({
    $core.String? repoId,
    $core.String? kind,
    $core.String? label,
    $core.String? contentMd,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? attrs,
    $core.String? sourceKind,
    $core.double? confidence,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (kind != null) result.kind = kind;
    if (label != null) result.label = label;
    if (contentMd != null) result.contentMd = contentMd;
    if (attrs != null) result.attrs.addEntries(attrs);
    if (sourceKind != null) result.sourceKind = sourceKind;
    if (confidence != null) result.confidence = confidence;
    return result;
  }

  CreateNodeRequest._();

  factory CreateNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateNodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'contentMd')
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'attrs',
        entryClassName: 'CreateNodeRequest.AttrsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..aOS(6, _omitFieldNames ? '' : 'sourceKind')
    ..aD(7, _omitFieldNames ? '' : 'confidence', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateNodeRequest copyWith(void Function(CreateNodeRequest) updates) =>
      super.copyWith((message) => updates(message as CreateNodeRequest))
          as CreateNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateNodeRequest create() => CreateNodeRequest._();
  @$core.override
  CreateNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateNodeRequest>(create);
  static CreateNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get contentMd => $_getSZ(3);
  @$pb.TagNumber(4)
  set contentMd($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContentMd() => $_has(3);
  @$pb.TagNumber(4)
  void clearContentMd() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get attrs => $_getMap(4);

  /// Defaults to "manual" if omitted — the only legitimate value for
  /// UI-originated creations. Non-manual source_kinds are accepted so
  /// the analyzer / observer can write directly.
  @$pb.TagNumber(6)
  $core.String get sourceKind => $_getSZ(5);
  @$pb.TagNumber(6)
  set sourceKind($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSourceKind() => $_has(5);
  @$pb.TagNumber(6)
  void clearSourceKind() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get confidence => $_getN(6);
  @$pb.TagNumber(7)
  set confidence($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConfidence() => $_has(6);
  @$pb.TagNumber(7)
  void clearConfidence() => $_clearField(7);
}

class UpdateNodeRequest extends $pb.GeneratedMessage {
  factory UpdateNodeRequest({
    $core.String? nodeId,
    $core.String? label,
    $core.String? contentMd,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? attrs,
    $core.int? enabledOp,
    $core.int? pinnedOp,
    $core.double? confidence,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (label != null) result.label = label;
    if (contentMd != null) result.contentMd = contentMd;
    if (attrs != null) result.attrs.addEntries(attrs);
    if (enabledOp != null) result.enabledOp = enabledOp;
    if (pinnedOp != null) result.pinnedOp = pinnedOp;
    if (confidence != null) result.confidence = confidence;
    return result;
  }

  UpdateNodeRequest._();

  factory UpdateNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateNodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'contentMd')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'attrs',
        entryClassName: 'UpdateNodeRequest.AttrsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..aI(5, _omitFieldNames ? '' : 'enabledOp')
    ..aI(6, _omitFieldNames ? '' : 'pinnedOp')
    ..aD(7, _omitFieldNames ? '' : 'confidence', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNodeRequest copyWith(void Function(UpdateNodeRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateNodeRequest))
          as UpdateNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateNodeRequest create() => UpdateNodeRequest._();
  @$core.override
  UpdateNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateNodeRequest>(create);
  static UpdateNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  /// Only non-empty string fields and explicitly-set oneof fields are
  /// applied. Encoding "clear this field" for optional strings would
  /// require wrappers; keep semantics simple by rejecting empty label
  /// updates (UpdateNode with empty label → InvalidArgument).
  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get contentMd => $_getSZ(2);
  @$pb.TagNumber(3)
  set contentMd($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContentMd() => $_has(2);
  @$pb.TagNumber(3)
  void clearContentMd() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.String> get attrs => $_getMap(3);

  /// Tri-state: 0=unchanged, 1=enable, 2=disable. Same shape for pinned.
  @$pb.TagNumber(5)
  $core.int get enabledOp => $_getIZ(4);
  @$pb.TagNumber(5)
  set enabledOp($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnabledOp() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnabledOp() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get pinnedOp => $_getIZ(5);
  @$pb.TagNumber(6)
  set pinnedOp($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPinnedOp() => $_has(5);
  @$pb.TagNumber(6)
  void clearPinnedOp() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get confidence => $_getN(6);
  @$pb.TagNumber(7)
  set confidence($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConfidence() => $_has(6);
  @$pb.TagNumber(7)
  void clearConfidence() => $_clearField(7);
}

class PinNodeRequest extends $pb.GeneratedMessage {
  factory PinNodeRequest({
    $core.String? nodeId,
    $core.bool? pinned,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (pinned != null) result.pinned = pinned;
    return result;
  }

  PinNodeRequest._();

  factory PinNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PinNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PinNodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOB(2, _omitFieldNames ? '' : 'pinned')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PinNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PinNodeRequest copyWith(void Function(PinNodeRequest) updates) =>
      super.copyWith((message) => updates(message as PinNodeRequest))
          as PinNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PinNodeRequest create() => PinNodeRequest._();
  @$core.override
  PinNodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PinNodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PinNodeRequest>(create);
  static PinNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get pinned => $_getBF(1);
  @$pb.TagNumber(2)
  set pinned($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPinned() => $_has(1);
  @$pb.TagNumber(2)
  void clearPinned() => $_clearField(2);
}

class ListEdgesRequest extends $pb.GeneratedMessage {
  factory ListEdgesRequest({
    $core.String? repoId,
    $core.String? nodeId,
    $core.Iterable<$core.String>? rels,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (nodeId != null) result.nodeId = nodeId;
    if (rels != null) result.rels.addAll(rels);
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ListEdgesRequest._();

  factory ListEdgesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEdgesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEdgesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOS(2, _omitFieldNames ? '' : 'nodeId')
    ..pPS(3, _omitFieldNames ? '' : 'rels')
    ..aI(4, _omitFieldNames ? '' : 'limit')
    ..aI(5, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEdgesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEdgesRequest copyWith(void Function(ListEdgesRequest) updates) =>
      super.copyWith((message) => updates(message as ListEdgesRequest))
          as ListEdgesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEdgesRequest create() => ListEdgesRequest._();
  @$core.override
  ListEdgesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEdgesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEdgesRequest>(create);
  static ListEdgesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  /// Optional: only edges incident to this node (either direction).
  @$pb.TagNumber(2)
  $core.String get nodeId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nodeId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodeId() => $_clearField(2);

  /// Optional filter on rel string.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get rels => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get offset => $_getIZ(4);
  @$pb.TagNumber(5)
  set offset($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearOffset() => $_clearField(5);
}

class ListEdgesResponse extends $pb.GeneratedMessage {
  factory ListEdgesResponse({
    $core.Iterable<ContextEdge>? edges,
    $core.int? total,
  }) {
    final result = create();
    if (edges != null) result.edges.addAll(edges);
    if (total != null) result.total = total;
    return result;
  }

  ListEdgesResponse._();

  factory ListEdgesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEdgesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEdgesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<ContextEdge>(1, _omitFieldNames ? '' : 'edges',
        subBuilder: ContextEdge.create)
    ..aI(2, _omitFieldNames ? '' : 'total')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEdgesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEdgesResponse copyWith(void Function(ListEdgesResponse) updates) =>
      super.copyWith((message) => updates(message as ListEdgesResponse))
          as ListEdgesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEdgesResponse create() => ListEdgesResponse._();
  @$core.override
  ListEdgesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEdgesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEdgesResponse>(create);
  static ListEdgesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ContextEdge> get edges => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);
}

class CreateEdgeRequest extends $pb.GeneratedMessage {
  factory CreateEdgeRequest({
    $core.String? repoId,
    $core.String? srcNodeId,
    $core.String? dstNodeId,
    $core.String? rel,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? attrs,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (srcNodeId != null) result.srcNodeId = srcNodeId;
    if (dstNodeId != null) result.dstNodeId = dstNodeId;
    if (rel != null) result.rel = rel;
    if (attrs != null) result.attrs.addEntries(attrs);
    return result;
  }

  CreateEdgeRequest._();

  factory CreateEdgeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateEdgeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateEdgeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOS(2, _omitFieldNames ? '' : 'srcNodeId')
    ..aOS(3, _omitFieldNames ? '' : 'dstNodeId')
    ..aOS(4, _omitFieldNames ? '' : 'rel')
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'attrs',
        entryClassName: 'CreateEdgeRequest.AttrsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateEdgeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateEdgeRequest copyWith(void Function(CreateEdgeRequest) updates) =>
      super.copyWith((message) => updates(message as CreateEdgeRequest))
          as CreateEdgeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateEdgeRequest create() => CreateEdgeRequest._();
  @$core.override
  CreateEdgeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateEdgeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateEdgeRequest>(create);
  static CreateEdgeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get srcNodeId => $_getSZ(1);
  @$pb.TagNumber(2)
  set srcNodeId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSrcNodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSrcNodeId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get dstNodeId => $_getSZ(2);
  @$pb.TagNumber(3)
  set dstNodeId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDstNodeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDstNodeId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get rel => $_getSZ(3);
  @$pb.TagNumber(4)
  set rel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRel() => $_has(3);
  @$pb.TagNumber(4)
  void clearRel() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get attrs => $_getMap(4);
}

class ListFactsRequest extends $pb.GeneratedMessage {
  factory ListFactsRequest({
    $core.String? repoId,
    $core.String? subjectNodeId,
    $core.bool? includeExpired,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (subjectNodeId != null) result.subjectNodeId = subjectNodeId;
    if (includeExpired != null) result.includeExpired = includeExpired;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ListFactsRequest._();

  factory ListFactsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListFactsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFactsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOS(2, _omitFieldNames ? '' : 'subjectNodeId')
    ..aOB(3, _omitFieldNames ? '' : 'includeExpired')
    ..aI(4, _omitFieldNames ? '' : 'limit')
    ..aI(5, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFactsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFactsRequest copyWith(void Function(ListFactsRequest) updates) =>
      super.copyWith((message) => updates(message as ListFactsRequest))
          as ListFactsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListFactsRequest create() => ListFactsRequest._();
  @$core.override
  ListFactsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListFactsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFactsRequest>(create);
  static ListFactsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  /// Optional filter — only facts for this subject node.
  @$pb.TagNumber(2)
  $core.String get subjectNodeId => $_getSZ(1);
  @$pb.TagNumber(2)
  set subjectNodeId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubjectNodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubjectNodeId() => $_clearField(2);

  /// When true, include facts whose valid_to is in the past. Defaults
  /// to false (only currently-active facts).
  @$pb.TagNumber(3)
  $core.bool get includeExpired => $_getBF(2);
  @$pb.TagNumber(3)
  set includeExpired($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIncludeExpired() => $_has(2);
  @$pb.TagNumber(3)
  void clearIncludeExpired() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get offset => $_getIZ(4);
  @$pb.TagNumber(5)
  set offset($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearOffset() => $_clearField(5);
}

class ListFactsResponse extends $pb.GeneratedMessage {
  factory ListFactsResponse({
    $core.Iterable<ContextFact>? facts,
    $core.int? total,
  }) {
    final result = create();
    if (facts != null) result.facts.addAll(facts);
    if (total != null) result.total = total;
    return result;
  }

  ListFactsResponse._();

  factory ListFactsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListFactsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFactsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<ContextFact>(1, _omitFieldNames ? '' : 'facts',
        subBuilder: ContextFact.create)
    ..aI(2, _omitFieldNames ? '' : 'total')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFactsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFactsResponse copyWith(void Function(ListFactsResponse) updates) =>
      super.copyWith((message) => updates(message as ListFactsResponse))
          as ListFactsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListFactsResponse create() => ListFactsResponse._();
  @$core.override
  ListFactsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListFactsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFactsResponse>(create);
  static ListFactsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ContextFact> get facts => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);
}

/// InjectionSource lists one memory item that contributed to an
/// injected prompt. source_ref is ContextNode.id or ContextFact.id
/// depending on source_type. Ordering mirrors the Markdown that was
/// rendered, so the UI can display sources as a numbered sidebar.
class InjectionSource extends $pb.GeneratedMessage {
  factory InjectionSource({
    $core.String? sourceType,
    $core.String? sourceRef,
    $core.String? label,
    $core.String? channel,
    $core.int? tokens,
    $core.double? relevance,
  }) {
    final result = create();
    if (sourceType != null) result.sourceType = sourceType;
    if (sourceRef != null) result.sourceRef = sourceRef;
    if (label != null) result.label = label;
    if (channel != null) result.channel = channel;
    if (tokens != null) result.tokens = tokens;
    if (relevance != null) result.relevance = relevance;
    return result;
  }

  InjectionSource._();

  factory InjectionSource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InjectionSource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InjectionSource',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceType')
    ..aOS(2, _omitFieldNames ? '' : 'sourceRef')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'channel')
    ..aI(5, _omitFieldNames ? '' : 'tokens')
    ..aD(6, _omitFieldNames ? '' : 'relevance', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InjectionSource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InjectionSource copyWith(void Function(InjectionSource) updates) =>
      super.copyWith((message) => updates(message as InjectionSource))
          as InjectionSource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InjectionSource create() => InjectionSource._();
  @$core.override
  InjectionSource createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InjectionSource getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InjectionSource>(create);
  static InjectionSource? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceType => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceType($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceType() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sourceRef => $_getSZ(1);
  @$pb.TagNumber(2)
  set sourceRef($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSourceRef() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourceRef() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get channel => $_getSZ(3);
  @$pb.TagNumber(4)
  set channel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChannel() => $_has(3);
  @$pb.TagNumber(4)
  void clearChannel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get tokens => $_getIZ(4);
  @$pb.TagNumber(5)
  set tokens($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTokens() => $_has(4);
  @$pb.TagNumber(5)
  void clearTokens() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get relevance => $_getN(5);
  @$pb.TagNumber(6)
  set relevance($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRelevance() => $_has(5);
  @$pb.TagNumber(6)
  void clearRelevance() => $_clearField(6);
}

class InjectionPreview extends $pb.GeneratedMessage {
  factory InjectionPreview({
    $core.String? systemPrompt,
    $core.Iterable<InjectionSource>? sources,
    $core.int? estimatedTokens,
    $core.String? tier,
  }) {
    final result = create();
    if (systemPrompt != null) result.systemPrompt = systemPrompt;
    if (sources != null) result.sources.addAll(sources);
    if (estimatedTokens != null) result.estimatedTokens = estimatedTokens;
    if (tier != null) result.tier = tier;
    return result;
  }

  InjectionPreview._();

  factory InjectionPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InjectionPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InjectionPreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'systemPrompt')
    ..pPM<InjectionSource>(2, _omitFieldNames ? '' : 'sources',
        subBuilder: InjectionSource.create)
    ..aI(3, _omitFieldNames ? '' : 'estimatedTokens')
    ..aOS(4, _omitFieldNames ? '' : 'tier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InjectionPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InjectionPreview copyWith(void Function(InjectionPreview) updates) =>
      super.copyWith((message) => updates(message as InjectionPreview))
          as InjectionPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InjectionPreview create() => InjectionPreview._();
  @$core.override
  InjectionPreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InjectionPreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InjectionPreview>(create);
  static InjectionPreview? _defaultInstance;

  /// The assembled Markdown block that would be prepended to the
  /// Copilot system prompt. Empty when memory is disabled for the repo.
  @$pb.TagNumber(1)
  $core.String get systemPrompt => $_getSZ(0);
  @$pb.TagNumber(1)
  set systemPrompt($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSystemPrompt() => $_has(0);
  @$pb.TagNumber(1)
  void clearSystemPrompt() => $_clearField(1);

  /// Ordered contributions so the UI can render a sidebar.
  @$pb.TagNumber(2)
  $pb.PbList<InjectionSource> get sources => $_getList(1);

  /// Rough token estimate so the UI can compare against the Passive
  /// budget from MemorySettings.
  @$pb.TagNumber(3)
  $core.int get estimatedTokens => $_getIZ(2);
  @$pb.TagNumber(3)
  set estimatedTokens($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEstimatedTokens() => $_has(2);
  @$pb.TagNumber(3)
  void clearEstimatedTokens() => $_clearField(3);

  /// Injection tier this preview represents.
  /// "passive" | "reactive" | "active"
  @$pb.TagNumber(4)
  $core.String get tier => $_getSZ(3);
  @$pb.TagNumber(4)
  set tier($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTier() => $_has(3);
  @$pb.TagNumber(4)
  void clearTier() => $_clearField(4);
}

class PreviewInjectionRequest extends $pb.GeneratedMessage {
  factory PreviewInjectionRequest({
    $core.String? repoId,
    $core.String? taskId,
    $core.String? rawPrompt,
    $core.String? tier,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (taskId != null) result.taskId = taskId;
    if (rawPrompt != null) result.rawPrompt = rawPrompt;
    if (tier != null) result.tier = tier;
    return result;
  }

  PreviewInjectionRequest._();

  factory PreviewInjectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewInjectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewInjectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOS(2, _omitFieldNames ? '' : 'taskId')
    ..aOS(3, _omitFieldNames ? '' : 'rawPrompt')
    ..aOS(4, _omitFieldNames ? '' : 'tier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewInjectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewInjectionRequest copyWith(
          void Function(PreviewInjectionRequest) updates) =>
      super.copyWith((message) => updates(message as PreviewInjectionRequest))
          as PreviewInjectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewInjectionRequest create() => PreviewInjectionRequest._();
  @$core.override
  PreviewInjectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewInjectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewInjectionRequest>(create);
  static PreviewInjectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  /// Either task_id (use its goal / base branch / review feedback) OR
  /// raw_prompt (for a hypothetical task the user is about to create).
  /// Exactly one must be set.
  @$pb.TagNumber(2)
  $core.String get taskId => $_getSZ(1);
  @$pb.TagNumber(2)
  set taskId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTaskId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get rawPrompt => $_getSZ(2);
  @$pb.TagNumber(3)
  set rawPrompt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRawPrompt() => $_has(2);
  @$pb.TagNumber(3)
  void clearRawPrompt() => $_clearField(3);

  /// Which tier to preview. Defaults to "passive".
  @$pb.TagNumber(4)
  $core.String get tier => $_getSZ(3);
  @$pb.TagNumber(4)
  set tier($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTier() => $_has(3);
  @$pb.TagNumber(4)
  void clearTier() => $_clearField(4);
}

class RebuildEmbeddingsResponse extends $pb.GeneratedMessage {
  factory RebuildEmbeddingsResponse({
    $core.int? rebuilt,
    $core.int? skipped,
  }) {
    final result = create();
    if (rebuilt != null) result.rebuilt = rebuilt;
    if (skipped != null) result.skipped = skipped;
    return result;
  }

  RebuildEmbeddingsResponse._();

  factory RebuildEmbeddingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RebuildEmbeddingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RebuildEmbeddingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'rebuilt')
    ..aI(2, _omitFieldNames ? '' : 'skipped')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebuildEmbeddingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebuildEmbeddingsResponse copyWith(
          void Function(RebuildEmbeddingsResponse) updates) =>
      super.copyWith((message) => updates(message as RebuildEmbeddingsResponse))
          as RebuildEmbeddingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RebuildEmbeddingsResponse create() => RebuildEmbeddingsResponse._();
  @$core.override
  RebuildEmbeddingsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RebuildEmbeddingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RebuildEmbeddingsResponse>(create);
  static RebuildEmbeddingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get rebuilt => $_getIZ(0);
  @$pb.TagNumber(1)
  set rebuilt($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRebuilt() => $_has(0);
  @$pb.TagNumber(1)
  void clearRebuilt() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get skipped => $_getIZ(1);
  @$pb.TagNumber(2)
  set skipped($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSkipped() => $_has(1);
  @$pb.TagNumber(2)
  void clearSkipped() => $_clearField(2);
}

class RebuildCodeGraphResponse extends $pb.GeneratedMessage {
  factory RebuildCodeGraphResponse({
    $core.int? filesScanned,
    $core.int? nodesCreated,
    $core.int? nodesUpdated,
    $core.int? edgesCreated,
  }) {
    final result = create();
    if (filesScanned != null) result.filesScanned = filesScanned;
    if (nodesCreated != null) result.nodesCreated = nodesCreated;
    if (nodesUpdated != null) result.nodesUpdated = nodesUpdated;
    if (edgesCreated != null) result.edgesCreated = edgesCreated;
    return result;
  }

  RebuildCodeGraphResponse._();

  factory RebuildCodeGraphResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RebuildCodeGraphResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RebuildCodeGraphResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'filesScanned')
    ..aI(2, _omitFieldNames ? '' : 'nodesCreated')
    ..aI(3, _omitFieldNames ? '' : 'nodesUpdated')
    ..aI(4, _omitFieldNames ? '' : 'edgesCreated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebuildCodeGraphResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RebuildCodeGraphResponse copyWith(
          void Function(RebuildCodeGraphResponse) updates) =>
      super.copyWith((message) => updates(message as RebuildCodeGraphResponse))
          as RebuildCodeGraphResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RebuildCodeGraphResponse create() => RebuildCodeGraphResponse._();
  @$core.override
  RebuildCodeGraphResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RebuildCodeGraphResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RebuildCodeGraphResponse>(create);
  static RebuildCodeGraphResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get filesScanned => $_getIZ(0);
  @$pb.TagNumber(1)
  set filesScanned($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilesScanned() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilesScanned() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get nodesCreated => $_getIZ(1);
  @$pb.TagNumber(2)
  set nodesCreated($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNodesCreated() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodesCreated() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get nodesUpdated => $_getIZ(2);
  @$pb.TagNumber(3)
  set nodesUpdated($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNodesUpdated() => $_has(2);
  @$pb.TagNumber(3)
  void clearNodesUpdated() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get edgesCreated => $_getIZ(3);
  @$pb.TagNumber(4)
  set edgesCreated($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEdgesCreated() => $_has(3);
  @$pb.TagNumber(4)
  void clearEdgesCreated() => $_clearField(4);
}

class AnalyzeRepoRequest extends $pb.GeneratedMessage {
  factory AnalyzeRepoRequest({
    $core.String? repoId,
    $core.bool? force,
    $core.String? model,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (force != null) result.force = force;
    if (model != null) result.model = model;
    return result;
  }

  AnalyzeRepoRequest._();

  factory AnalyzeRepoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AnalyzeRepoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnalyzeRepoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOB(2, _omitFieldNames ? '' : 'force')
    ..aOS(3, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnalyzeRepoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnalyzeRepoRequest copyWith(void Function(AnalyzeRepoRequest) updates) =>
      super.copyWith((message) => updates(message as AnalyzeRepoRequest))
          as AnalyzeRepoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AnalyzeRepoRequest create() => AnalyzeRepoRequest._();
  @$core.override
  AnalyzeRepoRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AnalyzeRepoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnalyzeRepoRequest>(create);
  static AnalyzeRepoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  /// When true, re-analyze even if an analyzer run already finished for
  /// this repo. Defaults to false so "Analyze this repository" is
  /// idempotent in normal operation.
  @$pb.TagNumber(2)
  $core.bool get force => $_getBF(1);
  @$pb.TagNumber(2)
  set force($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasForce() => $_has(1);
  @$pb.TagNumber(2)
  void clearForce() => $_clearField(2);

  /// Optional override: the LLM model used for the analyzer session.
  /// Falls back to MemorySettings.llm_model when empty.
  @$pb.TagNumber(3)
  $core.String get model => $_getSZ(2);
  @$pb.TagNumber(3)
  set model($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModel() => $_has(2);
  @$pb.TagNumber(3)
  void clearModel() => $_clearField(3);
}

class MemorySettings extends $pb.GeneratedMessage {
  factory MemorySettings({
    $core.String? repoId,
    $core.bool? enabled,
    $core.String? embeddingProvider,
    $core.String? embeddingModel,
    $core.int? embeddingDim,
    $core.String? llmProvider,
    $core.String? llmModel,
    $core.int? passiveTokenBudget,
    $core.int? topKNeighbors,
    $core.bool? autoPromoteHighConfidence,
    $core.double? autoPromoteThreshold,
    $2.Timestamp? updatedAt,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (enabled != null) result.enabled = enabled;
    if (embeddingProvider != null) result.embeddingProvider = embeddingProvider;
    if (embeddingModel != null) result.embeddingModel = embeddingModel;
    if (embeddingDim != null) result.embeddingDim = embeddingDim;
    if (llmProvider != null) result.llmProvider = llmProvider;
    if (llmModel != null) result.llmModel = llmModel;
    if (passiveTokenBudget != null)
      result.passiveTokenBudget = passiveTokenBudget;
    if (topKNeighbors != null) result.topKNeighbors = topKNeighbors;
    if (autoPromoteHighConfidence != null)
      result.autoPromoteHighConfidence = autoPromoteHighConfidence;
    if (autoPromoteThreshold != null)
      result.autoPromoteThreshold = autoPromoteThreshold;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  MemorySettings._();

  factory MemorySettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MemorySettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemorySettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aOS(3, _omitFieldNames ? '' : 'embeddingProvider')
    ..aOS(4, _omitFieldNames ? '' : 'embeddingModel')
    ..aI(5, _omitFieldNames ? '' : 'embeddingDim')
    ..aOS(6, _omitFieldNames ? '' : 'llmProvider')
    ..aOS(7, _omitFieldNames ? '' : 'llmModel')
    ..aI(8, _omitFieldNames ? '' : 'passiveTokenBudget')
    ..aI(9, _omitFieldNames ? '' : 'topKNeighbors')
    ..aOB(10, _omitFieldNames ? '' : 'autoPromoteHighConfidence')
    ..aD(11, _omitFieldNames ? '' : 'autoPromoteThreshold',
        fieldType: $pb.PbFieldType.OF)
    ..aOM<$2.Timestamp>(12, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemorySettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemorySettings copyWith(void Function(MemorySettings) updates) =>
      super.copyWith((message) => updates(message as MemorySettings))
          as MemorySettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MemorySettings create() => MemorySettings._();
  @$core.override
  MemorySettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MemorySettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemorySettings>(create);
  static MemorySettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);

  /// Ollama | openai | voyage | google | openrouter | azure_openai
  @$pb.TagNumber(3)
  $core.String get embeddingProvider => $_getSZ(2);
  @$pb.TagNumber(3)
  set embeddingProvider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmbeddingProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmbeddingProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get embeddingModel => $_getSZ(3);
  @$pb.TagNumber(4)
  set embeddingModel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmbeddingModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmbeddingModel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get embeddingDim => $_getIZ(4);
  @$pb.TagNumber(5)
  set embeddingDim($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEmbeddingDim() => $_has(4);
  @$pb.TagNumber(5)
  void clearEmbeddingDim() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get llmProvider => $_getSZ(5);
  @$pb.TagNumber(6)
  set llmProvider($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLlmProvider() => $_has(5);
  @$pb.TagNumber(6)
  void clearLlmProvider() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get llmModel => $_getSZ(6);
  @$pb.TagNumber(7)
  set llmModel($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLlmModel() => $_has(6);
  @$pb.TagNumber(7)
  void clearLlmModel() => $_clearField(7);

  /// Token budget for the Passive tier injection block. Hits above
  /// this budget are truncated from the lowest-ranked tail.
  @$pb.TagNumber(8)
  $core.int get passiveTokenBudget => $_getIZ(7);
  @$pb.TagNumber(8)
  set passiveTokenBudget($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPassiveTokenBudget() => $_has(7);
  @$pb.TagNumber(8)
  void clearPassiveTokenBudget() => $_clearField(8);

  /// Hops to expand the top-ranked semantic + keyword hits when
  /// computing graph-neighborhood boost. 0 disables the boost.
  @$pb.TagNumber(9)
  $core.int get topKNeighbors => $_getIZ(8);
  @$pb.TagNumber(9)
  set topKNeighbors($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTopKNeighbors() => $_has(8);
  @$pb.TagNumber(9)
  void clearTopKNeighbors() => $_clearField(9);

  /// When true, scratchpad entries whose confidence >= threshold skip
  /// the trust gate and become ContextNodes directly. Default false.
  @$pb.TagNumber(10)
  $core.bool get autoPromoteHighConfidence => $_getBF(9);
  @$pb.TagNumber(10)
  set autoPromoteHighConfidence($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAutoPromoteHighConfidence() => $_has(9);
  @$pb.TagNumber(10)
  void clearAutoPromoteHighConfidence() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get autoPromoteThreshold => $_getN(10);
  @$pb.TagNumber(11)
  set autoPromoteThreshold($core.double value) => $_setFloat(10, value);
  @$pb.TagNumber(11)
  $core.bool hasAutoPromoteThreshold() => $_has(10);
  @$pb.TagNumber(11)
  void clearAutoPromoteThreshold() => $_clearField(11);

  @$pb.TagNumber(12)
  $2.Timestamp get updatedAt => $_getN(11);
  @$pb.TagNumber(12)
  set updatedAt($2.Timestamp value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasUpdatedAt() => $_has(11);
  @$pb.TagNumber(12)
  void clearUpdatedAt() => $_clearField(12);
  @$pb.TagNumber(12)
  $2.Timestamp ensureUpdatedAt() => $_ensure(11);
}

class UpdateMemorySettingsRequest extends $pb.GeneratedMessage {
  factory UpdateMemorySettingsRequest({
    MemorySettings? settings,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    return result;
  }

  UpdateMemorySettingsRequest._();

  factory UpdateMemorySettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateMemorySettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateMemorySettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOM<MemorySettings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: MemorySettings.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemorySettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateMemorySettingsRequest copyWith(
          void Function(UpdateMemorySettingsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateMemorySettingsRequest))
          as UpdateMemorySettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateMemorySettingsRequest create() =>
      UpdateMemorySettingsRequest._();
  @$core.override
  UpdateMemorySettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateMemorySettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateMemorySettingsRequest>(create);
  static UpdateMemorySettingsRequest? _defaultInstance;

  /// settings.repo_id is required. All other fields are applied as-is
  /// (including zero values); to ignore a field, fetch, mutate, and
  /// resend — the semantics mirror SetConcurrency.
  @$pb.TagNumber(1)
  MemorySettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(MemorySettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  MemorySettings ensureSettings() => $_ensure(0);
}

/// MemoryHealth is the lightweight snapshot returned by GetMemoryHealth.
/// Purpose-built for polling: no expensive aggregates (counts by kind,
/// scratchpad buckets) — those live on ContextOverview.
class MemoryHealth extends $pb.GeneratedMessage {
  factory MemoryHealth({
    $core.bool? enabled,
    $core.bool? providerReachable,
    $core.int? vectorCount,
    $2.Timestamp? lastRebuildAt,
    $core.String? lastError,
  }) {
    final result = create();
    if (enabled != null) result.enabled = enabled;
    if (providerReachable != null) result.providerReachable = providerReachable;
    if (vectorCount != null) result.vectorCount = vectorCount;
    if (lastRebuildAt != null) result.lastRebuildAt = lastRebuildAt;
    if (lastError != null) result.lastError = lastError;
    return result;
  }

  MemoryHealth._();

  factory MemoryHealth.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MemoryHealth.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemoryHealth',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'providerReachable')
    ..aI(3, _omitFieldNames ? '' : 'vectorCount')
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'lastRebuildAt',
        subBuilder: $2.Timestamp.create)
    ..aOS(5, _omitFieldNames ? '' : 'lastError')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemoryHealth clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemoryHealth copyWith(void Function(MemoryHealth) updates) =>
      super.copyWith((message) => updates(message as MemoryHealth))
          as MemoryHealth;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MemoryHealth create() => MemoryHealth._();
  @$core.override
  MemoryHealth createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MemoryHealth getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemoryHealth>(create);
  static MemoryHealth? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get providerReachable => $_getBF(1);
  @$pb.TagNumber(2)
  set providerReachable($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProviderReachable() => $_has(1);
  @$pb.TagNumber(2)
  void clearProviderReachable() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get vectorCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set vectorCount($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVectorCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearVectorCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $2.Timestamp get lastRebuildAt => $_getN(3);
  @$pb.TagNumber(4)
  set lastRebuildAt($2.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLastRebuildAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastRebuildAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureLastRebuildAt() => $_ensure(3);

  /// Human-readable error from the last provider build or reachability
  /// probe. Empty when healthy. Rendered verbatim in the Settings panel.
  @$pb.TagNumber(5)
  $core.String get lastError => $_getSZ(4);
  @$pb.TagNumber(5)
  set lastError($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLastError() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastError() => $_clearField(5);
}

class SuggestForNewTaskRequest extends $pb.GeneratedMessage {
  factory SuggestForNewTaskRequest({
    $core.String? repoId,
    $core.String? draftGoal,
    $core.int? limit,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (draftGoal != null) result.draftGoal = draftGoal;
    if (limit != null) result.limit = limit;
    return result;
  }

  SuggestForNewTaskRequest._();

  factory SuggestForNewTaskRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SuggestForNewTaskRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SuggestForNewTaskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..aOS(2, _omitFieldNames ? '' : 'draftGoal')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestForNewTaskRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestForNewTaskRequest copyWith(
          void Function(SuggestForNewTaskRequest) updates) =>
      super.copyWith((message) => updates(message as SuggestForNewTaskRequest))
          as SuggestForNewTaskRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SuggestForNewTaskRequest create() => SuggestForNewTaskRequest._();
  @$core.override
  SuggestForNewTaskRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SuggestForNewTaskRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SuggestForNewTaskRequest>(create);
  static SuggestForNewTaskRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get draftGoal => $_getSZ(1);
  @$pb.TagNumber(2)
  set draftGoal($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDraftGoal() => $_has(1);
  @$pb.TagNumber(2)
  void clearDraftGoal() => $_clearField(2);

  /// Per-bucket cap. Defaults to 5 when unset. The server pulls 3x this
  /// from the fused channel so each bucket has headroom.
  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class TaskSuggestion extends $pb.GeneratedMessage {
  factory TaskSuggestion({
    $core.String? nodeId,
    $core.String? label,
    $core.String? summaryMd,
    $core.double? score,
    $core.String? sourceTaskId,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (label != null) result.label = label;
    if (summaryMd != null) result.summaryMd = summaryMd;
    if (score != null) result.score = score;
    if (sourceTaskId != null) result.sourceTaskId = sourceTaskId;
    return result;
  }

  TaskSuggestion._();

  factory TaskSuggestion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TaskSuggestion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskSuggestion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'summaryMd')
    ..aD(4, _omitFieldNames ? '' : 'score', fieldType: $pb.PbFieldType.OF)
    ..aOS(5, _omitFieldNames ? '' : 'sourceTaskId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskSuggestion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskSuggestion copyWith(void Function(TaskSuggestion) updates) =>
      super.copyWith((message) => updates(message as TaskSuggestion))
          as TaskSuggestion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskSuggestion create() => TaskSuggestion._();
  @$core.override
  TaskSuggestion createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TaskSuggestion getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskSuggestion>(create);
  static TaskSuggestion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get summaryMd => $_getSZ(2);
  @$pb.TagNumber(3)
  set summaryMd($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSummaryMd() => $_has(2);
  @$pb.TagNumber(3)
  void clearSummaryMd() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get score => $_getN(3);
  @$pb.TagNumber(4)
  set score($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasScore() => $_has(3);
  @$pb.TagNumber(4)
  void clearScore() => $_clearField(4);

  /// Original task ID — UI uses this to deep-link back to the Kanban row.
  @$pb.TagNumber(5)
  $core.String get sourceTaskId => $_getSZ(4);
  @$pb.TagNumber(5)
  set sourceTaskId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSourceTaskId() => $_has(4);
  @$pb.TagNumber(5)
  void clearSourceTaskId() => $_clearField(5);
}

class ContextNodeSummary extends $pb.GeneratedMessage {
  factory ContextNodeSummary({
    $core.String? nodeId,
    $core.String? kind,
    $core.String? label,
    $core.String? contentMd,
    $core.double? score,
  }) {
    final result = create();
    if (nodeId != null) result.nodeId = nodeId;
    if (kind != null) result.kind = kind;
    if (label != null) result.label = label;
    if (contentMd != null) result.contentMd = contentMd;
    if (score != null) result.score = score;
    return result;
  }

  ContextNodeSummary._();

  factory ContextNodeSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextNodeSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextNodeSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'contentMd')
    ..aD(5, _omitFieldNames ? '' : 'score', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextNodeSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextNodeSummary copyWith(void Function(ContextNodeSummary) updates) =>
      super.copyWith((message) => updates(message as ContextNodeSummary))
          as ContextNodeSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextNodeSummary create() => ContextNodeSummary._();
  @$core.override
  ContextNodeSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextNodeSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextNodeSummary>(create);
  static ContextNodeSummary? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  /// Decision | Constraint (filtered server-side to those two kinds).
  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get contentMd => $_getSZ(3);
  @$pb.TagNumber(4)
  set contentMd($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContentMd() => $_has(3);
  @$pb.TagNumber(4)
  void clearContentMd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get score => $_getN(4);
  @$pb.TagNumber(5)
  set score($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasScore() => $_has(4);
  @$pb.TagNumber(5)
  void clearScore() => $_clearField(5);
}

class SuggestForNewTaskResponse extends $pb.GeneratedMessage {
  factory SuggestForNewTaskResponse({
    $core.Iterable<TaskSuggestion>? similarTasks,
    $core.Iterable<ContextNodeSummary>? relatedDecisions,
    $core.Iterable<ContextNodeSummary>? relatedConstraints,
  }) {
    final result = create();
    if (similarTasks != null) result.similarTasks.addAll(similarTasks);
    if (relatedDecisions != null)
      result.relatedDecisions.addAll(relatedDecisions);
    if (relatedConstraints != null)
      result.relatedConstraints.addAll(relatedConstraints);
    return result;
  }

  SuggestForNewTaskResponse._();

  factory SuggestForNewTaskResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SuggestForNewTaskResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SuggestForNewTaskResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<TaskSuggestion>(1, _omitFieldNames ? '' : 'similarTasks',
        subBuilder: TaskSuggestion.create)
    ..pPM<ContextNodeSummary>(2, _omitFieldNames ? '' : 'relatedDecisions',
        subBuilder: ContextNodeSummary.create)
    ..pPM<ContextNodeSummary>(3, _omitFieldNames ? '' : 'relatedConstraints',
        subBuilder: ContextNodeSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestForNewTaskResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuggestForNewTaskResponse copyWith(
          void Function(SuggestForNewTaskResponse) updates) =>
      super.copyWith((message) => updates(message as SuggestForNewTaskResponse))
          as SuggestForNewTaskResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SuggestForNewTaskResponse create() => SuggestForNewTaskResponse._();
  @$core.override
  SuggestForNewTaskResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SuggestForNewTaskResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SuggestForNewTaskResponse>(create);
  static SuggestForNewTaskResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TaskSuggestion> get similarTasks => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<ContextNodeSummary> get relatedDecisions => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<ContextNodeSummary> get relatedConstraints => $_getList(2);
}

/// WatchContextRequest resumes a stream by passing the server sequence
/// of the last observed change per change-kind. Unset → send only
/// future changes (no backfill).
class WatchContextRequest extends $pb.GeneratedMessage {
  factory WatchContextRequest({
    $core.String? repoId,
    $core.Iterable<$core.MapEntry<$core.String, $fixnum.Int64>>? sinceSeqByKind,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (sinceSeqByKind != null)
      result.sinceSeqByKind.addEntries(sinceSeqByKind);
    return result;
  }

  WatchContextRequest._();

  factory WatchContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchContextRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..m<$core.String, $fixnum.Int64>(2, _omitFieldNames ? '' : 'sinceSeqByKind',
        entryClassName: 'WatchContextRequest.SinceSeqByKindEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O6,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchContextRequest copyWith(void Function(WatchContextRequest) updates) =>
      super.copyWith((message) => updates(message as WatchContextRequest))
          as WatchContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchContextRequest create() => WatchContextRequest._();
  @$core.override
  WatchContextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchContextRequest>(create);
  static WatchContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $fixnum.Int64> get sinceSeqByKind => $_getMap(1);
}

class ContextChangeEvent extends $pb.GeneratedMessage {
  factory ContextChangeEvent({
    $fixnum.Int64? seq,
    $core.String? kind,
    $core.String? op,
    $core.String? id,
    $core.String? repoId,
    $2.Timestamp? occurredAt,
    $core.String? message,
  }) {
    final result = create();
    if (seq != null) result.seq = seq;
    if (kind != null) result.kind = kind;
    if (op != null) result.op = op;
    if (id != null) result.id = id;
    if (repoId != null) result.repoId = repoId;
    if (occurredAt != null) result.occurredAt = occurredAt;
    if (message != null) result.message = message;
    return result;
  }

  ContextChangeEvent._();

  factory ContextChangeEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContextChangeEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContextChangeEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'seq')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'op')
    ..aOS(4, _omitFieldNames ? '' : 'id')
    ..aOS(5, _omitFieldNames ? '' : 'repoId')
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'occurredAt',
        subBuilder: $2.Timestamp.create)
    ..aOS(7, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextChangeEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContextChangeEvent copyWith(void Function(ContextChangeEvent) updates) =>
      super.copyWith((message) => updates(message as ContextChangeEvent))
          as ContextChangeEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContextChangeEvent create() => ContextChangeEvent._();
  @$core.override
  ContextChangeEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContextChangeEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContextChangeEvent>(create);
  static ContextChangeEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get op => $_getSZ(2);
  @$pb.TagNumber(3)
  set op($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOp() => $_has(2);
  @$pb.TagNumber(3)
  void clearOp() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get id => $_getSZ(3);
  @$pb.TagNumber(4)
  set id($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasId() => $_has(3);
  @$pb.TagNumber(4)
  void clearId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get repoId => $_getSZ(4);
  @$pb.TagNumber(5)
  set repoId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRepoId() => $_has(4);
  @$pb.TagNumber(5)
  void clearRepoId() => $_clearField(5);

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

  /// Human-readable detail. Populated for analyzer error events so the
  /// UI can render the failure message (with a copy button) inline
  /// rather than forcing the user to tail the sidecar log.
  @$pb.TagNumber(7)
  $core.String get message => $_getSZ(6);
  @$pb.TagNumber(7)
  set message($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMessage() => $_has(6);
  @$pb.TagNumber(7)
  void clearMessage() => $_clearField(7);
}

class ScratchpadEntry extends $pb.GeneratedMessage {
  factory ScratchpadEntry({
    $core.String? id,
    $core.String? repoId,
    $core.String? proposedKind,
    $core.String? proposedLabel,
    $core.String? proposedContentMd,
    $core.String? sourceKind,
    $core.String? sourceRef,
    $core.Iterable<$core.String>? signals,
    $core.double? confidence,
    $core.String? status,
    $2.Timestamp? snoozedUntil,
    $2.Timestamp? createdAt,
    $2.Timestamp? updatedAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (repoId != null) result.repoId = repoId;
    if (proposedKind != null) result.proposedKind = proposedKind;
    if (proposedLabel != null) result.proposedLabel = proposedLabel;
    if (proposedContentMd != null) result.proposedContentMd = proposedContentMd;
    if (sourceKind != null) result.sourceKind = sourceKind;
    if (sourceRef != null) result.sourceRef = sourceRef;
    if (signals != null) result.signals.addAll(signals);
    if (confidence != null) result.confidence = confidence;
    if (status != null) result.status = status;
    if (snoozedUntil != null) result.snoozedUntil = snoozedUntil;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  ScratchpadEntry._();

  factory ScratchpadEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScratchpadEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScratchpadEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'repoId')
    ..aOS(3, _omitFieldNames ? '' : 'proposedKind')
    ..aOS(4, _omitFieldNames ? '' : 'proposedLabel')
    ..aOS(5, _omitFieldNames ? '' : 'proposedContentMd')
    ..aOS(6, _omitFieldNames ? '' : 'sourceKind')
    ..aOS(7, _omitFieldNames ? '' : 'sourceRef')
    ..pPS(8, _omitFieldNames ? '' : 'signals')
    ..aD(9, _omitFieldNames ? '' : 'confidence', fieldType: $pb.PbFieldType.OF)
    ..aOS(10, _omitFieldNames ? '' : 'status')
    ..aOM<$2.Timestamp>(11, _omitFieldNames ? '' : 'snoozedUntil',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(12, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(13, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScratchpadEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScratchpadEntry copyWith(void Function(ScratchpadEntry) updates) =>
      super.copyWith((message) => updates(message as ScratchpadEntry))
          as ScratchpadEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScratchpadEntry create() => ScratchpadEntry._();
  @$core.override
  ScratchpadEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScratchpadEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScratchpadEntry>(create);
  static ScratchpadEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get repoId => $_getSZ(1);
  @$pb.TagNumber(2)
  set repoId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepoId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepoId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get proposedKind => $_getSZ(2);
  @$pb.TagNumber(3)
  set proposedKind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProposedKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearProposedKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get proposedLabel => $_getSZ(3);
  @$pb.TagNumber(4)
  set proposedLabel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProposedLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearProposedLabel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get proposedContentMd => $_getSZ(4);
  @$pb.TagNumber(5)
  set proposedContentMd($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProposedContentMd() => $_has(4);
  @$pb.TagNumber(5)
  void clearProposedContentMd() => $_clearField(5);

  /// observer-signal | analyzer | session-summary | manual-draft
  @$pb.TagNumber(6)
  $core.String get sourceKind => $_getSZ(5);
  @$pb.TagNumber(6)
  set sourceKind($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSourceKind() => $_has(5);
  @$pb.TagNumber(6)
  void clearSourceKind() => $_clearField(6);

  /// Origin task / session for debug / trust UI. Empty when the
  /// observer aggregated multiple sessions.
  @$pb.TagNumber(7)
  $core.String get sourceRef => $_getSZ(6);
  @$pb.TagNumber(7)
  set sourceRef($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSourceRef() => $_has(6);
  @$pb.TagNumber(7)
  void clearSourceRef() => $_clearField(7);

  /// Free-form signal strings ("repeated file co-access (8x)",
  /// "explicit reference in session summary", "matches dead-end
  /// pattern X"). Rendered as chips in the Scratchpad card.
  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get signals => $_getList(7);

  @$pb.TagNumber(9)
  $core.double get confidence => $_getN(8);
  @$pb.TagNumber(9)
  set confidence($core.double value) => $_setFloat(8, value);
  @$pb.TagNumber(9)
  $core.bool hasConfidence() => $_has(8);
  @$pb.TagNumber(9)
  void clearConfidence() => $_clearField(9);

  /// pending | promoted | rejected | snoozed
  @$pb.TagNumber(10)
  $core.String get status => $_getSZ(9);
  @$pb.TagNumber(10)
  set status($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasStatus() => $_has(9);
  @$pb.TagNumber(10)
  void clearStatus() => $_clearField(10);

  @$pb.TagNumber(11)
  $2.Timestamp get snoozedUntil => $_getN(10);
  @$pb.TagNumber(11)
  set snoozedUntil($2.Timestamp value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasSnoozedUntil() => $_has(10);
  @$pb.TagNumber(11)
  void clearSnoozedUntil() => $_clearField(11);
  @$pb.TagNumber(11)
  $2.Timestamp ensureSnoozedUntil() => $_ensure(10);

  @$pb.TagNumber(12)
  $2.Timestamp get createdAt => $_getN(11);
  @$pb.TagNumber(12)
  set createdAt($2.Timestamp value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasCreatedAt() => $_has(11);
  @$pb.TagNumber(12)
  void clearCreatedAt() => $_clearField(12);
  @$pb.TagNumber(12)
  $2.Timestamp ensureCreatedAt() => $_ensure(11);

  @$pb.TagNumber(13)
  $2.Timestamp get updatedAt => $_getN(12);
  @$pb.TagNumber(13)
  set updatedAt($2.Timestamp value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasUpdatedAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearUpdatedAt() => $_clearField(13);
  @$pb.TagNumber(13)
  $2.Timestamp ensureUpdatedAt() => $_ensure(12);
}

class ListPendingRequest extends $pb.GeneratedMessage {
  factory ListPendingRequest({
    $core.String? repoId,
    $core.Iterable<$core.String>? statuses,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (repoId != null) result.repoId = repoId;
    if (statuses != null) result.statuses.addAll(statuses);
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ListPendingRequest._();

  factory ListPendingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListPendingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPendingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repoId')
    ..pPS(2, _omitFieldNames ? '' : 'statuses')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..aI(4, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPendingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPendingRequest copyWith(void Function(ListPendingRequest) updates) =>
      super.copyWith((message) => updates(message as ListPendingRequest))
          as ListPendingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListPendingRequest create() => ListPendingRequest._();
  @$core.override
  ListPendingRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListPendingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListPendingRequest>(create);
  static ListPendingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repoId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repoId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepoId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepoId() => $_clearField(1);

  /// Include statuses beyond "pending". Defaults to pending-only.
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
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);
}

class ListPendingResponse extends $pb.GeneratedMessage {
  factory ListPendingResponse({
    $core.Iterable<ScratchpadEntry>? entries,
    $core.int? total,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (total != null) result.total = total;
    return result;
  }

  ListPendingResponse._();

  factory ListPendingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListPendingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPendingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<ScratchpadEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ScratchpadEntry.create)
    ..aI(2, _omitFieldNames ? '' : 'total')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPendingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPendingResponse copyWith(void Function(ListPendingResponse) updates) =>
      super.copyWith((message) => updates(message as ListPendingResponse))
          as ListPendingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListPendingResponse create() => ListPendingResponse._();
  @$core.override
  ListPendingResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListPendingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListPendingResponse>(create);
  static ListPendingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ScratchpadEntry> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);
}

class RejectEntryRequest extends $pb.GeneratedMessage {
  factory RejectEntryRequest({
    $core.String? entryId,
    $core.String? reason,
  }) {
    final result = create();
    if (entryId != null) result.entryId = entryId;
    if (reason != null) result.reason = reason;
    return result;
  }

  RejectEntryRequest._();

  factory RejectEntryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RejectEntryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RejectEntryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'entryId')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectEntryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectEntryRequest copyWith(void Function(RejectEntryRequest) updates) =>
      super.copyWith((message) => updates(message as RejectEntryRequest))
          as RejectEntryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RejectEntryRequest create() => RejectEntryRequest._();
  @$core.override
  RejectEntryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RejectEntryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RejectEntryRequest>(create);
  static RejectEntryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set entryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntryId() => $_clearField(1);

  /// Optional reason — persisted alongside the entry for auditability
  /// and shown in the rejected filter of the Scratchpad tab.
  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);
}

class EditAndPromoteRequest extends $pb.GeneratedMessage {
  factory EditAndPromoteRequest({
    $core.String? entryId,
    $core.String? editedKind,
    $core.String? editedLabel,
    $core.String? editedContentMd,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? editedAttrs,
  }) {
    final result = create();
    if (entryId != null) result.entryId = entryId;
    if (editedKind != null) result.editedKind = editedKind;
    if (editedLabel != null) result.editedLabel = editedLabel;
    if (editedContentMd != null) result.editedContentMd = editedContentMd;
    if (editedAttrs != null) result.editedAttrs.addEntries(editedAttrs);
    return result;
  }

  EditAndPromoteRequest._();

  factory EditAndPromoteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EditAndPromoteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditAndPromoteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'entryId')
    ..aOS(2, _omitFieldNames ? '' : 'editedKind')
    ..aOS(3, _omitFieldNames ? '' : 'editedLabel')
    ..aOS(4, _omitFieldNames ? '' : 'editedContentMd')
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'editedAttrs',
        entryClassName: 'EditAndPromoteRequest.EditedAttrsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('fleetkanban.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditAndPromoteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditAndPromoteRequest copyWith(
          void Function(EditAndPromoteRequest) updates) =>
      super.copyWith((message) => updates(message as EditAndPromoteRequest))
          as EditAndPromoteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EditAndPromoteRequest create() => EditAndPromoteRequest._();
  @$core.override
  EditAndPromoteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EditAndPromoteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditAndPromoteRequest>(create);
  static EditAndPromoteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set entryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntryId() => $_clearField(1);

  /// Optional overrides — empty keeps the scratchpad value.
  @$pb.TagNumber(2)
  $core.String get editedKind => $_getSZ(1);
  @$pb.TagNumber(2)
  set editedKind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEditedKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearEditedKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get editedLabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set editedLabel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEditedLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearEditedLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get editedContentMd => $_getSZ(3);
  @$pb.TagNumber(4)
  set editedContentMd($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEditedContentMd() => $_has(3);
  @$pb.TagNumber(4)
  void clearEditedContentMd() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get editedAttrs => $_getMap(4);
}

class SnoozeRequest extends $pb.GeneratedMessage {
  factory SnoozeRequest({
    $core.String? entryId,
    $core.int? days,
  }) {
    final result = create();
    if (entryId != null) result.entryId = entryId;
    if (days != null) result.days = days;
    return result;
  }

  SnoozeRequest._();

  factory SnoozeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SnoozeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SnoozeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'entryId')
    ..aI(2, _omitFieldNames ? '' : 'days')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnoozeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SnoozeRequest copyWith(void Function(SnoozeRequest) updates) =>
      super.copyWith((message) => updates(message as SnoozeRequest))
          as SnoozeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SnoozeRequest create() => SnoozeRequest._();
  @$core.override
  SnoozeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SnoozeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnoozeRequest>(create);
  static SnoozeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get entryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set entryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEntryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntryId() => $_clearField(1);

  /// Server clamps to [1h, 30d]. Typical UI choices: 1d, 7d, 30d.
  @$pb.TagNumber(2)
  $core.int get days => $_getIZ(1);
  @$pb.TagNumber(2)
  set days($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDays() => $_has(1);
  @$pb.TagNumber(2)
  void clearDays() => $_clearField(2);
}

class ScratchpadChangeEvent extends $pb.GeneratedMessage {
  factory ScratchpadChangeEvent({
    $fixnum.Int64? seq,
    $core.String? op,
    $core.String? entryId,
    $core.String? repoId,
    $2.Timestamp? occurredAt,
  }) {
    final result = create();
    if (seq != null) result.seq = seq;
    if (op != null) result.op = op;
    if (entryId != null) result.entryId = entryId;
    if (repoId != null) result.repoId = repoId;
    if (occurredAt != null) result.occurredAt = occurredAt;
    return result;
  }

  ScratchpadChangeEvent._();

  factory ScratchpadChangeEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScratchpadChangeEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScratchpadChangeEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'seq')
    ..aOS(2, _omitFieldNames ? '' : 'op')
    ..aOS(3, _omitFieldNames ? '' : 'entryId')
    ..aOS(4, _omitFieldNames ? '' : 'repoId')
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'occurredAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScratchpadChangeEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScratchpadChangeEvent copyWith(
          void Function(ScratchpadChangeEvent) updates) =>
      super.copyWith((message) => updates(message as ScratchpadChangeEvent))
          as ScratchpadChangeEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScratchpadChangeEvent create() => ScratchpadChangeEvent._();
  @$core.override
  ScratchpadChangeEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScratchpadChangeEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScratchpadChangeEvent>(create);
  static ScratchpadChangeEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get op => $_getSZ(1);
  @$pb.TagNumber(2)
  set op($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOp() => $_has(1);
  @$pb.TagNumber(2)
  void clearOp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get entryId => $_getSZ(2);
  @$pb.TagNumber(3)
  set entryId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEntryId() => $_has(2);
  @$pb.TagNumber(3)
  void clearEntryId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get repoId => $_getSZ(3);
  @$pb.TagNumber(4)
  set repoId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRepoId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRepoId() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Timestamp get occurredAt => $_getN(4);
  @$pb.TagNumber(5)
  set occurredAt($2.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOccurredAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearOccurredAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureOccurredAt() => $_ensure(4);
}

class OllamaStatus extends $pb.GeneratedMessage {
  factory OllamaStatus({
    $core.bool? installed,
    $core.bool? running,
    $core.String? baseUrl,
    $core.String? version,
    $core.String? message,
    $core.String? installCommand,
  }) {
    final result = create();
    if (installed != null) result.installed = installed;
    if (running != null) result.running = running;
    if (baseUrl != null) result.baseUrl = baseUrl;
    if (version != null) result.version = version;
    if (message != null) result.message = message;
    if (installCommand != null) result.installCommand = installCommand;
    return result;
  }

  OllamaStatus._();

  factory OllamaStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OllamaStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OllamaStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'installed')
    ..aOB(2, _omitFieldNames ? '' : 'running')
    ..aOS(3, _omitFieldNames ? '' : 'baseUrl')
    ..aOS(4, _omitFieldNames ? '' : 'version')
    ..aOS(5, _omitFieldNames ? '' : 'message')
    ..aOS(6, _omitFieldNames ? '' : 'installCommand')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaStatus copyWith(void Function(OllamaStatus) updates) =>
      super.copyWith((message) => updates(message as OllamaStatus))
          as OllamaStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OllamaStatus create() => OllamaStatus._();
  @$core.override
  OllamaStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OllamaStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OllamaStatus>(create);
  static OllamaStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get installed => $_getBF(0);
  @$pb.TagNumber(1)
  set installed($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstalled() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstalled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get running => $_getBF(1);
  @$pb.TagNumber(2)
  set running($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRunning() => $_has(1);
  @$pb.TagNumber(2)
  void clearRunning() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get baseUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set baseUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBaseUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearBaseUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get version => $_getSZ(3);
  @$pb.TagNumber(4)
  set version($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersion() => $_clearField(4);

  /// Empty on success; set when the sidecar could not reach Ollama so
  /// the UI can surface a specific message ("connection refused",
  /// "not found on PATH").
  @$pb.TagNumber(5)
  $core.String get message => $_getSZ(4);
  @$pb.TagNumber(5)
  set message($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessage() => $_clearField(5);

  /// Canonical install command for the user's OS (winget string on
  /// Windows). Populated only when installed == false.
  @$pb.TagNumber(6)
  $core.String get installCommand => $_getSZ(5);
  @$pb.TagNumber(6)
  set installCommand($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasInstallCommand() => $_has(5);
  @$pb.TagNumber(6)
  void clearInstallCommand() => $_clearField(6);
}

class OllamaModel extends $pb.GeneratedMessage {
  factory OllamaModel({
    $core.String? name,
    $fixnum.Int64? sizeBytes,
    $core.double? sizeGb,
    $core.String? modifiedAt,
    $core.bool? isEmbedding,
    $core.int? embeddingDim,
    $core.String? description,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (sizeGb != null) result.sizeGb = sizeGb;
    if (modifiedAt != null) result.modifiedAt = modifiedAt;
    if (isEmbedding != null) result.isEmbedding = isEmbedding;
    if (embeddingDim != null) result.embeddingDim = embeddingDim;
    if (description != null) result.description = description;
    return result;
  }

  OllamaModel._();

  factory OllamaModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OllamaModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OllamaModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aInt64(2, _omitFieldNames ? '' : 'sizeBytes')
    ..aD(3, _omitFieldNames ? '' : 'sizeGb')
    ..aOS(4, _omitFieldNames ? '' : 'modifiedAt')
    ..aOB(5, _omitFieldNames ? '' : 'isEmbedding')
    ..aI(6, _omitFieldNames ? '' : 'embeddingDim')
    ..aOS(7, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaModel copyWith(void Function(OllamaModel) updates) =>
      super.copyWith((message) => updates(message as OllamaModel))
          as OllamaModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OllamaModel create() => OllamaModel._();
  @$core.override
  OllamaModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OllamaModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OllamaModel>(create);
  static OllamaModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sizeBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSizeBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearSizeBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get sizeGb => $_getN(2);
  @$pb.TagNumber(3)
  set sizeGb($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeGb() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeGb() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get modifiedAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set modifiedAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModifiedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearModifiedAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isEmbedding => $_getBF(4);
  @$pb.TagNumber(5)
  set isEmbedding($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsEmbedding() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsEmbedding() => $_clearField(5);

  /// Set when the model's /api/show response declares embedding.
  @$pb.TagNumber(6)
  $core.int get embeddingDim => $_getIZ(5);
  @$pb.TagNumber(6)
  set embeddingDim($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEmbeddingDim() => $_has(5);
  @$pb.TagNumber(6)
  void clearEmbeddingDim() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get description => $_getSZ(6);
  @$pb.TagNumber(7)
  set description($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDescription() => $_has(6);
  @$pb.TagNumber(7)
  void clearDescription() => $_clearField(7);
}

class OllamaListModelsResponse extends $pb.GeneratedMessage {
  factory OllamaListModelsResponse({
    $core.Iterable<OllamaModel>? models,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    return result;
  }

  OllamaListModelsResponse._();

  factory OllamaListModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OllamaListModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OllamaListModelsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<OllamaModel>(1, _omitFieldNames ? '' : 'models',
        subBuilder: OllamaModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaListModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaListModelsResponse copyWith(
          void Function(OllamaListModelsResponse) updates) =>
      super.copyWith((message) => updates(message as OllamaListModelsResponse))
          as OllamaListModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OllamaListModelsResponse create() => OllamaListModelsResponse._();
  @$core.override
  OllamaListModelsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OllamaListModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OllamaListModelsResponse>(create);
  static OllamaListModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OllamaModel> get models => $_getList(0);
}

class OllamaRecommendedModel extends $pb.GeneratedMessage {
  factory OllamaRecommendedModel({
    $core.String? name,
    $core.String? description,
    $core.String? sizeEstimate,
    $core.int? embeddingDim,
    $core.bool? installed,
    $core.String? role,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (sizeEstimate != null) result.sizeEstimate = sizeEstimate;
    if (embeddingDim != null) result.embeddingDim = embeddingDim;
    if (installed != null) result.installed = installed;
    if (role != null) result.role = role;
    return result;
  }

  OllamaRecommendedModel._();

  factory OllamaRecommendedModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OllamaRecommendedModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OllamaRecommendedModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'sizeEstimate')
    ..aI(4, _omitFieldNames ? '' : 'embeddingDim')
    ..aOB(5, _omitFieldNames ? '' : 'installed')
    ..aOS(6, _omitFieldNames ? '' : 'role')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaRecommendedModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaRecommendedModel copyWith(
          void Function(OllamaRecommendedModel) updates) =>
      super.copyWith((message) => updates(message as OllamaRecommendedModel))
          as OllamaRecommendedModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OllamaRecommendedModel create() => OllamaRecommendedModel._();
  @$core.override
  OllamaRecommendedModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OllamaRecommendedModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OllamaRecommendedModel>(create);
  static OllamaRecommendedModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sizeEstimate => $_getSZ(2);
  @$pb.TagNumber(3)
  set sizeEstimate($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeEstimate() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeEstimate() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get embeddingDim => $_getIZ(3);
  @$pb.TagNumber(4)
  set embeddingDim($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmbeddingDim() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmbeddingDim() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get installed => $_getBF(4);
  @$pb.TagNumber(5)
  set installed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInstalled() => $_has(4);
  @$pb.TagNumber(5)
  void clearInstalled() => $_clearField(5);

  /// "embedding" | "llm"
  @$pb.TagNumber(6)
  $core.String get role => $_getSZ(5);
  @$pb.TagNumber(6)
  set role($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRole() => $_has(5);
  @$pb.TagNumber(6)
  void clearRole() => $_clearField(6);
}

class OllamaListRecommendedResponse extends $pb.GeneratedMessage {
  factory OllamaListRecommendedResponse({
    $core.Iterable<OllamaRecommendedModel>? models,
  }) {
    final result = create();
    if (models != null) result.models.addAll(models);
    return result;
  }

  OllamaListRecommendedResponse._();

  factory OllamaListRecommendedResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OllamaListRecommendedResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OllamaListRecommendedResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<OllamaRecommendedModel>(1, _omitFieldNames ? '' : 'models',
        subBuilder: OllamaRecommendedModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaListRecommendedResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaListRecommendedResponse copyWith(
          void Function(OllamaListRecommendedResponse) updates) =>
      super.copyWith(
              (message) => updates(message as OllamaListRecommendedResponse))
          as OllamaListRecommendedResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OllamaListRecommendedResponse create() =>
      OllamaListRecommendedResponse._();
  @$core.override
  OllamaListRecommendedResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OllamaListRecommendedResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OllamaListRecommendedResponse>(create);
  static OllamaListRecommendedResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OllamaRecommendedModel> get models => $_getList(0);
}

class PullModelRequest extends $pb.GeneratedMessage {
  factory PullModelRequest({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  PullModelRequest._();

  factory PullModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PullModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PullModelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullModelRequest copyWith(void Function(PullModelRequest) updates) =>
      super.copyWith((message) => updates(message as PullModelRequest))
          as PullModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PullModelRequest create() => PullModelRequest._();
  @$core.override
  PullModelRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PullModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PullModelRequest>(create);
  static PullModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

/// OllamaPullProgressEvent is one streamed progress chunk from Ollama's
/// /api/pull streaming endpoint. Exactly one of status / error / done
/// is non-empty per event.
class OllamaPullProgressEvent extends $pb.GeneratedMessage {
  factory OllamaPullProgressEvent({
    $core.String? status,
    $fixnum.Int64? downloaded,
    $fixnum.Int64? total,
    $core.String? digest,
    $core.String? error,
    $core.bool? done,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (downloaded != null) result.downloaded = downloaded;
    if (total != null) result.total = total;
    if (digest != null) result.digest = digest;
    if (error != null) result.error = error;
    if (done != null) result.done = done;
    return result;
  }

  OllamaPullProgressEvent._();

  factory OllamaPullProgressEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OllamaPullProgressEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OllamaPullProgressEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..aInt64(2, _omitFieldNames ? '' : 'downloaded')
    ..aInt64(3, _omitFieldNames ? '' : 'total')
    ..aOS(4, _omitFieldNames ? '' : 'digest')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..aOB(6, _omitFieldNames ? '' : 'done')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaPullProgressEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OllamaPullProgressEvent copyWith(
          void Function(OllamaPullProgressEvent) updates) =>
      super.copyWith((message) => updates(message as OllamaPullProgressEvent))
          as OllamaPullProgressEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OllamaPullProgressEvent create() => OllamaPullProgressEvent._();
  @$core.override
  OllamaPullProgressEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OllamaPullProgressEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OllamaPullProgressEvent>(create);
  static OllamaPullProgressEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get downloaded => $_getI64(1);
  @$pb.TagNumber(2)
  set downloaded($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDownloaded() => $_has(1);
  @$pb.TagNumber(2)
  void clearDownloaded() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get total => $_getI64(2);
  @$pb.TagNumber(3)
  set total($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get digest => $_getSZ(3);
  @$pb.TagNumber(4)
  set digest($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDigest() => $_has(3);
  @$pb.TagNumber(4)
  void clearDigest() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get done => $_getBF(5);
  @$pb.TagNumber(6)
  set done($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDone() => $_has(5);
  @$pb.TagNumber(6)
  void clearDone() => $_clearField(6);
}

/// Artifact mirrors internal/store.Artifact. attrs_json is a free-form
/// JSON object for kind-specific metadata (e.g. subtask_id for code
/// artifacts, harness version for harness artifacts).
class Artifact extends $pb.GeneratedMessage {
  factory Artifact({
    $core.String? id,
    $core.String? taskId,
    $core.String? subtaskId,
    $core.String? stage,
    $core.String? path,
    $core.String? kind,
    $core.String? contentHash,
    $fixnum.Int64? sizeBytes,
    $core.String? attrsJson,
    $2.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (taskId != null) result.taskId = taskId;
    if (subtaskId != null) result.subtaskId = subtaskId;
    if (stage != null) result.stage = stage;
    if (path != null) result.path = path;
    if (kind != null) result.kind = kind;
    if (contentHash != null) result.contentHash = contentHash;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (attrsJson != null) result.attrsJson = attrsJson;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  Artifact._();

  factory Artifact.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Artifact.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Artifact',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'taskId')
    ..aOS(3, _omitFieldNames ? '' : 'subtaskId')
    ..aOS(4, _omitFieldNames ? '' : 'stage')
    ..aOS(5, _omitFieldNames ? '' : 'path')
    ..aOS(6, _omitFieldNames ? '' : 'kind')
    ..aOS(7, _omitFieldNames ? '' : 'contentHash')
    ..aInt64(8, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(9, _omitFieldNames ? '' : 'attrsJson')
    ..aOM<$2.Timestamp>(10, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Artifact clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Artifact copyWith(void Function(Artifact) updates) =>
      super.copyWith((message) => updates(message as Artifact)) as Artifact;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Artifact create() => Artifact._();
  @$core.override
  Artifact createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Artifact getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Artifact>(create);
  static Artifact? _defaultInstance;

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
  $core.String get subtaskId => $_getSZ(2);
  @$pb.TagNumber(3)
  set subtaskId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubtaskId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubtaskId() => $_clearField(3);

  /// stage: plan | code | review | harness | attempt
  @$pb.TagNumber(4)
  $core.String get stage => $_getSZ(3);
  @$pb.TagNumber(4)
  set stage($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStage() => $_has(3);
  @$pb.TagNumber(4)
  void clearStage() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get path => $_getSZ(4);
  @$pb.TagNumber(5)
  set path($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPath() => $_has(4);
  @$pb.TagNumber(5)
  void clearPath() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get kind => $_getSZ(5);
  @$pb.TagNumber(6)
  set kind($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasKind() => $_has(5);
  @$pb.TagNumber(6)
  void clearKind() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get contentHash => $_getSZ(6);
  @$pb.TagNumber(7)
  set contentHash($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasContentHash() => $_has(6);
  @$pb.TagNumber(7)
  void clearContentHash() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get sizeBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSizeBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearSizeBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get attrsJson => $_getSZ(8);
  @$pb.TagNumber(9)
  set attrsJson($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAttrsJson() => $_has(8);
  @$pb.TagNumber(9)
  void clearAttrsJson() => $_clearField(9);

  @$pb.TagNumber(10)
  $2.Timestamp get createdAt => $_getN(9);
  @$pb.TagNumber(10)
  set createdAt($2.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearCreatedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $2.Timestamp ensureCreatedAt() => $_ensure(9);
}

class ListArtifactsRequest extends $pb.GeneratedMessage {
  factory ListArtifactsRequest({
    $core.String? taskId,
    $core.String? stage,
    $core.int? limit,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (taskId != null) result.taskId = taskId;
    if (stage != null) result.stage = stage;
    if (limit != null) result.limit = limit;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListArtifactsRequest._();

  factory ListArtifactsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListArtifactsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListArtifactsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'taskId')
    ..aOS(2, _omitFieldNames ? '' : 'stage')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..aI(4, _omitFieldNames ? '' : 'pageSize')
    ..aOS(5, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListArtifactsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListArtifactsRequest copyWith(void Function(ListArtifactsRequest) updates) =>
      super.copyWith((message) => updates(message as ListArtifactsRequest))
          as ListArtifactsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListArtifactsRequest create() => ListArtifactsRequest._();
  @$core.override
  ListArtifactsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListArtifactsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListArtifactsRequest>(create);
  static ListArtifactsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get taskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set taskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTaskId() => $_clearField(1);

  /// Optional filter on stage string. Empty = all stages.
  @$pb.TagNumber(2)
  $core.String get stage => $_getSZ(1);
  @$pb.TagNumber(2)
  set stage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStage() => $_has(1);
  @$pb.TagNumber(2)
  void clearStage() => $_clearField(2);

  /// Legacy hard cap (kept for wire compatibility with pre-pagination
  /// clients). New callers should use page_size instead. When both are
  /// set page_size wins.
  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);

  /// Maximum number of rows to return in this page. 0 delegates to the
  /// server default (currently 500). The server may return fewer rows
  /// than requested at the end of the result set.
  @$pb.TagNumber(4)
  $core.int get pageSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set pageSize($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPageSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearPageSize() => $_clearField(4);

  /// Opaque cursor returned by a previous ListArtifacts call. Empty on
  /// the first page. Callers MUST pass the exact bytes the server
  /// returned — format is an implementation detail and may change.
  @$pb.TagNumber(5)
  $core.String get pageToken => $_getSZ(4);
  @$pb.TagNumber(5)
  set pageToken($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPageToken() => $_has(4);
  @$pb.TagNumber(5)
  void clearPageToken() => $_clearField(5);
}

class ListArtifactsResponse extends $pb.GeneratedMessage {
  factory ListArtifactsResponse({
    $core.Iterable<Artifact>? artifacts,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (artifacts != null) result.artifacts.addAll(artifacts);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListArtifactsResponse._();

  factory ListArtifactsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListArtifactsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListArtifactsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<Artifact>(1, _omitFieldNames ? '' : 'artifacts',
        subBuilder: Artifact.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListArtifactsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListArtifactsResponse copyWith(
          void Function(ListArtifactsResponse) updates) =>
      super.copyWith((message) => updates(message as ListArtifactsResponse))
          as ListArtifactsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListArtifactsResponse create() => ListArtifactsResponse._();
  @$core.override
  ListArtifactsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListArtifactsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListArtifactsResponse>(create);
  static ListArtifactsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Artifact> get artifacts => $_getList(0);

  /// Non-empty when more rows are available. Pass to the next
  /// ListArtifacts call's page_token to continue. Empty on the final page.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

class GetArtifactRequest extends $pb.GeneratedMessage {
  factory GetArtifactRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetArtifactRequest._();

  factory GetArtifactRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetArtifactRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetArtifactRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetArtifactRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetArtifactRequest copyWith(void Function(GetArtifactRequest) updates) =>
      super.copyWith((message) => updates(message as GetArtifactRequest))
          as GetArtifactRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetArtifactRequest create() => GetArtifactRequest._();
  @$core.override
  GetArtifactRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetArtifactRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetArtifactRequest>(create);
  static GetArtifactRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class GetArtifactContentRequest extends $pb.GeneratedMessage {
  factory GetArtifactContentRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetArtifactContentRequest._();

  factory GetArtifactContentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetArtifactContentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetArtifactContentRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetArtifactContentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetArtifactContentRequest copyWith(
          void Function(GetArtifactContentRequest) updates) =>
      super.copyWith((message) => updates(message as GetArtifactContentRequest))
          as GetArtifactContentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetArtifactContentRequest create() => GetArtifactContentRequest._();
  @$core.override
  GetArtifactContentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetArtifactContentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetArtifactContentRequest>(create);
  static GetArtifactContentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

/// ArtifactChunk is one streaming chunk from GetContent. eof is set on
/// the final message; data may be empty when eof is true (flush sentinel).
class ArtifactChunk extends $pb.GeneratedMessage {
  factory ArtifactChunk({
    $core.List<$core.int>? data,
    $core.bool? eof,
  }) {
    final result = create();
    if (data != null) result.data = data;
    if (eof != null) result.eof = eof;
    return result;
  }

  ArtifactChunk._();

  factory ArtifactChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactChunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOB(2, _omitFieldNames ? '' : 'eof')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactChunk copyWith(void Function(ArtifactChunk) updates) =>
      super.copyWith((message) => updates(message as ArtifactChunk))
          as ArtifactChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactChunk create() => ArtifactChunk._();
  @$core.override
  ArtifactChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactChunk>(create);
  static ArtifactChunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get eof => $_getBF(1);
  @$pb.TagNumber(2)
  set eof($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEof() => $_has(1);
  @$pb.TagNumber(2)
  void clearEof() => $_clearField(2);
}

/// HarnessSkill is one immutable snapshot of the NL skill file. Each
/// UpdateSkill call mints a new version; the active version is the one
/// with the highest version number. artifact_id links back to the
/// Artifact row that backs this version on disk.
class HarnessSkill extends $pb.GeneratedMessage {
  factory HarnessSkill({
    $core.String? artifactId,
    $core.int? version,
    $core.String? contentMd,
    $2.Timestamp? createdAt,
    $core.String? contentHash,
  }) {
    final result = create();
    if (artifactId != null) result.artifactId = artifactId;
    if (version != null) result.version = version;
    if (contentMd != null) result.contentMd = contentMd;
    if (createdAt != null) result.createdAt = createdAt;
    if (contentHash != null) result.contentHash = contentHash;
    return result;
  }

  HarnessSkill._();

  factory HarnessSkill.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HarnessSkill.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HarnessSkill',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'artifactId')
    ..aI(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'contentMd')
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..aOS(5, _omitFieldNames ? '' : 'contentHash')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HarnessSkill clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HarnessSkill copyWith(void Function(HarnessSkill) updates) =>
      super.copyWith((message) => updates(message as HarnessSkill))
          as HarnessSkill;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HarnessSkill create() => HarnessSkill._();
  @$core.override
  HarnessSkill createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HarnessSkill getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HarnessSkill>(create);
  static HarnessSkill? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get artifactId => $_getSZ(0);
  @$pb.TagNumber(1)
  set artifactId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasArtifactId() => $_has(0);
  @$pb.TagNumber(1)
  void clearArtifactId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get contentMd => $_getSZ(2);
  @$pb.TagNumber(3)
  set contentMd($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContentMd() => $_has(2);
  @$pb.TagNumber(3)
  void clearContentMd() => $_clearField(3);

  @$pb.TagNumber(4)
  $2.Timestamp get createdAt => $_getN(3);
  @$pb.TagNumber(4)
  set createdAt($2.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureCreatedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get contentHash => $_getSZ(4);
  @$pb.TagNumber(5)
  set contentHash($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContentHash() => $_has(4);
  @$pb.TagNumber(5)
  void clearContentHash() => $_clearField(5);
}

class ListSkillVersionsResponse extends $pb.GeneratedMessage {
  factory ListSkillVersionsResponse({
    $core.Iterable<HarnessSkill>? versions,
  }) {
    final result = create();
    if (versions != null) result.versions.addAll(versions);
    return result;
  }

  ListSkillVersionsResponse._();

  factory ListSkillVersionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSkillVersionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSkillVersionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<HarnessSkill>(1, _omitFieldNames ? '' : 'versions',
        subBuilder: HarnessSkill.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillVersionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillVersionsResponse copyWith(
          void Function(ListSkillVersionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSkillVersionsResponse))
          as ListSkillVersionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSkillVersionsResponse create() => ListSkillVersionsResponse._();
  @$core.override
  ListSkillVersionsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListSkillVersionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSkillVersionsResponse>(create);
  static ListSkillVersionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<HarnessSkill> get versions => $_getList(0);
}

class ValidateSkillRequest extends $pb.GeneratedMessage {
  factory ValidateSkillRequest({
    $core.String? contentMd,
  }) {
    final result = create();
    if (contentMd != null) result.contentMd = contentMd;
    return result;
  }

  ValidateSkillRequest._();

  factory ValidateSkillRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidateSkillRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidateSkillRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'contentMd')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateSkillRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateSkillRequest copyWith(void Function(ValidateSkillRequest) updates) =>
      super.copyWith((message) => updates(message as ValidateSkillRequest))
          as ValidateSkillRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidateSkillRequest create() => ValidateSkillRequest._();
  @$core.override
  ValidateSkillRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ValidateSkillRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidateSkillRequest>(create);
  static ValidateSkillRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get contentMd => $_getSZ(0);
  @$pb.TagNumber(1)
  set contentMd($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContentMd() => $_has(0);
  @$pb.TagNumber(1)
  void clearContentMd() => $_clearField(1);
}

/// ValidateSkillResponse carries lint results for the proposed harness
/// content. ok=true means the content is safe to activate; warnings are
/// non-fatal style notes the UI may surface as inline hints.
class ValidateSkillResponse extends $pb.GeneratedMessage {
  factory ValidateSkillResponse({
    $core.bool? ok,
    $core.Iterable<$core.String>? errors,
    $core.Iterable<$core.String>? warnings,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (errors != null) result.errors.addAll(errors);
    if (warnings != null) result.warnings.addAll(warnings);
    return result;
  }

  ValidateSkillResponse._();

  factory ValidateSkillResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidateSkillResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidateSkillResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..pPS(2, _omitFieldNames ? '' : 'errors')
    ..pPS(3, _omitFieldNames ? '' : 'warnings')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateSkillResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateSkillResponse copyWith(
          void Function(ValidateSkillResponse) updates) =>
      super.copyWith((message) => updates(message as ValidateSkillResponse))
          as ValidateSkillResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidateSkillResponse create() => ValidateSkillResponse._();
  @$core.override
  ValidateSkillResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ValidateSkillResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidateSkillResponse>(create);
  static ValidateSkillResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get errors => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get warnings => $_getList(2);
}

class UpdateSkillRequest extends $pb.GeneratedMessage {
  factory UpdateSkillRequest({
    $core.String? contentMd,
  }) {
    final result = create();
    if (contentMd != null) result.contentMd = contentMd;
    return result;
  }

  UpdateSkillRequest._();

  factory UpdateSkillRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSkillRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSkillRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'contentMd')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSkillRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSkillRequest copyWith(void Function(UpdateSkillRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateSkillRequest))
          as UpdateSkillRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSkillRequest create() => UpdateSkillRequest._();
  @$core.override
  UpdateSkillRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateSkillRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSkillRequest>(create);
  static UpdateSkillRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get contentMd => $_getSZ(0);
  @$pb.TagNumber(1)
  set contentMd($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContentMd() => $_has(0);
  @$pb.TagNumber(1)
  void clearContentMd() => $_clearField(1);
}

class RollbackSkillRequest extends $pb.GeneratedMessage {
  factory RollbackSkillRequest({
    $core.String? artifactId,
  }) {
    final result = create();
    if (artifactId != null) result.artifactId = artifactId;
    return result;
  }

  RollbackSkillRequest._();

  factory RollbackSkillRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RollbackSkillRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RollbackSkillRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'artifactId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RollbackSkillRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RollbackSkillRequest copyWith(void Function(RollbackSkillRequest) updates) =>
      super.copyWith((message) => updates(message as RollbackSkillRequest))
          as RollbackSkillRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RollbackSkillRequest create() => RollbackSkillRequest._();
  @$core.override
  RollbackSkillRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RollbackSkillRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RollbackSkillRequest>(create);
  static RollbackSkillRequest? _defaultInstance;

  /// artifact_id of the HarnessSkill version to restore as the new active
  /// version. A new version row is created (rather than mutating history)
  /// so the audit trail is preserved.
  @$pb.TagNumber(1)
  $core.String get artifactId => $_getSZ(0);
  @$pb.TagNumber(1)
  set artifactId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasArtifactId() => $_has(0);
  @$pb.TagNumber(1)
  void clearArtifactId() => $_clearField(1);
}

/// HarnessAttempt mirrors internal/store.HarnessAttempt.
/// decision is one of: pending | approved | rejected | superseded.
/// proposed_patch is intentionally empty in Phase C; LLM patch generation
/// is wired in the subsequent Phase C LLM integration step.
class HarnessAttempt extends $pb.GeneratedMessage {
  factory HarnessAttempt({
    $core.String? id,
    $core.String? taskId,
    $core.int? reworkRound,
    $core.String? failureClass,
    $core.String? observationMd,
    $core.String? proposedPatch,
    $core.String? proposedHash,
    $core.String? decision,
    $core.String? decidedBy,
    $2.Timestamp? decidedAt,
    $2.Timestamp? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (taskId != null) result.taskId = taskId;
    if (reworkRound != null) result.reworkRound = reworkRound;
    if (failureClass != null) result.failureClass = failureClass;
    if (observationMd != null) result.observationMd = observationMd;
    if (proposedPatch != null) result.proposedPatch = proposedPatch;
    if (proposedHash != null) result.proposedHash = proposedHash;
    if (decision != null) result.decision = decision;
    if (decidedBy != null) result.decidedBy = decidedBy;
    if (decidedAt != null) result.decidedAt = decidedAt;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  HarnessAttempt._();

  factory HarnessAttempt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HarnessAttempt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HarnessAttempt',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'taskId')
    ..aI(3, _omitFieldNames ? '' : 'reworkRound')
    ..aOS(4, _omitFieldNames ? '' : 'failureClass')
    ..aOS(5, _omitFieldNames ? '' : 'observationMd')
    ..aOS(6, _omitFieldNames ? '' : 'proposedPatch')
    ..aOS(7, _omitFieldNames ? '' : 'proposedHash')
    ..aOS(8, _omitFieldNames ? '' : 'decision')
    ..aOS(9, _omitFieldNames ? '' : 'decidedBy')
    ..aOM<$2.Timestamp>(10, _omitFieldNames ? '' : 'decidedAt',
        subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(11, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HarnessAttempt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HarnessAttempt copyWith(void Function(HarnessAttempt) updates) =>
      super.copyWith((message) => updates(message as HarnessAttempt))
          as HarnessAttempt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HarnessAttempt create() => HarnessAttempt._();
  @$core.override
  HarnessAttempt createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HarnessAttempt getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HarnessAttempt>(create);
  static HarnessAttempt? _defaultInstance;

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
  $core.int get reworkRound => $_getIZ(2);
  @$pb.TagNumber(3)
  set reworkRound($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReworkRound() => $_has(2);
  @$pb.TagNumber(3)
  void clearReworkRound() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get failureClass => $_getSZ(3);
  @$pb.TagNumber(4)
  set failureClass($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFailureClass() => $_has(3);
  @$pb.TagNumber(4)
  void clearFailureClass() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get observationMd => $_getSZ(4);
  @$pb.TagNumber(5)
  set observationMd($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasObservationMd() => $_has(4);
  @$pb.TagNumber(5)
  void clearObservationMd() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get proposedPatch => $_getSZ(5);
  @$pb.TagNumber(6)
  set proposedPatch($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProposedPatch() => $_has(5);
  @$pb.TagNumber(6)
  void clearProposedPatch() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get proposedHash => $_getSZ(6);
  @$pb.TagNumber(7)
  set proposedHash($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProposedHash() => $_has(6);
  @$pb.TagNumber(7)
  void clearProposedHash() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get decision => $_getSZ(7);
  @$pb.TagNumber(8)
  set decision($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDecision() => $_has(7);
  @$pb.TagNumber(8)
  void clearDecision() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get decidedBy => $_getSZ(8);
  @$pb.TagNumber(9)
  set decidedBy($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDecidedBy() => $_has(8);
  @$pb.TagNumber(9)
  void clearDecidedBy() => $_clearField(9);

  @$pb.TagNumber(10)
  $2.Timestamp get decidedAt => $_getN(9);
  @$pb.TagNumber(10)
  set decidedAt($2.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasDecidedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearDecidedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $2.Timestamp ensureDecidedAt() => $_ensure(9);

  @$pb.TagNumber(11)
  $2.Timestamp get createdAt => $_getN(10);
  @$pb.TagNumber(11)
  set createdAt($2.Timestamp value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasCreatedAt() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreatedAt() => $_clearField(11);
  @$pb.TagNumber(11)
  $2.Timestamp ensureCreatedAt() => $_ensure(10);
}

class ListHarnessAttemptsResponse extends $pb.GeneratedMessage {
  factory ListHarnessAttemptsResponse({
    $core.Iterable<HarnessAttempt>? attempts,
  }) {
    final result = create();
    if (attempts != null) result.attempts.addAll(attempts);
    return result;
  }

  ListHarnessAttemptsResponse._();

  factory ListHarnessAttemptsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListHarnessAttemptsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListHarnessAttemptsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..pPM<HarnessAttempt>(1, _omitFieldNames ? '' : 'attempts',
        subBuilder: HarnessAttempt.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHarnessAttemptsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHarnessAttemptsResponse copyWith(
          void Function(ListHarnessAttemptsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListHarnessAttemptsResponse))
          as ListHarnessAttemptsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListHarnessAttemptsResponse create() =>
      ListHarnessAttemptsResponse._();
  @$core.override
  ListHarnessAttemptsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListHarnessAttemptsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListHarnessAttemptsResponse>(create);
  static ListHarnessAttemptsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<HarnessAttempt> get attempts => $_getList(0);
}

class ListHarnessAttemptsForTaskRequest extends $pb.GeneratedMessage {
  factory ListHarnessAttemptsForTaskRequest({
    $core.String? taskId,
  }) {
    final result = create();
    if (taskId != null) result.taskId = taskId;
    return result;
  }

  ListHarnessAttemptsForTaskRequest._();

  factory ListHarnessAttemptsForTaskRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListHarnessAttemptsForTaskRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListHarnessAttemptsForTaskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'taskId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHarnessAttemptsForTaskRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHarnessAttemptsForTaskRequest copyWith(
          void Function(ListHarnessAttemptsForTaskRequest) updates) =>
      super.copyWith((message) =>
              updates(message as ListHarnessAttemptsForTaskRequest))
          as ListHarnessAttemptsForTaskRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListHarnessAttemptsForTaskRequest create() =>
      ListHarnessAttemptsForTaskRequest._();
  @$core.override
  ListHarnessAttemptsForTaskRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListHarnessAttemptsForTaskRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListHarnessAttemptsForTaskRequest>(
          create);
  static ListHarnessAttemptsForTaskRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get taskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set taskId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTaskId() => $_clearField(1);
}

class ApproveHarnessAttemptRequest extends $pb.GeneratedMessage {
  factory ApproveHarnessAttemptRequest({
    $core.String? id,
    $core.String? decidedBy,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (decidedBy != null) result.decidedBy = decidedBy;
    return result;
  }

  ApproveHarnessAttemptRequest._();

  factory ApproveHarnessAttemptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApproveHarnessAttemptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApproveHarnessAttemptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'decidedBy')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveHarnessAttemptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveHarnessAttemptRequest copyWith(
          void Function(ApproveHarnessAttemptRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ApproveHarnessAttemptRequest))
          as ApproveHarnessAttemptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApproveHarnessAttemptRequest create() =>
      ApproveHarnessAttemptRequest._();
  @$core.override
  ApproveHarnessAttemptRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApproveHarnessAttemptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApproveHarnessAttemptRequest>(create);
  static ApproveHarnessAttemptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get decidedBy => $_getSZ(1);
  @$pb.TagNumber(2)
  set decidedBy($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDecidedBy() => $_has(1);
  @$pb.TagNumber(2)
  void clearDecidedBy() => $_clearField(2);
}

class RejectHarnessAttemptRequest extends $pb.GeneratedMessage {
  factory RejectHarnessAttemptRequest({
    $core.String? id,
    $core.String? decidedBy,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (decidedBy != null) result.decidedBy = decidedBy;
    return result;
  }

  RejectHarnessAttemptRequest._();

  factory RejectHarnessAttemptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RejectHarnessAttemptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RejectHarnessAttemptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'decidedBy')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectHarnessAttemptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectHarnessAttemptRequest copyWith(
          void Function(RejectHarnessAttemptRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RejectHarnessAttemptRequest))
          as RejectHarnessAttemptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RejectHarnessAttemptRequest create() =>
      RejectHarnessAttemptRequest._();
  @$core.override
  RejectHarnessAttemptRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RejectHarnessAttemptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RejectHarnessAttemptRequest>(create);
  static RejectHarnessAttemptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get decidedBy => $_getSZ(1);
  @$pb.TagNumber(2)
  set decidedBy($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDecidedBy() => $_has(1);
  @$pb.TagNumber(2)
  void clearDecidedBy() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
