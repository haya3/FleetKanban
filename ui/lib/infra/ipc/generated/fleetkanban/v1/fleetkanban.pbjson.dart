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

@$core.Deprecated('Use stashUncommittedResponseDescriptor instead')
const StashUncommittedResponse$json = {
  '1': 'StashUncommittedResponse',
  '2': [
    {'1': 'stashed', '3': 1, '4': 1, '5': 8, '10': 'stashed'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `StashUncommittedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stashUncommittedResponseDescriptor =
    $convert.base64Decode(
        'ChhTdGFzaFVuY29tbWl0dGVkUmVzcG9uc2USGAoHc3Rhc2hlZBgBIAEoCFIHc3Rhc2hlZBIYCg'
        'dtZXNzYWdlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use agentSettingsDescriptor instead')
const AgentSettings$json = {
  '1': 'AgentSettings',
  '2': [
    {'1': 'output_language', '3': 4, '4': 1, '5': 9, '10': 'outputLanguage'},
  ],
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
  ],
  '10': ['plan_prompt', 'code_prompt', 'review_prompt'],
};

/// Descriptor for `AgentSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agentSettingsDescriptor = $convert.base64Decode(
    'Cg1BZ2VudFNldHRpbmdzEicKD291dHB1dF9sYW5ndWFnZRgEIAEoCVIOb3V0cHV0TGFuZ3VhZ2'
    'VKBAgBEAJKBAgCEANKBAgDEARSC3BsYW5fcHJvbXB0Ugtjb2RlX3Byb21wdFINcmV2aWV3X3By'
    'b21wdA==');

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
    {'1': 'harness_version', '3': 21, '4': 1, '5': 5, '10': 'harnessVersion'},
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
    'lSC3Jldmlld01vZGVsEicKD2hhcm5lc3NfdmVyc2lvbhgVIAEoBVIOaGFybmVzc1ZlcnNpb24=');

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
    {'1': 'round', '3': 11, '4': 1, '5': 5, '10': 'round'},
    {'1': 'prompt', '3': 12, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'write_paths', '3': 13, '4': 3, '5': 9, '10': 'writePaths'},
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
    'ZGVsEhQKBXJvdW5kGAsgASgFUgVyb3VuZBIWCgZwcm9tcHQYDCABKAlSBnByb21wdBIfCgt3cm'
    'l0ZV9wYXRocxgNIAMoCVIKd3JpdGVQYXRocw==');

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

@$core.Deprecated('Use getSubtaskContextRequestDescriptor instead')
const GetSubtaskContextRequest$json = {
  '1': 'GetSubtaskContextRequest',
  '2': [
    {'1': 'subtask_id', '3': 1, '4': 1, '5': 9, '10': 'subtaskId'},
    {'1': 'round', '3': 2, '4': 1, '5': 5, '10': 'round'},
  ],
};

/// Descriptor for `GetSubtaskContextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSubtaskContextRequestDescriptor =
    $convert.base64Decode(
        'ChhHZXRTdWJ0YXNrQ29udGV4dFJlcXVlc3QSHQoKc3VidGFza19pZBgBIAEoCVIJc3VidGFza0'
        'lkEhQKBXJvdW5kGAIgASgFUgVyb3VuZA==');

@$core.Deprecated('Use copilotSubtaskContextDescriptor instead')
const CopilotSubtaskContext$json = {
  '1': 'CopilotSubtaskContext',
  '2': [
    {'1': 'subtask_id', '3': 1, '4': 1, '5': 9, '10': 'subtaskId'},
    {'1': 'round', '3': 2, '4': 1, '5': 5, '10': 'round'},
    {'1': 'system_prompt', '3': 3, '4': 1, '5': 9, '10': 'systemPrompt'},
    {'1': 'user_prompt', '3': 4, '4': 1, '5': 9, '10': 'userPrompt'},
    {
      '1': 'stage_prompt_template',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'stagePromptTemplate'
    },
    {'1': 'plan_summary', '3': 6, '4': 1, '5': 9, '10': 'planSummary'},
    {'1': 'prior_summaries', '3': 7, '4': 3, '5': 9, '10': 'priorSummaries'},
    {'1': 'memory_block', '3': 8, '4': 1, '5': 9, '10': 'memoryBlock'},
    {'1': 'output_language', '3': 9, '4': 1, '5': 9, '10': 'outputLanguage'},
    {
      '1': 'harness_skill_version_id',
      '3': 10,
      '4': 1,
      '5': 9,
      '10': 'harnessSkillVersionId'
    },
    {'1': 'harness_skill_md', '3': 11, '4': 1, '5': 9, '10': 'harnessSkillMd'},
    {'1': 'not_recorded', '3': 12, '4': 1, '5': 8, '10': 'notRecorded'},
  ],
};

/// Descriptor for `CopilotSubtaskContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copilotSubtaskContextDescriptor = $convert.base64Decode(
    'ChVDb3BpbG90U3VidGFza0NvbnRleHQSHQoKc3VidGFza19pZBgBIAEoCVIJc3VidGFza0lkEh'
    'QKBXJvdW5kGAIgASgFUgVyb3VuZBIjCg1zeXN0ZW1fcHJvbXB0GAMgASgJUgxzeXN0ZW1Qcm9t'
    'cHQSHwoLdXNlcl9wcm9tcHQYBCABKAlSCnVzZXJQcm9tcHQSMgoVc3RhZ2VfcHJvbXB0X3RlbX'
    'BsYXRlGAUgASgJUhNzdGFnZVByb21wdFRlbXBsYXRlEiEKDHBsYW5fc3VtbWFyeRgGIAEoCVIL'
    'cGxhblN1bW1hcnkSJwoPcHJpb3Jfc3VtbWFyaWVzGAcgAygJUg5wcmlvclN1bW1hcmllcxIhCg'
    'xtZW1vcnlfYmxvY2sYCCABKAlSC21lbW9yeUJsb2NrEicKD291dHB1dF9sYW5ndWFnZRgJIAEo'
    'CVIOb3V0cHV0TGFuZ3VhZ2USNwoYaGFybmVzc19za2lsbF92ZXJzaW9uX2lkGAogASgJUhVoYX'
    'JuZXNzU2tpbGxWZXJzaW9uSWQSKAoQaGFybmVzc19za2lsbF9tZBgLIAEoCVIOaGFybmVzc1Nr'
    'aWxsTWQSIQoMbm90X3JlY29yZGVkGAwgASgIUgtub3RSZWNvcmRlZA==');

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
    {'1': 'write_paths', '3': 7, '4': 3, '5': 9, '10': 'writePaths'},
  ],
};

/// Descriptor for `CreateSubtaskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSubtaskRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVTdWJ0YXNrUmVxdWVzdBIXCgd0YXNrX2lkGAEgASgJUgZ0YXNrSWQSFAoFdGl0bG'
    'UYAiABKAlSBXRpdGxlEhYKBnN0YXR1cxgDIAEoCVIGc3RhdHVzEhsKCW9yZGVyX2lkeBgEIAEo'
    'BVIIb3JkZXJJZHgSHQoKYWdlbnRfcm9sZRgFIAEoCVIJYWdlbnRSb2xlEh0KCmRlcGVuZHNfb2'
    '4YBiADKAlSCWRlcGVuZHNPbhIfCgt3cml0ZV9wYXRocxgHIAMoCVIKd3JpdGVQYXRocw==');

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

@$core.Deprecated('Use copilotQuotaInfoDescriptor instead')
const CopilotQuotaInfo$json = {
  '1': 'CopilotQuotaInfo',
  '2': [
    {
      '1': 'snapshots',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.CopilotQuotaInfo.SnapshotsEntry',
      '10': 'snapshots'
    },
  ],
  '3': [CopilotQuotaInfo_SnapshotsEntry$json],
};

@$core.Deprecated('Use copilotQuotaInfoDescriptor instead')
const CopilotQuotaInfo_SnapshotsEntry$json = {
  '1': 'SnapshotsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fleetkanban.v1.CopilotQuotaSnapshot',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `CopilotQuotaInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copilotQuotaInfoDescriptor = $convert.base64Decode(
    'ChBDb3BpbG90UXVvdGFJbmZvEk0KCXNuYXBzaG90cxgBIAMoCzIvLmZsZWV0a2FuYmFuLnYxLk'
    'NvcGlsb3RRdW90YUluZm8uU25hcHNob3RzRW50cnlSCXNuYXBzaG90cxpiCg5TbmFwc2hvdHNF'
    'bnRyeRIQCgNrZXkYASABKAlSA2tleRI6CgV2YWx1ZRgCIAEoCzIkLmZsZWV0a2FuYmFuLnYxLk'
    'NvcGlsb3RRdW90YVNuYXBzaG90UgV2YWx1ZToCOAE=');

@$core.Deprecated('Use copilotQuotaSnapshotDescriptor instead')
const CopilotQuotaSnapshot$json = {
  '1': 'CopilotQuotaSnapshot',
  '2': [
    {
      '1': 'entitlement_requests',
      '3': 1,
      '4': 1,
      '5': 1,
      '10': 'entitlementRequests'
    },
    {'1': 'used_requests', '3': 2, '4': 1, '5': 1, '10': 'usedRequests'},
    {
      '1': 'remaining_percentage',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'remainingPercentage'
    },
    {'1': 'overage', '3': 4, '4': 1, '5': 1, '10': 'overage'},
    {
      '1': 'overage_allowed_with_exhausted_quota',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'overageAllowedWithExhaustedQuota'
    },
    {'1': 'reset_date', '3': 6, '4': 1, '5': 9, '10': 'resetDate'},
  ],
};

/// Descriptor for `CopilotQuotaSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List copilotQuotaSnapshotDescriptor = $convert.base64Decode(
    'ChRDb3BpbG90UXVvdGFTbmFwc2hvdBIxChRlbnRpdGxlbWVudF9yZXF1ZXN0cxgBIAEoAVITZW'
    '50aXRsZW1lbnRSZXF1ZXN0cxIjCg11c2VkX3JlcXVlc3RzGAIgASgBUgx1c2VkUmVxdWVzdHMS'
    'MQoUcmVtYWluaW5nX3BlcmNlbnRhZ2UYAyABKAFSE3JlbWFpbmluZ1BlcmNlbnRhZ2USGAoHb3'
    'ZlcmFnZRgEIAEoAVIHb3ZlcmFnZRJOCiRvdmVyYWdlX2FsbG93ZWRfd2l0aF9leGhhdXN0ZWRf'
    'cXVvdGEYBSABKAhSIG92ZXJhZ2VBbGxvd2VkV2l0aEV4aGF1c3RlZFF1b3RhEh0KCnJlc2V0X2'
    'RhdGUYBiABKAlSCXJlc2V0RGF0ZQ==');

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

@$core.Deprecated('Use contextNodeDescriptor instead')
const ContextNode$json = {
  '1': 'ContextNode',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'repo_id', '3': 2, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'label', '3': 4, '4': 1, '5': 9, '10': 'label'},
    {'1': 'content_md', '3': 5, '4': 1, '5': 9, '10': 'contentMd'},
    {
      '1': 'attrs',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextNode.AttrsEntry',
      '10': 'attrs'
    },
    {'1': 'source_kind', '3': 7, '4': 1, '5': 9, '10': 'sourceKind'},
    {'1': 'confidence', '3': 8, '4': 1, '5': 2, '10': 'confidence'},
    {'1': 'enabled', '3': 9, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'pinned', '3': 10, '4': 1, '5': 8, '10': 'pinned'},
    {
      '1': 'created_at',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
  ],
  '3': [ContextNode_AttrsEntry$json],
};

