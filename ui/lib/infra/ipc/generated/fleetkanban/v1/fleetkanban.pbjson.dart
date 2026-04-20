// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/fleetkanban.proto.

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

@$core.Deprecated('Use finalizeActionDescriptor instead')
const FinalizeAction$json = {
  '1': 'FinalizeAction',
  '2': [
    {'1': 'FINALIZE_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'FINALIZE_ACTION_KEEP', '2': 1},
    {'1': 'FINALIZE_ACTION_MERGE', '2': 2},
    {'1': 'FINALIZE_ACTION_DISCARD', '2': 3},
  ],
};

/// Descriptor for `FinalizeAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List finalizeActionDescriptor = $convert.base64Decode(
    'Cg5GaW5hbGl6ZUFjdGlvbhIfChtGSU5BTElaRV9BQ1RJT05fVU5TUEVDSUZJRUQQABIYChRGSU'
    '5BTElaRV9BQ1RJT05fS0VFUBABEhkKFUZJTkFMSVpFX0FDVElPTl9NRVJHRRACEhsKF0ZJTkFM'
    'SVpFX0FDVElPTl9ESVNDQVJEEAM=');

@$core.Deprecated('Use reviewActionDescriptor instead')
const ReviewAction$json = {
  '1': 'ReviewAction',
  '2': [
    {'1': 'REVIEW_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'REVIEW_ACTION_APPROVE', '2': 1},
    {'1': 'REVIEW_ACTION_REWORK', '2': 2},
    {'1': 'REVIEW_ACTION_REJECT', '2': 3},
  ],
};

/// Descriptor for `ReviewAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List reviewActionDescriptor = $convert.base64Decode(
    'CgxSZXZpZXdBY3Rpb24SHQoZUkVWSUVXX0FDVElPTl9VTlNQRUNJRklFRBAAEhkKFVJFVklFV1'
    '9BQ1RJT05fQVBQUk9WRRABEhgKFFJFVklFV19BQ1RJT05fUkVXT1JLEAISGAoUUkVWSUVXX0FD'
    'VElPTl9SRUpFQ1QQAw==');

@$core.Deprecated('Use copilotLoginSessionStateDescriptor instead')
const CopilotLoginSessionState$json = {
  '1': 'CopilotLoginSessionState',
  '2': [
    {'1': 'COPILOT_LOGIN_SESSION_STATE_UNSPECIFIED', '2': 0},
    {'1': 'COPILOT_LOGIN_SESSION_STATE_IDLE', '2': 1},
    {'1': 'COPILOT_LOGIN_SESSION_STATE_RUNNING', '2': 2},
    {'1': 'COPILOT_LOGIN_SESSION_STATE_SUCCEEDED', '2': 3},
    {'1': 'COPILOT_LOGIN_SESSION_STATE_FAILED', '2': 4},
  ],
};

/// Descriptor for `CopilotLoginSessionState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List copilotLoginSessionStateDescriptor = $convert.base64Decode(
    'ChhDb3BpbG90TG9naW5TZXNzaW9uU3RhdGUSKwonQ09QSUxPVF9MT0dJTl9TRVNTSU9OX1NUQV'
    'RFX1VOU1BFQ0lGSUVEEAASJAogQ09QSUxPVF9MT0dJTl9TRVNTSU9OX1NUQVRFX0lETEUQARIn'
    'CiNDT1BJTE9UX0xPR0lOX1NFU1NJT05fU1RBVEVfUlVOTklORxACEikKJUNPUElMT1RfTE9HSU'
    '5fU0VTU0lPTl9TVEFURV9TVUNDRUVERUQQAxImCiJDT1BJTE9UX0xPR0lOX1NFU1NJT05fU1RB'
    'VEVfRkFJTEVEEAQ=');

@$core.Deprecated('Use idRequestDescriptor instead')
const IdRequest$json = {
  '1': 'IdRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `IdRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List idRequestDescriptor =
    $convert.base64Decode('CglJZFJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use boolValueDescriptor instead')
const BoolValue$json = {
  '1': 'BoolValue',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `BoolValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List boolValueDescriptor =
    $convert.base64Decode('CglCb29sVmFsdWUSFAoFdmFsdWUYASABKAhSBXZhbHVl');

@$core.Deprecated('Use intValueDescriptor instead')
const IntValue$json = {
  '1': 'IntValue',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `IntValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List intValueDescriptor =
    $convert.base64Decode('CghJbnRWYWx1ZRIUCgV2YWx1ZRgBIAEoBVIFdmFsdWU=');

@$core.Deprecated('Use versionInfoDescriptor instead')
const VersionInfo$json = {
  '1': 'VersionInfo',
  '2': [
    {'1': 'protocol_version', '3': 1, '4': 1, '5': 5, '10': 'protocolVersion'},
    {'1': 'app_version', '3': 2, '4': 1, '5': 9, '10': 'appVersion'},
    {
      '1': 'copilot_sdk_version',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'copilotSdkVersion'
    },
    {'1': 'go_version', '3': 4, '4': 1, '5': 9, '10': 'goVersion'},
  ],
};

/// Descriptor for `VersionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List versionInfoDescriptor = $convert.base64Decode(
    'CgtWZXJzaW9uSW5mbxIpChBwcm90b2NvbF92ZXJzaW9uGAEgASgFUg9wcm90b2NvbFZlcnNpb2'
    '4SHwoLYXBwX3ZlcnNpb24YAiABKAlSCmFwcFZlcnNpb24SLgoTY29waWxvdF9zZGtfdmVyc2lv'
    'bhgDIAEoCVIRY29waWxvdFNka1ZlcnNpb24SHQoKZ29fdmVyc2lvbhgEIAEoCVIJZ29WZXJzaW'
    '9u');

@$core.Deprecated('Use preconditionDescriptor instead')
const Precondition$json = {
  '1': 'Precondition',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'satisfied', '3': 2, '4': 1, '5': 8, '10': 'satisfied'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'auto_installable', '3': 4, '4': 1, '5': 8, '10': 'autoInstallable'},
    {'1': 'detail', '3': 5, '4': 1, '5': 9, '10': 'detail'},
    {'1': 'manual_command', '3': 6, '4': 1, '5': 9, '10': 'manualCommand'},
  ],
};

