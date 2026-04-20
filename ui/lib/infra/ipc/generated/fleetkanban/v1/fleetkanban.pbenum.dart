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

import 'package:protobuf/protobuf.dart' as $pb;

/// FinalizeAction is the user's post-run choice for a finalized task.
///
/// KEEP removes the worktree directory but preserves `fleetkanban/<id>` so
/// the user can still inspect or manually merge the commits later.
///
/// MERGE attempts a fast-forward (or --no-ff merge commit when the base
/// branch has diverged) of `fleetkanban/<id>` into the task's recorded
/// `base_branch`, then removes both the worktree and the task branch.
/// Conflicts or a dirty base-branch working tree abort the operation
/// before any ref is touched.
///
/// DISCARD removes both the worktree and the task branch without merging.
class FinalizeAction extends $pb.ProtobufEnum {
  static const FinalizeAction FINALIZE_ACTION_UNSPECIFIED =
      FinalizeAction._(0, _omitEnumNames ? '' : 'FINALIZE_ACTION_UNSPECIFIED');
  static const FinalizeAction FINALIZE_ACTION_KEEP =
      FinalizeAction._(1, _omitEnumNames ? '' : 'FINALIZE_ACTION_KEEP');
  static const FinalizeAction FINALIZE_ACTION_MERGE =
      FinalizeAction._(2, _omitEnumNames ? '' : 'FINALIZE_ACTION_MERGE');
  static const FinalizeAction FINALIZE_ACTION_DISCARD =
      FinalizeAction._(3, _omitEnumNames ? '' : 'FINALIZE_ACTION_DISCARD');

  static const $core.List<FinalizeAction> values = <FinalizeAction>[
    FINALIZE_ACTION_UNSPECIFIED,
    FINALIZE_ACTION_KEEP,
    FINALIZE_ACTION_MERGE,
    FINALIZE_ACTION_DISCARD,
  ];

  static final $core.List<FinalizeAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static FinalizeAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FinalizeAction._(super.value, super.name);
}

/// ReviewAction is the reviewer's verdict on an ai_review or human_review task.
class ReviewAction extends $pb.ProtobufEnum {
  static const ReviewAction REVIEW_ACTION_UNSPECIFIED =
      ReviewAction._(0, _omitEnumNames ? '' : 'REVIEW_ACTION_UNSPECIFIED');

  /// APPROVE moves ai_review → human_review (AI approved) or is a no-op on
  /// human_review (the UI then calls FinalizeTask with KEEP/MERGE to finalize).
  /// Kept separate so future phases can gate FinalizeTask on AI approval.
  static const ReviewAction REVIEW_ACTION_APPROVE =
      ReviewAction._(1, _omitEnumNames ? '' : 'REVIEW_ACTION_APPROVE');

  /// REWORK saves feedback, transitions the task back to queued, and tells
  /// the orchestrator to prepend feedback to the next Copilot prompt.
  static const ReviewAction REVIEW_ACTION_REWORK =
      ReviewAction._(2, _omitEnumNames ? '' : 'REVIEW_ACTION_REWORK');

  /// REJECT terminates the task as failed(ai_review). Only valid from
  /// ai_review; human reviewers should prefer Discard from human_review.
  static const ReviewAction REVIEW_ACTION_REJECT =
      ReviewAction._(3, _omitEnumNames ? '' : 'REVIEW_ACTION_REJECT');

  static const $core.List<ReviewAction> values = <ReviewAction>[
    REVIEW_ACTION_UNSPECIFIED,
    REVIEW_ACTION_APPROVE,
    REVIEW_ACTION_REWORK,
    REVIEW_ACTION_REJECT,
  ];

  static final $core.List<ReviewAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ReviewAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ReviewAction._(super.value, super.name);
}

/// CopilotLoginSessionState is the lifecycle of a `copilot login` subprocess
/// owned by the sidecar's LoginCoordinator. Returned by GetCopilotLoginSession
/// so the UI can drive the sign-in dialog off the subprocess itself rather
/// than off CheckCopilotAuth (which reflects the SDK client's possibly-stale
/// view of auth and can report authenticated=true before the new login
/// completes).
class CopilotLoginSessionState extends $pb.ProtobufEnum {
  /// Default / pre-enum-migration fallback. Callers should treat as IDLE.
  static const CopilotLoginSessionState
      COPILOT_LOGIN_SESSION_STATE_UNSPECIFIED = CopilotLoginSessionState._(
          0, _omitEnumNames ? '' : 'COPILOT_LOGIN_SESSION_STATE_UNSPECIFIED');

  /// No login is in progress. Either BeginCopilotLogin was never called, or
  /// the UI called CancelCopilotLogin to tear the session down.
  static const CopilotLoginSessionState COPILOT_LOGIN_SESSION_STATE_IDLE =
      CopilotLoginSessionState._(
          1, _omitEnumNames ? '' : 'COPILOT_LOGIN_SESSION_STATE_IDLE');

  /// Subprocess is alive and waiting for the user to complete the device
  /// flow in the browser. The UI should keep the dialog open.
  static const CopilotLoginSessionState COPILOT_LOGIN_SESSION_STATE_RUNNING =
      CopilotLoginSessionState._(
          2, _omitEnumNames ? '' : 'COPILOT_LOGIN_SESSION_STATE_RUNNING');

  /// Subprocess exited with status 0 AND the SDK client has been reloaded
  /// against the new credentials. Safe to close the dialog.
  static const CopilotLoginSessionState COPILOT_LOGIN_SESSION_STATE_SUCCEEDED =
      CopilotLoginSessionState._(
          3, _omitEnumNames ? '' : 'COPILOT_LOGIN_SESSION_STATE_SUCCEEDED');

  /// Subprocess exited with a non-zero status, or ReloadAuth after a
  /// successful exit failed. error_message carries the formatted reason.
  static const CopilotLoginSessionState COPILOT_LOGIN_SESSION_STATE_FAILED =
      CopilotLoginSessionState._(
          4, _omitEnumNames ? '' : 'COPILOT_LOGIN_SESSION_STATE_FAILED');

  static const $core.List<CopilotLoginSessionState> values =
      <CopilotLoginSessionState>[
    COPILOT_LOGIN_SESSION_STATE_UNSPECIFIED,
    COPILOT_LOGIN_SESSION_STATE_IDLE,
    COPILOT_LOGIN_SESSION_STATE_RUNNING,
    COPILOT_LOGIN_SESSION_STATE_SUCCEEDED,
    COPILOT_LOGIN_SESSION_STATE_FAILED,
  ];

  static final $core.List<CopilotLoginSessionState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static CopilotLoginSessionState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CopilotLoginSessionState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
