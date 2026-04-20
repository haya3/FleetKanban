// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/insights.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use getInsightsRequestDescriptor instead')
const GetInsightsRequest$json = {
  '1': 'GetInsightsRequest',
  '2': [
    {'1': 'repository_id', '3': 1, '4': 1, '5': 9, '10': 'repositoryId'},
  ],
};

/// Descriptor for `GetInsightsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInsightsRequestDescriptor = $convert.base64Decode(
    'ChJHZXRJbnNpZ2h0c1JlcXVlc3QSIwoNcmVwb3NpdG9yeV9pZBgBIAEoCVIMcmVwb3NpdG9yeU'
    'lk');

@$core.Deprecated('Use insightsSummaryDescriptor instead')
const InsightsSummary$json = {
  '1': 'InsightsSummary',
  '2': [
    {'1': 'total_tasks', '3': 1, '4': 1, '5': 5, '10': 'totalTasks'},
    {'1': 'active_tasks', '3': 2, '4': 1, '5': 5, '10': 'activeTasks'},
    {'1': 'done_tasks', '3': 3, '4': 1, '5': 5, '10': 'doneTasks'},
    {'1': 'cancelled_tasks', '3': 4, '4': 1, '5': 5, '10': 'cancelledTasks'},
    {'1': 'aborted_tasks', '3': 5, '4': 1, '5': 5, '10': 'abortedTasks'},
    {'1': 'failed_tasks', '3': 6, '4': 1, '5': 5, '10': 'failedTasks'},
    {
      '1': 'completed_samples',
      '3': 7,
      '4': 1,
      '5': 5,
      '10': 'completedSamples'
    },
    {
      '1': 'avg_duration_seconds',
      '3': 8,
      '4': 1,
      '5': 1,
      '10': 'avgDurationSeconds'
    },
    {
      '1': 'median_duration_seconds',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'medianDurationSeconds'
    },
    {
      '1': 'p90_duration_seconds',
      '3': 10,
      '4': 1,
      '5': 1,
      '10': 'p90DurationSeconds'
    },
    {
      '1': 'rework_buckets',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ReworkBucket',
      '10': 'reworkBuckets'
    },
    {
      '1': 'failure_buckets',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.FailureBucket',
      '10': 'failureBuckets'
    },
    {
      '1': 'repositories',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.RepositoryInsight',
      '10': 'repositories'
    },
    {
      '1': 'daily_throughput',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.DailyThroughput',
      '10': 'dailyThroughput'
    },
    {'1': 'completion_rate', '3': 15, '4': 1, '5': 1, '10': 'completionRate'},
  ],
};

/// Descriptor for `InsightsSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List insightsSummaryDescriptor = $convert.base64Decode(
    'Cg9JbnNpZ2h0c1N1bW1hcnkSHwoLdG90YWxfdGFza3MYASABKAVSCnRvdGFsVGFza3MSIQoMYW'
    'N0aXZlX3Rhc2tzGAIgASgFUgthY3RpdmVUYXNrcxIdCgpkb25lX3Rhc2tzGAMgASgFUglkb25l'
    'VGFza3MSJwoPY2FuY2VsbGVkX3Rhc2tzGAQgASgFUg5jYW5jZWxsZWRUYXNrcxIjCg1hYm9ydG'
    'VkX3Rhc2tzGAUgASgFUgxhYm9ydGVkVGFza3MSIQoMZmFpbGVkX3Rhc2tzGAYgASgFUgtmYWls'
    'ZWRUYXNrcxIrChFjb21wbGV0ZWRfc2FtcGxlcxgHIAEoBVIQY29tcGxldGVkU2FtcGxlcxIwCh'
    'RhdmdfZHVyYXRpb25fc2Vjb25kcxgIIAEoAVISYXZnRHVyYXRpb25TZWNvbmRzEjYKF21lZGlh'
    'bl9kdXJhdGlvbl9zZWNvbmRzGAkgASgBUhVtZWRpYW5EdXJhdGlvblNlY29uZHMSMAoUcDkwX2'
    'R1cmF0aW9uX3NlY29uZHMYCiABKAFSEnA5MER1cmF0aW9uU2Vjb25kcxJDCg5yZXdvcmtfYnVj'
    'a2V0cxgLIAMoCzIcLmZsZWV0a2FuYmFuLnYxLlJld29ya0J1Y2tldFINcmV3b3JrQnVja2V0cx'
    'JGCg9mYWlsdXJlX2J1Y2tldHMYDCADKAsyHS5mbGVldGthbmJhbi52MS5GYWlsdXJlQnVja2V0'
    'Ug5mYWlsdXJlQnVja2V0cxJFCgxyZXBvc2l0b3JpZXMYDSADKAsyIS5mbGVldGthbmJhbi52MS'
    '5SZXBvc2l0b3J5SW5zaWdodFIMcmVwb3NpdG9yaWVzEkoKEGRhaWx5X3Rocm91Z2hwdXQYDiAD'
    'KAsyHy5mbGVldGthbmJhbi52MS5EYWlseVRocm91Z2hwdXRSD2RhaWx5VGhyb3VnaHB1dBInCg'
    '9jb21wbGV0aW9uX3JhdGUYDyABKAFSDmNvbXBsZXRpb25SYXRl');