/// Descriptor for `Precondition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preconditionDescriptor = $convert.base64Decode(
    'CgxQcmVjb25kaXRpb24SEgoEa2luZBgBIAEoCVIEa2luZBIcCglzYXRpc2ZpZWQYAiABKAhSCX'
    'NhdGlzZmllZBIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SKQoQYXV0b19pbnN0'
    'YWxsYWJsZRgEIAEoCFIPYXV0b0luc3RhbGxhYmxlEhYKBmRldGFpbBgFIAEoCVIGZGV0YWlsEi'
    'UKDm1hbnVhbF9jb21tYW5kGAYgASgJUg1tYW51YWxDb21tYW5k');

@$core.Deprecated('Use preconditionsResponseDescriptor instead')
const PreconditionsResponse$json = {
  '1': 'PreconditionsResponse',
  '2': [
    {
      '1': 'preconditions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.Precondition',
      '10': 'preconditions'
    },
  ],
};

/// Descriptor for `PreconditionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preconditionsResponseDescriptor = $convert.base64Decode(
    'ChVQcmVjb25kaXRpb25zUmVzcG9uc2USQgoNcHJlY29uZGl0aW9ucxgBIAMoCzIcLmZsZWV0a2'
    'FuYmFuLnYxLlByZWNvbmRpdGlvblINcHJlY29uZGl0aW9ucw==');

@$core.Deprecated('Use installPreconditionRequestDescriptor instead')
const InstallPreconditionRequest$json = {
  '1': 'InstallPreconditionRequest',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
  ],
};

/// Descriptor for `InstallPreconditionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installPreconditionRequestDescriptor =
    $convert.base64Decode(
        'ChpJbnN0YWxsUHJlY29uZGl0aW9uUmVxdWVzdBISCgRraW5kGAEgASgJUgRraW5k');

