// This is a generated file - do not edit.
//
// Generated from fleetkanban/v1/fleetkanban.proto.

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
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $1;

import 'fleetkanban.pb.dart' as $0;

export 'fleetkanban.pb.dart';

@$pb.GrpcServiceName('fleetkanban.v1.TaskService')
class TaskServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TaskServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.Task> createTask(
    $0.CreateTaskRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createTask, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListTasksResponse> listTasks(
    $0.ListTasksRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listTasks, request, options: options);
  }

  $grpc.ResponseFuture<$0.Task> getTask(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getTask, request, options: options);
  }

  $grpc.ResponseFuture<$0.DiffResponse> getTaskDiff(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getTaskDiff, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> runTask(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$runTask, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> cancelTask(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelTask, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> finalizeTask(
    $0.FinalizeTaskRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$finalizeTask, request, options: options);
  }

  /// DeleteTask removes a task row and its associated worktree from disk.
  /// Intended for pruning terminal (done / cancelled / failed / aborted)
  /// or stuck tasks that the user wants off the Kanban entirely. The
  /// branch is preserved by default; pass delete_branch=true to also
  /// remove the fleetkanban/<id> branch.
  ///
  /// Running tasks (in_progress / ai_review) must be cancelled first —
  /// the sidecar rejects Delete calls for those states with
  /// FailedPrecondition so the UI can prompt for cancel.
  $grpc.ResponseFuture<$1.Empty> deleteTask(
    $0.DeleteTaskRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteTask, request, options: options);
  }

  /// DeleteTaskBranch force-removes the fleetkanban/<id> branch of a
  /// finalized task (Done or Aborted) while leaving the task row intact.
  /// Intended for the Housekeeping UI's Stale list "Discard" action; the
  /// UI is responsible for confirming the user understands unmerged work
  /// on the branch will be lost. Returns FailedPrecondition for tasks in
  /// any other status, and NotFound when the task itself is missing.
  $grpc.ResponseFuture<$1.Empty> deleteTaskBranch(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteTaskBranch, request, options: options);
  }

  /// SubmitReview records a reviewer decision for a task in ai_review or
  /// human_review. When action == APPROVE the task transitions toward done
  /// (human_review only — caller then calls FinalizeTask). When action ==
  /// REWORK the feedback is persisted and the task is transitioned back to
  /// queued; the orchestrator prepends feedback to the next Copilot prompt.
  /// When action == REJECT the task transitions to failed(ai_review).
  $grpc.ResponseFuture<$1.Empty> submitReview(
    $0.SubmitReviewRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$submitReview, request, options: options);
  }

  $grpc.ResponseFuture<$0.TaskEventsResponse> taskEvents(
    $0.TaskEventsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$taskEvents, request, options: options);
  }

  $grpc.ResponseStream<$0.AgentEvent> watchEvents(
    $0.WatchEventsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchEvents, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$createTask = $grpc.ClientMethod<$0.CreateTaskRequest, $0.Task>(
      '/fleetkanban.v1.TaskService/CreateTask',
      ($0.CreateTaskRequest value) => value.writeToBuffer(),
      $0.Task.fromBuffer);
  static final _$listTasks =
      $grpc.ClientMethod<$0.ListTasksRequest, $0.ListTasksResponse>(
          '/fleetkanban.v1.TaskService/ListTasks',
          ($0.ListTasksRequest value) => value.writeToBuffer(),
          $0.ListTasksResponse.fromBuffer);
  static final _$getTask = $grpc.ClientMethod<$0.IdRequest, $0.Task>(
      '/fleetkanban.v1.TaskService/GetTask',
      ($0.IdRequest value) => value.writeToBuffer(),
      $0.Task.fromBuffer);
  static final _$getTaskDiff =
      $grpc.ClientMethod<$0.IdRequest, $0.DiffResponse>(
          '/fleetkanban.v1.TaskService/GetTaskDiff',
          ($0.IdRequest value) => value.writeToBuffer(),
          $0.DiffResponse.fromBuffer);
  static final _$runTask = $grpc.ClientMethod<$0.IdRequest, $1.Empty>(
      '/fleetkanban.v1.TaskService/RunTask',
      ($0.IdRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$cancelTask = $grpc.ClientMethod<$0.IdRequest, $1.Empty>(
      '/fleetkanban.v1.TaskService/CancelTask',
      ($0.IdRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$finalizeTask =
      $grpc.ClientMethod<$0.FinalizeTaskRequest, $1.Empty>(
          '/fleetkanban.v1.TaskService/FinalizeTask',
          ($0.FinalizeTaskRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$deleteTask =
      $grpc.ClientMethod<$0.DeleteTaskRequest, $1.Empty>(
          '/fleetkanban.v1.TaskService/DeleteTask',
          ($0.DeleteTaskRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$deleteTaskBranch = $grpc.ClientMethod<$0.IdRequest, $1.Empty>(
      '/fleetkanban.v1.TaskService/DeleteTaskBranch',
      ($0.IdRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$submitReview =
      $grpc.ClientMethod<$0.SubmitReviewRequest, $1.Empty>(
          '/fleetkanban.v1.TaskService/SubmitReview',
          ($0.SubmitReviewRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$taskEvents =
      $grpc.ClientMethod<$0.TaskEventsRequest, $0.TaskEventsResponse>(
          '/fleetkanban.v1.TaskService/TaskEvents',
          ($0.TaskEventsRequest value) => value.writeToBuffer(),
          $0.TaskEventsResponse.fromBuffer);
  static final _$watchEvents =
      $grpc.ClientMethod<$0.WatchEventsRequest, $0.AgentEvent>(
          '/fleetkanban.v1.TaskService/WatchEvents',
          ($0.WatchEventsRequest value) => value.writeToBuffer(),
          $0.AgentEvent.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.TaskService')
abstract class TaskServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.TaskService';

  TaskServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CreateTaskRequest, $0.Task>(
        'CreateTask',
        createTask_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreateTaskRequest.fromBuffer(value),
        ($0.Task value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListTasksRequest, $0.ListTasksResponse>(
        'ListTasks',
        listTasks_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListTasksRequest.fromBuffer(value),
        ($0.ListTasksResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $0.Task>(
        'GetTask',
        getTask_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($0.Task value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $0.DiffResponse>(
        'GetTaskDiff',
        getTaskDiff_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($0.DiffResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $1.Empty>(
        'RunTask',
        runTask_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $1.Empty>(
        'CancelTask',
        cancelTask_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FinalizeTaskRequest, $1.Empty>(
        'FinalizeTask',
        finalizeTask_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.FinalizeTaskRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteTaskRequest, $1.Empty>(
        'DeleteTask',
        deleteTask_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteTaskRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $1.Empty>(
        'DeleteTaskBranch',
        deleteTaskBranch_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SubmitReviewRequest, $1.Empty>(
        'SubmitReview',
        submitReview_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SubmitReviewRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TaskEventsRequest, $0.TaskEventsResponse>(
        'TaskEvents',
        taskEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.TaskEventsRequest.fromBuffer(value),
        ($0.TaskEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchEventsRequest, $0.AgentEvent>(
        'WatchEvents',
        watchEvents_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.WatchEventsRequest.fromBuffer(value),
        ($0.AgentEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.Task> createTask_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateTaskRequest> $request) async {
    return createTask($call, await $request);
  }

  $async.Future<$0.Task> createTask(
      $grpc.ServiceCall call, $0.CreateTaskRequest request);

  $async.Future<$0.ListTasksResponse> listTasks_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListTasksRequest> $request) async {
    return listTasks($call, await $request);
  }

  $async.Future<$0.ListTasksResponse> listTasks(
      $grpc.ServiceCall call, $0.ListTasksRequest request);

  $async.Future<$0.Task> getTask_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return getTask($call, await $request);
  }

  $async.Future<$0.Task> getTask($grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$0.DiffResponse> getTaskDiff_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return getTaskDiff($call, await $request);
  }

  $async.Future<$0.DiffResponse> getTaskDiff(
      $grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$1.Empty> runTask_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return runTask($call, await $request);
  }

  $async.Future<$1.Empty> runTask($grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$1.Empty> cancelTask_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return cancelTask($call, await $request);
  }

  $async.Future<$1.Empty> cancelTask(
      $grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$1.Empty> finalizeTask_Pre($grpc.ServiceCall $call,
      $async.Future<$0.FinalizeTaskRequest> $request) async {
    return finalizeTask($call, await $request);
  }

  $async.Future<$1.Empty> finalizeTask(
      $grpc.ServiceCall call, $0.FinalizeTaskRequest request);

  $async.Future<$1.Empty> deleteTask_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteTaskRequest> $request) async {
    return deleteTask($call, await $request);
  }

  $async.Future<$1.Empty> deleteTask(
      $grpc.ServiceCall call, $0.DeleteTaskRequest request);

  $async.Future<$1.Empty> deleteTaskBranch_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return deleteTaskBranch($call, await $request);
  }

  $async.Future<$1.Empty> deleteTaskBranch(
      $grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$1.Empty> submitReview_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SubmitReviewRequest> $request) async {
    return submitReview($call, await $request);
  }

  $async.Future<$1.Empty> submitReview(
      $grpc.ServiceCall call, $0.SubmitReviewRequest request);

  $async.Future<$0.TaskEventsResponse> taskEvents_Pre($grpc.ServiceCall $call,
      $async.Future<$0.TaskEventsRequest> $request) async {
    return taskEvents($call, await $request);
  }

  $async.Future<$0.TaskEventsResponse> taskEvents(
      $grpc.ServiceCall call, $0.TaskEventsRequest request);

  $async.Stream<$0.AgentEvent> watchEvents_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchEventsRequest> $request) async* {
    yield* watchEvents($call, await $request);
  }

  $async.Stream<$0.AgentEvent> watchEvents(
      $grpc.ServiceCall call, $0.WatchEventsRequest request);
}

/// SubtaskService manages the AI-authored subtask DAG for a parent task.
/// Subtasks are produced by the planner (one role per node, dependency
/// edges in depends_on) and executed one Copilot session per node.
@$pb.GrpcServiceName('fleetkanban.v1.SubtaskService')
class SubtaskServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SubtaskServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListSubtasksResponse> listSubtasks(
    $0.ListSubtasksRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSubtasks, request, options: options);
  }

  $grpc.ResponseFuture<$0.Subtask> createSubtask(
    $0.CreateSubtaskRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createSubtask, request, options: options);
  }

  $grpc.ResponseFuture<$0.Subtask> updateSubtask(
    $0.UpdateSubtaskRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateSubtask, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> deleteSubtask(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSubtask, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> reorderSubtasks(
    $0.ReorderSubtasksRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reorderSubtasks, request, options: options);
  }

  // method descriptors

  static final _$listSubtasks =
      $grpc.ClientMethod<$0.ListSubtasksRequest, $0.ListSubtasksResponse>(
          '/fleetkanban.v1.SubtaskService/ListSubtasks',
          ($0.ListSubtasksRequest value) => value.writeToBuffer(),
          $0.ListSubtasksResponse.fromBuffer);
  static final _$createSubtask =
      $grpc.ClientMethod<$0.CreateSubtaskRequest, $0.Subtask>(
          '/fleetkanban.v1.SubtaskService/CreateSubtask',
          ($0.CreateSubtaskRequest value) => value.writeToBuffer(),
          $0.Subtask.fromBuffer);
  static final _$updateSubtask =
      $grpc.ClientMethod<$0.UpdateSubtaskRequest, $0.Subtask>(
          '/fleetkanban.v1.SubtaskService/UpdateSubtask',
          ($0.UpdateSubtaskRequest value) => value.writeToBuffer(),
          $0.Subtask.fromBuffer);
  static final _$deleteSubtask = $grpc.ClientMethod<$0.IdRequest, $1.Empty>(
      '/fleetkanban.v1.SubtaskService/DeleteSubtask',
      ($0.IdRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$reorderSubtasks =
      $grpc.ClientMethod<$0.ReorderSubtasksRequest, $1.Empty>(
          '/fleetkanban.v1.SubtaskService/ReorderSubtasks',
          ($0.ReorderSubtasksRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.SubtaskService')
abstract class SubtaskServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.SubtaskService';

  SubtaskServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListSubtasksRequest, $0.ListSubtasksResponse>(
            'ListSubtasks',
            listSubtasks_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListSubtasksRequest.fromBuffer(value),
            ($0.ListSubtasksResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateSubtaskRequest, $0.Subtask>(
        'CreateSubtask',
        createSubtask_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateSubtaskRequest.fromBuffer(value),
        ($0.Subtask value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateSubtaskRequest, $0.Subtask>(
        'UpdateSubtask',
        updateSubtask_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateSubtaskRequest.fromBuffer(value),
        ($0.Subtask value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $1.Empty>(
        'DeleteSubtask',
        deleteSubtask_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReorderSubtasksRequest, $1.Empty>(
        'ReorderSubtasks',
        reorderSubtasks_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReorderSubtasksRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListSubtasksResponse> listSubtasks_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListSubtasksRequest> $request) async {
    return listSubtasks($call, await $request);
  }

  $async.Future<$0.ListSubtasksResponse> listSubtasks(
      $grpc.ServiceCall call, $0.ListSubtasksRequest request);

  $async.Future<$0.Subtask> createSubtask_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateSubtaskRequest> $request) async {
    return createSubtask($call, await $request);
  }

  $async.Future<$0.Subtask> createSubtask(
      $grpc.ServiceCall call, $0.CreateSubtaskRequest request);

  $async.Future<$0.Subtask> updateSubtask_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateSubtaskRequest> $request) async {
    return updateSubtask($call, await $request);
  }

  $async.Future<$0.Subtask> updateSubtask(
      $grpc.ServiceCall call, $0.UpdateSubtaskRequest request);

  $async.Future<$1.Empty> deleteSubtask_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return deleteSubtask($call, await $request);
  }

  $async.Future<$1.Empty> deleteSubtask(
      $grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$1.Empty> reorderSubtasks_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReorderSubtasksRequest> $request) async {
    return reorderSubtasks($call, await $request);
  }

  $async.Future<$1.Empty> reorderSubtasks(
      $grpc.ServiceCall call, $0.ReorderSubtasksRequest request);
}

@$pb.GrpcServiceName('fleetkanban.v1.RepositoryService')
class RepositoryServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  RepositoryServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.Repository> registerRepository(
    $0.RegisterRepositoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$registerRepository, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListRepositoriesResponse> listRepositories(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listRepositories, request, options: options);
  }

  $grpc.ResponseFuture<$0.GitConfigStatus> checkGitConfig(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkGitConfig, request, options: options);
  }

  /// ScanGitRepositories walks `path` up to `max_depth` levels deep looking
  /// for `.git` entries. Useful when the user picks a folder that itself
  /// is not a repository but contains several (e.g. `C:\src\` with
  /// `C:\src\app\.git` + `C:\src\lib\.git`). The response is filtered to
  /// paths that are NOT yet registered so the UI can offer one-tap
  /// multi-registration.
  $grpc.ResponseFuture<$0.ScanGitRepositoriesResponse> scanGitRepositories(
    $0.ScanGitRepositoriesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$scanGitRepositories, request, options: options);
  }

  /// UpdateDefaultBaseBranch pins (or unpins) a repository's default base
  /// branch. Empty default_base_branch clears the pin and returns the
  /// repository to auto-detection mode (origin/HEAD → main → master → HEAD).
  /// Non-empty values are validated against refs/heads/ before persisting —
  /// callers can rely on "success means the branch exists right now".
  $grpc.ResponseFuture<$0.Repository> updateDefaultBaseBranch(
    $0.UpdateDefaultBaseBranchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateDefaultBaseBranch, request,
        options: options);
  }

  /// ListBranches returns every refs/heads/ entry in the repository, with
  /// FleetKanban's own `fleetkanban/<id>` task branches filtered out (they
  /// are internal churn, not meaningful base branches). `default_branch`
  /// is the result of the auto-detect resolver at call time — the UI
  /// shows it as the "(auto-detect: main)" option in the new-task dialog
  /// so the user sees what empty selection means.
  $grpc.ResponseFuture<$0.ListBranchesResponse> listBranches(
    $0.ListBranchesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listBranches, request, options: options);
  }

  /// CreateInitialCommit seeds a registered but empty repository (one that
  /// was only `git init`'d and has no commits) with a single empty root
  /// commit. Without this, task creation fails with "could not determine
  /// a base branch" because `git worktree add` needs a committish to fork
  /// from. The commit is authored as FleetKanban so it succeeds even when
  /// the user has not set global user.name/user.email. Returns
  /// FailedPrecondition when the repository already has commits — callers
  /// should refresh their cached `has_commits` flag and hide the button.
  $grpc.ResponseFuture<$0.Repository> createInitialCommit(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createInitialCommit, request, options: options);
  }

  // method descriptors

  static final _$registerRepository =
      $grpc.ClientMethod<$0.RegisterRepositoryRequest, $0.Repository>(
          '/fleetkanban.v1.RepositoryService/RegisterRepository',
          ($0.RegisterRepositoryRequest value) => value.writeToBuffer(),
          $0.Repository.fromBuffer);
  static final _$listRepositories =
      $grpc.ClientMethod<$1.Empty, $0.ListRepositoriesResponse>(
          '/fleetkanban.v1.RepositoryService/ListRepositories',
          ($1.Empty value) => value.writeToBuffer(),
          $0.ListRepositoriesResponse.fromBuffer);
  static final _$checkGitConfig =
      $grpc.ClientMethod<$1.Empty, $0.GitConfigStatus>(
          '/fleetkanban.v1.RepositoryService/CheckGitConfig',
          ($1.Empty value) => value.writeToBuffer(),
          $0.GitConfigStatus.fromBuffer);
  static final _$scanGitRepositories = $grpc.ClientMethod<
          $0.ScanGitRepositoriesRequest, $0.ScanGitRepositoriesResponse>(
      '/fleetkanban.v1.RepositoryService/ScanGitRepositories',
      ($0.ScanGitRepositoriesRequest value) => value.writeToBuffer(),
      $0.ScanGitRepositoriesResponse.fromBuffer);
  static final _$updateDefaultBaseBranch =
      $grpc.ClientMethod<$0.UpdateDefaultBaseBranchRequest, $0.Repository>(
          '/fleetkanban.v1.RepositoryService/UpdateDefaultBaseBranch',
          ($0.UpdateDefaultBaseBranchRequest value) => value.writeToBuffer(),
          $0.Repository.fromBuffer);
  static final _$listBranches =
      $grpc.ClientMethod<$0.ListBranchesRequest, $0.ListBranchesResponse>(
          '/fleetkanban.v1.RepositoryService/ListBranches',
          ($0.ListBranchesRequest value) => value.writeToBuffer(),
          $0.ListBranchesResponse.fromBuffer);
  static final _$createInitialCommit =
      $grpc.ClientMethod<$0.IdRequest, $0.Repository>(
          '/fleetkanban.v1.RepositoryService/CreateInitialCommit',
          ($0.IdRequest value) => value.writeToBuffer(),
          $0.Repository.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.RepositoryService')
abstract class RepositoryServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.RepositoryService';

  RepositoryServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.RegisterRepositoryRequest, $0.Repository>(
        'RegisterRepository',
        registerRepository_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RegisterRepositoryRequest.fromBuffer(value),
        ($0.Repository value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.ListRepositoriesResponse>(
        'ListRepositories',
        listRepositories_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.ListRepositoriesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.GitConfigStatus>(
        'CheckGitConfig',
        checkGitConfig_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.GitConfigStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ScanGitRepositoriesRequest,
            $0.ScanGitRepositoriesResponse>(
        'ScanGitRepositories',
        scanGitRepositories_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ScanGitRepositoriesRequest.fromBuffer(value),
        ($0.ScanGitRepositoriesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateDefaultBaseBranchRequest, $0.Repository>(
            'UpdateDefaultBaseBranch',
            updateDefaultBaseBranch_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateDefaultBaseBranchRequest.fromBuffer(value),
            ($0.Repository value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListBranchesRequest, $0.ListBranchesResponse>(
            'ListBranches',
            listBranches_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListBranchesRequest.fromBuffer(value),
            ($0.ListBranchesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $0.Repository>(
        'CreateInitialCommit',
        createInitialCommit_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($0.Repository value) => value.writeToBuffer()));
  }

  $async.Future<$0.Repository> registerRepository_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RegisterRepositoryRequest> $request) async {
    return registerRepository($call, await $request);
  }

  $async.Future<$0.Repository> registerRepository(
      $grpc.ServiceCall call, $0.RegisterRepositoryRequest request);

  $async.Future<$0.ListRepositoriesResponse> listRepositories_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return listRepositories($call, await $request);
  }

  $async.Future<$0.ListRepositoriesResponse> listRepositories(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.GitConfigStatus> checkGitConfig_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return checkGitConfig($call, await $request);
  }

  $async.Future<$0.GitConfigStatus> checkGitConfig(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.ScanGitRepositoriesResponse> scanGitRepositories_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ScanGitRepositoriesRequest> $request) async {
    return scanGitRepositories($call, await $request);
  }

  $async.Future<$0.ScanGitRepositoriesResponse> scanGitRepositories(
      $grpc.ServiceCall call, $0.ScanGitRepositoriesRequest request);

  $async.Future<$0.Repository> updateDefaultBaseBranch_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateDefaultBaseBranchRequest> $request) async {
    return updateDefaultBaseBranch($call, await $request);
  }

  $async.Future<$0.Repository> updateDefaultBaseBranch(
      $grpc.ServiceCall call, $0.UpdateDefaultBaseBranchRequest request);

  $async.Future<$0.ListBranchesResponse> listBranches_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListBranchesRequest> $request) async {
    return listBranches($call, await $request);
  }

  $async.Future<$0.ListBranchesResponse> listBranches(
      $grpc.ServiceCall call, $0.ListBranchesRequest request);

  $async.Future<$0.Repository> createInitialCommit_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return createInitialCommit($call, await $request);
  }

  $async.Future<$0.Repository> createInitialCommit(
      $grpc.ServiceCall call, $0.IdRequest request);
}

@$pb.GrpcServiceName('fleetkanban.v1.ModelService')
class ModelServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ModelServiceClient(super.channel, {super.options, super.interceptors});

  /// ListModels returns the model IDs the embedded Copilot CLI reports as
  /// available for the currently authenticated user. The UI uses this to
  /// populate the Settings model pickers — hard-coded lists go stale as
  /// GitHub rotates models, producing "model X is not available" errors
  /// at task-run time.
  $grpc.ResponseFuture<$0.ListModelsResponse> listModels(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listModels, request, options: options);
  }

  // method descriptors

  static final _$listModels =
      $grpc.ClientMethod<$1.Empty, $0.ListModelsResponse>(
          '/fleetkanban.v1.ModelService/ListModels',
          ($1.Empty value) => value.writeToBuffer(),
          $0.ListModelsResponse.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.ModelService')
abstract class ModelServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.ModelService';

  ModelServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.ListModelsResponse>(
        'ListModels',
        listModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.ListModelsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListModelsResponse> listModels_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return listModels($call, await $request);
  }

  $async.Future<$0.ListModelsResponse> listModels(
      $grpc.ServiceCall call, $1.Empty request);
}

@$pb.GrpcServiceName('fleetkanban.v1.AuthService')
class AuthServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AuthServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.AuthStatus> checkCopilotAuth(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkCopilotAuth, request, options: options);
  }

  /// BeginCopilotLogin launches a headless `copilot login` subprocess on the
  /// sidecar, parses the device code from its stdout, opens the GitHub
  /// verification URL (with user_code pre-filled) in the default browser, and
  /// returns the challenge so the UI can display it. The UI polls
  /// CheckCopilotAuth to detect completion; the sidecar auto-reloads the SDK
  /// client when the login subprocess exits successfully. This replaces the
  /// previous StartCopilotLogin terminal-spawn flow — Device Flow is
  /// inherently a browser-based step, so terminal input is never required.
  $grpc.ResponseFuture<$0.CopilotLoginChallenge> beginCopilotLogin(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$beginCopilotLogin, request, options: options);
  }

  /// CancelCopilotLogin terminates the login subprocess started by
  /// BeginCopilotLogin, if one is running. No-op otherwise. The UI calls
  /// this when the user dismisses the sign-in dialog without completing.
  $grpc.ResponseFuture<$1.Empty> cancelCopilotLogin(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelCopilotLogin, request, options: options);
  }

  /// GetCopilotLoginSession reports the lifecycle state of the login
  /// subprocess owned by BeginCopilotLogin. The sign-in dialog polls this
  /// instead of CheckCopilotAuth so that stale "already authenticated" state
  /// from the previous SDK client (common on account-switch flows, where
  /// ReloadAuth only runs after the new login succeeds) cannot close the
  /// dialog prematurely. SUCCEEDED is set only once the subprocess exits
  /// cleanly AND the SDK client has been reloaded with the fresh
  /// credentials, so callers can trust it as the "login complete" signal.
  $grpc.ResponseFuture<$0.CopilotLoginSessionInfo> getCopilotLoginSession(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCopilotLoginSession, request,
        options: options);
  }

  /// StartCopilotLogout opens an interactive terminal with the embedded
  /// Copilot CLI. The user is expected to type "/logout" (the CLI does not
  /// expose a headless logout subcommand). Device Flow login afterwards
  /// should be initiated via BeginCopilotLogin, not this terminal.
  $grpc.ResponseFuture<$1.Empty> startCopilotLogout(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startCopilotLogout, request, options: options);
  }

  /// ReloadCopilotAuth forces the embedded Copilot CLI server to restart so
  /// it re-reads the on-disk OAuth token store. The onboarding UI calls
  /// this after the user completes /login in the spawned terminal, because
  /// auth.getStatus against a long-running CLI server may otherwise keep
  /// reporting the stale pre-login state. Returns the fresh AuthStatus so
  /// the caller can transition off the onboarding screen in one round-trip.
  $grpc.ResponseFuture<$0.AuthStatus> reloadCopilotAuth(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reloadCopilotAuth, request, options: options);
  }

  /// Backward-compatible shortcuts for the "default" (active) PAT. New code
  /// should prefer the label-aware APIs below.
  $grpc.ResponseFuture<$0.BoolValue> hasGitHubToken(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$hasGitHubToken, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> setGitHubToken(
    $0.SetGitHubTokenRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setGitHubToken, request, options: options);
  }

  /// Label-aware PAT management. Multiple PATs can be stored, each under a
  /// user-chosen label; one is marked active and fed into the Copilot SDK
  /// ClientOptions.GitHubToken. Switching the active token hot-reloads the
  /// SDK client so the change takes effect without a sidecar restart.
  /// (Approach B)
  $grpc.ResponseFuture<$0.ListGitHubTokensResponse> listGitHubTokens(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listGitHubTokens, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> addGitHubToken(
    $0.AddGitHubTokenRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addGitHubToken, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> removeGitHubToken(
    $0.GitHubTokenLabelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeGitHubToken, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> setActiveGitHubToken(
    $0.GitHubTokenLabelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setActiveGitHubToken, request, options: options);
  }

  /// GetGitHubAccountInfo fetches `/user` from the GitHub REST API with the
  /// active PAT and surfaces plan + profile metadata. Returns INVALID_ARGUMENT
  /// when no PAT is configured. Premium-request quotas are not exposed by the
  /// GitHub public API, so the response intentionally omits them.
  $grpc.ResponseFuture<$0.GitHubAccountInfo> getGitHubAccountInfo(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getGitHubAccountInfo, request, options: options);
  }

  // method descriptors

  static final _$checkCopilotAuth = $grpc.ClientMethod<$1.Empty, $0.AuthStatus>(
      '/fleetkanban.v1.AuthService/CheckCopilotAuth',
      ($1.Empty value) => value.writeToBuffer(),
      $0.AuthStatus.fromBuffer);
  static final _$beginCopilotLogin =
      $grpc.ClientMethod<$1.Empty, $0.CopilotLoginChallenge>(
          '/fleetkanban.v1.AuthService/BeginCopilotLogin',
          ($1.Empty value) => value.writeToBuffer(),
          $0.CopilotLoginChallenge.fromBuffer);
  static final _$cancelCopilotLogin = $grpc.ClientMethod<$1.Empty, $1.Empty>(
      '/fleetkanban.v1.AuthService/CancelCopilotLogin',
      ($1.Empty value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$getCopilotLoginSession =
      $grpc.ClientMethod<$1.Empty, $0.CopilotLoginSessionInfo>(
          '/fleetkanban.v1.AuthService/GetCopilotLoginSession',
          ($1.Empty value) => value.writeToBuffer(),
          $0.CopilotLoginSessionInfo.fromBuffer);
  static final _$startCopilotLogout = $grpc.ClientMethod<$1.Empty, $1.Empty>(
      '/fleetkanban.v1.AuthService/StartCopilotLogout',
      ($1.Empty value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$reloadCopilotAuth =
      $grpc.ClientMethod<$1.Empty, $0.AuthStatus>(
          '/fleetkanban.v1.AuthService/ReloadCopilotAuth',
          ($1.Empty value) => value.writeToBuffer(),
          $0.AuthStatus.fromBuffer);
  static final _$hasGitHubToken = $grpc.ClientMethod<$1.Empty, $0.BoolValue>(
      '/fleetkanban.v1.AuthService/HasGitHubToken',
      ($1.Empty value) => value.writeToBuffer(),
      $0.BoolValue.fromBuffer);
  static final _$setGitHubToken =
      $grpc.ClientMethod<$0.SetGitHubTokenRequest, $1.Empty>(
          '/fleetkanban.v1.AuthService/SetGitHubToken',
          ($0.SetGitHubTokenRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$listGitHubTokens =
      $grpc.ClientMethod<$1.Empty, $0.ListGitHubTokensResponse>(
          '/fleetkanban.v1.AuthService/ListGitHubTokens',
          ($1.Empty value) => value.writeToBuffer(),
          $0.ListGitHubTokensResponse.fromBuffer);
  static final _$addGitHubToken =
      $grpc.ClientMethod<$0.AddGitHubTokenRequest, $1.Empty>(
          '/fleetkanban.v1.AuthService/AddGitHubToken',
          ($0.AddGitHubTokenRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$removeGitHubToken =
      $grpc.ClientMethod<$0.GitHubTokenLabelRequest, $1.Empty>(
          '/fleetkanban.v1.AuthService/RemoveGitHubToken',
          ($0.GitHubTokenLabelRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$setActiveGitHubToken =
      $grpc.ClientMethod<$0.GitHubTokenLabelRequest, $1.Empty>(
          '/fleetkanban.v1.AuthService/SetActiveGitHubToken',
          ($0.GitHubTokenLabelRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$getGitHubAccountInfo =
      $grpc.ClientMethod<$1.Empty, $0.GitHubAccountInfo>(
          '/fleetkanban.v1.AuthService/GetGitHubAccountInfo',
          ($1.Empty value) => value.writeToBuffer(),
          $0.GitHubAccountInfo.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.AuthService')
abstract class AuthServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.AuthService';

  AuthServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.AuthStatus>(
        'CheckCopilotAuth',
        checkCopilotAuth_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.AuthStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.CopilotLoginChallenge>(
        'BeginCopilotLogin',
        beginCopilotLogin_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.CopilotLoginChallenge value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $1.Empty>(
        'CancelCopilotLogin',
        cancelCopilotLogin_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.CopilotLoginSessionInfo>(
        'GetCopilotLoginSession',
        getCopilotLoginSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.CopilotLoginSessionInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $1.Empty>(
        'StartCopilotLogout',
        startCopilotLogout_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.AuthStatus>(
        'ReloadCopilotAuth',
        reloadCopilotAuth_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.AuthStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.BoolValue>(
        'HasGitHubToken',
        hasGitHubToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.BoolValue value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetGitHubTokenRequest, $1.Empty>(
        'SetGitHubToken',
        setGitHubToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetGitHubTokenRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.ListGitHubTokensResponse>(
        'ListGitHubTokens',
        listGitHubTokens_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.ListGitHubTokensResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddGitHubTokenRequest, $1.Empty>(
        'AddGitHubToken',
        addGitHubToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AddGitHubTokenRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GitHubTokenLabelRequest, $1.Empty>(
        'RemoveGitHubToken',
        removeGitHubToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GitHubTokenLabelRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GitHubTokenLabelRequest, $1.Empty>(
        'SetActiveGitHubToken',
        setActiveGitHubToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GitHubTokenLabelRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.GitHubAccountInfo>(
        'GetGitHubAccountInfo',
        getGitHubAccountInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.GitHubAccountInfo value) => value.writeToBuffer()));
  }

  $async.Future<$0.AuthStatus> checkCopilotAuth_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return checkCopilotAuth($call, await $request);
  }

  $async.Future<$0.AuthStatus> checkCopilotAuth(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.CopilotLoginChallenge> beginCopilotLogin_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return beginCopilotLogin($call, await $request);
  }

  $async.Future<$0.CopilotLoginChallenge> beginCopilotLogin(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$1.Empty> cancelCopilotLogin_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return cancelCopilotLogin($call, await $request);
  }

  $async.Future<$1.Empty> cancelCopilotLogin(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.CopilotLoginSessionInfo> getCopilotLoginSession_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getCopilotLoginSession($call, await $request);
  }

  $async.Future<$0.CopilotLoginSessionInfo> getCopilotLoginSession(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$1.Empty> startCopilotLogout_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return startCopilotLogout($call, await $request);
  }

  $async.Future<$1.Empty> startCopilotLogout(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.AuthStatus> reloadCopilotAuth_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return reloadCopilotAuth($call, await $request);
  }

  $async.Future<$0.AuthStatus> reloadCopilotAuth(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.BoolValue> hasGitHubToken_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return hasGitHubToken($call, await $request);
  }

  $async.Future<$0.BoolValue> hasGitHubToken(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$1.Empty> setGitHubToken_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetGitHubTokenRequest> $request) async {
    return setGitHubToken($call, await $request);
  }

  $async.Future<$1.Empty> setGitHubToken(
      $grpc.ServiceCall call, $0.SetGitHubTokenRequest request);

  $async.Future<$0.ListGitHubTokensResponse> listGitHubTokens_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return listGitHubTokens($call, await $request);
  }

  $async.Future<$0.ListGitHubTokensResponse> listGitHubTokens(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$1.Empty> addGitHubToken_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AddGitHubTokenRequest> $request) async {
    return addGitHubToken($call, await $request);
  }

  $async.Future<$1.Empty> addGitHubToken(
      $grpc.ServiceCall call, $0.AddGitHubTokenRequest request);

  $async.Future<$1.Empty> removeGitHubToken_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GitHubTokenLabelRequest> $request) async {
    return removeGitHubToken($call, await $request);
  }

  $async.Future<$1.Empty> removeGitHubToken(
      $grpc.ServiceCall call, $0.GitHubTokenLabelRequest request);

  $async.Future<$1.Empty> setActiveGitHubToken_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GitHubTokenLabelRequest> $request) async {
    return setActiveGitHubToken($call, await $request);
  }

  $async.Future<$1.Empty> setActiveGitHubToken(
      $grpc.ServiceCall call, $0.GitHubTokenLabelRequest request);

  $async.Future<$0.GitHubAccountInfo> getGitHubAccountInfo_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getGitHubAccountInfo($call, await $request);
  }

  $async.Future<$0.GitHubAccountInfo> getGitHubAccountInfo(
      $grpc.ServiceCall call, $1.Empty request);
}

@$pb.GrpcServiceName('fleetkanban.v1.SystemService')
class SystemServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SystemServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.IntValue> getConcurrency(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getConcurrency, request, options: options);
  }

  $grpc.ResponseFuture<$0.IntValue> setConcurrency(
    $0.IntValue request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setConcurrency, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> shutdown(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$shutdown, request, options: options);
  }

  /// GetVersion returns the sidecar's ProtocolVersion. The UI calls this
  /// immediately after connecting (including when reusing a handshake from
  /// a prior sidecar instance) and kills + respawns the process if the
  /// version doesn't match the client's compiled-in expectation. That
  /// replaces the silent "UNIMPLEMENTED: unknown service ..." failure
  /// mode after a rebuild where the old sidecar is still running.
  $grpc.ResponseFuture<$0.VersionInfo> getVersion(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getVersion, request, options: options);
  }

  /// GetPreconditions lists runtime dependencies the sidecar requires
  /// (today: PowerShell 7+). The UI calls this on first render and shows
  /// a modal if any dependency reports satisfied=false so the user can
  /// resolve the setup gap without dropping to a terminal.
  $grpc.ResponseFuture<$0.PreconditionsResponse> getPreconditions(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getPreconditions, request, options: options);
  }

  /// InstallPrecondition attempts the canonical auto-install for the
  /// named dependency (e.g. winget per-user install of PowerShell 7).
  /// Blocks for the duration of the install — 1–3 minutes typical — so
  /// the UI should reserve headroom in any client-side gRPC timeout.
  $grpc.ResponseFuture<$0.InstallPreconditionResponse> installPrecondition(
    $0.InstallPreconditionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$installPrecondition, request, options: options);
  }

  // method descriptors

  static final _$getConcurrency = $grpc.ClientMethod<$1.Empty, $0.IntValue>(
      '/fleetkanban.v1.SystemService/GetConcurrency',
      ($1.Empty value) => value.writeToBuffer(),
      $0.IntValue.fromBuffer);
  static final _$setConcurrency = $grpc.ClientMethod<$0.IntValue, $0.IntValue>(
      '/fleetkanban.v1.SystemService/SetConcurrency',
      ($0.IntValue value) => value.writeToBuffer(),
      $0.IntValue.fromBuffer);
  static final _$shutdown = $grpc.ClientMethod<$1.Empty, $1.Empty>(
      '/fleetkanban.v1.SystemService/Shutdown',
      ($1.Empty value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$getVersion = $grpc.ClientMethod<$1.Empty, $0.VersionInfo>(
      '/fleetkanban.v1.SystemService/GetVersion',
      ($1.Empty value) => value.writeToBuffer(),
      $0.VersionInfo.fromBuffer);
  static final _$getPreconditions =
      $grpc.ClientMethod<$1.Empty, $0.PreconditionsResponse>(
          '/fleetkanban.v1.SystemService/GetPreconditions',
          ($1.Empty value) => value.writeToBuffer(),
          $0.PreconditionsResponse.fromBuffer);
  static final _$installPrecondition = $grpc.ClientMethod<
          $0.InstallPreconditionRequest, $0.InstallPreconditionResponse>(
      '/fleetkanban.v1.SystemService/InstallPrecondition',
      ($0.InstallPreconditionRequest value) => value.writeToBuffer(),
      $0.InstallPreconditionResponse.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.SystemService')
abstract class SystemServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.SystemService';

  SystemServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.IntValue>(
        'GetConcurrency',
        getConcurrency_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.IntValue value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IntValue, $0.IntValue>(
        'SetConcurrency',
        setConcurrency_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IntValue.fromBuffer(value),
        ($0.IntValue value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $1.Empty>(
        'Shutdown',
        shutdown_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.VersionInfo>(
        'GetVersion',
        getVersion_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.VersionInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.PreconditionsResponse>(
        'GetPreconditions',
        getPreconditions_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.PreconditionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.InstallPreconditionRequest,
            $0.InstallPreconditionResponse>(
        'InstallPrecondition',
        installPrecondition_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.InstallPreconditionRequest.fromBuffer(value),
        ($0.InstallPreconditionResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.IntValue> getConcurrency_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getConcurrency($call, await $request);
  }

  $async.Future<$0.IntValue> getConcurrency(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.IntValue> setConcurrency_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IntValue> $request) async {
    return setConcurrency($call, await $request);
  }

  $async.Future<$0.IntValue> setConcurrency(
      $grpc.ServiceCall call, $0.IntValue request);

  $async.Future<$1.Empty> shutdown_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return shutdown($call, await $request);
  }

  $async.Future<$1.Empty> shutdown($grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.VersionInfo> getVersion_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getVersion($call, await $request);
  }

  $async.Future<$0.VersionInfo> getVersion(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.PreconditionsResponse> getPreconditions_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getPreconditions($call, await $request);
  }

  $async.Future<$0.PreconditionsResponse> getPreconditions(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.InstallPreconditionResponse> installPrecondition_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.InstallPreconditionRequest> $request) async {
    return installPrecondition($call, await $request);
  }

  $async.Future<$0.InstallPreconditionResponse> installPrecondition(
      $grpc.ServiceCall call, $0.InstallPreconditionRequest request);
}

/// WorktreeService exposes the contents of the per-repo `git worktree list`
/// output joined with the local tasks DB, so the Worktrees pane can show
/// every worktree FleetKanban knows about (including orphans whose task row
/// has been deleted, and worktrees whose on-disk directory was removed
/// outside the app).
@$pb.GrpcServiceName('fleetkanban.v1.WorktreeService')
class WorktreeServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  WorktreeServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListWorktreesResponse> listWorktrees(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listWorktrees, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> removeWorktree(
    $0.RemoveWorktreeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeWorktree, request, options: options);
  }

  // method descriptors

  static final _$listWorktrees =
      $grpc.ClientMethod<$1.Empty, $0.ListWorktreesResponse>(
          '/fleetkanban.v1.WorktreeService/ListWorktrees',
          ($1.Empty value) => value.writeToBuffer(),
          $0.ListWorktreesResponse.fromBuffer);
  static final _$removeWorktree =
      $grpc.ClientMethod<$0.RemoveWorktreeRequest, $1.Empty>(
          '/fleetkanban.v1.WorktreeService/RemoveWorktree',
          ($0.RemoveWorktreeRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.WorktreeService')
abstract class WorktreeServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.WorktreeService';

  WorktreeServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.ListWorktreesResponse>(
        'ListWorktrees',
        listWorktrees_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.ListWorktreesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RemoveWorktreeRequest, $1.Empty>(
        'RemoveWorktree',
        removeWorktree_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RemoveWorktreeRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListWorktreesResponse> listWorktrees_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return listWorktrees($call, await $request);
  }

  $async.Future<$0.ListWorktreesResponse> listWorktrees(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$1.Empty> removeWorktree_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RemoveWorktreeRequest> $request) async {
    return removeWorktree($call, await $request);
  }

  $async.Future<$1.Empty> removeWorktree(
      $grpc.ServiceCall call, $0.RemoveWorktreeRequest request);
}