@$core.Deprecated('Use contextNodeDescriptor instead')
const ContextNode_AttrsEntry$json = {
  '1': 'AttrsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ContextNode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextNodeDescriptor = $convert.base64Decode(
    'CgtDb250ZXh0Tm9kZRIOCgJpZBgBIAEoCVICaWQSFwoHcmVwb19pZBgCIAEoCVIGcmVwb0lkEh'
    'IKBGtpbmQYAyABKAlSBGtpbmQSFAoFbGFiZWwYBCABKAlSBWxhYmVsEh0KCmNvbnRlbnRfbWQY'
    'BSABKAlSCWNvbnRlbnRNZBI8CgVhdHRycxgGIAMoCzImLmZsZWV0a2FuYmFuLnYxLkNvbnRleH'
    'ROb2RlLkF0dHJzRW50cnlSBWF0dHJzEh8KC3NvdXJjZV9raW5kGAcgASgJUgpzb3VyY2VLaW5k'
    'Eh4KCmNvbmZpZGVuY2UYCCABKAJSCmNvbmZpZGVuY2USGAoHZW5hYmxlZBgJIAEoCFIHZW5hYm'
    'xlZBIWCgZwaW5uZWQYCiABKAhSBnBpbm5lZBI5CgpjcmVhdGVkX2F0GAsgASgLMhouZ29vZ2xl'
    'LnByb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0EjkKCnVwZGF0ZWRfYXQYDCABKAsyGi5nb2'
    '9nbGUucHJvdG9idWYuVGltZXN0YW1wUgl1cGRhdGVkQXQaOAoKQXR0cnNFbnRyeRIQCgNrZXkY'
    'ASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use contextEdgeDescriptor instead')
const ContextEdge$json = {
  '1': 'ContextEdge',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'repo_id', '3': 2, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'src_node_id', '3': 3, '4': 1, '5': 9, '10': 'srcNodeId'},
    {'1': 'dst_node_id', '3': 4, '4': 1, '5': 9, '10': 'dstNodeId'},
    {'1': 'rel', '3': 5, '4': 1, '5': 9, '10': 'rel'},
    {
      '1': 'attrs',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextEdge.AttrsEntry',
      '10': 'attrs'
    },
    {
      '1': 'created_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
  '3': [ContextEdge_AttrsEntry$json],
};

@$core.Deprecated('Use contextEdgeDescriptor instead')
const ContextEdge_AttrsEntry$json = {
  '1': 'AttrsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ContextEdge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextEdgeDescriptor = $convert.base64Decode(
    'CgtDb250ZXh0RWRnZRIOCgJpZBgBIAEoCVICaWQSFwoHcmVwb19pZBgCIAEoCVIGcmVwb0lkEh'
    '4KC3NyY19ub2RlX2lkGAMgASgJUglzcmNOb2RlSWQSHgoLZHN0X25vZGVfaWQYBCABKAlSCWRz'
    'dE5vZGVJZBIQCgNyZWwYBSABKAlSA3JlbBI8CgVhdHRycxgGIAMoCzImLmZsZWV0a2FuYmFuLn'
    'YxLkNvbnRleHRFZGdlLkF0dHJzRW50cnlSBWF0dHJzEjkKCmNyZWF0ZWRfYXQYByABKAsyGi5n'
    'b29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQaOAoKQXR0cnNFbnRyeRIQCgNrZX'
    'kYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use contextFactDescriptor instead')
const ContextFact$json = {
  '1': 'ContextFact',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'repo_id', '3': 2, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'subject_node_id', '3': 3, '4': 1, '5': 9, '10': 'subjectNodeId'},
    {'1': 'predicate', '3': 4, '4': 1, '5': 9, '10': 'predicate'},
    {'1': 'object_text', '3': 5, '4': 1, '5': 9, '10': 'objectText'},
    {
      '1': 'valid_from',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'validFrom'
    },
    {
      '1': 'valid_to',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'validTo'
    },
    {'1': 'supersedes', '3': 8, '4': 1, '5': 9, '10': 'supersedes'},
    {
      '1': 'created_at',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `ContextFact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextFactDescriptor = $convert.base64Decode(
    'CgtDb250ZXh0RmFjdBIOCgJpZBgBIAEoCVICaWQSFwoHcmVwb19pZBgCIAEoCVIGcmVwb0lkEi'
    'YKD3N1YmplY3Rfbm9kZV9pZBgDIAEoCVINc3ViamVjdE5vZGVJZBIcCglwcmVkaWNhdGUYBCAB'
    'KAlSCXByZWRpY2F0ZRIfCgtvYmplY3RfdGV4dBgFIAEoCVIKb2JqZWN0VGV4dBI5Cgp2YWxpZF'
    '9mcm9tGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJdmFsaWRGcm9tEjUKCHZh'
    'bGlkX3RvGAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHdmFsaWRUbxIeCgpzdX'
    'BlcnNlZGVzGAggASgJUgpzdXBlcnNlZGVzEjkKCmNyZWF0ZWRfYXQYCSABKAsyGi5nb29nbGUu'
    'cHJvdG9idWYuVGltZXN0YW1wUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use contextNodeDetailDescriptor instead')
const ContextNodeDetail$json = {
  '1': 'ContextNodeDetail',
  '2': [
    {
      '1': 'node',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fleetkanban.v1.ContextNode',
      '10': 'node'
    },
    {
      '1': 'out_edges',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextEdge',
      '10': 'outEdges'
    },
    {
      '1': 'in_edges',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextEdge',
      '10': 'inEdges'
    },
    {
      '1': 'neighbors',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextNode',
      '10': 'neighbors'
    },
    {
      '1': 'facts',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextFact',
      '10': 'facts'
    },
    {'1': 'source_task_id', '3': 6, '4': 1, '5': 9, '10': 'sourceTaskId'},
    {'1': 'source_session_id', '3': 7, '4': 1, '5': 9, '10': 'sourceSessionId'},
  ],
};

/// Descriptor for `ContextNodeDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextNodeDetailDescriptor = $convert.base64Decode(
    'ChFDb250ZXh0Tm9kZURldGFpbBIvCgRub2RlGAEgASgLMhsuZmxlZXRrYW5iYW4udjEuQ29udG'
    'V4dE5vZGVSBG5vZGUSOAoJb3V0X2VkZ2VzGAIgAygLMhsuZmxlZXRrYW5iYW4udjEuQ29udGV4'
    'dEVkZ2VSCG91dEVkZ2VzEjYKCGluX2VkZ2VzGAMgAygLMhsuZmxlZXRrYW5iYW4udjEuQ29udG'
    'V4dEVkZ2VSB2luRWRnZXMSOQoJbmVpZ2hib3JzGAQgAygLMhsuZmxlZXRrYW5iYW4udjEuQ29u'
    'dGV4dE5vZGVSCW5laWdoYm9ycxIxCgVmYWN0cxgFIAMoCzIbLmZsZWV0a2FuYmFuLnYxLkNvbn'
    'RleHRGYWN0UgVmYWN0cxIkCg5zb3VyY2VfdGFza19pZBgGIAEoCVIMc291cmNlVGFza0lkEioK'
    'EXNvdXJjZV9zZXNzaW9uX2lkGAcgASgJUg9zb3VyY2VTZXNzaW9uSWQ=');

@$core.Deprecated('Use contextOverviewDescriptor instead')
const ContextOverview$json = {
  '1': 'ContextOverview',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {
      '1': 'node_counts_by_kind',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextOverview.NodeCountsByKindEntry',
      '10': 'nodeCountsByKind'
    },
    {
      '1': 'edge_counts_by_rel',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextOverview.EdgeCountsByRelEntry',
      '10': 'edgeCountsByRel'
    },
    {'1': 'active_fact_count', '3': 4, '4': 1, '5': 5, '10': 'activeFactCount'},
    {
      '1': 'expired_fact_count',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'expiredFactCount'
    },
    {
      '1': 'pending_scratchpad_count',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'pendingScratchpadCount'
    },
    {
      '1': 'promoted_scratchpad_count',
      '3': 7,
      '4': 1,
      '5': 5,
      '10': 'promotedScratchpadCount'
    },
    {
      '1': 'rejected_scratchpad_count',
      '3': 8,
      '4': 1,
      '5': 5,
      '10': 'rejectedScratchpadCount'
    },
    {'1': 'vector_count', '3': 9, '4': 1, '5': 5, '10': 'vectorCount'},
    {'1': 'vector_dim', '3': 10, '4': 1, '5': 5, '10': 'vectorDim'},
    {'1': 'vector_bytes', '3': 11, '4': 1, '5': 3, '10': 'vectorBytes'},
    {
      '1': 'observed_session_count',
      '3': 12,
      '4': 1,
      '5': 5,
      '10': 'observedSessionCount'
    },
    {'1': 'enabled', '3': 13, '4': 1, '5': 8, '10': 'enabled'},
  ],
  '3': [
    ContextOverview_NodeCountsByKindEntry$json,
    ContextOverview_EdgeCountsByRelEntry$json
  ],
};

@$core.Deprecated('Use contextOverviewDescriptor instead')
const ContextOverview_NodeCountsByKindEntry$json = {
  '1': 'NodeCountsByKindEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use contextOverviewDescriptor instead')
const ContextOverview_EdgeCountsByRelEntry$json = {
  '1': 'EdgeCountsByRelEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ContextOverview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextOverviewDescriptor = $convert.base64Decode(
    'Cg9Db250ZXh0T3ZlcnZpZXcSFwoHcmVwb19pZBgBIAEoCVIGcmVwb0lkEmQKE25vZGVfY291bn'
    'RzX2J5X2tpbmQYAiADKAsyNS5mbGVldGthbmJhbi52MS5Db250ZXh0T3ZlcnZpZXcuTm9kZUNv'
    'dW50c0J5S2luZEVudHJ5UhBub2RlQ291bnRzQnlLaW5kEmEKEmVkZ2VfY291bnRzX2J5X3JlbB'
    'gDIAMoCzI0LmZsZWV0a2FuYmFuLnYxLkNvbnRleHRPdmVydmlldy5FZGdlQ291bnRzQnlSZWxF'
    'bnRyeVIPZWRnZUNvdW50c0J5UmVsEioKEWFjdGl2ZV9mYWN0X2NvdW50GAQgASgFUg9hY3Rpdm'
    'VGYWN0Q291bnQSLAoSZXhwaXJlZF9mYWN0X2NvdW50GAUgASgFUhBleHBpcmVkRmFjdENvdW50'
    'EjgKGHBlbmRpbmdfc2NyYXRjaHBhZF9jb3VudBgGIAEoBVIWcGVuZGluZ1NjcmF0Y2hwYWRDb3'
    'VudBI6Chlwcm9tb3RlZF9zY3JhdGNocGFkX2NvdW50GAcgASgFUhdwcm9tb3RlZFNjcmF0Y2hw'
    'YWRDb3VudBI6ChlyZWplY3RlZF9zY3JhdGNocGFkX2NvdW50GAggASgFUhdyZWplY3RlZFNjcm'
    'F0Y2hwYWRDb3VudBIhCgx2ZWN0b3JfY291bnQYCSABKAVSC3ZlY3RvckNvdW50Eh0KCnZlY3Rv'
    'cl9kaW0YCiABKAVSCXZlY3RvckRpbRIhCgx2ZWN0b3JfYnl0ZXMYCyABKANSC3ZlY3RvckJ5dG'
    'VzEjQKFm9ic2VydmVkX3Nlc3Npb25fY291bnQYDCABKAVSFG9ic2VydmVkU2Vzc2lvbkNvdW50'
    'EhgKB2VuYWJsZWQYDSABKAhSB2VuYWJsZWQaQwoVTm9kZUNvdW50c0J5S2luZEVudHJ5EhAKA2'
    'tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgFUgV2YWx1ZToCOAEaQgoURWRnZUNvdW50c0J5'
    'UmVsRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAVSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use repoIdRequestDescriptor instead')