@$core.Deprecated('Use installPreconditionResponseDescriptor instead')
const InstallPreconditionResponse$json = {
  '1': 'InstallPreconditionResponse',
  '2': [
    {
      '1': 'precondition',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fleetkanban.v1.Precondition',
      '10': 'precondition'
    },
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `InstallPreconditionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installPreconditionResponseDescriptor =
    $convert.base64Decode(
        'ChtJbnN0YWxsUHJlY29uZGl0aW9uUmVzcG9uc2USQAoMcHJlY29uZGl0aW9uGAEgASgLMhwuZm'
        'xlZXRrYW5iYW4udjEuUHJlY29uZGl0aW9uUgxwcmVjb25kaXRpb24SFAoFZXJyb3IYAiABKAlS'
        'BWVycm9y');

@$core.Deprecated('Use taskDescriptor instead')
const Task$json = {
  '1': 'Task',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'repository_id', '3': 2, '4': 1, '5': 9, '10': 'repositoryId'},
    {'1': 'goal', '3': 3, '4': 1, '5': 9, '10': 'goal'},
    {'1': 'base_branch', '3': 4, '4': 1, '5': 9, '10': 'baseBranch'},
    {'1': 'branch', '3': 5, '4': 1, '5': 9, '10': 'branch'},
    {'1': 'worktree_path', '3': 6, '4': 1, '5': 9, '10': 'worktreePath'},
    {'1': 'model', '3': 7, '4': 1, '5': 9, '10': 'model'},
    {'1': 'status', '3': 8, '4': 1, '5': 9, '10': 'status'},
    {'1': 'error_code', '3': 9, '4': 1, '5': 9, '10': 'errorCode'},
    {'1': 'error_message', '3': 10, '4': 1, '5': 9, '10': 'errorMessage'},
    {'1': 'session_id', '3': 11, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'branch_exists', '3': 12, '4': 1, '5': 8, '10': 'branchExists'},
    {
      '1': 'created_at',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {
      '1': 'started_at',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startedAt'
    },
    {
      '1': 'finished_at',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'finishedAt'
    },
    {'1': 'review_feedback', '3': 17, '4': 1, '5': 9, '10': 'reviewFeedback'},
    {'1': 'rework_count', '3': 18, '4': 1, '5': 5, '10': 'reworkCount'},
    {'1': 'plan_model', '3': 19, '4': 1, '5': 9, '10': 'planModel'},
    {'1': 'review_model', '3': 20, '4': 1, '5': 9, '10': 'reviewModel'},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor = $convert.base64Decode(
    'CgRUYXNrEg4KAmlkGAEgASgJUgJpZBIjCg1yZXBvc2l0b3J5X2lkGAIgASgJUgxyZXBvc2l0b3'
    'J5SWQSEgoEZ29hbBgDIAEoCVIEZ29hbBIfCgtiYXNlX2JyYW5jaBgEIAEoCVIKYmFzZUJyYW5j'
    'aBIWCgZicmFuY2gYBSABKAlSBmJyYW5jaBIjCg13b3JrdHJlZV9wYXRoGAYgASgJUgx3b3JrdH'
    'JlZVBhdGgSFAoFbW9kZWwYByABKAlSBW1vZGVsEhYKBnN0YXR1cxgIIAEoCVIGc3RhdHVzEh0K'
    'CmVycm9yX2NvZGUYCSABKAlSCWVycm9yQ29kZRIjCg1lcnJvcl9tZXNzYWdlGAogASgJUgxlcn'
    'Jvck1lc3NhZ2USHQoKc2Vzc2lvbl9pZBgLIAEoCVIJc2Vzc2lvbklkEiMKDWJyYW5jaF9leGlz'
    'dHMYDCABKAhSDGJyYW5jaEV4aXN0cxI5CgpjcmVhdGVkX2F0GA0gASgLMhouZ29vZ2xlLnByb3'
    'RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0EjkKCnVwZGF0ZWRfYXQYDiABKAsyGi5nb29nbGUu'
    'cHJvdG9idWYuVGltZXN0YW1wUgl1cGRhdGVkQXQSOQoKc3RhcnRlZF9hdBgPIAEoCzIaLmdvb2'
    'dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0ZWRBdBI7CgtmaW5pc2hlZF9hdBgQIAEoCzIa'
    'Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmZpbmlzaGVkQXQSJwoPcmV2aWV3X2ZlZWRiYW'
    'NrGBEgASgJUg5yZXZpZXdGZWVkYmFjaxIhCgxyZXdvcmtfY291bnQYEiABKAVSC3Jld29ya0Nv'
    'dW50Eh0KCnBsYW5fbW9kZWwYEyABKAlSCXBsYW5Nb2RlbBIhCgxyZXZpZXdfbW9kZWwYFCABKA'
    'lSC3Jldmlld01vZGVs');

@$core.Deprecated('Use subtaskDescriptor instead')
const Subtask$json = {
  '1': 'Subtask',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'task_id', '3': 2, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'status', '3': 4, '4': 1, '5': 9, '10': 'status'},
    {'1': 'order_idx', '3': 5, '4': 1, '5': 5, '10': 'orderIdx'},
    {
      '1': 'created_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {'1': 'agent_role', '3': 8, '4': 1, '5': 9, '10': 'agentRole'},
    {'1': 'depends_on', '3': 9, '4': 3, '5': 9, '10': 'dependsOn'},
    {'1': 'code_model', '3': 10, '4': 1, '5': 9, '10': 'codeModel'},
  ],
};

/// Descriptor for `Subtask`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subtaskDescriptor = $convert.base64Decode(
    'CgdTdWJ0YXNrEg4KAmlkGAEgASgJUgJpZBIXCgd0YXNrX2lkGAIgASgJUgZ0YXNrSWQSFAoFdG'
    'l0bGUYAyABKAlSBXRpdGxlEhYKBnN0YXR1cxgEIAEoCVIGc3RhdHVzEhsKCW9yZGVyX2lkeBgF'
    'IAEoBVIIb3JkZXJJZHgSOQoKY3JlYXRlZF9hdBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW'
    '1lc3RhbXBSCWNyZWF0ZWRBdBI5Cgp1cGRhdGVkX2F0GAcgASgLMhouZ29vZ2xlLnByb3RvYnVm'
    'LlRpbWVzdGFtcFIJdXBkYXRlZEF0Eh0KCmFnZW50X3JvbGUYCCABKAlSCWFnZW50Um9sZRIdCg'
    'pkZXBlbmRzX29uGAkgAygJUglkZXBlbmRzT24SHQoKY29kZV9tb2RlbBgKIAEoCVIJY29kZU1v'
    'ZGVs');

@$core.Deprecated('Use repositoryDescriptor instead')
const Repository$json = {
  '1': 'Repository',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'default_base_branch',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'defaultBaseBranch'
    },
    {
      '1': 'created_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'last_used_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastUsedAt'
    },
  ],
};

/// Descriptor for `Repository`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryDescriptor = $convert.base64Decode(
    'CgpSZXBvc2l0b3J5Eg4KAmlkGAEgASgJUgJpZBISCgRwYXRoGAIgASgJUgRwYXRoEiEKDGRpc3'
    'BsYXlfbmFtZRgDIAEoCVILZGlzcGxheU5hbWUSLgoTZGVmYXVsdF9iYXNlX2JyYW5jaBgEIAEo'
    'CVIRZGVmYXVsdEJhc2VCcmFuY2gSOQoKY3JlYXRlZF9hdBgFIAEoCzIaLmdvb2dsZS5wcm90b2'
    'J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI8CgxsYXN0X3VzZWRfYXQYBiABKAsyGi5nb29nbGUu'
    'cHJvdG9idWYuVGltZXN0YW1wUgpsYXN0VXNlZEF0');

@$core.Deprecated('Use agentEventDescriptor instead')
const AgentEvent$json = {
  '1': 'AgentEvent',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'task_id', '3': 2, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'seq', '3': 3, '4': 1, '5': 3, '10': 'seq'},
    {'1': 'kind', '3': 4, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'payload', '3': 5, '4': 1, '5': 9, '10': 'payload'},
    {
      '1': 'occurred_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'occurredAt'
    },
  ],
};

/// Descriptor for `AgentEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agentEventDescriptor = $convert.base64Decode(
    'CgpBZ2VudEV2ZW50Eg4KAmlkGAEgASgJUgJpZBIXCgd0YXNrX2lkGAIgASgJUgZ0YXNrSWQSEA'
    'oDc2VxGAMgASgDUgNzZXESEgoEa2luZBgEIAEoCVIEa2luZBIYCgdwYXlsb2FkGAUgASgJUgdw'
    'YXlsb2FkEjsKC29jY3VycmVkX2F0GAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcF'
    'IKb2NjdXJyZWRBdA==');

@$core.Deprecated('Use authStatusDescriptor instead')
const AuthStatus$json = {
  '1': 'AuthStatus',
  '2': [
    {'1': 'authenticated', '3': 1, '4': 1, '5': 8, '10': 'authenticated'},
    {'1': 'user', '3': 2, '4': 1, '5': 9, '10': 'user'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'checked_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'checkedAt'
    },
  ],
};

/// Descriptor for `AuthStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authStatusDescriptor = $convert.base64Decode(
    'CgpBdXRoU3RhdHVzEiQKDWF1dGhlbnRpY2F0ZWQYASABKAhSDWF1dGhlbnRpY2F0ZWQSEgoEdX'
    'NlchgCIAEoCVIEdXNlchIYCgdtZXNzYWdlGAMgASgJUgdtZXNzYWdlEjkKCmNoZWNrZWRfYXQY'
    'BCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljaGVja2VkQXQ=');

@$core.Deprecated('Use gitConfigStatusDescriptor instead')
const GitConfigStatus$json = {
  '1': 'GitConfigStatus',
  '2': [
    {'1': 'long_paths_ok', '3': 1, '4': 1, '5': 8, '10': 'longPathsOk'},
    {'1': 'long_paths_val', '3': 2, '4': 1, '5': 9, '10': 'longPathsVal'},
    {'1': 'autocrlf_ok', '3': 3, '4': 1, '5': 8, '10': 'autocrlfOk'},
    {'1': 'autocrlf_val', '3': 4, '4': 1, '5': 9, '10': 'autocrlfVal'},
  ],
};

/// Descriptor for `GitConfigStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitConfigStatusDescriptor = $convert.base64Decode(
    'Cg9HaXRDb25maWdTdGF0dXMSIgoNbG9uZ19wYXRoc19vaxgBIAEoCFILbG9uZ1BhdGhzT2sSJA'
    'oObG9uZ19wYXRoc192YWwYAiABKAlSDGxvbmdQYXRoc1ZhbBIfCgthdXRvY3JsZl9vaxgDIAEo'
    'CFIKYXV0b2NybGZPaxIhCgxhdXRvY3JsZl92YWwYBCABKAlSC2F1dG9jcmxmVmFs');