@$core.Deprecated('Use reworkBucketDescriptor instead')
const ReworkBucket$json = {
  '1': 'ReworkBucket',
  '2': [
    {'1': 'rework_count', '3': 1, '4': 1, '5': 5, '10': 'reworkCount'},
    {'1': 'task_count', '3': 2, '4': 1, '5': 5, '10': 'taskCount'},
  ],
};

/// Descriptor for `ReworkBucket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reworkBucketDescriptor = $convert.base64Decode(
    'CgxSZXdvcmtCdWNrZXQSIQoMcmV3b3JrX2NvdW50GAEgASgFUgtyZXdvcmtDb3VudBIdCgp0YX'
    'NrX2NvdW50GAIgASgFUgl0YXNrQ291bnQ=');

@$core.Deprecated('Use failureBucketDescriptor instead')
const FailureBucket$json = {
  '1': 'FailureBucket',
  '2': [
    {'1': 'error_code', '3': 1, '4': 1, '5': 9, '10': 'errorCode'},
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `FailureBucket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List failureBucketDescriptor = $convert.base64Decode(
    'Cg1GYWlsdXJlQnVja2V0Eh0KCmVycm9yX2NvZGUYASABKAlSCWVycm9yQ29kZRIUCgVjb3VudB'
    'gCIAEoBVIFY291bnQ=');

@$core.Deprecated('Use repositoryInsightDescriptor instead')
const RepositoryInsight$json = {
  '1': 'RepositoryInsight',
  '2': [
    {'1': 'repository_id', '3': 1, '4': 1, '5': 9, '10': 'repositoryId'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'total', '3': 3, '4': 1, '5': 5, '10': 'total'},
    {'1': 'done', '3': 4, '4': 1, '5': 5, '10': 'done'},
    {'1': 'failed', '3': 5, '4': 1, '5': 5, '10': 'failed'},
    {'1': 'aborted', '3': 6, '4': 1, '5': 5, '10': 'aborted'},
    {'1': 'cancelled', '3': 7, '4': 1, '5': 5, '10': 'cancelled'},
    {'1': 'completion_rate', '3': 8, '4': 1, '5': 1, '10': 'completionRate'},
    {
      '1': 'avg_duration_seconds',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'avgDurationSeconds'
    },
  ],
};

/// Descriptor for `RepositoryInsight`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryInsightDescriptor = $convert.base64Decode(
    'ChFSZXBvc2l0b3J5SW5zaWdodBIjCg1yZXBvc2l0b3J5X2lkGAEgASgJUgxyZXBvc2l0b3J5SW'
    'QSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZRIUCgV0b3RhbBgDIAEoBVIFdG90'
    'YWwSEgoEZG9uZRgEIAEoBVIEZG9uZRIWCgZmYWlsZWQYBSABKAVSBmZhaWxlZBIYCgdhYm9ydG'
    'VkGAYgASgFUgdhYm9ydGVkEhwKCWNhbmNlbGxlZBgHIAEoBVIJY2FuY2VsbGVkEicKD2NvbXBs'
    'ZXRpb25fcmF0ZRgIIAEoAVIOY29tcGxldGlvblJhdGUSMAoUYXZnX2R1cmF0aW9uX3NlY29uZH'
    'MYCSABKAFSEmF2Z0R1cmF0aW9uU2Vjb25kcw==');

@$core.Deprecated('Use dailyThroughputDescriptor instead')
const DailyThroughput$json = {
  '1': 'DailyThroughput',
  '2': [
    {'1': 'date', '3': 1, '4': 1, '5': 9, '10': 'date'},
    {'1': 'completed', '3': 2, '4': 1, '5': 5, '10': 'completed'},
    {'1': 'failed', '3': 3, '4': 1, '5': 5, '10': 'failed'},
  ],
};

/// Descriptor for `DailyThroughput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dailyThroughputDescriptor = $convert.base64Decode(
    'Cg9EYWlseVRocm91Z2hwdXQSEgoEZGF0ZRgBIAEoCVIEZGF0ZRIcCgljb21wbGV0ZWQYAiABKA'
    'VSCWNvbXBsZXRlZBIWCgZmYWlsZWQYAyABKAVSBmZhaWxlZA==');