const RepoIdRequest$json = {
  '1': 'RepoIdRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
  ],
};

/// Descriptor for `RepoIdRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repoIdRequestDescriptor = $convert
    .base64Decode('Cg1SZXBvSWRSZXF1ZXN0EhcKB3JlcG9faWQYASABKAlSBnJlcG9JZA==');

@$core.Deprecated('Use nodeIdRequestDescriptor instead')
const NodeIdRequest$json = {
  '1': 'NodeIdRequest',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
  ],
};

/// Descriptor for `NodeIdRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeIdRequestDescriptor = $convert
    .base64Decode('Cg1Ob2RlSWRSZXF1ZXN0EhcKB25vZGVfaWQYASABKAlSBm5vZGVJZA==');

@$core.Deprecated('Use edgeIdRequestDescriptor instead')
const EdgeIdRequest$json = {
  '1': 'EdgeIdRequest',
  '2': [
    {'1': 'edge_id', '3': 1, '4': 1, '5': 9, '10': 'edgeId'},
  ],
};

/// Descriptor for `EdgeIdRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List edgeIdRequestDescriptor = $convert
    .base64Decode('Cg1FZGdlSWRSZXF1ZXN0EhcKB2VkZ2VfaWQYASABKAlSBmVkZ2VJZA==');

@$core.Deprecated('Use entryIdRequestDescriptor instead')
const EntryIdRequest$json = {
  '1': 'EntryIdRequest',
  '2': [
    {'1': 'entry_id', '3': 1, '4': 1, '5': 9, '10': 'entryId'},
  ],
};

/// Descriptor for `EntryIdRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entryIdRequestDescriptor = $convert.base64Decode(
    'Cg5FbnRyeUlkUmVxdWVzdBIZCghlbnRyeV9pZBgBIAEoCVIHZW50cnlJZA==');

@$core.Deprecated('Use searchContextRequestDescriptor instead')
const SearchContextRequest$json = {
  '1': 'SearchContextRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    {'1': 'mode', '3': 3, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'limit', '3': 4, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'kinds', '3': 5, '4': 3, '5': 9, '10': 'kinds'},
    {'1': 'only_enabled', '3': 6, '4': 1, '5': 8, '10': 'onlyEnabled'},
  ],
};

/// Descriptor for `SearchContextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchContextRequestDescriptor = $convert.base64Decode(
    'ChRTZWFyY2hDb250ZXh0UmVxdWVzdBIXCgdyZXBvX2lkGAEgASgJUgZyZXBvSWQSFAoFcXVlcn'
    'kYAiABKAlSBXF1ZXJ5EhIKBG1vZGUYAyABKAlSBG1vZGUSFAoFbGltaXQYBCABKAVSBWxpbWl0'
    'EhQKBWtpbmRzGAUgAygJUgVraW5kcxIhCgxvbmx5X2VuYWJsZWQYBiABKAhSC29ubHlFbmFibG'
    'Vk');

@$core.Deprecated('Use searchHitDescriptor instead')
const SearchHit$json = {
  '1': 'SearchHit',
  '2': [
    {
      '1': 'node',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fleetkanban.v1.ContextNode',
      '10': 'node'
    },
    {'1': 'score', '3': 2, '4': 1, '5': 2, '10': 'score'},
    {'1': 'rank', '3': 3, '4': 1, '5': 5, '10': 'rank'},
    {'1': 'channel', '3': 4, '4': 1, '5': 9, '10': 'channel'},
    {'1': 'reason', '3': 5, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `SearchHit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchHitDescriptor = $convert.base64Decode(
    'CglTZWFyY2hIaXQSLwoEbm9kZRgBIAEoCzIbLmZsZWV0a2FuYmFuLnYxLkNvbnRleHROb2RlUg'
    'Rub2RlEhQKBXNjb3JlGAIgASgCUgVzY29yZRISCgRyYW5rGAMgASgFUgRyYW5rEhgKB2NoYW5u'
    'ZWwYBCABKAlSB2NoYW5uZWwSFgoGcmVhc29uGAUgASgJUgZyZWFzb24=');

@$core.Deprecated('Use searchContextResponseDescriptor instead')
const SearchContextResponse$json = {
  '1': 'SearchContextResponse',
  '2': [
    {
      '1': 'channels',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.SearchContextResponse.ChannelsEntry',
      '10': 'channels'
    },
    {'1': 'total_unique', '3': 2, '4': 1, '5': 5, '10': 'totalUnique'},
  ],
  '3': [SearchContextResponse_ChannelsEntry$json],
};

@$core.Deprecated('Use searchContextResponseDescriptor instead')
const SearchContextResponse_ChannelsEntry$json = {
  '1': 'ChannelsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fleetkanban.v1.SearchHitList',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `SearchContextResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchContextResponseDescriptor = $convert.base64Decode(
    'ChVTZWFyY2hDb250ZXh0UmVzcG9uc2USTwoIY2hhbm5lbHMYASADKAsyMy5mbGVldGthbmJhbi'
    '52MS5TZWFyY2hDb250ZXh0UmVzcG9uc2UuQ2hhbm5lbHNFbnRyeVIIY2hhbm5lbHMSIQoMdG90'
    'YWxfdW5pcXVlGAIgASgFUgt0b3RhbFVuaXF1ZRpaCg1DaGFubmVsc0VudHJ5EhAKA2tleRgBIA'
    'EoCVIDa2V5EjMKBXZhbHVlGAIgASgLMh0uZmxlZXRrYW5iYW4udjEuU2VhcmNoSGl0TGlzdFIF'
    'dmFsdWU6AjgB');

@$core.Deprecated('Use searchHitListDescriptor instead')
const SearchHitList$json = {
  '1': 'SearchHitList',
  '2': [
    {
      '1': 'hits',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.SearchHit',
      '10': 'hits'
    },
  ],
};

/// Descriptor for `SearchHitList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchHitListDescriptor = $convert.base64Decode(
    'Cg1TZWFyY2hIaXRMaXN0Ei0KBGhpdHMYASADKAsyGS5mbGVldGthbmJhbi52MS5TZWFyY2hIaX'
    'RSBGhpdHM=');

@$core.Deprecated('Use listNodesRequestDescriptor instead')
const ListNodesRequest$json = {
  '1': 'ListNodesRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'kinds', '3': 2, '4': 3, '5': 9, '10': 'kinds'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'offset', '3': 4, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'sort', '3': 5, '4': 1, '5': 9, '10': 'sort'},
    {'1': 'source_kinds', '3': 6, '4': 3, '5': 9, '10': 'sourceKinds'},
    {'1': 'label_contains', '3': 7, '4': 1, '5': 9, '10': 'labelContains'},
    {'1': 'pinned_filter', '3': 8, '4': 1, '5': 5, '10': 'pinnedFilter'},
    {'1': 'enabled_filter', '3': 9, '4': 1, '5': 5, '10': 'enabledFilter'},
  ],
};

/// Descriptor for `ListNodesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNodesRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0Tm9kZXNSZXF1ZXN0EhcKB3JlcG9faWQYASABKAlSBnJlcG9JZBIUCgVraW5kcxgCIA'
    'MoCVIFa2luZHMSFAoFbGltaXQYAyABKAVSBWxpbWl0EhYKBm9mZnNldBgEIAEoBVIGb2Zmc2V0'
    'EhIKBHNvcnQYBSABKAlSBHNvcnQSIQoMc291cmNlX2tpbmRzGAYgAygJUgtzb3VyY2VLaW5kcx'
    'IlCg5sYWJlbF9jb250YWlucxgHIAEoCVINbGFiZWxDb250YWlucxIjCg1waW5uZWRfZmlsdGVy'
    'GAggASgFUgxwaW5uZWRGaWx0ZXISJQoOZW5hYmxlZF9maWx0ZXIYCSABKAVSDWVuYWJsZWRGaW'
    'x0ZXI=');

@$core.Deprecated('Use listNodesResponseDescriptor instead')
const ListNodesResponse$json = {
  '1': 'ListNodesResponse',
  '2': [
    {
      '1': 'nodes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextNode',
      '10': 'nodes'
    },
    {'1': 'total', '3': 2, '4': 1, '5': 5, '10': 'total'},
  ],
};

/// Descriptor for `ListNodesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listNodesResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0Tm9kZXNSZXNwb25zZRIxCgVub2RlcxgBIAMoCzIbLmZsZWV0a2FuYmFuLnYxLkNvbn'
    'RleHROb2RlUgVub2RlcxIUCgV0b3RhbBgCIAEoBVIFdG90YWw=');

@$core.Deprecated('Use createNodeRequestDescriptor instead')
const CreateNodeRequest$json = {
  '1': 'CreateNodeRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'content_md', '3': 4, '4': 1, '5': 9, '10': 'contentMd'},
    {
      '1': 'attrs',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.CreateNodeRequest.AttrsEntry',
      '10': 'attrs'
    },
    {'1': 'source_kind', '3': 6, '4': 1, '5': 9, '10': 'sourceKind'},
    {'1': 'confidence', '3': 7, '4': 1, '5': 2, '10': 'confidence'},
  ],
  '3': [CreateNodeRequest_AttrsEntry$json],
};