@$core.Deprecated('Use createTaskRequestDescriptor instead')
const CreateTaskRequest$json = {
  '1': 'CreateTaskRequest',
  '2': [
    {'1': 'repository_id', '3': 1, '4': 1, '5': 9, '10': 'repositoryId'},
    {'1': 'goal', '3': 2, '4': 1, '5': 9, '10': 'goal'},
    {'1': 'base_branch', '3': 3, '4': 1, '5': 9, '10': 'baseBranch'},
    {'1': 'model', '3': 4, '4': 1, '5': 9, '10': 'model'},
    {'1': 'plan_model', '3': 5, '4': 1, '5': 9, '10': 'planModel'},
    {'1': 'review_model', '3': 6, '4': 1, '5': 9, '10': 'reviewModel'},
  ],
};

/// Descriptor for `CreateTaskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createTaskRequestDescriptor = $convert.base64Decode(
    'ChFDcmVhdGVUYXNrUmVxdWVzdBIjCg1yZXBvc2l0b3J5X2lkGAEgASgJUgxyZXBvc2l0b3J5SW'
    'QSEgoEZ29hbBgCIAEoCVIEZ29hbBIfCgtiYXNlX2JyYW5jaBgDIAEoCVIKYmFzZUJyYW5jaBIU'
    'CgVtb2RlbBgEIAEoCVIFbW9kZWwSHQoKcGxhbl9tb2RlbBgFIAEoCVIJcGxhbk1vZGVsEiEKDH'
    'Jldmlld19tb2RlbBgGIAEoCVILcmV2aWV3TW9kZWw=');

@$core.Deprecated('Use listTasksRequestDescriptor instead')
const ListTasksRequest$json = {
  '1': 'ListTasksRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'statuses', '3': 2, '4': 3, '5': 9, '10': 'statuses'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'ascending', '3': 4, '4': 1, '5': 8, '10': 'ascending'},
  ],
};

/// Descriptor for `ListTasksRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTasksRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0VGFza3NSZXF1ZXN0EhcKB3JlcG9faWQYASABKAlSBnJlcG9JZBIaCghzdGF0dXNlcx'
    'gCIAMoCVIIc3RhdHVzZXMSFAoFbGltaXQYAyABKAVSBWxpbWl0EhwKCWFzY2VuZGluZxgEIAEo'
    'CFIJYXNjZW5kaW5n');

@$core.Deprecated('Use listTasksResponseDescriptor instead')
const ListTasksResponse$json = {
  '1': 'ListTasksResponse',
  '2': [
    {
      '1': 'tasks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.Task',
      '10': 'tasks'
    },
  ],
};

/// Descriptor for `ListTasksResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTasksResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0VGFza3NSZXNwb25zZRIqCgV0YXNrcxgBIAMoCzIULmZsZWV0a2FuYmFuLnYxLlRhc2'
    'tSBXRhc2tz');

@$core.Deprecated('Use diffResponseDescriptor instead')
const DiffResponse$json = {
  '1': 'DiffResponse',
  '2': [
    {'1': 'unified_diff', '3': 1, '4': 1, '5': 9, '10': 'unifiedDiff'},
  ],
};

/// Descriptor for `DiffResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diffResponseDescriptor = $convert.base64Decode(
    'CgxEaWZmUmVzcG9uc2USIQoMdW5pZmllZF9kaWZmGAEgASgJUgt1bmlmaWVkRGlmZg==');

@$core.Deprecated('Use finalizeTaskRequestDescriptor instead')
const FinalizeTaskRequest$json = {
  '1': 'FinalizeTaskRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'action',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.fleetkanban.v1.FinalizeAction',
      '10': 'action'
    },
  ],
};

/// Descriptor for `FinalizeTaskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List finalizeTaskRequestDescriptor = $convert.base64Decode(
    'ChNGaW5hbGl6ZVRhc2tSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBI2CgZhY3Rpb24YAiABKA4yHi'
    '5mbGVldGthbmJhbi52MS5GaW5hbGl6ZUFjdGlvblIGYWN0aW9u');

@$core.Deprecated('Use deleteTaskRequestDescriptor instead')
const DeleteTaskRequest$json = {
  '1': 'DeleteTaskRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'delete_branch', '3': 2, '4': 1, '5': 8, '10': 'deleteBranch'},
  ],
};

/// Descriptor for `DeleteTaskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteTaskRequestDescriptor = $convert.base64Decode(
    'ChFEZWxldGVUYXNrUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSIwoNZGVsZXRlX2JyYW5jaBgCIA'
    'EoCFIMZGVsZXRlQnJhbmNo');

@$core.Deprecated('Use submitReviewRequestDescriptor instead')
const SubmitReviewRequest$json = {
  '1': 'SubmitReviewRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'action',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.fleetkanban.v1.ReviewAction',
      '10': 'action'
    },
    {'1': 'feedback', '3': 3, '4': 1, '5': 9, '10': 'feedback'},
  ],
};

/// Descriptor for `SubmitReviewRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitReviewRequestDescriptor = $convert.base64Decode(
    'ChNTdWJtaXRSZXZpZXdSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBI0CgZhY3Rpb24YAiABKA4yHC'
    '5mbGVldGthbmJhbi52MS5SZXZpZXdBY3Rpb25SBmFjdGlvbhIaCghmZWVkYmFjaxgDIAEoCVII'
    'ZmVlZGJhY2s=');

