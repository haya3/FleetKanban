// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/insights.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class GetInsightsRequest extends $pb.GeneratedMessage {
  factory GetInsightsRequest({
    $core.String? repositoryId,
  }) {
    final result = create();
    if (repositoryId != null) result.repositoryId = repositoryId;
    return result;
  }

  GetInsightsRequest._();

  factory GetInsightsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInsightsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInsightsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repositoryId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInsightsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInsightsRequest copyWith(void Function(GetInsightsRequest) updates) =>
      super.copyWith((message) => updates(message as GetInsightsRequest))
          as GetInsightsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInsightsRequest create() => GetInsightsRequest._();
  @$core.override
  GetInsightsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInsightsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInsightsRequest>(create);
  static GetInsightsRequest? _defaultInstance;

  /// Repository scope. Empty = all repositories.
  @$pb.TagNumber(1)
  $core.String get repositoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repositoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepositoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepositoryId() => $_clearField(1);
}

/// InsightsSummary bundles every metric the dashboard needs in one
/// round-trip. Fields with "_seconds" suffix are floating-point seconds so
/// the UI can format them as hh:mm:ss without another server call.
class InsightsSummary extends $pb.GeneratedMessage {
  factory InsightsSummary({
    $core.int? totalTasks,
    $core.int? activeTasks,
    $core.int? doneTasks,
    $core.int? cancelledTasks,
    $core.int? abortedTasks,
    $core.int? failedTasks,
    $core.int? completedSamples,
    $core.double? avgDurationSeconds,
    $core.double? medianDurationSeconds,
    $core.double? p90DurationSeconds,
    $core.Iterable<ReworkBucket>? reworkBuckets,
    $core.Iterable<FailureBucket>? failureBuckets,
    $core.Iterable<RepositoryInsight>? repositories,
    $core.Iterable<DailyThroughput>? dailyThroughput,
    $core.double? completionRate,
  }) {
    final result = create();
    if (totalTasks != null) result.totalTasks = totalTasks;
    if (activeTasks != null) result.activeTasks = activeTasks;
    if (doneTasks != null) result.doneTasks = doneTasks;
    if (cancelledTasks != null) result.cancelledTasks = cancelledTasks;
    if (abortedTasks != null) result.abortedTasks = abortedTasks;
    if (failedTasks != null) result.failedTasks = failedTasks;
    if (completedSamples != null) result.completedSamples = completedSamples;
    if (avgDurationSeconds != null)
      result.avgDurationSeconds = avgDurationSeconds;
    if (medianDurationSeconds != null)
      result.medianDurationSeconds = medianDurationSeconds;
    if (p90DurationSeconds != null)
      result.p90DurationSeconds = p90DurationSeconds;
    if (reworkBuckets != null) result.reworkBuckets.addAll(reworkBuckets);
    if (failureBuckets != null) result.failureBuckets.addAll(failureBuckets);
    if (repositories != null) result.repositories.addAll(repositories);
    if (dailyThroughput != null) result.dailyThroughput.addAll(dailyThroughput);
    if (completionRate != null) result.completionRate = completionRate;
    return result;
  }

  InsightsSummary._();