@$core.Deprecated('Use createNodeRequestDescriptor instead')
const CreateNodeRequest_AttrsEntry$json = {
  '1': 'AttrsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `CreateNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createNodeRequestDescriptor = $convert.base64Decode(
    'ChFDcmVhdGVOb2RlUmVxdWVzdBIXCgdyZXBvX2lkGAEgASgJUgZyZXBvSWQSEgoEa2luZBgCIA'
    'EoCVIEa2luZBIUCgVsYWJlbBgDIAEoCVIFbGFiZWwSHQoKY29udGVudF9tZBgEIAEoCVIJY29u'
    'dGVudE1kEkIKBWF0dHJzGAUgAygLMiwuZmxlZXRrYW5iYW4udjEuQ3JlYXRlTm9kZVJlcXVlc3'
    'QuQXR0cnNFbnRyeVIFYXR0cnMSHwoLc291cmNlX2tpbmQYBiABKAlSCnNvdXJjZUtpbmQSHgoK'
    'Y29uZmlkZW5jZRgHIAEoAlIKY29uZmlkZW5jZRo4CgpBdHRyc0VudHJ5EhAKA2tleRgBIAEoCV'
    'IDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use updateNodeRequestDescriptor instead')
const UpdateNodeRequest$json = {
  '1': 'UpdateNodeRequest',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'content_md', '3': 3, '4': 1, '5': 9, '10': 'contentMd'},
    {
      '1': 'attrs',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.UpdateNodeRequest.AttrsEntry',
      '10': 'attrs'
    },
    {'1': 'enabled_op', '3': 5, '4': 1, '5': 5, '10': 'enabledOp'},
    {'1': 'pinned_op', '3': 6, '4': 1, '5': 5, '10': 'pinnedOp'},
    {'1': 'confidence', '3': 7, '4': 1, '5': 2, '10': 'confidence'},
  ],
  '3': [UpdateNodeRequest_AttrsEntry$json],
};

@$core.Deprecated('Use updateNodeRequestDescriptor instead')
const UpdateNodeRequest_AttrsEntry$json = {
  '1': 'AttrsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `UpdateNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateNodeRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVOb2RlUmVxdWVzdBIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQSFAoFbGFiZWwYAi'
    'ABKAlSBWxhYmVsEh0KCmNvbnRlbnRfbWQYAyABKAlSCWNvbnRlbnRNZBJCCgVhdHRycxgEIAMo'
    'CzIsLmZsZWV0a2FuYmFuLnYxLlVwZGF0ZU5vZGVSZXF1ZXN0LkF0dHJzRW50cnlSBWF0dHJzEh'
    '0KCmVuYWJsZWRfb3AYBSABKAVSCWVuYWJsZWRPcBIbCglwaW5uZWRfb3AYBiABKAVSCHBpbm5l'
    'ZE9wEh4KCmNvbmZpZGVuY2UYByABKAJSCmNvbmZpZGVuY2UaOAoKQXR0cnNFbnRyeRIQCgNrZX'
    'kYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use pinNodeRequestDescriptor instead')
const PinNodeRequest$json = {
  '1': 'PinNodeRequest',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'pinned', '3': 2, '4': 1, '5': 8, '10': 'pinned'},
  ],
};

/// Descriptor for `PinNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pinNodeRequestDescriptor = $convert.base64Decode(
    'Cg5QaW5Ob2RlUmVxdWVzdBIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQSFgoGcGlubmVkGAIgAS'
    'gIUgZwaW5uZWQ=');

@$core.Deprecated('Use listEdgesRequestDescriptor instead')
const ListEdgesRequest$json = {
  '1': 'ListEdgesRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'node_id', '3': 2, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'rels', '3': 3, '4': 3, '5': 9, '10': 'rels'},
    {'1': 'limit', '3': 4, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'offset', '3': 5, '4': 1, '5': 5, '10': 'offset'},
  ],
};

/// Descriptor for `ListEdgesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEdgesRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0RWRnZXNSZXF1ZXN0EhcKB3JlcG9faWQYASABKAlSBnJlcG9JZBIXCgdub2RlX2lkGA'
    'IgASgJUgZub2RlSWQSEgoEcmVscxgDIAMoCVIEcmVscxIUCgVsaW1pdBgEIAEoBVIFbGltaXQS'
    'FgoGb2Zmc2V0GAUgASgFUgZvZmZzZXQ=');

@$core.Deprecated('Use listEdgesResponseDescriptor instead')
const ListEdgesResponse$json = {
  '1': 'ListEdgesResponse',
  '2': [
    {
      '1': 'edges',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextEdge',
      '10': 'edges'
    },
    {'1': 'total', '3': 2, '4': 1, '5': 5, '10': 'total'},
  ],
};

/// Descriptor for `ListEdgesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEdgesResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0RWRnZXNSZXNwb25zZRIxCgVlZGdlcxgBIAMoCzIbLmZsZWV0a2FuYmFuLnYxLkNvbn'
    'RleHRFZGdlUgVlZGdlcxIUCgV0b3RhbBgCIAEoBVIFdG90YWw=');

@$core.Deprecated('Use createEdgeRequestDescriptor instead')
const CreateEdgeRequest$json = {
  '1': 'CreateEdgeRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'src_node_id', '3': 2, '4': 1, '5': 9, '10': 'srcNodeId'},
    {'1': 'dst_node_id', '3': 3, '4': 1, '5': 9, '10': 'dstNodeId'},
    {'1': 'rel', '3': 4, '4': 1, '5': 9, '10': 'rel'},
    {
      '1': 'attrs',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.CreateEdgeRequest.AttrsEntry',
      '10': 'attrs'
    },
  ],
  '3': [CreateEdgeRequest_AttrsEntry$json],
};

@$core.Deprecated('Use createEdgeRequestDescriptor instead')
const CreateEdgeRequest_AttrsEntry$json = {
  '1': 'AttrsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `CreateEdgeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createEdgeRequestDescriptor = $convert.base64Decode(
    'ChFDcmVhdGVFZGdlUmVxdWVzdBIXCgdyZXBvX2lkGAEgASgJUgZyZXBvSWQSHgoLc3JjX25vZG'
    'VfaWQYAiABKAlSCXNyY05vZGVJZBIeCgtkc3Rfbm9kZV9pZBgDIAEoCVIJZHN0Tm9kZUlkEhAK'
    'A3JlbBgEIAEoCVIDcmVsEkIKBWF0dHJzGAUgAygLMiwuZmxlZXRrYW5iYW4udjEuQ3JlYXRlRW'
    'RnZVJlcXVlc3QuQXR0cnNFbnRyeVIFYXR0cnMaOAoKQXR0cnNFbnRyeRIQCgNrZXkYASABKAlS'
    'A2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use listFactsRequestDescriptor instead')
const ListFactsRequest$json = {
  '1': 'ListFactsRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'subject_node_id', '3': 2, '4': 1, '5': 9, '10': 'subjectNodeId'},
    {'1': 'include_expired', '3': 3, '4': 1, '5': 8, '10': 'includeExpired'},
    {'1': 'limit', '3': 4, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'offset', '3': 5, '4': 1, '5': 5, '10': 'offset'},
  ],
};

/// Descriptor for `ListFactsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFactsRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0RmFjdHNSZXF1ZXN0EhcKB3JlcG9faWQYASABKAlSBnJlcG9JZBImCg9zdWJqZWN0X2'
    '5vZGVfaWQYAiABKAlSDXN1YmplY3ROb2RlSWQSJwoPaW5jbHVkZV9leHBpcmVkGAMgASgIUg5p'
    'bmNsdWRlRXhwaXJlZBIUCgVsaW1pdBgEIAEoBVIFbGltaXQSFgoGb2Zmc2V0GAUgASgFUgZvZm'
    'ZzZXQ=');

@$core.Deprecated('Use listFactsResponseDescriptor instead')
const ListFactsResponse$json = {
  '1': 'ListFactsResponse',
  '2': [
    {
      '1': 'facts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextFact',
      '10': 'facts'
    },
    {'1': 'total', '3': 2, '4': 1, '5': 5, '10': 'total'},
  ],
};

/// Descriptor for `ListFactsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFactsResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0RmFjdHNSZXNwb25zZRIxCgVmYWN0cxgBIAMoCzIbLmZsZWV0a2FuYmFuLnYxLkNvbn'
    'RleHRGYWN0UgVmYWN0cxIUCgV0b3RhbBgCIAEoBVIFdG90YWw=');

@$core.Deprecated('Use injectionSourceDescriptor instead')
const InjectionSource$json = {
  '1': 'InjectionSource',
  '2': [
    {'1': 'source_type', '3': 1, '4': 1, '5': 9, '10': 'sourceType'},
    {'1': 'source_ref', '3': 2, '4': 1, '5': 9, '10': 'sourceRef'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'channel', '3': 4, '4': 1, '5': 9, '10': 'channel'},
    {'1': 'tokens', '3': 5, '4': 1, '5': 5, '10': 'tokens'},
    {'1': 'relevance', '3': 6, '4': 1, '5': 2, '10': 'relevance'},
  ],
};

/// Descriptor for `InjectionSource`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List injectionSourceDescriptor = $convert.base64Decode(
    'Cg9JbmplY3Rpb25Tb3VyY2USHwoLc291cmNlX3R5cGUYASABKAlSCnNvdXJjZVR5cGUSHQoKc2'
    '91cmNlX3JlZhgCIAEoCVIJc291cmNlUmVmEhQKBWxhYmVsGAMgASgJUgVsYWJlbBIYCgdjaGFu'
    'bmVsGAQgASgJUgdjaGFubmVsEhYKBnRva2VucxgFIAEoBVIGdG9rZW5zEhwKCXJlbGV2YW5jZR'
    'gGIAEoAlIJcmVsZXZhbmNl');

@$core.Deprecated('Use injectionPreviewDescriptor instead')
const InjectionPreview$json = {
  '1': 'InjectionPreview',
  '2': [
    {'1': 'system_prompt', '3': 1, '4': 1, '5': 9, '10': 'systemPrompt'},
    {
      '1': 'sources',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.InjectionSource',
      '10': 'sources'
    },
    {'1': 'estimated_tokens', '3': 3, '4': 1, '5': 5, '10': 'estimatedTokens'},
    {'1': 'tier', '3': 4, '4': 1, '5': 9, '10': 'tier'},
  ],
};

/// Descriptor for `InjectionPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List injectionPreviewDescriptor = $convert.base64Decode(
    'ChBJbmplY3Rpb25QcmV2aWV3EiMKDXN5c3RlbV9wcm9tcHQYASABKAlSDHN5c3RlbVByb21wdB'
    'I5Cgdzb3VyY2VzGAIgAygLMh8uZmxlZXRrYW5iYW4udjEuSW5qZWN0aW9uU291cmNlUgdzb3Vy'
    'Y2VzEikKEGVzdGltYXRlZF90b2tlbnMYAyABKAVSD2VzdGltYXRlZFRva2VucxISCgR0aWVyGA'
    'QgASgJUgR0aWVy');

@$core.Deprecated('Use previewInjectionRequestDescriptor instead')
const PreviewInjectionRequest$json = {
  '1': 'PreviewInjectionRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'task_id', '3': 2, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'raw_prompt', '3': 3, '4': 1, '5': 9, '10': 'rawPrompt'},
    {'1': 'tier', '3': 4, '4': 1, '5': 9, '10': 'tier'},
  ],
};

/// Descriptor for `PreviewInjectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewInjectionRequestDescriptor = $convert.base64Decode(
    'ChdQcmV2aWV3SW5qZWN0aW9uUmVxdWVzdBIXCgdyZXBvX2lkGAEgASgJUgZyZXBvSWQSFwoHdG'
    'Fza19pZBgCIAEoCVIGdGFza0lkEh0KCnJhd19wcm9tcHQYAyABKAlSCXJhd1Byb21wdBISCgR0'
    'aWVyGAQgASgJUgR0aWVy');