@$core.Deprecated('Use taskEventsRequestDescriptor instead')
const TaskEventsRequest$json = {
  '1': 'TaskEventsRequest',
  '2': [
    {'1': 'task_id', '3': 1, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'since_seq', '3': 2, '4': 1, '5': 3, '10': 'sinceSeq'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `TaskEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskEventsRequestDescriptor = $convert.base64Decode(
    'ChFUYXNrRXZlbnRzUmVxdWVzdBIXCgd0YXNrX2lkGAEgASgJUgZ0YXNrSWQSGwoJc2luY2Vfc2'
    'VxGAIgASgDUghzaW5jZVNlcRIUCgVsaW1pdBgDIAEoBVIFbGltaXQ=');

@$core.Deprecated('Use taskEventsResponseDescriptor instead')
const TaskEventsResponse$json = {
  '1': 'TaskEventsResponse',
  '2': [
    {
      '1': 'events',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.AgentEvent',
      '10': 'events'
    },
  ],
};

/// Descriptor for `TaskEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskEventsResponseDescriptor = $convert.base64Decode(
    'ChJUYXNrRXZlbnRzUmVzcG9uc2USMgoGZXZlbnRzGAEgAygLMhouZmxlZXRrYW5iYW4udjEuQW'
    'dlbnRFdmVudFIGZXZlbnRz');

@$core.Deprecated('Use watchEventsRequestDescriptor instead')
const WatchEventsRequest$json = {
  '1': 'WatchEventsRequest',
  '2': [
    {
      '1': 'since_seq_by_task',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.WatchEventsRequest.SinceSeqByTaskEntry',
      '10': 'sinceSeqByTask'
    },
  ],
  '3': [WatchEventsRequest_SinceSeqByTaskEntry$json],
};

@$core.Deprecated('Use watchEventsRequestDescriptor instead')
const WatchEventsRequest_SinceSeqByTaskEntry$json = {
  '1': 'SinceSeqByTaskEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 3, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `WatchEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchEventsRequestDescriptor = $convert.base64Decode(
    'ChJXYXRjaEV2ZW50c1JlcXVlc3QSYQoRc2luY2Vfc2VxX2J5X3Rhc2sYASADKAsyNi5mbGVldG'
    'thbmJhbi52MS5XYXRjaEV2ZW50c1JlcXVlc3QuU2luY2VTZXFCeVRhc2tFbnRyeVIOc2luY2VT'
    'ZXFCeVRhc2saQQoTU2luY2VTZXFCeVRhc2tFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YW'
    'x1ZRgCIAEoA1IFdmFsdWU6AjgB');

@$core.Deprecated('Use listSubtasksRequestDescriptor instead')
const ListSubtasksRequest$json = {
  '1': 'ListSubtasksRequest',
  '2': [
    {'1': 'task_id', '3': 1, '4': 1, '5': 9, '10': 'taskId'},
  ],
};

/// Descriptor for `ListSubtasksRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSubtasksRequestDescriptor =
    $convert.base64Decode(
        'ChNMaXN0U3VidGFza3NSZXF1ZXN0EhcKB3Rhc2tfaWQYASABKAlSBnRhc2tJZA==');

@$core.Deprecated('Use listSubtasksResponseDescriptor instead')
const ListSubtasksResponse$json = {
  '1': 'ListSubtasksResponse',
  '2': [
    {
      '1': 'subtasks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.Subtask',
      '10': 'subtasks'
    },
  ],
};

/// Descriptor for `ListSubtasksResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSubtasksResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0U3VidGFza3NSZXNwb25zZRIzCghzdWJ0YXNrcxgBIAMoCzIXLmZsZWV0a2FuYmFuLn'
    'YxLlN1YnRhc2tSCHN1YnRhc2tz');

@$core.Deprecated('Use createSubtaskRequestDescriptor instead')
const CreateSubtaskRequest$json = {
  '1': 'CreateSubtaskRequest',
  '2': [
    {'1': 'task_id', '3': 1, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
    {'1': 'order_idx', '3': 4, '4': 1, '5': 5, '10': 'orderIdx'},
    {'1': 'agent_role', '3': 5, '4': 1, '5': 9, '10': 'agentRole'},
    {'1': 'depends_on', '3': 6, '4': 3, '5': 9, '10': 'dependsOn'},
  ],
};

/// Descriptor for `CreateSubtaskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSubtaskRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVTdWJ0YXNrUmVxdWVzdBIXCgd0YXNrX2lkGAEgASgJUgZ0YXNrSWQSFAoFdGl0bG'
    'UYAiABKAlSBXRpdGxlEhYKBnN0YXR1cxgDIAEoCVIGc3RhdHVzEhsKCW9yZGVyX2lkeBgEIAEo'
    'BVIIb3JkZXJJZHgSHQoKYWdlbnRfcm9sZRgFIAEoCVIJYWdlbnRSb2xlEh0KCmRlcGVuZHNfb2'
    '4YBiADKAlSCWRlcGVuZHNPbg==');

@$core.Deprecated('Use updateSubtaskRequestDescriptor instead')
const UpdateSubtaskRequest$json = {
  '1': 'UpdateSubtaskRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `UpdateSubtaskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSubtaskRequestDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVTdWJ0YXNrUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBX'
    'RpdGxlEhYKBnN0YXR1cxgDIAEoCVIGc3RhdHVz');

@$core.Deprecated('Use reorderSubtasksRequestDescriptor instead')
const ReorderSubtasksRequest$json = {
  '1': 'ReorderSubtasksRequest',
  '2': [
    {'1': 'task_id', '3': 1, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'ids', '3': 2, '4': 3, '5': 9, '10': 'ids'},
  ],
};

/// Descriptor for `ReorderSubtasksRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reorderSubtasksRequestDescriptor =
    $convert.base64Decode(
        'ChZSZW9yZGVyU3VidGFza3NSZXF1ZXN0EhcKB3Rhc2tfaWQYASABKAlSBnRhc2tJZBIQCgNpZH'
        'MYAiADKAlSA2lkcw==');

@$core.Deprecated('Use registerRepositoryRequestDescriptor instead')
const RegisterRepositoryRequest$json = {
  '1': 'RegisterRepositoryRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'initialize_if_empty',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'initializeIfEmpty'
    },
  ],
};

