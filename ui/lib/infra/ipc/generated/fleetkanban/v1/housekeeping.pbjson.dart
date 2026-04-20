// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/housekeeping.proto.

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

@$core.Deprecated('Use getAutoSweepDaysResponseDescriptor instead')
const GetAutoSweepDaysResponse$json = {
  '1': 'GetAutoSweepDaysResponse',
  '2': [
    {'1': 'days', '3': 1, '4': 1, '5': 5, '10': 'days'},
    {'1': 'present', '3': 2, '4': 1, '5': 8, '10': 'present'},
  ],
};

/// Descriptor for `GetAutoSweepDaysResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAutoSweepDaysResponseDescriptor =
    $convert.base64Decode(
        'ChhHZXRBdXRvU3dlZXBEYXlzUmVzcG9uc2USEgoEZGF5cxgBIAEoBVIEZGF5cxIYCgdwcmVzZW'
        '50GAIgASgIUgdwcmVzZW50');

@$core.Deprecated('Use setAutoSweepDaysRequestDescriptor instead')
const SetAutoSweepDaysRequest$json = {
  '1': 'SetAutoSweepDaysRequest',
  '2': [
    {'1': 'days', '3': 1, '4': 1, '5': 5, '10': 'days'},
  ],
};

/// Descriptor for `SetAutoSweepDaysRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setAutoSweepDaysRequestDescriptor =
    $convert.base64Decode(
        'ChdTZXRBdXRvU3dlZXBEYXlzUmVxdWVzdBISCgRkYXlzGAEgASgFUgRkYXlz');

@$core.Deprecated('Use setAutoSweepDaysResponseDescriptor instead')
const SetAutoSweepDaysResponse$json = {
  '1': 'SetAutoSweepDaysResponse',
  '2': [
    {'1': 'effective_days', '3': 1, '4': 1, '5': 5, '10': 'effectiveDays'},
  ],
};

/// Descriptor for `SetAutoSweepDaysResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setAutoSweepDaysResponseDescriptor =
    $convert.base64Decode(
        'ChhTZXRBdXRvU3dlZXBEYXlzUmVzcG9uc2USJQoOZWZmZWN0aXZlX2RheXMYASABKAVSDWVmZm'
        'VjdGl2ZURheXM=');

@$core.Deprecated('Use listStaleBranchesRequestDescriptor instead')
const ListStaleBranchesRequest$json = {
  '1': 'ListStaleBranchesRequest',
  '2': [
    {'1': 'older_than_days', '3': 1, '4': 1, '5': 5, '10': 'olderThanDays'},
  ],
};

/// Descriptor for `ListStaleBranchesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listStaleBranchesRequestDescriptor =
    $convert.base64Decode(
        'ChhMaXN0U3RhbGVCcmFuY2hlc1JlcXVlc3QSJgoPb2xkZXJfdGhhbl9kYXlzGAEgASgFUg1vbG'
        'RlclRoYW5EYXlz');

@$core.Deprecated('Use staleBranchDescriptor instead')
const StaleBranch$json = {
  '1': 'StaleBranch',
  '2': [
    {'1': 'task_id', '3': 1, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'repo_id', '3': 2, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'repo_path', '3': 3, '4': 1, '5': 9, '10': 'repoPath'},
    {'1': 'branch', '3': 4, '4': 1, '5': 9, '10': 'branch'},
    {'1': 'base_branch', '3': 5, '4': 1, '5': 9, '10': 'baseBranch'},
    {'1': 'goal', '3': 6, '4': 1, '5': 9, '10': 'goal'},
    {'1': 'status', '3': 7, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'finished_at',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'finishedAt'
    },
    {'1': 'age_days', '3': 9, '4': 1, '5': 5, '10': 'ageDays'},
    {'1': 'merged', '3': 10, '4': 1, '5': 8, '10': 'merged'},
  ],
};

/// Descriptor for `StaleBranch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List staleBranchDescriptor = $convert.base64Decode(
    'CgtTdGFsZUJyYW5jaBIXCgd0YXNrX2lkGAEgASgJUgZ0YXNrSWQSFwoHcmVwb19pZBgCIAEoCV'
    'IGcmVwb0lkEhsKCXJlcG9fcGF0aBgDIAEoCVIIcmVwb1BhdGgSFgoGYnJhbmNoGAQgASgJUgZi'
    'cmFuY2gSHwoLYmFzZV9icmFuY2gYBSABKAlSCmJhc2VCcmFuY2gSEgoEZ29hbBgGIAEoCVIEZ2'
    '9hbBIWCgZzdGF0dXMYByABKAlSBnN0YXR1cxI7CgtmaW5pc2hlZF9hdBgIIAEoCzIaLmdvb2ds'
    'ZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmZpbmlzaGVkQXQSGQoIYWdlX2RheXMYCSABKAVSB2FnZU'
    'RheXMSFgoGbWVyZ2VkGAogASgIUgZtZXJnZWQ=');

@$core.Deprecated('Use listStaleBranchesResponseDescriptor instead')
const ListStaleBranchesResponse$json = {
  '1': 'ListStaleBranchesResponse',
  '2': [
    {
      '1': 'branches',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.StaleBranch',
      '10': 'branches'
    },
  ],
};

/// Descriptor for `ListStaleBranchesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listStaleBranchesResponseDescriptor =
    $convert.base64Decode(
        'ChlMaXN0U3RhbGVCcmFuY2hlc1Jlc3BvbnNlEjcKCGJyYW5jaGVzGAEgAygLMhsuZmxlZXRrYW'
        '5iYW4udjEuU3RhbGVCcmFuY2hSCGJyYW5jaGVz');

@$core.Deprecated('Use runSweepNowRequestDescriptor instead')
const RunSweepNowRequest$json = {
  '1': 'RunSweepNowRequest',
  '2': [
    {'1': 'days', '3': 1, '4': 1, '5': 5, '10': 'days'},
  ],
};

/// Descriptor for `RunSweepNowRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runSweepNowRequestDescriptor = $convert
    .base64Decode('ChJSdW5Td2VlcE5vd1JlcXVlc3QSEgoEZGF5cxgBIAEoBVIEZGF5cw==');

@$core.Deprecated('Use runSweepNowResponseDescriptor instead')
const RunSweepNowResponse$json = {
  '1': 'RunSweepNowResponse',
  '2': [
    {'1': 'considered', '3': 1, '4': 1, '5': 5, '10': 'considered'},
    {'1': 'deleted', '3': 2, '4': 1, '5': 5, '10': 'deleted'},
    {'1': 'skipped', '3': 3, '4': 1, '5': 5, '10': 'skipped'},
  ],
};

/// Descriptor for `RunSweepNowResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runSweepNowResponseDescriptor = $convert.base64Decode(
    'ChNSdW5Td2VlcE5vd1Jlc3BvbnNlEh4KCmNvbnNpZGVyZWQYASABKAVSCmNvbnNpZGVyZWQSGA'
    'oHZGVsZXRlZBgCIAEoBVIHZGVsZXRlZBIYCgdza2lwcGVkGAMgASgFUgdza2lwcGVk');