@$core.Deprecated('Use rebuildEmbeddingsResponseDescriptor instead')
const RebuildEmbeddingsResponse$json = {
  '1': 'RebuildEmbeddingsResponse',
  '2': [
    {'1': 'rebuilt', '3': 1, '4': 1, '5': 5, '10': 'rebuilt'},
    {'1': 'skipped', '3': 2, '4': 1, '5': 5, '10': 'skipped'},
  ],
};

/// Descriptor for `RebuildEmbeddingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rebuildEmbeddingsResponseDescriptor =
    $convert.base64Decode(
        'ChlSZWJ1aWxkRW1iZWRkaW5nc1Jlc3BvbnNlEhgKB3JlYnVpbHQYASABKAVSB3JlYnVpbHQSGA'
        'oHc2tpcHBlZBgCIAEoBVIHc2tpcHBlZA==');

@$core.Deprecated('Use rebuildCodeGraphResponseDescriptor instead')
const RebuildCodeGraphResponse$json = {
  '1': 'RebuildCodeGraphResponse',
  '2': [
    {'1': 'files_scanned', '3': 1, '4': 1, '5': 5, '10': 'filesScanned'},
    {'1': 'nodes_created', '3': 2, '4': 1, '5': 5, '10': 'nodesCreated'},
    {'1': 'nodes_updated', '3': 3, '4': 1, '5': 5, '10': 'nodesUpdated'},
    {'1': 'edges_created', '3': 4, '4': 1, '5': 5, '10': 'edgesCreated'},
  ],
};

/// Descriptor for `RebuildCodeGraphResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rebuildCodeGraphResponseDescriptor = $convert.base64Decode(
    'ChhSZWJ1aWxkQ29kZUdyYXBoUmVzcG9uc2USIwoNZmlsZXNfc2Nhbm5lZBgBIAEoBVIMZmlsZX'
    'NTY2FubmVkEiMKDW5vZGVzX2NyZWF0ZWQYAiABKAVSDG5vZGVzQ3JlYXRlZBIjCg1ub2Rlc191'
    'cGRhdGVkGAMgASgFUgxub2Rlc1VwZGF0ZWQSIwoNZWRnZXNfY3JlYXRlZBgEIAEoBVIMZWRnZX'
    'NDcmVhdGVk');

@$core.Deprecated('Use analyzeRepoRequestDescriptor instead')
const AnalyzeRepoRequest$json = {
  '1': 'AnalyzeRepoRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'force', '3': 2, '4': 1, '5': 8, '10': 'force'},
    {'1': 'model', '3': 3, '4': 1, '5': 9, '10': 'model'},
  ],
};

/// Descriptor for `AnalyzeRepoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List analyzeRepoRequestDescriptor = $convert.base64Decode(
    'ChJBbmFseXplUmVwb1JlcXVlc3QSFwoHcmVwb19pZBgBIAEoCVIGcmVwb0lkEhQKBWZvcmNlGA'
    'IgASgIUgVmb3JjZRIUCgVtb2RlbBgDIAEoCVIFbW9kZWw=');

@$core.Deprecated('Use memorySettingsDescriptor instead')
const MemorySettings$json = {
  '1': 'MemorySettings',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'embedding_provider',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'embeddingProvider'
    },
    {'1': 'embedding_model', '3': 4, '4': 1, '5': 9, '10': 'embeddingModel'},
    {'1': 'embedding_dim', '3': 5, '4': 1, '5': 5, '10': 'embeddingDim'},
    {'1': 'llm_provider', '3': 6, '4': 1, '5': 9, '10': 'llmProvider'},
    {'1': 'llm_model', '3': 7, '4': 1, '5': 9, '10': 'llmModel'},
    {
      '1': 'passive_token_budget',
      '3': 8,
      '4': 1,
      '5': 5,
      '10': 'passiveTokenBudget'
    },
    {'1': 'top_k_neighbors', '3': 9, '4': 1, '5': 5, '10': 'topKNeighbors'},
    {
      '1': 'auto_promote_high_confidence',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'autoPromoteHighConfidence'
    },
    {
      '1': 'auto_promote_threshold',
      '3': 11,
      '4': 1,
      '5': 2,
      '10': 'autoPromoteThreshold'
    },
    {
      '1': 'updated_at',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
  ],
};

/// Descriptor for `MemorySettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memorySettingsDescriptor = $convert.base64Decode(
    'Cg5NZW1vcnlTZXR0aW5ncxIXCgdyZXBvX2lkGAEgASgJUgZyZXBvSWQSGAoHZW5hYmxlZBgCIA'
    'EoCFIHZW5hYmxlZBItChJlbWJlZGRpbmdfcHJvdmlkZXIYAyABKAlSEWVtYmVkZGluZ1Byb3Zp'
    'ZGVyEicKD2VtYmVkZGluZ19tb2RlbBgEIAEoCVIOZW1iZWRkaW5nTW9kZWwSIwoNZW1iZWRkaW'
    '5nX2RpbRgFIAEoBVIMZW1iZWRkaW5nRGltEiEKDGxsbV9wcm92aWRlchgGIAEoCVILbGxtUHJv'
    'dmlkZXISGwoJbGxtX21vZGVsGAcgASgJUghsbG1Nb2RlbBIwChRwYXNzaXZlX3Rva2VuX2J1ZG'
    'dldBgIIAEoBVIScGFzc2l2ZVRva2VuQnVkZ2V0EiYKD3RvcF9rX25laWdoYm9ycxgJIAEoBVIN'
    'dG9wS05laWdoYm9ycxI/ChxhdXRvX3Byb21vdGVfaGlnaF9jb25maWRlbmNlGAogASgIUhlhdX'
    'RvUHJvbW90ZUhpZ2hDb25maWRlbmNlEjQKFmF1dG9fcHJvbW90ZV90aHJlc2hvbGQYCyABKAJS'
    'FGF1dG9Qcm9tb3RlVGhyZXNob2xkEjkKCnVwZGF0ZWRfYXQYDCABKAsyGi5nb29nbGUucHJvdG'
    '9idWYuVGltZXN0YW1wUgl1cGRhdGVkQXQ=');

@$core.Deprecated('Use updateMemorySettingsRequestDescriptor instead')
const UpdateMemorySettingsRequest$json = {
  '1': 'UpdateMemorySettingsRequest',
  '2': [
    {
      '1': 'settings',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fleetkanban.v1.MemorySettings',
      '10': 'settings'
    },
  ],
};

/// Descriptor for `UpdateMemorySettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateMemorySettingsRequestDescriptor =
    $convert.base64Decode(
        'ChtVcGRhdGVNZW1vcnlTZXR0aW5nc1JlcXVlc3QSOgoIc2V0dGluZ3MYASABKAsyHi5mbGVldG'
        'thbmJhbi52MS5NZW1vcnlTZXR0aW5nc1IIc2V0dGluZ3M=');

@$core.Deprecated('Use memoryHealthDescriptor instead')
const MemoryHealth$json = {
  '1': 'MemoryHealth',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {
      '1': 'provider_reachable',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'providerReachable'
    },
    {'1': 'vector_count', '3': 3, '4': 1, '5': 5, '10': 'vectorCount'},
    {
      '1': 'last_rebuild_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastRebuildAt'
    },
    {'1': 'last_error', '3': 5, '4': 1, '5': 9, '10': 'lastError'},
  ],
};

/// Descriptor for `MemoryHealth`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memoryHealthDescriptor = $convert.base64Decode(
    'CgxNZW1vcnlIZWFsdGgSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBItChJwcm92aWRlcl9yZW'
    'FjaGFibGUYAiABKAhSEXByb3ZpZGVyUmVhY2hhYmxlEiEKDHZlY3Rvcl9jb3VudBgDIAEoBVIL'
    'dmVjdG9yQ291bnQSQgoPbGFzdF9yZWJ1aWxkX2F0GAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLl'
    'RpbWVzdGFtcFINbGFzdFJlYnVpbGRBdBIdCgpsYXN0X2Vycm9yGAUgASgJUglsYXN0RXJyb3I=');

@$core.Deprecated('Use suggestForNewTaskRequestDescriptor instead')
const SuggestForNewTaskRequest$json = {
  '1': 'SuggestForNewTaskRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'draft_goal', '3': 2, '4': 1, '5': 9, '10': 'draftGoal'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `SuggestForNewTaskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List suggestForNewTaskRequestDescriptor =
    $convert.base64Decode(
        'ChhTdWdnZXN0Rm9yTmV3VGFza1JlcXVlc3QSFwoHcmVwb19pZBgBIAEoCVIGcmVwb0lkEh0KCm'
        'RyYWZ0X2dvYWwYAiABKAlSCWRyYWZ0R29hbBIUCgVsaW1pdBgDIAEoBVIFbGltaXQ=');

@$core.Deprecated('Use taskSuggestionDescriptor instead')
const TaskSuggestion$json = {
  '1': 'TaskSuggestion',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'summary_md', '3': 3, '4': 1, '5': 9, '10': 'summaryMd'},
    {'1': 'score', '3': 4, '4': 1, '5': 2, '10': 'score'},
    {'1': 'source_task_id', '3': 5, '4': 1, '5': 9, '10': 'sourceTaskId'},
  ],
};

/// Descriptor for `TaskSuggestion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskSuggestionDescriptor = $convert.base64Decode(
    'Cg5UYXNrU3VnZ2VzdGlvbhIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQSFAoFbGFiZWwYAiABKA'
    'lSBWxhYmVsEh0KCnN1bW1hcnlfbWQYAyABKAlSCXN1bW1hcnlNZBIUCgVzY29yZRgEIAEoAlIF'
    'c2NvcmUSJAoOc291cmNlX3Rhc2tfaWQYBSABKAlSDHNvdXJjZVRhc2tJZA==');

@$core.Deprecated('Use contextNodeSummaryDescriptor instead')
const ContextNodeSummary$json = {
  '1': 'ContextNodeSummary',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'content_md', '3': 4, '4': 1, '5': 9, '10': 'contentMd'},
    {'1': 'score', '3': 5, '4': 1, '5': 2, '10': 'score'},
  ],
};

/// Descriptor for `ContextNodeSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextNodeSummaryDescriptor = $convert.base64Decode(
    'ChJDb250ZXh0Tm9kZVN1bW1hcnkSFwoHbm9kZV9pZBgBIAEoCVIGbm9kZUlkEhIKBGtpbmQYAi'
    'ABKAlSBGtpbmQSFAoFbGFiZWwYAyABKAlSBWxhYmVsEh0KCmNvbnRlbnRfbWQYBCABKAlSCWNv'
    'bnRlbnRNZBIUCgVzY29yZRgFIAEoAlIFc2NvcmU=');