/// Descriptor for `RegisterRepositoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerRepositoryRequestDescriptor = $convert.base64Decode(
    'ChlSZWdpc3RlclJlcG9zaXRvcnlSZXF1ZXN0EhIKBHBhdGgYASABKAlSBHBhdGgSIQoMZGlzcG'
    'xheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZRIuChNpbml0aWFsaXplX2lmX2VtcHR5GAMgASgI'
    'UhFpbml0aWFsaXplSWZFbXB0eQ==');

@$core.Deprecated('Use listRepositoriesResponseDescriptor instead')
const ListRepositoriesResponse$json = {
  '1': 'ListRepositoriesResponse',
  '2': [
    {
      '1': 'repositories',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.Repository',
      '10': 'repositories'
    },
  ],
};

/// Descriptor for `ListRepositoriesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRepositoriesResponseDescriptor =
    $convert.base64Decode(
        'ChhMaXN0UmVwb3NpdG9yaWVzUmVzcG9uc2USPgoMcmVwb3NpdG9yaWVzGAEgAygLMhouZmxlZX'
        'RrYW5iYW4udjEuUmVwb3NpdG9yeVIMcmVwb3NpdG9yaWVz');

@$core.Deprecated('Use scanGitRepositoriesRequestDescriptor instead')
const ScanGitRepositoriesRequest$json = {
  '1': 'ScanGitRepositoriesRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'max_depth', '3': 2, '4': 1, '5': 5, '10': 'maxDepth'},
  ],
};

/// Descriptor for `ScanGitRepositoriesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanGitRepositoriesRequestDescriptor =
    $convert.base64Decode(
        'ChpTY2FuR2l0UmVwb3NpdG9yaWVzUmVxdWVzdBISCgRwYXRoGAEgASgJUgRwYXRoEhsKCW1heF'
        '9kZXB0aBgCIAEoBVIIbWF4RGVwdGg=');

@$core.Deprecated('Use foundRepositoryDescriptor instead')
const FoundRepository$json = {
  '1': 'FoundRepository',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'default_branch', '3': 2, '4': 1, '5': 9, '10': 'defaultBranch'},
    {
      '1': 'already_registered',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'alreadyRegistered'
    },
  ],
};

/// Descriptor for `FoundRepository`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List foundRepositoryDescriptor = $convert.base64Decode(
    'Cg9Gb3VuZFJlcG9zaXRvcnkSEgoEcGF0aBgBIAEoCVIEcGF0aBIlCg5kZWZhdWx0X2JyYW5jaB'
    'gCIAEoCVINZGVmYXVsdEJyYW5jaBItChJhbHJlYWR5X3JlZ2lzdGVyZWQYAyABKAhSEWFscmVh'
    'ZHlSZWdpc3RlcmVk');

@$core.Deprecated('Use scanGitRepositoriesResponseDescriptor instead')
const ScanGitRepositoriesResponse$json = {
  '1': 'ScanGitRepositoriesResponse',
  '2': [
    {
      '1': 'repositories',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.FoundRepository',
      '10': 'repositories'
    },
    {'1': 'root_is_repo', '3': 2, '4': 1, '5': 8, '10': 'rootIsRepo'},
  ],
};

/// Descriptor for `ScanGitRepositoriesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scanGitRepositoriesResponseDescriptor =
    $convert.base64Decode(
        'ChtTY2FuR2l0UmVwb3NpdG9yaWVzUmVzcG9uc2USQwoMcmVwb3NpdG9yaWVzGAEgAygLMh8uZm'
        'xlZXRrYW5iYW4udjEuRm91bmRSZXBvc2l0b3J5UgxyZXBvc2l0b3JpZXMSIAoMcm9vdF9pc19y'
        'ZXBvGAIgASgIUgpyb290SXNSZXBv');

@$core.Deprecated('Use updateDefaultBaseBranchRequestDescriptor instead')
const UpdateDefaultBaseBranchRequest$json = {
  '1': 'UpdateDefaultBaseBranchRequest',
  '2': [
    {'1': 'repository_id', '3': 1, '4': 1, '5': 9, '10': 'repositoryId'},
    {
      '1': 'default_base_branch',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'defaultBaseBranch'
    },
  ],
};

/// Descriptor for `UpdateDefaultBaseBranchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateDefaultBaseBranchRequestDescriptor =
    $convert.base64Decode(
        'Ch5VcGRhdGVEZWZhdWx0QmFzZUJyYW5jaFJlcXVlc3QSIwoNcmVwb3NpdG9yeV9pZBgBIAEoCV'
        'IMcmVwb3NpdG9yeUlkEi4KE2RlZmF1bHRfYmFzZV9icmFuY2gYAiABKAlSEWRlZmF1bHRCYXNl'
        'QnJhbmNo');

@$core.Deprecated('Use listBranchesRequestDescriptor instead')
const ListBranchesRequest$json = {
  '1': 'ListBranchesRequest',
  '2': [
    {'1': 'repository_id', '3': 1, '4': 1, '5': 9, '10': 'repositoryId'},
  ],
};

/// Descriptor for `ListBranchesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBranchesRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0QnJhbmNoZXNSZXF1ZXN0EiMKDXJlcG9zaXRvcnlfaWQYASABKAlSDHJlcG9zaXRvcn'
    'lJZA==');

@$core.Deprecated('Use listBranchesResponseDescriptor instead')
const ListBranchesResponse$json = {
  '1': 'ListBranchesResponse',
  '2': [
    {'1': 'branches', '3': 1, '4': 3, '5': 9, '10': 'branches'},
    {'1': 'default_branch', '3': 2, '4': 1, '5': 9, '10': 'defaultBranch'},
    {'1': 'has_commits', '3': 3, '4': 1, '5': 8, '10': 'hasCommits'},
  ],
};

/// Descriptor for `ListBranchesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBranchesResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0QnJhbmNoZXNSZXNwb25zZRIaCghicmFuY2hlcxgBIAMoCVIIYnJhbmNoZXMSJQoOZG'
    'VmYXVsdF9icmFuY2gYAiABKAlSDWRlZmF1bHRCcmFuY2gSHwoLaGFzX2NvbW1pdHMYAyABKAhS'
    'Cmhhc0NvbW1pdHM=');