  factory InsightsSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InsightsSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InsightsSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'totalTasks')
    ..aI(2, _omitFieldNames ? '' : 'activeTasks')
    ..aI(3, _omitFieldNames ? '' : 'doneTasks')
    ..aI(4, _omitFieldNames ? '' : 'cancelledTasks')
    ..aI(5, _omitFieldNames ? '' : 'abortedTasks')
    ..aI(6, _omitFieldNames ? '' : 'failedTasks')
    ..aI(7, _omitFieldNames ? '' : 'completedSamples')
    ..aD(8, _omitFieldNames ? '' : 'avgDurationSeconds')
    ..aD(9, _omitFieldNames ? '' : 'medianDurationSeconds')
    ..aD(10, _omitFieldNames ? '' : 'p90DurationSeconds')
    ..pPM<ReworkBucket>(11, _omitFieldNames ? '' : 'reworkBuckets',
        subBuilder: ReworkBucket.create)
    ..pPM<FailureBucket>(12, _omitFieldNames ? '' : 'failureBuckets',
        subBuilder: FailureBucket.create)
    ..pPM<RepositoryInsight>(13, _omitFieldNames ? '' : 'repositories',
        subBuilder: RepositoryInsight.create)
    ..pPM<DailyThroughput>(14, _omitFieldNames ? '' : 'dailyThroughput',
        subBuilder: DailyThroughput.create)
    ..aD(15, _omitFieldNames ? '' : 'completionRate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InsightsSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InsightsSummary copyWith(void Function(InsightsSummary) updates) =>
      super.copyWith((message) => updates(message as InsightsSummary))
          as InsightsSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InsightsSummary create() => InsightsSummary._();
  @$core.override
  InsightsSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InsightsSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InsightsSummary>(create);
  static InsightsSummary? _defaultInstance;

  /// Totals across the scope.
  @$pb.TagNumber(1)
  $core.int get totalTasks => $_getIZ(0);
  @$pb.TagNumber(1)
  set totalTasks($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotalTasks() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotalTasks() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get activeTasks => $_getIZ(1);
  @$pb.TagNumber(2)
  set activeTasks($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActiveTasks() => $_has(1);
  @$pb.TagNumber(2)
  void clearActiveTasks() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get doneTasks => $_getIZ(2);
  @$pb.TagNumber(3)
  set doneTasks($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDoneTasks() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoneTasks() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get cancelledTasks => $_getIZ(3);
  @$pb.TagNumber(4)
  set cancelledTasks($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCancelledTasks() => $_has(3);
  @$pb.TagNumber(4)
  void clearCancelledTasks() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get abortedTasks => $_getIZ(4);
  @$pb.TagNumber(5)
  set abortedTasks($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAbortedTasks() => $_has(4);
  @$pb.TagNumber(5)
  void clearAbortedTasks() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get failedTasks => $_getIZ(5);
  @$pb.TagNumber(6)
  set failedTasks($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFailedTasks() => $_has(5);
  @$pb.TagNumber(6)
  void clearFailedTasks() => $_clearField(6);

  /// Completion metrics over tasks that have both started_at and finished_at
  /// (i.e. actually ran to completion or terminal failure).
  @$pb.TagNumber(7)
  $core.int get completedSamples => $_getIZ(6);
  @$pb.TagNumber(7)
  set completedSamples($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCompletedSamples() => $_has(6);
  @$pb.TagNumber(7)
  void clearCompletedSamples() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get avgDurationSeconds => $_getN(7);
  @$pb.TagNumber(8)
  set avgDurationSeconds($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAvgDurationSeconds() => $_has(7);
  @$pb.TagNumber(8)
  void clearAvgDurationSeconds() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get medianDurationSeconds => $_getN(8);
  @$pb.TagNumber(9)
  set medianDurationSeconds($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMedianDurationSeconds() => $_has(8);
  @$pb.TagNumber(9)
  void clearMedianDurationSeconds() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get p90DurationSeconds => $_getN(9);
  @$pb.TagNumber(10)
  set p90DurationSeconds($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasP90DurationSeconds() => $_has(9);
  @$pb.TagNumber(10)
  void clearP90DurationSeconds() => $_clearField(10);

  /// Rework histogram: one bucket per observed rework_count value where
  /// at least one task lives. Ascending by rework_count.
  @$pb.TagNumber(11)
  $pb.PbList<ReworkBucket> get reworkBuckets => $_getList(10);

  /// Failure breakdown by error_code (only failed tasks). Descending by count.
  @$pb.TagNumber(12)
  $pb.PbList<FailureBucket> get failureBuckets => $_getList(11);

  /// Per-repository rows, ordered by total tasks desc. Only populated when
  /// the request scope is "all repositories" (repository_id empty); when a
  /// specific repo is requested this slice is empty and the caller should
  /// render the top-level totals instead.
  @$pb.TagNumber(13)
  $pb.PbList<RepositoryInsight> get repositories => $_getList(12);

  /// Rolling 30-day throughput: one entry per calendar day (UTC), oldest
  /// first, for the past 30 days. Days with zero completions are included
  /// so the UI can render a continuous sparkline without gap handling.
  @$pb.TagNumber(14)
  $pb.PbList<DailyThroughput> get dailyThroughput => $_getList(13);

  /// Computed server-side as done_tasks / (done_tasks + failed_tasks +
  /// aborted_tasks + cancelled_tasks), range [0, 1]. 0 when no terminal
  /// tasks exist so the UI can suppress the badge instead of showing NaN.
  @$pb.TagNumber(15)
  $core.double get completionRate => $_getN(14);
  @$pb.TagNumber(15)
  set completionRate($core.double value) => $_setDouble(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCompletionRate() => $_has(14);
  @$pb.TagNumber(15)
  void clearCompletionRate() => $_clearField(15);
}

class ReworkBucket extends $pb.GeneratedMessage {
  factory ReworkBucket({
    $core.int? reworkCount,
    $core.int? taskCount,
  }) {
    final result = create();
    if (reworkCount != null) result.reworkCount = reworkCount;
    if (taskCount != null) result.taskCount = taskCount;
    return result;
  }

  ReworkBucket._();

  factory ReworkBucket.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReworkBucket.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReworkBucket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'reworkCount')
    ..aI(2, _omitFieldNames ? '' : 'taskCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReworkBucket clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReworkBucket copyWith(void Function(ReworkBucket) updates) =>
      super.copyWith((message) => updates(message as ReworkBucket))
          as ReworkBucket;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReworkBucket create() => ReworkBucket._();
  @$core.override
  ReworkBucket createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReworkBucket getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReworkBucket>(create);
  static ReworkBucket? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get reworkCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set reworkCount($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReworkCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearReworkCount() => $_clearField(1);

  /// required N AI-review retry cycles.
  @$pb.TagNumber(2)
  $core.int get taskCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set taskCount($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTaskCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskCount() => $_clearField(2);
}

class FailureBucket extends $pb.GeneratedMessage {
  factory FailureBucket({
    $core.String? errorCode,
    $core.int? count,
  }) {
    final result = create();
    if (errorCode != null) result.errorCode = errorCode;
    if (count != null) result.count = count;
    return result;
  }

  FailureBucket._();

  factory FailureBucket.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FailureBucket.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FailureBucket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'errorCode')
    ..aI(2, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FailureBucket clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FailureBucket copyWith(void Function(FailureBucket) updates) =>
      super.copyWith((message) => updates(message as FailureBucket))
          as FailureBucket;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FailureBucket create() => FailureBucket._();
  @$core.override
  FailureBucket createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FailureBucket getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FailureBucket>(create);
  static FailureBucket? _defaultInstance;

  /// error_code as persisted in tasks.error_code (e.g. "auth", "runner",
  /// "ai_review", "interrupted"). Forwarded verbatim so new codes do not
  /// require a proto bump.
  @$pb.TagNumber(1)
  $core.String get errorCode => $_getSZ(0);
  @$pb.TagNumber(1)
  set errorCode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrorCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrorCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(2)
  set count($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

class RepositoryInsight extends $pb.GeneratedMessage {
  factory RepositoryInsight({
    $core.String? repositoryId,
    $core.String? displayName,
    $core.int? total,
    $core.int? done,
    $core.int? failed,
    $core.int? aborted,
    $core.int? cancelled,
    $core.double? completionRate,
    $core.double? avgDurationSeconds,
  }) {
    final result = create();
    if (repositoryId != null) result.repositoryId = repositoryId;
    if (displayName != null) result.displayName = displayName;
    if (total != null) result.total = total;
    if (done != null) result.done = done;
    if (failed != null) result.failed = failed;
    if (aborted != null) result.aborted = aborted;
    if (cancelled != null) result.cancelled = cancelled;
    if (completionRate != null) result.completionRate = completionRate;
    if (avgDurationSeconds != null)
      result.avgDurationSeconds = avgDurationSeconds;
    return result;
  }

  RepositoryInsight._();

  factory RepositoryInsight.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RepositoryInsight.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RepositoryInsight',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repositoryId')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aI(3, _omitFieldNames ? '' : 'total')
    ..aI(4, _omitFieldNames ? '' : 'done')
    ..aI(5, _omitFieldNames ? '' : 'failed')
    ..aI(6, _omitFieldNames ? '' : 'aborted')
    ..aI(7, _omitFieldNames ? '' : 'cancelled')
    ..aD(8, _omitFieldNames ? '' : 'completionRate')
    ..aD(9, _omitFieldNames ? '' : 'avgDurationSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RepositoryInsight clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RepositoryInsight copyWith(void Function(RepositoryInsight) updates) =>
      super.copyWith((message) => updates(message as RepositoryInsight))
          as RepositoryInsight;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RepositoryInsight create() => RepositoryInsight._();
  @$core.override
  RepositoryInsight createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RepositoryInsight getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RepositoryInsight>(create);
  static RepositoryInsight? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repositoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set repositoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepositoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepositoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get total => $_getIZ(2);
  @$pb.TagNumber(3)
  set total($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get done => $_getIZ(3);
  @$pb.TagNumber(4)
  set done($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDone() => $_has(3);
  @$pb.TagNumber(4)
  void clearDone() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get failed => $_getIZ(4);
  @$pb.TagNumber(5)
  set failed($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFailed() => $_has(4);
  @$pb.TagNumber(5)
  void clearFailed() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get aborted => $_getIZ(5);
  @$pb.TagNumber(6)
  set aborted($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAborted() => $_has(5);
  @$pb.TagNumber(6)
  void clearAborted() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get cancelled => $_getIZ(6);
  @$pb.TagNumber(7)
  set cancelled($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCancelled() => $_has(6);
  @$pb.TagNumber(7)
  void clearCancelled() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get completionRate => $_getN(7);
  @$pb.TagNumber(8)
  set completionRate($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCompletionRate() => $_has(7);
  @$pb.TagNumber(8)
  void clearCompletionRate() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get avgDurationSeconds => $_getN(8);
  @$pb.TagNumber(9)
  set avgDurationSeconds($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAvgDurationSeconds() => $_has(8);
  @$pb.TagNumber(9)
  void clearAvgDurationSeconds() => $_clearField(9);
}

class DailyThroughput extends $pb.GeneratedMessage {
  factory DailyThroughput({
    $core.String? date,
    $core.int? completed,
    $core.int? failed,
  }) {
    final result = create();
    if (date != null) result.date = date;
    if (completed != null) result.completed = completed;
    if (failed != null) result.failed = failed;
    return result;
  }

  DailyThroughput._();

  factory DailyThroughput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DailyThroughput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DailyThroughput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'fleetkanban.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'date')
    ..aI(2, _omitFieldNames ? '' : 'completed')
    ..aI(3, _omitFieldNames ? '' : 'failed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DailyThroughput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DailyThroughput copyWith(void Function(DailyThroughput) updates) =>
      super.copyWith((message) => updates(message as DailyThroughput))
          as DailyThroughput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DailyThroughput create() => DailyThroughput._();
  @$core.override
  DailyThroughput createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DailyThroughput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DailyThroughput>(create);
  static DailyThroughput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get date => $_getSZ(0);
  @$pb.TagNumber(1)
  set date($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDate() => $_has(0);
  @$pb.TagNumber(1)
  void clearDate() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get completed => $_getIZ(1);
  @$pb.TagNumber(2)
  set completed($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCompleted() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompleted() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get failed => $_getIZ(2);
  @$pb.TagNumber(3)
  set failed($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFailed() => $_has(2);
  @$pb.TagNumber(3)
  void clearFailed() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