@$core.Deprecated('Use suggestForNewTaskResponseDescriptor instead')
const SuggestForNewTaskResponse$json = {
  '1': 'SuggestForNewTaskResponse',
  '2': [
    {
      '1': 'similar_tasks',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.TaskSuggestion',
      '10': 'similarTasks'
    },
    {
      '1': 'related_decisions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextNodeSummary',
      '10': 'relatedDecisions'
    },
    {
      '1': 'related_constraints',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ContextNodeSummary',
      '10': 'relatedConstraints'
    },
  ],
};

/// Descriptor for `SuggestForNewTaskResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List suggestForNewTaskResponseDescriptor = $convert.base64Decode(
    'ChlTdWdnZXN0Rm9yTmV3VGFza1Jlc3BvbnNlEkMKDXNpbWlsYXJfdGFza3MYASADKAsyHi5mbG'
    'VldGthbmJhbi52MS5UYXNrU3VnZ2VzdGlvblIMc2ltaWxhclRhc2tzEk8KEXJlbGF0ZWRfZGVj'
    'aXNpb25zGAIgAygLMiIuZmxlZXRrYW5iYW4udjEuQ29udGV4dE5vZGVTdW1tYXJ5UhByZWxhdG'
    'VkRGVjaXNpb25zElMKE3JlbGF0ZWRfY29uc3RyYWludHMYAyADKAsyIi5mbGVldGthbmJhbi52'
    'MS5Db250ZXh0Tm9kZVN1bW1hcnlSEnJlbGF0ZWRDb25zdHJhaW50cw==');

@$core.Deprecated('Use watchContextRequestDescriptor instead')
const WatchContextRequest$json = {
  '1': 'WatchContextRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {
      '1': 'since_seq_by_kind',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.WatchContextRequest.SinceSeqByKindEntry',
      '10': 'sinceSeqByKind'
    },
  ],
  '3': [WatchContextRequest_SinceSeqByKindEntry$json],
};

@$core.Deprecated('Use watchContextRequestDescriptor instead')
const WatchContextRequest_SinceSeqByKindEntry$json = {
  '1': 'SinceSeqByKindEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 3, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `WatchContextRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchContextRequestDescriptor = $convert.base64Decode(
    'ChNXYXRjaENvbnRleHRSZXF1ZXN0EhcKB3JlcG9faWQYASABKAlSBnJlcG9JZBJiChFzaW5jZV'
    '9zZXFfYnlfa2luZBgCIAMoCzI3LmZsZWV0a2FuYmFuLnYxLldhdGNoQ29udGV4dFJlcXVlc3Qu'
    'U2luY2VTZXFCeUtpbmRFbnRyeVIOc2luY2VTZXFCeUtpbmQaQQoTU2luY2VTZXFCeUtpbmRFbn'
    'RyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoA1IFdmFsdWU6AjgB');

@$core.Deprecated('Use contextChangeEventDescriptor instead')
const ContextChangeEvent$json = {
  '1': 'ContextChangeEvent',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'op', '3': 3, '4': 1, '5': 9, '10': 'op'},
    {'1': 'id', '3': 4, '4': 1, '5': 9, '10': 'id'},
    {'1': 'repo_id', '3': 5, '4': 1, '5': 9, '10': 'repoId'},
    {
      '1': 'occurred_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'occurredAt'
    },
    {'1': 'message', '3': 7, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ContextChangeEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contextChangeEventDescriptor = $convert.base64Decode(
    'ChJDb250ZXh0Q2hhbmdlRXZlbnQSEAoDc2VxGAEgASgDUgNzZXESEgoEa2luZBgCIAEoCVIEa2'
    'luZBIOCgJvcBgDIAEoCVICb3ASDgoCaWQYBCABKAlSAmlkEhcKB3JlcG9faWQYBSABKAlSBnJl'
    'cG9JZBI7CgtvY2N1cnJlZF9hdBgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCm'
    '9jY3VycmVkQXQSGAoHbWVzc2FnZRgHIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use scratchpadEntryDescriptor instead')
const ScratchpadEntry$json = {
  '1': 'ScratchpadEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'repo_id', '3': 2, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'proposed_kind', '3': 3, '4': 1, '5': 9, '10': 'proposedKind'},
    {'1': 'proposed_label', '3': 4, '4': 1, '5': 9, '10': 'proposedLabel'},
    {
      '1': 'proposed_content_md',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'proposedContentMd'
    },
    {'1': 'source_kind', '3': 6, '4': 1, '5': 9, '10': 'sourceKind'},
    {'1': 'source_ref', '3': 7, '4': 1, '5': 9, '10': 'sourceRef'},
    {'1': 'signals', '3': 8, '4': 3, '5': 9, '10': 'signals'},
    {'1': 'confidence', '3': 9, '4': 1, '5': 2, '10': 'confidence'},
    {'1': 'status', '3': 10, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'snoozed_until',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'snoozedUntil'
    },
    {
      '1': 'created_at',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
  ],
};

/// Descriptor for `ScratchpadEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scratchpadEntryDescriptor = $convert.base64Decode(
    'Cg9TY3JhdGNocGFkRW50cnkSDgoCaWQYASABKAlSAmlkEhcKB3JlcG9faWQYAiABKAlSBnJlcG'
    '9JZBIjCg1wcm9wb3NlZF9raW5kGAMgASgJUgxwcm9wb3NlZEtpbmQSJQoOcHJvcG9zZWRfbGFi'
    'ZWwYBCABKAlSDXByb3Bvc2VkTGFiZWwSLgoTcHJvcG9zZWRfY29udGVudF9tZBgFIAEoCVIRcH'
    'JvcG9zZWRDb250ZW50TWQSHwoLc291cmNlX2tpbmQYBiABKAlSCnNvdXJjZUtpbmQSHQoKc291'
    'cmNlX3JlZhgHIAEoCVIJc291cmNlUmVmEhgKB3NpZ25hbHMYCCADKAlSB3NpZ25hbHMSHgoKY2'
    '9uZmlkZW5jZRgJIAEoAlIKY29uZmlkZW5jZRIWCgZzdGF0dXMYCiABKAlSBnN0YXR1cxI/Cg1z'
    'bm9vemVkX3VudGlsGAsgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIMc25vb3plZF'
    'VudGlsEjkKCmNyZWF0ZWRfYXQYDCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglj'
    'cmVhdGVkQXQSOQoKdXBkYXRlZF9hdBgNIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbX'
    'BSCXVwZGF0ZWRBdA==');

@$core.Deprecated('Use listPendingRequestDescriptor instead')
const ListPendingRequest$json = {
  '1': 'ListPendingRequest',
  '2': [
    {'1': 'repo_id', '3': 1, '4': 1, '5': 9, '10': 'repoId'},
    {'1': 'statuses', '3': 2, '4': 3, '5': 9, '10': 'statuses'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'offset', '3': 4, '4': 1, '5': 5, '10': 'offset'},
  ],
};

/// Descriptor for `ListPendingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPendingRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0UGVuZGluZ1JlcXVlc3QSFwoHcmVwb19pZBgBIAEoCVIGcmVwb0lkEhoKCHN0YXR1c2'
    'VzGAIgAygJUghzdGF0dXNlcxIUCgVsaW1pdBgDIAEoBVIFbGltaXQSFgoGb2Zmc2V0GAQgASgF'
    'UgZvZmZzZXQ=');

@$core.Deprecated('Use listPendingResponseDescriptor instead')
const ListPendingResponse$json = {
  '1': 'ListPendingResponse',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.ScratchpadEntry',
      '10': 'entries'
    },
    {'1': 'total', '3': 2, '4': 1, '5': 5, '10': 'total'},
  ],
};

/// Descriptor for `ListPendingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPendingResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0UGVuZGluZ1Jlc3BvbnNlEjkKB2VudHJpZXMYASADKAsyHy5mbGVldGthbmJhbi52MS'
    '5TY3JhdGNocGFkRW50cnlSB2VudHJpZXMSFAoFdG90YWwYAiABKAVSBXRvdGFs');

@$core.Deprecated('Use rejectEntryRequestDescriptor instead')
const RejectEntryRequest$json = {
  '1': 'RejectEntryRequest',
  '2': [
    {'1': 'entry_id', '3': 1, '4': 1, '5': 9, '10': 'entryId'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `RejectEntryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rejectEntryRequestDescriptor = $convert.base64Decode(
    'ChJSZWplY3RFbnRyeVJlcXVlc3QSGQoIZW50cnlfaWQYASABKAlSB2VudHJ5SWQSFgoGcmVhc2'
    '9uGAIgASgJUgZyZWFzb24=');

@$core.Deprecated('Use editAndPromoteRequestDescriptor instead')
const EditAndPromoteRequest$json = {
  '1': 'EditAndPromoteRequest',
  '2': [
    {'1': 'entry_id', '3': 1, '4': 1, '5': 9, '10': 'entryId'},
    {'1': 'edited_kind', '3': 2, '4': 1, '5': 9, '10': 'editedKind'},
    {'1': 'edited_label', '3': 3, '4': 1, '5': 9, '10': 'editedLabel'},
    {'1': 'edited_content_md', '3': 4, '4': 1, '5': 9, '10': 'editedContentMd'},
    {
      '1': 'edited_attrs',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.EditAndPromoteRequest.EditedAttrsEntry',
      '10': 'editedAttrs'
    },
  ],
  '3': [EditAndPromoteRequest_EditedAttrsEntry$json],
};

@$core.Deprecated('Use editAndPromoteRequestDescriptor instead')
const EditAndPromoteRequest_EditedAttrsEntry$json = {
  '1': 'EditedAttrsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `EditAndPromoteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editAndPromoteRequestDescriptor = $convert.base64Decode(
    'ChVFZGl0QW5kUHJvbW90ZVJlcXVlc3QSGQoIZW50cnlfaWQYASABKAlSB2VudHJ5SWQSHwoLZW'
    'RpdGVkX2tpbmQYAiABKAlSCmVkaXRlZEtpbmQSIQoMZWRpdGVkX2xhYmVsGAMgASgJUgtlZGl0'
    'ZWRMYWJlbBIqChFlZGl0ZWRfY29udGVudF9tZBgEIAEoCVIPZWRpdGVkQ29udGVudE1kElkKDG'
    'VkaXRlZF9hdHRycxgFIAMoCzI2LmZsZWV0a2FuYmFuLnYxLkVkaXRBbmRQcm9tb3RlUmVxdWVz'
    'dC5FZGl0ZWRBdHRyc0VudHJ5UgtlZGl0ZWRBdHRycxo+ChBFZGl0ZWRBdHRyc0VudHJ5EhAKA2'
    'tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use snoozeRequestDescriptor instead')
const SnoozeRequest$json = {
  '1': 'SnoozeRequest',
  '2': [
    {'1': 'entry_id', '3': 1, '4': 1, '5': 9, '10': 'entryId'},
    {'1': 'days', '3': 2, '4': 1, '5': 5, '10': 'days'},
  ],
};

/// Descriptor for `SnoozeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snoozeRequestDescriptor = $convert.base64Decode(
    'Cg1Tbm9vemVSZXF1ZXN0EhkKCGVudHJ5X2lkGAEgASgJUgdlbnRyeUlkEhIKBGRheXMYAiABKA'
    'VSBGRheXM=');

@$core.Deprecated('Use scratchpadChangeEventDescriptor instead')
const ScratchpadChangeEvent$json = {
  '1': 'ScratchpadChangeEvent',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {'1': 'op', '3': 2, '4': 1, '5': 9, '10': 'op'},
    {'1': 'entry_id', '3': 3, '4': 1, '5': 9, '10': 'entryId'},
    {'1': 'repo_id', '3': 4, '4': 1, '5': 9, '10': 'repoId'},
    {
      '1': 'occurred_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'occurredAt'
    },
  ],
};

/// Descriptor for `ScratchpadChangeEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scratchpadChangeEventDescriptor = $convert.base64Decode(
    'ChVTY3JhdGNocGFkQ2hhbmdlRXZlbnQSEAoDc2VxGAEgASgDUgNzZXESDgoCb3AYAiABKAlSAm'
    '9wEhkKCGVudHJ5X2lkGAMgASgJUgdlbnRyeUlkEhcKB3JlcG9faWQYBCABKAlSBnJlcG9JZBI7'
    'CgtvY2N1cnJlZF9hdBgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCm9jY3Vycm'
    'VkQXQ=');