@$core.Deprecated('Use setGitHubTokenRequestDescriptor instead')
const SetGitHubTokenRequest$json = {
  '1': 'SetGitHubTokenRequest',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `SetGitHubTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setGitHubTokenRequestDescriptor =
    $convert.base64Decode(
        'ChVTZXRHaXRIdWJUb2tlblJlcXVlc3QSFAoFdG9rZW4YASABKAlSBXRva2Vu');

@$core.Deprecated('Use copilotLoginChallengeDescriptor instead')
const CopilotLoginChallenge$json = {
  '1': 'CopilotLoginChallenge',
  '2': [
    {'1': 'user_code', '3': 1, '4': 1, '5': 9, '10': 'userCode'},
    {'1': 'verification_uri', '3': 2, '4': 1, '5': 9, '10': 'verificationUri'},
    {
      '1': 'expires_in_seconds',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'expiresInSeconds'
    },
  ],
};

/// Descriptor for `CopilotLoginChallenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copilotLoginChallengeDescriptor = $convert.base64Decode(
    'ChVDb3BpbG90TG9naW5DaGFsbGVuZ2USGwoJdXNlcl9jb2RlGAEgASgJUgh1c2VyQ29kZRIpCh'
    'B2ZXJpZmljYXRpb25fdXJpGAIgASgJUg92ZXJpZmljYXRpb25VcmkSLAoSZXhwaXJlc19pbl9z'
    'ZWNvbmRzGAMgASgFUhBleHBpcmVzSW5TZWNvbmRz');

@$core.Deprecated('Use copilotLoginSessionInfoDescriptor instead')
const CopilotLoginSessionInfo$json = {
  '1': 'CopilotLoginSessionInfo',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.fleetkanban.v1.CopilotLoginSessionState',
      '10': 'state'
    },
    {'1': 'error_message', '3': 2, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `CopilotLoginSessionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copilotLoginSessionInfoDescriptor = $convert.base64Decode(
    'ChdDb3BpbG90TG9naW5TZXNzaW9uSW5mbxI+CgVzdGF0ZRgBIAEoDjIoLmZsZWV0a2FuYmFuLn'
    'YxLkNvcGlsb3RMb2dpblNlc3Npb25TdGF0ZVIFc3RhdGUSIwoNZXJyb3JfbWVzc2FnZRgCIAEo'
    'CVIMZXJyb3JNZXNzYWdl');

@$core.Deprecated('Use gitHubTokenEntryDescriptor instead')
const GitHubTokenEntry$json = {
  '1': 'GitHubTokenEntry',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'active', '3': 2, '4': 1, '5': 8, '10': 'active'},
  ],
};

/// Descriptor for `GitHubTokenEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitHubTokenEntryDescriptor = $convert.base64Decode(
    'ChBHaXRIdWJUb2tlbkVudHJ5EhQKBWxhYmVsGAEgASgJUgVsYWJlbBIWCgZhY3RpdmUYAiABKA'
    'hSBmFjdGl2ZQ==');

@$core.Deprecated('Use listGitHubTokensResponseDescriptor instead')
const ListGitHubTokensResponse$json = {
  '1': 'ListGitHubTokensResponse',
  '2': [
    {
      '1': 'tokens',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.GitHubTokenEntry',
      '10': 'tokens'
    },
    {'1': 'active_label', '3': 2, '4': 1, '5': 9, '10': 'activeLabel'},
  ],
};

/// Descriptor for `ListGitHubTokensResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listGitHubTokensResponseDescriptor = $convert.base64Decode(
    'ChhMaXN0R2l0SHViVG9rZW5zUmVzcG9uc2USOAoGdG9rZW5zGAEgAygLMiAuZmxlZXRrYW5iYW'
    '4udjEuR2l0SHViVG9rZW5FbnRyeVIGdG9rZW5zEiEKDGFjdGl2ZV9sYWJlbBgCIAEoCVILYWN0'
    'aXZlTGFiZWw=');

@$core.Deprecated('Use addGitHubTokenRequestDescriptor instead')
const AddGitHubTokenRequest$json = {
  '1': 'AddGitHubTokenRequest',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'set_active', '3': 3, '4': 1, '5': 8, '10': 'setActive'},
  ],
};

/// Descriptor for `AddGitHubTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addGitHubTokenRequestDescriptor = $convert.base64Decode(
    'ChVBZGRHaXRIdWJUb2tlblJlcXVlc3QSFAoFbGFiZWwYASABKAlSBWxhYmVsEhQKBXRva2VuGA'
    'IgASgJUgV0b2tlbhIdCgpzZXRfYWN0aXZlGAMgASgIUglzZXRBY3RpdmU=');

@$core.Deprecated('Use gitHubTokenLabelRequestDescriptor instead')
const GitHubTokenLabelRequest$json = {
  '1': 'GitHubTokenLabelRequest',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
  ],
};

/// Descriptor for `GitHubTokenLabelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitHubTokenLabelRequestDescriptor =
    $convert.base64Decode(
        'ChdHaXRIdWJUb2tlbkxhYmVsUmVxdWVzdBIUCgVsYWJlbBgBIAEoCVIFbGFiZWw=');

@$core.Deprecated('Use gitHubAccountInfoDescriptor instead')
const GitHubAccountInfo$json = {
  '1': 'GitHubAccountInfo',
  '2': [
    {'1': 'login', '3': 1, '4': 1, '5': 9, '10': 'login'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'avatar_url', '3': 3, '4': 1, '5': 9, '10': 'avatarUrl'},
    {'1': 'plan_name', '3': 4, '4': 1, '5': 9, '10': 'planName'},
    {
      '1': 'plan_private_repos',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'planPrivateRepos'
    },
    {
      '1': 'plan_collaborators',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'planCollaborators'
    },
    {'1': 'plan_space', '3': 7, '4': 1, '5': 3, '10': 'planSpace'},
    {'1': 'copilot_enabled', '3': 8, '4': 1, '5': 8, '10': 'copilotEnabled'},
    {'1': 'raw_message', '3': 9, '4': 1, '5': 9, '10': 'rawMessage'},
  ],
};