@$core.Deprecated('Use ollamaStatusDescriptor instead')
const OllamaStatus$json = {
  '1': 'OllamaStatus',
  '2': [
    {'1': 'installed', '3': 1, '4': 1, '5': 8, '10': 'installed'},
    {'1': 'running', '3': 2, '4': 1, '5': 8, '10': 'running'},
    {'1': 'base_url', '3': 3, '4': 1, '5': 9, '10': 'baseUrl'},
    {'1': 'version', '3': 4, '4': 1, '5': 9, '10': 'version'},
    {'1': 'message', '3': 5, '4': 1, '5': 9, '10': 'message'},
    {'1': 'install_command', '3': 6, '4': 1, '5': 9, '10': 'installCommand'},
  ],
};

/// Descriptor for `OllamaStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ollamaStatusDescriptor = $convert.base64Decode(
    'CgxPbGxhbWFTdGF0dXMSHAoJaW5zdGFsbGVkGAEgASgIUglpbnN0YWxsZWQSGAoHcnVubmluZx'
    'gCIAEoCFIHcnVubmluZxIZCghiYXNlX3VybBgDIAEoCVIHYmFzZVVybBIYCgd2ZXJzaW9uGAQg'
    'ASgJUgd2ZXJzaW9uEhgKB21lc3NhZ2UYBSABKAlSB21lc3NhZ2USJwoPaW5zdGFsbF9jb21tYW'
    '5kGAYgASgJUg5pbnN0YWxsQ29tbWFuZA==');

@$core.Deprecated('Use ollamaModelDescriptor instead')
const OllamaModel$json = {
  '1': 'OllamaModel',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'size_bytes', '3': 2, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'size_gb', '3': 3, '4': 1, '5': 1, '10': 'sizeGb'},
    {'1': 'modified_at', '3': 4, '4': 1, '5': 9, '10': 'modifiedAt'},
    {'1': 'is_embedding', '3': 5, '4': 1, '5': 8, '10': 'isEmbedding'},
    {'1': 'embedding_dim', '3': 6, '4': 1, '5': 5, '10': 'embeddingDim'},
    {'1': 'description', '3': 7, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `OllamaModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ollamaModelDescriptor = $convert.base64Decode(
    'CgtPbGxhbWFNb2RlbBISCgRuYW1lGAEgASgJUgRuYW1lEh0KCnNpemVfYnl0ZXMYAiABKANSCX'
    'NpemVCeXRlcxIXCgdzaXplX2diGAMgASgBUgZzaXplR2ISHwoLbW9kaWZpZWRfYXQYBCABKAlS'
    'Cm1vZGlmaWVkQXQSIQoMaXNfZW1iZWRkaW5nGAUgASgIUgtpc0VtYmVkZGluZxIjCg1lbWJlZG'
    'RpbmdfZGltGAYgASgFUgxlbWJlZGRpbmdEaW0SIAoLZGVzY3JpcHRpb24YByABKAlSC2Rlc2Ny'
    'aXB0aW9u');

@$core.Deprecated('Use ollamaListModelsResponseDescriptor instead')
const OllamaListModelsResponse$json = {
  '1': 'OllamaListModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.OllamaModel',
      '10': 'models'
    },
  ],
};

/// Descriptor for `OllamaListModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ollamaListModelsResponseDescriptor =
    $convert.base64Decode(
        'ChhPbGxhbWFMaXN0TW9kZWxzUmVzcG9uc2USMwoGbW9kZWxzGAEgAygLMhsuZmxlZXRrYW5iYW'
        '4udjEuT2xsYW1hTW9kZWxSBm1vZGVscw==');

@$core.Deprecated('Use ollamaRecommendedModelDescriptor instead')
const OllamaRecommendedModel$json = {
  '1': 'OllamaRecommendedModel',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'size_estimate', '3': 3, '4': 1, '5': 9, '10': 'sizeEstimate'},
    {'1': 'embedding_dim', '3': 4, '4': 1, '5': 5, '10': 'embeddingDim'},
    {'1': 'installed', '3': 5, '4': 1, '5': 8, '10': 'installed'},
    {'1': 'role', '3': 6, '4': 1, '5': 9, '10': 'role'},
  ],
};

/// Descriptor for `OllamaRecommendedModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ollamaRecommendedModelDescriptor = $convert.base64Decode(
    'ChZPbGxhbWFSZWNvbW1lbmRlZE1vZGVsEhIKBG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcH'
    'Rpb24YAiABKAlSC2Rlc2NyaXB0aW9uEiMKDXNpemVfZXN0aW1hdGUYAyABKAlSDHNpemVFc3Rp'
    'bWF0ZRIjCg1lbWJlZGRpbmdfZGltGAQgASgFUgxlbWJlZGRpbmdEaW0SHAoJaW5zdGFsbGVkGA'
    'UgASgIUglpbnN0YWxsZWQSEgoEcm9sZRgGIAEoCVIEcm9sZQ==');

@$core.Deprecated('Use ollamaListRecommendedResponseDescriptor instead')
const OllamaListRecommendedResponse$json = {
  '1': 'OllamaListRecommendedResponse',
  '2': [
    {
      '1': 'models',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.OllamaRecommendedModel',
      '10': 'models'
    },
  ],
};

/// Descriptor for `OllamaListRecommendedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ollamaListRecommendedResponseDescriptor =
    $convert.base64Decode(
        'Ch1PbGxhbWFMaXN0UmVjb21tZW5kZWRSZXNwb25zZRI+CgZtb2RlbHMYASADKAsyJi5mbGVldG'
        'thbmJhbi52MS5PbGxhbWFSZWNvbW1lbmRlZE1vZGVsUgZtb2RlbHM=');

@$core.Deprecated('Use pullModelRequestDescriptor instead')
const PullModelRequest$json = {
  '1': 'PullModelRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `PullModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pullModelRequestDescriptor = $convert
    .base64Decode('ChBQdWxsTW9kZWxSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWU=');

@$core.Deprecated('Use ollamaPullProgressEventDescriptor instead')
const OllamaPullProgressEvent$json = {
  '1': 'OllamaPullProgressEvent',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {'1': 'downloaded', '3': 2, '4': 1, '5': 3, '10': 'downloaded'},
    {'1': 'total', '3': 3, '4': 1, '5': 3, '10': 'total'},
    {'1': 'digest', '3': 4, '4': 1, '5': 9, '10': 'digest'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
    {'1': 'done', '3': 6, '4': 1, '5': 8, '10': 'done'},
  ],
};

/// Descriptor for `OllamaPullProgressEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ollamaPullProgressEventDescriptor = $convert.base64Decode(
    'ChdPbGxhbWFQdWxsUHJvZ3Jlc3NFdmVudBIWCgZzdGF0dXMYASABKAlSBnN0YXR1cxIeCgpkb3'
    'dubG9hZGVkGAIgASgDUgpkb3dubG9hZGVkEhQKBXRvdGFsGAMgASgDUgV0b3RhbBIWCgZkaWdl'
    'c3QYBCABKAlSBmRpZ2VzdBIUCgVlcnJvchgFIAEoCVIFZXJyb3ISEgoEZG9uZRgGIAEoCFIEZG'
    '9uZQ==');

@$core.Deprecated('Use artifactDescriptor instead')
const Artifact$json = {
  '1': 'Artifact',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'task_id', '3': 2, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'subtask_id', '3': 3, '4': 1, '5': 9, '10': 'subtaskId'},
    {'1': 'stage', '3': 4, '4': 1, '5': 9, '10': 'stage'},
    {'1': 'path', '3': 5, '4': 1, '5': 9, '10': 'path'},
    {'1': 'kind', '3': 6, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'content_hash', '3': 7, '4': 1, '5': 9, '10': 'contentHash'},
    {'1': 'size_bytes', '3': 8, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'attrs_json', '3': 9, '4': 1, '5': 9, '10': 'attrsJson'},
    {
      '1': 'created_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `Artifact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactDescriptor = $convert.base64Decode(
    'CghBcnRpZmFjdBIOCgJpZBgBIAEoCVICaWQSFwoHdGFza19pZBgCIAEoCVIGdGFza0lkEh0KCn'
    'N1YnRhc2tfaWQYAyABKAlSCXN1YnRhc2tJZBIUCgVzdGFnZRgEIAEoCVIFc3RhZ2USEgoEcGF0'
    'aBgFIAEoCVIEcGF0aBISCgRraW5kGAYgASgJUgRraW5kEiEKDGNvbnRlbnRfaGFzaBgHIAEoCV'
    'ILY29udGVudEhhc2gSHQoKc2l6ZV9ieXRlcxgIIAEoA1IJc2l6ZUJ5dGVzEh0KCmF0dHJzX2pz'
    'b24YCSABKAlSCWF0dHJzSnNvbhI5CgpjcmVhdGVkX2F0GAogASgLMhouZ29vZ2xlLnByb3RvYn'
    'VmLlRpbWVzdGFtcFIJY3JlYXRlZEF0');

@$core.Deprecated('Use listArtifactsRequestDescriptor instead')
const ListArtifactsRequest$json = {
  '1': 'ListArtifactsRequest',
  '2': [
    {'1': 'task_id', '3': 1, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'stage', '3': 2, '4': 1, '5': 9, '10': 'stage'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'page_size', '3': 4, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 5, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `ListArtifactsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listArtifactsRequestDescriptor = $convert.base64Decode(
    'ChRMaXN0QXJ0aWZhY3RzUmVxdWVzdBIXCgd0YXNrX2lkGAEgASgJUgZ0YXNrSWQSFAoFc3RhZ2'
    'UYAiABKAlSBXN0YWdlEhQKBWxpbWl0GAMgASgFUgVsaW1pdBIbCglwYWdlX3NpemUYBCABKAVS'
    'CHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YBSABKAlSCXBhZ2VUb2tlbg==');

@$core.Deprecated('Use listArtifactsResponseDescriptor instead')
const ListArtifactsResponse$json = {
  '1': 'ListArtifactsResponse',
  '2': [
    {
      '1': 'artifacts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.Artifact',
      '10': 'artifacts'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListArtifactsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listArtifactsResponseDescriptor = $convert.base64Decode(
    'ChVMaXN0QXJ0aWZhY3RzUmVzcG9uc2USNgoJYXJ0aWZhY3RzGAEgAygLMhguZmxlZXRrYW5iYW'
    '4udjEuQXJ0aWZhY3RSCWFydGlmYWN0cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ'
    'YWdlVG9rZW4=');

@$core.Deprecated('Use getArtifactRequestDescriptor instead')
const GetArtifactRequest$json = {
  '1': 'GetArtifactRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetArtifactRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getArtifactRequestDescriptor =
    $convert.base64Decode('ChJHZXRBcnRpZmFjdFJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use getArtifactContentRequestDescriptor instead')
const GetArtifactContentRequest$json = {
  '1': 'GetArtifactContentRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetArtifactContentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getArtifactContentRequestDescriptor =
    $convert.base64Decode(
        'ChlHZXRBcnRpZmFjdENvbnRlbnRSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use artifactChunkDescriptor instead')
const ArtifactChunk$json = {
  '1': 'ArtifactChunk',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'eof', '3': 2, '4': 1, '5': 8, '10': 'eof'},
  ],
};

/// Descriptor for `ArtifactChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactChunkDescriptor = $convert.base64Decode(
    'Cg1BcnRpZmFjdENodW5rEhIKBGRhdGEYASABKAxSBGRhdGESEAoDZW9mGAIgASgIUgNlb2Y=');

@$core.Deprecated('Use harnessSkillDescriptor instead')
const HarnessSkill$json = {
  '1': 'HarnessSkill',
  '2': [
    {'1': 'artifact_id', '3': 1, '4': 1, '5': 9, '10': 'artifactId'},
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'content_md', '3': 3, '4': 1, '5': 9, '10': 'contentMd'},
    {
      '1': 'created_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {'1': 'content_hash', '3': 5, '4': 1, '5': 9, '10': 'contentHash'},
  ],
};

/// Descriptor for `HarnessSkill`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List harnessSkillDescriptor = $convert.base64Decode(
    'CgxIYXJuZXNzU2tpbGwSHwoLYXJ0aWZhY3RfaWQYASABKAlSCmFydGlmYWN0SWQSGAoHdmVyc2'
    'lvbhgCIAEoBVIHdmVyc2lvbhIdCgpjb250ZW50X21kGAMgASgJUgljb250ZW50TWQSOQoKY3Jl'
    'YXRlZF9hdBgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBIhCg'
    'xjb250ZW50X2hhc2gYBSABKAlSC2NvbnRlbnRIYXNo');

@$core.Deprecated('Use listSkillVersionsResponseDescriptor instead')
const ListSkillVersionsResponse$json = {
  '1': 'ListSkillVersionsResponse',
  '2': [
    {
      '1': 'versions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.HarnessSkill',
      '10': 'versions'
    },
  ],
};

/// Descriptor for `ListSkillVersionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSkillVersionsResponseDescriptor =
    $convert.base64Decode(
        'ChlMaXN0U2tpbGxWZXJzaW9uc1Jlc3BvbnNlEjgKCHZlcnNpb25zGAEgAygLMhwuZmxlZXRrYW'
        '5iYW4udjEuSGFybmVzc1NraWxsUgh2ZXJzaW9ucw==');

@$core.Deprecated('Use validateSkillRequestDescriptor instead')
const ValidateSkillRequest$json = {
  '1': 'ValidateSkillRequest',
  '2': [
    {'1': 'content_md', '3': 1, '4': 1, '5': 9, '10': 'contentMd'},
  ],
};

/// Descriptor for `ValidateSkillRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validateSkillRequestDescriptor = $convert.base64Decode(
    'ChRWYWxpZGF0ZVNraWxsUmVxdWVzdBIdCgpjb250ZW50X21kGAEgASgJUgljb250ZW50TWQ=');

@$core.Deprecated('Use validateSkillResponseDescriptor instead')
const ValidateSkillResponse$json = {
  '1': 'ValidateSkillResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'errors', '3': 2, '4': 3, '5': 9, '10': 'errors'},
    {'1': 'warnings', '3': 3, '4': 3, '5': 9, '10': 'warnings'},
  ],
};

/// Descriptor for `ValidateSkillResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validateSkillResponseDescriptor = $convert.base64Decode(
    'ChVWYWxpZGF0ZVNraWxsUmVzcG9uc2USDgoCb2sYASABKAhSAm9rEhYKBmVycm9ycxgCIAMoCV'
    'IGZXJyb3JzEhoKCHdhcm5pbmdzGAMgAygJUgh3YXJuaW5ncw==');

@$core.Deprecated('Use updateSkillRequestDescriptor instead')
const UpdateSkillRequest$json = {
  '1': 'UpdateSkillRequest',
  '2': [
    {'1': 'content_md', '3': 1, '4': 1, '5': 9, '10': 'contentMd'},
  ],
};

/// Descriptor for `UpdateSkillRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSkillRequestDescriptor =
    $convert.base64Decode(
        'ChJVcGRhdGVTa2lsbFJlcXVlc3QSHQoKY29udGVudF9tZBgBIAEoCVIJY29udGVudE1k');

@$core.Deprecated('Use rollbackSkillRequestDescriptor instead')
const RollbackSkillRequest$json = {
  '1': 'RollbackSkillRequest',
  '2': [
    {'1': 'artifact_id', '3': 1, '4': 1, '5': 9, '10': 'artifactId'},
  ],
};

/// Descriptor for `RollbackSkillRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rollbackSkillRequestDescriptor = $convert.base64Decode(
    'ChRSb2xsYmFja1NraWxsUmVxdWVzdBIfCgthcnRpZmFjdF9pZBgBIAEoCVIKYXJ0aWZhY3RJZA'
    '==');

@$core.Deprecated('Use harnessAttemptDescriptor instead')
const HarnessAttempt$json = {
  '1': 'HarnessAttempt',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'task_id', '3': 2, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'rework_round', '3': 3, '4': 1, '5': 5, '10': 'reworkRound'},
    {'1': 'failure_class', '3': 4, '4': 1, '5': 9, '10': 'failureClass'},
    {'1': 'observation_md', '3': 5, '4': 1, '5': 9, '10': 'observationMd'},
    {'1': 'proposed_patch', '3': 6, '4': 1, '5': 9, '10': 'proposedPatch'},
    {'1': 'proposed_hash', '3': 7, '4': 1, '5': 9, '10': 'proposedHash'},
    {'1': 'decision', '3': 8, '4': 1, '5': 9, '10': 'decision'},
    {'1': 'decided_by', '3': 9, '4': 1, '5': 9, '10': 'decidedBy'},
    {
      '1': 'decided_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'decidedAt'
    },
    {
      '1': 'created_at',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `HarnessAttempt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List harnessAttemptDescriptor = $convert.base64Decode(
    'Cg5IYXJuZXNzQXR0ZW1wdBIOCgJpZBgBIAEoCVICaWQSFwoHdGFza19pZBgCIAEoCVIGdGFza0'
    'lkEiEKDHJld29ya19yb3VuZBgDIAEoBVILcmV3b3JrUm91bmQSIwoNZmFpbHVyZV9jbGFzcxgE'
    'IAEoCVIMZmFpbHVyZUNsYXNzEiUKDm9ic2VydmF0aW9uX21kGAUgASgJUg1vYnNlcnZhdGlvbk'
    '1kEiUKDnByb3Bvc2VkX3BhdGNoGAYgASgJUg1wcm9wb3NlZFBhdGNoEiMKDXByb3Bvc2VkX2hh'
    'c2gYByABKAlSDHByb3Bvc2VkSGFzaBIaCghkZWNpc2lvbhgIIAEoCVIIZGVjaXNpb24SHQoKZG'
    'VjaWRlZF9ieRgJIAEoCVIJZGVjaWRlZEJ5EjkKCmRlY2lkZWRfYXQYCiABKAsyGi5nb29nbGUu'
    'cHJvdG9idWYuVGltZXN0YW1wUglkZWNpZGVkQXQSOQoKY3JlYXRlZF9hdBgLIAEoCzIaLmdvb2'
    'dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdA==');

@$core.Deprecated('Use listHarnessAttemptsResponseDescriptor instead')
const ListHarnessAttemptsResponse$json = {
  '1': 'ListHarnessAttemptsResponse',
  '2': [
    {
      '1': 'attempts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fleetkanban.v1.HarnessAttempt',
      '10': 'attempts'
    },
  ],
};

/// Descriptor for `ListHarnessAttemptsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listHarnessAttemptsResponseDescriptor =
    $convert.base64Decode(
        'ChtMaXN0SGFybmVzc0F0dGVtcHRzUmVzcG9uc2USOgoIYXR0ZW1wdHMYASADKAsyHi5mbGVldG'
        'thbmJhbi52MS5IYXJuZXNzQXR0ZW1wdFIIYXR0ZW1wdHM=');

@$core.Deprecated('Use listHarnessAttemptsForTaskRequestDescriptor instead')
const ListHarnessAttemptsForTaskRequest$json = {
  '1': 'ListHarnessAttemptsForTaskRequest',
  '2': [
    {'1': 'task_id', '3': 1, '4': 1, '5': 9, '10': 'taskId'},
  ],
};

/// Descriptor for `ListHarnessAttemptsForTaskRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listHarnessAttemptsForTaskRequestDescriptor =
    $convert.base64Decode(
        'CiFMaXN0SGFybmVzc0F0dGVtcHRzRm9yVGFza1JlcXVlc3QSFwoHdGFza19pZBgBIAEoCVIGdG'
        'Fza0lk');

@$core.Deprecated('Use approveHarnessAttemptRequestDescriptor instead')
const ApproveHarnessAttemptRequest$json = {
  '1': 'ApproveHarnessAttemptRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'decided_by', '3': 2, '4': 1, '5': 9, '10': 'decidedBy'},
  ],
};

/// Descriptor for `ApproveHarnessAttemptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List approveHarnessAttemptRequestDescriptor =
    $convert.base64Decode(
        'ChxBcHByb3ZlSGFybmVzc0F0dGVtcHRSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIdCgpkZWNpZG'
        'VkX2J5GAIgASgJUglkZWNpZGVkQnk=');

@$core.Deprecated('Use rejectHarnessAttemptRequestDescriptor instead')
const RejectHarnessAttemptRequest$json = {
  '1': 'RejectHarnessAttemptRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'decided_by', '3': 2, '4': 1, '5': 9, '10': 'decidedBy'},
  ],
};

/// Descriptor for `RejectHarnessAttemptRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rejectHarnessAttemptRequestDescriptor =
    $convert.base64Decode(
        'ChtSZWplY3RIYXJuZXNzQXR0ZW1wdFJlcXVlc3QSDgoCaWQYASABKAlSAmlkEh0KCmRlY2lkZW'
        'RfYnkYAiABKAlSCWRlY2lkZWRCeQ==');