/// Descriptor for `GitHubAccountInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitHubAccountInfoDescriptor = $convert.base64Decode(
    'ChFHaXRIdWJBY2NvdW50SW5mbxIUCgVsb2dpbhgBIAEoCVIFbG9naW4SEgoEbmFtZRgCIAEoCV'
    'IEbmFtZRIdCgphdmF0YXJfdXJsGAMgASgJUglhdmF0YXJVcmwSGwoJcGxhbl9uYW1lGAQgASgJ'
    'UghwbGFuTmFtZRIsChJwbGFuX3ByaXZhdGVfcmVwb3MYBSABKAVSEHBsYW5Qcml2YXRlUmVwb3'
    'MSLQoScGxhbl9jb2xsYWJvcmF0b3JzGAYgASgFUhFwbGFuQ29sbGFib3JhdG9ycxIdCgpwbGFu'
    'X3NwYWNlGAcgASgDUglwbGFuU3BhY2USJwoPY29waWxvdF9lbmFibGVkGAggASgIUg5jb3BpbG'
    '90RW5hYmxlZBIfCgtyYXdfbWVzc2FnZRgJIAEoCVIKcmF3TWVzc2FnZQ==');

@$core.Deprecated('Use modelInfoDescriptor instead')
const ModelInfo$json = {
  '1': 'ModelInfo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'multiplier', '3': 3, '4': 1, '5': 1, '10': 'multiplier'},
  ],
};

/// Descriptor for `ModelInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelInfoDescriptor = $convert.base64Decode(
    'CglNb2RlbEluZm8SDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSHgoKbXVsdG'
    'lwbGllchgDIAEoAVIKbXVsdGlwbGllcg==');

@$core.Deprecated('Use listModelsResponseDescriptor instead')
const ListModelsResponse$json = {
  '1': 'ListModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ModelInfo',
      '10': 'models'
    },
  ],
};

/// Descriptor for `ListModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModelsResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0TW9kZWxzUmVzcG9uc2USMQoGbW9kZWxzGAEgAygLMhkuZmxlZXRrYW5iYW4udjEuTW'
    '9kZWxJbmZvUgZtb2RlbHM=');

@$core.Deprecated('Use worktreeEntryDescriptor instead')
const WorktreeEntry$json = {
  '1': 'WorktreeEntry',
  '2': [
    {'1': 'repository_id', '3': 1, '4': 1, '5': 9, '10': 'repositoryId'},
    {'1': 'repository_path', '3': 2, '4': 1, '5': 9, '10': 'repositoryPath'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {'1': 'branch', '3': 4, '4': 1, '5': 9, '10': 'branch'},
    {'1': 'path_exists', '3': 5, '4': 1, '5': 8, '10': 'pathExists'},
    {'1': 'is_primary', '3': 6, '4': 1, '5': 8, '10': 'isPrimary'},
    {'1': 'task_id', '3': 7, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'task_status', '3': 8, '4': 1, '5': 9, '10': 'taskStatus'},
    {'1': 'head', '3': 9, '4': 1, '5': 9, '10': 'head'},
  ],
};

/// Descriptor for `WorktreeEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List worktreeEntryDescriptor = $convert.base64Decode(
    'Cg1Xb3JrdHJlZUVudHJ5EiMKDXJlcG9zaXRvcnlfaWQYASABKAlSDHJlcG9zaXRvcnlJZBInCg'
    '9yZXBvc2l0b3J5X3BhdGgYAiABKAlSDnJlcG9zaXRvcnlQYXRoEhIKBHBhdGgYAyABKAlSBHBh'
    'dGgSFgoGYnJhbmNoGAQgASgJUgZicmFuY2gSHwoLcGF0aF9leGlzdHMYBSABKAhSCnBhdGhFeG'
    'lzdHMSHQoKaXNfcHJpbWFyeRgGIAEoCFIJaXNQcmltYXJ5EhcKB3Rhc2tfaWQYByABKAlSBnRh'
    'c2tJZBIfCgt0YXNrX3N0YXR1cxgIIAEoCVIKdGFza1N0YXR1cxISCgRoZWFkGAkgASgJUgRoZW'
    'Fk');

@$core.Deprecated('Use listWorktreesResponseDescriptor instead')
const ListWorktreesResponse$json = {
  '1': 'ListWorktreesResponse',
  '2': [
    {
      '1': 'worktrees',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.WorktreeEntry',
      '10': 'worktrees'
    },
  ],
};

/// Descriptor for `ListWorktreesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listWorktreesResponseDescriptor = $convert.base64Decode(
    'ChVMaXN0V29ya3RyZWVzUmVzcG9uc2USOwoJd29ya3RyZWVzGAEgAygLMh0uZmxlZXRrYW5iYW'
    '4udjEuV29ya3RyZWVFbnRyeVIJd29ya3RyZWVz');

@$core.Deprecated('Use removeWorktreeRequestDescriptor instead')
const RemoveWorktreeRequest$json = {
  '1': 'RemoveWorktreeRequest',
  '2': [
    {'1': 'repository_id', '3': 1, '4': 1, '5': 9, '10': 'repositoryId'},
    {'1': 'worktree_path', '3': 2, '4': 1, '5': 9, '10': 'worktreePath'},
    {'1': 'delete_branch', '3': 3, '4': 1, '5': 8, '10': 'deleteBranch'},
  ],
};

/// Descriptor for `RemoveWorktreeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeWorktreeRequestDescriptor = $convert.base64Decode(
    'ChVSZW1vdmVXb3JrdHJlZVJlcXVlc3QSIwoNcmVwb3NpdG9yeV9pZBgBIAEoCVIMcmVwb3NpdG'
    '9yeUlkEiMKDXdvcmt0cmVlX3BhdGgYAiABKAlSDHdvcmt0cmVlUGF0aBIjCg1kZWxldGVfYnJh'
    'bmNoGAMgASgIUgxkZWxldGVCcmFuY2g=');
