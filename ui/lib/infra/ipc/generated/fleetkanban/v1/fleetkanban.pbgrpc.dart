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

  /// GetSubtaskContext returns the full prompt + injected context the
  /// Copilot agent saw for a given subtask execution — system prompt,
  /// user prompt, plan summary, prior-subtask summaries, memory block,
  /// and the harness SKILL.md that was active at run time. Round 0
  /// means "latest round recorded". Returns a CopilotSubtaskContext
  /// with not_recorded=true when the subtask predates the v18 schema
  /// or has not been executed yet — the UI shows a fallback notice.
  $grpc.ResponseFuture<$0.CopilotSubtaskContext> getSubtaskContext(
    $0.GetSubtaskContextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSubtaskContext, request, options: options);
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
  static final _$getSubtaskContext =
      $grpc.ClientMethod<$0.GetSubtaskContextRequest, $0.CopilotSubtaskContext>(
          '/fleetkanban.v1.SubtaskService/GetSubtaskContext',
          ($0.GetSubtaskContextRequest value) => value.writeToBuffer(),
          $0.CopilotSubtaskContext.fromBuffer);
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
    $addMethod($grpc.ServiceMethod<$0.GetSubtaskContextRequest,
            $0.CopilotSubtaskContext>(
        'GetSubtaskContext',
        getSubtaskContext_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetSubtaskContextRequest.fromBuffer(value),
        ($0.CopilotSubtaskContext value) => value.writeToBuffer()));
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

  $async.Future<$0.CopilotSubtaskContext> getSubtaskContext_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetSubtaskContextRequest> $request) async {
    return getSubtaskContext($call, await $request);
  }

  $async.Future<$0.CopilotSubtaskContext> getSubtaskContext(
      $grpc.ServiceCall call, $0.GetSubtaskContextRequest request);
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

  /// StashUncommitted runs `git stash push --include-untracked` in the
  /// repository's main working tree. Used by the Merge retry dialog
  /// when the task's base branch is checked out with dirty changes
  /// that block the merge. Returns stashed=false when the tree is
  /// already clean (no error).
  $grpc.ResponseFuture<$0.StashUncommittedResponse> stashUncommitted(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stashUncommitted, request, options: options);
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
  static final _$stashUncommitted =
      $grpc.ClientMethod<$0.IdRequest, $0.StashUncommittedResponse>(
          '/fleetkanban.v1.RepositoryService/StashUncommitted',
          ($0.IdRequest value) => value.writeToBuffer(),
          $0.StashUncommittedResponse.fromBuffer);
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
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $0.StashUncommittedResponse>(
        'StashUncommitted',
        stashUncommitted_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($0.StashUncommittedResponse value) => value.writeToBuffer()));
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

  $async.Future<$0.StashUncommittedResponse> stashUncommitted_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return stashUncommitted($call, await $request);
  }

  $async.Future<$0.StashUncommittedResponse> stashUncommitted(
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

  /// GetCopilotQuota returns the Copilot billing quota snapshots for the
  /// currently authenticated user (premium interactions / chat / completions
  /// etc.), sourced from the SDK's account.getQuota RPC. Unlike
  /// GetGitHubAccountInfo this works with device-flow login alone — no PAT
  /// required — so the UI can surface remaining premium requests out of the
  /// box. Returns UNAVAILABLE when the embedded Copilot CLI is not running,
  /// or UNIMPLEMENTED if the bundled CLI predates the quota RPC.
  $grpc.ResponseFuture<$0.CopilotQuotaInfo> getCopilotQuota(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCopilotQuota, request, options: options);
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
  static final _$getCopilotQuota =
      $grpc.ClientMethod<$1.Empty, $0.CopilotQuotaInfo>(
          '/fleetkanban.v1.AuthService/GetCopilotQuota',
          ($1.Empty value) => value.writeToBuffer(),
          $0.CopilotQuotaInfo.fromBuffer);
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
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.CopilotQuotaInfo>(
        'GetCopilotQuota',
        getCopilotQuota_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.CopilotQuotaInfo value) => value.writeToBuffer()));
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

  $async.Future<$0.CopilotQuotaInfo> getCopilotQuota_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getCopilotQuota($call, await $request);
  }

  $async.Future<$0.CopilotQuotaInfo> getCopilotQuota(
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

  /// GetAgentSettings / SetAgentSettings expose the user-controlled
  /// output-language preference. Per-stage prompt customisation was
  /// removed in favour of the IHR Charter (harness-skill/SKILL.md) —
  /// that is the sanctioned surface for editing planner / runner /
  /// reviewer behaviour.
  $grpc.ResponseFuture<$0.AgentSettings> getAgentSettings(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAgentSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.AgentSettings> setAgentSettings(
    $0.AgentSettings request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setAgentSettings, request, options: options);
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
  static final _$getAgentSettings =
      $grpc.ClientMethod<$1.Empty, $0.AgentSettings>(
          '/fleetkanban.v1.SystemService/GetAgentSettings',
          ($1.Empty value) => value.writeToBuffer(),
          $0.AgentSettings.fromBuffer);
  static final _$setAgentSettings =
      $grpc.ClientMethod<$0.AgentSettings, $0.AgentSettings>(
          '/fleetkanban.v1.SystemService/SetAgentSettings',
          ($0.AgentSettings value) => value.writeToBuffer(),
          $0.AgentSettings.fromBuffer);
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
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.AgentSettings>(
        'GetAgentSettings',
        getAgentSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.AgentSettings value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AgentSettings, $0.AgentSettings>(
        'SetAgentSettings',
        setAgentSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AgentSettings.fromBuffer(value),
        ($0.AgentSettings value) => value.writeToBuffer()));
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

  $async.Future<$0.AgentSettings> getAgentSettings_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getAgentSettings($call, await $request);
  }

  $async.Future<$0.AgentSettings> getAgentSettings(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.AgentSettings> setAgentSettings_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.AgentSettings> $request) async {
    return setAgentSettings($call, await $request);
  }

  $async.Future<$0.AgentSettings> setAgentSettings(
      $grpc.ServiceCall call, $0.AgentSettings request);
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

/// ---------------------------------------------------------------------------
/// ContextService — repository-bound graph memory
/// ---------------------------------------------------------------------------
///
/// The Context feature stores structured knowledge about a registered
/// repository as a property graph (ctx_node + ctx_edge + ctx_closure),
/// vector embeddings (ctx_node_vec), and temporal facts (ctx_fact).
/// Entries arrive through three channels: static analysis, the observer
/// tapping session events, and manual user edits. Search is hybrid
/// (BM25 + vector cosine + graph-neighborhood boost, fused via RRF) and
/// feeds the three-tier injection pipeline (Passive / Reactive / Active)
/// that prepends memory to Copilot prompts.
///
/// Kind / rel / source_kind strings are intentionally NOT proto enums,
/// matching AgentEvent.kind's convention: values are persisted verbatim
/// and interpreted per-kind by the UI, so adding new kinds does not
/// require a proto bump.
@$pb.GrpcServiceName('fleetkanban.v1.ContextService')
class ContextServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ContextServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ContextOverview> getOverview(
    $0.RepoIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getOverview, request, options: options);
  }

  $grpc.ResponseFuture<$0.SearchContextResponse> searchContext(
    $0.SearchContextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$searchContext, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListNodesResponse> listNodes(
    $0.ListNodesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listNodes, request, options: options);
  }

  $grpc.ResponseFuture<$0.ContextNodeDetail> getNode(
    $0.NodeIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getNode, request, options: options);
  }

  $grpc.ResponseFuture<$0.ContextNode> createNode(
    $0.CreateNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createNode, request, options: options);
  }

  $grpc.ResponseFuture<$0.ContextNode> updateNode(
    $0.UpdateNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateNode, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> deleteNode(
    $0.NodeIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteNode, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> pinNode(
    $0.PinNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$pinNode, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListEdgesResponse> listEdges(
    $0.ListEdgesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listEdges, request, options: options);
  }

  $grpc.ResponseFuture<$0.ContextEdge> createEdge(
    $0.CreateEdgeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createEdge, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> deleteEdge(
    $0.EdgeIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteEdge, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListFactsResponse> listFacts(
    $0.ListFactsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listFacts, request, options: options);
  }

  /// PreviewInjection assembles the Passive-tier injection that WOULD be
  /// prepended to a Copilot session for the given task right now, so the
  /// user can audit what memory the agent will see. Does not side-effect.
  $grpc.ResponseFuture<$0.InjectionPreview> previewInjection(
    $0.PreviewInjectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$previewInjection, request, options: options);
  }

  /// AnalyzeRepository spawns a Copilot session that reads the repo and
  /// emits CLAUDE.md-style architectural summary entries into the
  /// scratchpad with source_kind="analyzer". The RPC returns immediately
  /// and progress is observed via the WatchContextChanges stream. User
  /// must promote individual entries from the Scratchpad tab to persist.
  $grpc.ResponseFuture<$1.Empty> analyzeRepository(
    $0.AnalyzeRepoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$analyzeRepository, request, options: options);
  }

  /// RebuildEmbeddings recomputes ctx_node_vec for every enabled node
  /// in the repo using the current embedding provider. Safe to call
  /// after enabling Memory or switching provider. Returns the count of
  /// rebuilt and skipped nodes so the UI can surface a toast.
  $grpc.ResponseFuture<$0.RebuildEmbeddingsResponse> rebuildEmbeddings(
    $0.RepoIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rebuildEmbeddings, request, options: options);
  }

  /// RebuildClosure recomputes the closure table — the redundant
  /// projection used by graph-neighborhood boost. Exposed for the
  /// "Rebuild closure" admin button on the Overview tab.
  $grpc.ResponseFuture<$1.Empty> rebuildClosure(
    $0.RepoIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rebuildClosure, request, options: options);
  }

  /// RebuildCodeGraph walks the repository filesystem and upserts
  /// File nodes + imports edges directly from source. Cheap — no LLM
  /// calls — so the UI typically runs it after Analyze or when the
  /// user notices new files are missing from Browse. Returns a
  /// summary so the UI can render a toast.
  $grpc.ResponseFuture<$0.RebuildCodeGraphResponse> rebuildCodeGraph(
    $0.RepoIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rebuildCodeGraph, request, options: options);
  }

  $grpc.ResponseFuture<$0.MemorySettings> getMemorySettings(
    $0.RepoIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMemorySettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.MemorySettings> updateMemorySettings(
    $0.UpdateMemorySettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateMemorySettings, request, options: options);
  }

  /// GetMemoryHealth is a fast status probe separate from GetOverview —
  /// cheap enough to poll every few seconds so the Settings panel and
  /// Kanban badge can show whether Memory is actually working (provider
  /// reachable, vectors present) without blocking on node/edge counts.
  $grpc.ResponseFuture<$0.MemoryHealth> getMemoryHealth(
    $0.RepoIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMemoryHealth, request, options: options);
  }

  /// SuggestForNewTask runs hybrid retrieval against finalized Task +
  /// promoted Decision + Constraint nodes using the user's draft goal
  /// as query text. The New Task dialog calls this on a 400ms debounce
  /// so the user sees past similar tasks and applicable decisions
  /// before they spend tokens running the plan again. Returns an empty
  /// bundle (no error) when Memory is disabled — the UI renders
  /// nothing in that case.
  $grpc.ResponseFuture<$0.SuggestForNewTaskResponse> suggestForNewTask(
    $0.SuggestForNewTaskRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$suggestForNewTask, request, options: options);
  }

  /// WatchContextChanges streams node / edge / fact / scratchpad updates
  /// scoped to a repository so the Context UI can refresh incrementally
  /// without polling. Analogous to TaskService.WatchEvents.
  $grpc.ResponseStream<$0.ContextChangeEvent> watchContextChanges(
    $0.WatchContextRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchContextChanges, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getOverview =
      $grpc.ClientMethod<$0.RepoIdRequest, $0.ContextOverview>(
          '/fleetkanban.v1.ContextService/GetOverview',
          ($0.RepoIdRequest value) => value.writeToBuffer(),
          $0.ContextOverview.fromBuffer);
  static final _$searchContext =
      $grpc.ClientMethod<$0.SearchContextRequest, $0.SearchContextResponse>(
          '/fleetkanban.v1.ContextService/SearchContext',
          ($0.SearchContextRequest value) => value.writeToBuffer(),
          $0.SearchContextResponse.fromBuffer);
  static final _$listNodes =
      $grpc.ClientMethod<$0.ListNodesRequest, $0.ListNodesResponse>(
          '/fleetkanban.v1.ContextService/ListNodes',
          ($0.ListNodesRequest value) => value.writeToBuffer(),
          $0.ListNodesResponse.fromBuffer);
  static final _$getNode =
      $grpc.ClientMethod<$0.NodeIdRequest, $0.ContextNodeDetail>(
          '/fleetkanban.v1.ContextService/GetNode',
          ($0.NodeIdRequest value) => value.writeToBuffer(),
          $0.ContextNodeDetail.fromBuffer);
  static final _$createNode =
      $grpc.ClientMethod<$0.CreateNodeRequest, $0.ContextNode>(
          '/fleetkanban.v1.ContextService/CreateNode',
          ($0.CreateNodeRequest value) => value.writeToBuffer(),
          $0.ContextNode.fromBuffer);
  static final _$updateNode =
      $grpc.ClientMethod<$0.UpdateNodeRequest, $0.ContextNode>(
          '/fleetkanban.v1.ContextService/UpdateNode',
          ($0.UpdateNodeRequest value) => value.writeToBuffer(),
          $0.ContextNode.fromBuffer);
  static final _$deleteNode = $grpc.ClientMethod<$0.NodeIdRequest, $1.Empty>(
      '/fleetkanban.v1.ContextService/DeleteNode',
      ($0.NodeIdRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$pinNode = $grpc.ClientMethod<$0.PinNodeRequest, $1.Empty>(
      '/fleetkanban.v1.ContextService/PinNode',
      ($0.PinNodeRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$listEdges =
      $grpc.ClientMethod<$0.ListEdgesRequest, $0.ListEdgesResponse>(
          '/fleetkanban.v1.ContextService/ListEdges',
          ($0.ListEdgesRequest value) => value.writeToBuffer(),
          $0.ListEdgesResponse.fromBuffer);
  static final _$createEdge =
      $grpc.ClientMethod<$0.CreateEdgeRequest, $0.ContextEdge>(
          '/fleetkanban.v1.ContextService/CreateEdge',
          ($0.CreateEdgeRequest value) => value.writeToBuffer(),
          $0.ContextEdge.fromBuffer);
  static final _$deleteEdge = $grpc.ClientMethod<$0.EdgeIdRequest, $1.Empty>(
      '/fleetkanban.v1.ContextService/DeleteEdge',
      ($0.EdgeIdRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$listFacts =
      $grpc.ClientMethod<$0.ListFactsRequest, $0.ListFactsResponse>(
          '/fleetkanban.v1.ContextService/ListFacts',
          ($0.ListFactsRequest value) => value.writeToBuffer(),
          $0.ListFactsResponse.fromBuffer);
  static final _$previewInjection =
      $grpc.ClientMethod<$0.PreviewInjectionRequest, $0.InjectionPreview>(
          '/fleetkanban.v1.ContextService/PreviewInjection',
          ($0.PreviewInjectionRequest value) => value.writeToBuffer(),
          $0.InjectionPreview.fromBuffer);
  static final _$analyzeRepository =
      $grpc.ClientMethod<$0.AnalyzeRepoRequest, $1.Empty>(
          '/fleetkanban.v1.ContextService/AnalyzeRepository',
          ($0.AnalyzeRepoRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$rebuildEmbeddings =
      $grpc.ClientMethod<$0.RepoIdRequest, $0.RebuildEmbeddingsResponse>(
          '/fleetkanban.v1.ContextService/RebuildEmbeddings',
          ($0.RepoIdRequest value) => value.writeToBuffer(),
          $0.RebuildEmbeddingsResponse.fromBuffer);
  static final _$rebuildClosure =
      $grpc.ClientMethod<$0.RepoIdRequest, $1.Empty>(
          '/fleetkanban.v1.ContextService/RebuildClosure',
          ($0.RepoIdRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$rebuildCodeGraph =
      $grpc.ClientMethod<$0.RepoIdRequest, $0.RebuildCodeGraphResponse>(
          '/fleetkanban.v1.ContextService/RebuildCodeGraph',
          ($0.RepoIdRequest value) => value.writeToBuffer(),
          $0.RebuildCodeGraphResponse.fromBuffer);
  static final _$getMemorySettings =
      $grpc.ClientMethod<$0.RepoIdRequest, $0.MemorySettings>(
          '/fleetkanban.v1.ContextService/GetMemorySettings',
          ($0.RepoIdRequest value) => value.writeToBuffer(),
          $0.MemorySettings.fromBuffer);
  static final _$updateMemorySettings =
      $grpc.ClientMethod<$0.UpdateMemorySettingsRequest, $0.MemorySettings>(
          '/fleetkanban.v1.ContextService/UpdateMemorySettings',
          ($0.UpdateMemorySettingsRequest value) => value.writeToBuffer(),
          $0.MemorySettings.fromBuffer);
  static final _$getMemoryHealth =
      $grpc.ClientMethod<$0.RepoIdRequest, $0.MemoryHealth>(
          '/fleetkanban.v1.ContextService/GetMemoryHealth',
          ($0.RepoIdRequest value) => value.writeToBuffer(),
          $0.MemoryHealth.fromBuffer);
  static final _$suggestForNewTask = $grpc.ClientMethod<
          $0.SuggestForNewTaskRequest, $0.SuggestForNewTaskResponse>(
      '/fleetkanban.v1.ContextService/SuggestForNewTask',
      ($0.SuggestForNewTaskRequest value) => value.writeToBuffer(),
      $0.SuggestForNewTaskResponse.fromBuffer);
  static final _$watchContextChanges =
      $grpc.ClientMethod<$0.WatchContextRequest, $0.ContextChangeEvent>(
          '/fleetkanban.v1.ContextService/WatchContextChanges',
          ($0.WatchContextRequest value) => value.writeToBuffer(),
          $0.ContextChangeEvent.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.ContextService')
abstract class ContextServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.ContextService';

  ContextServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.RepoIdRequest, $0.ContextOverview>(
        'GetOverview',
        getOverview_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RepoIdRequest.fromBuffer(value),
        ($0.ContextOverview value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SearchContextRequest, $0.SearchContextResponse>(
            'SearchContext',
            searchContext_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SearchContextRequest.fromBuffer(value),
            ($0.SearchContextResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListNodesRequest, $0.ListNodesResponse>(
        'ListNodes',
        listNodes_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListNodesRequest.fromBuffer(value),
        ($0.ListNodesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NodeIdRequest, $0.ContextNodeDetail>(
        'GetNode',
        getNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NodeIdRequest.fromBuffer(value),
        ($0.ContextNodeDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateNodeRequest, $0.ContextNode>(
        'CreateNode',
        createNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreateNodeRequest.fromBuffer(value),
        ($0.ContextNode value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateNodeRequest, $0.ContextNode>(
        'UpdateNode',
        updateNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UpdateNodeRequest.fromBuffer(value),
        ($0.ContextNode value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NodeIdRequest, $1.Empty>(
        'DeleteNode',
        deleteNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NodeIdRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PinNodeRequest, $1.Empty>(
        'PinNode',
        pinNode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PinNodeRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListEdgesRequest, $0.ListEdgesResponse>(
        'ListEdges',
        listEdges_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListEdgesRequest.fromBuffer(value),
        ($0.ListEdgesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateEdgeRequest, $0.ContextEdge>(
        'CreateEdge',
        createEdge_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreateEdgeRequest.fromBuffer(value),
        ($0.ContextEdge value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EdgeIdRequest, $1.Empty>(
        'DeleteEdge',
        deleteEdge_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EdgeIdRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListFactsRequest, $0.ListFactsResponse>(
        'ListFacts',
        listFacts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListFactsRequest.fromBuffer(value),
        ($0.ListFactsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.PreviewInjectionRequest, $0.InjectionPreview>(
            'PreviewInjection',
            previewInjection_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.PreviewInjectionRequest.fromBuffer(value),
            ($0.InjectionPreview value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AnalyzeRepoRequest, $1.Empty>(
        'AnalyzeRepository',
        analyzeRepository_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AnalyzeRepoRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RepoIdRequest, $0.RebuildEmbeddingsResponse>(
            'RebuildEmbeddings',
            rebuildEmbeddings_Pre,
            false,
            false,
            ($core.List<$core.int> value) => $0.RepoIdRequest.fromBuffer(value),
            ($0.RebuildEmbeddingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RepoIdRequest, $1.Empty>(
        'RebuildClosure',
        rebuildClosure_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RepoIdRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RepoIdRequest, $0.RebuildCodeGraphResponse>(
            'RebuildCodeGraph',
            rebuildCodeGraph_Pre,
            false,
            false,
            ($core.List<$core.int> value) => $0.RepoIdRequest.fromBuffer(value),
            ($0.RebuildCodeGraphResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RepoIdRequest, $0.MemorySettings>(
        'GetMemorySettings',
        getMemorySettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RepoIdRequest.fromBuffer(value),
        ($0.MemorySettings value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateMemorySettingsRequest, $0.MemorySettings>(
            'UpdateMemorySettings',
            updateMemorySettings_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateMemorySettingsRequest.fromBuffer(value),
            ($0.MemorySettings value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RepoIdRequest, $0.MemoryHealth>(
        'GetMemoryHealth',
        getMemoryHealth_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RepoIdRequest.fromBuffer(value),
        ($0.MemoryHealth value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SuggestForNewTaskRequest,
            $0.SuggestForNewTaskResponse>(
        'SuggestForNewTask',
        suggestForNewTask_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SuggestForNewTaskRequest.fromBuffer(value),
        ($0.SuggestForNewTaskResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.WatchContextRequest, $0.ContextChangeEvent>(
            'WatchContextChanges',
            watchContextChanges_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.WatchContextRequest.fromBuffer(value),
            ($0.ContextChangeEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.ContextOverview> getOverview_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RepoIdRequest> $request) async {
    return getOverview($call, await $request);
  }

  $async.Future<$0.ContextOverview> getOverview(
      $grpc.ServiceCall call, $0.RepoIdRequest request);

  $async.Future<$0.SearchContextResponse> searchContext_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SearchContextRequest> $request) async {
    return searchContext($call, await $request);
  }

  $async.Future<$0.SearchContextResponse> searchContext(
      $grpc.ServiceCall call, $0.SearchContextRequest request);

  $async.Future<$0.ListNodesResponse> listNodes_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListNodesRequest> $request) async {
    return listNodes($call, await $request);
  }

  $async.Future<$0.ListNodesResponse> listNodes(
      $grpc.ServiceCall call, $0.ListNodesRequest request);

  $async.Future<$0.ContextNodeDetail> getNode_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.NodeIdRequest> $request) async {
    return getNode($call, await $request);
  }

  $async.Future<$0.ContextNodeDetail> getNode(
      $grpc.ServiceCall call, $0.NodeIdRequest request);

  $async.Future<$0.ContextNode> createNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateNodeRequest> $request) async {
    return createNode($call, await $request);
  }

  $async.Future<$0.ContextNode> createNode(
      $grpc.ServiceCall call, $0.CreateNodeRequest request);

  $async.Future<$0.ContextNode> updateNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateNodeRequest> $request) async {
    return updateNode($call, await $request);
  }

  $async.Future<$0.ContextNode> updateNode(
      $grpc.ServiceCall call, $0.UpdateNodeRequest request);

  $async.Future<$1.Empty> deleteNode_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.NodeIdRequest> $request) async {
    return deleteNode($call, await $request);
  }

  $async.Future<$1.Empty> deleteNode(
      $grpc.ServiceCall call, $0.NodeIdRequest request);

  $async.Future<$1.Empty> pinNode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PinNodeRequest> $request) async {
    return pinNode($call, await $request);
  }

  $async.Future<$1.Empty> pinNode(
      $grpc.ServiceCall call, $0.PinNodeRequest request);

  $async.Future<$0.ListEdgesResponse> listEdges_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListEdgesRequest> $request) async {
    return listEdges($call, await $request);
  }

  $async.Future<$0.ListEdgesResponse> listEdges(
      $grpc.ServiceCall call, $0.ListEdgesRequest request);

  $async.Future<$0.ContextEdge> createEdge_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateEdgeRequest> $request) async {
    return createEdge($call, await $request);
  }

  $async.Future<$0.ContextEdge> createEdge(
      $grpc.ServiceCall call, $0.CreateEdgeRequest request);

  $async.Future<$1.Empty> deleteEdge_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.EdgeIdRequest> $request) async {
    return deleteEdge($call, await $request);
  }

  $async.Future<$1.Empty> deleteEdge(
      $grpc.ServiceCall call, $0.EdgeIdRequest request);

  $async.Future<$0.ListFactsResponse> listFacts_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListFactsRequest> $request) async {
    return listFacts($call, await $request);
  }

  $async.Future<$0.ListFactsResponse> listFacts(
      $grpc.ServiceCall call, $0.ListFactsRequest request);

  $async.Future<$0.InjectionPreview> previewInjection_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PreviewInjectionRequest> $request) async {
    return previewInjection($call, await $request);
  }

  $async.Future<$0.InjectionPreview> previewInjection(
      $grpc.ServiceCall call, $0.PreviewInjectionRequest request);

  $async.Future<$1.Empty> analyzeRepository_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AnalyzeRepoRequest> $request) async {
    return analyzeRepository($call, await $request);
  }

  $async.Future<$1.Empty> analyzeRepository(
      $grpc.ServiceCall call, $0.AnalyzeRepoRequest request);

  $async.Future<$0.RebuildEmbeddingsResponse> rebuildEmbeddings_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RepoIdRequest> $request) async {
    return rebuildEmbeddings($call, await $request);
  }

  $async.Future<$0.RebuildEmbeddingsResponse> rebuildEmbeddings(
      $grpc.ServiceCall call, $0.RepoIdRequest request);

  $async.Future<$1.Empty> rebuildClosure_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RepoIdRequest> $request) async {
    return rebuildClosure($call, await $request);
  }

  $async.Future<$1.Empty> rebuildClosure(
      $grpc.ServiceCall call, $0.RepoIdRequest request);

  $async.Future<$0.RebuildCodeGraphResponse> rebuildCodeGraph_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RepoIdRequest> $request) async {
    return rebuildCodeGraph($call, await $request);
  }

  $async.Future<$0.RebuildCodeGraphResponse> rebuildCodeGraph(
      $grpc.ServiceCall call, $0.RepoIdRequest request);

  $async.Future<$0.MemorySettings> getMemorySettings_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RepoIdRequest> $request) async {
    return getMemorySettings($call, await $request);
  }

  $async.Future<$0.MemorySettings> getMemorySettings(
      $grpc.ServiceCall call, $0.RepoIdRequest request);

  $async.Future<$0.MemorySettings> updateMemorySettings_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdateMemorySettingsRequest> $request) async {
    return updateMemorySettings($call, await $request);
  }

  $async.Future<$0.MemorySettings> updateMemorySettings(
      $grpc.ServiceCall call, $0.UpdateMemorySettingsRequest request);

  $async.Future<$0.MemoryHealth> getMemoryHealth_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RepoIdRequest> $request) async {
    return getMemoryHealth($call, await $request);
  }

  $async.Future<$0.MemoryHealth> getMemoryHealth(
      $grpc.ServiceCall call, $0.RepoIdRequest request);

  $async.Future<$0.SuggestForNewTaskResponse> suggestForNewTask_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SuggestForNewTaskRequest> $request) async {
    return suggestForNewTask($call, await $request);
  }

  $async.Future<$0.SuggestForNewTaskResponse> suggestForNewTask(
      $grpc.ServiceCall call, $0.SuggestForNewTaskRequest request);

  $async.Stream<$0.ContextChangeEvent> watchContextChanges_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.WatchContextRequest> $request) async* {
    yield* watchContextChanges($call, await $request);
  }

  $async.Stream<$0.ContextChangeEvent> watchContextChanges(
      $grpc.ServiceCall call, $0.WatchContextRequest request);
}

/// ScratchpadService manages pending memory entries waiting for a trust
/// gate decision. The observer and analyzer push candidates here; the
/// user promotes, rejects, edits, or snoozes them from the Context
/// scratchpad tab. Auto-promotion can be enabled per-repo for
/// high-confidence entries via MemorySettings.
@$pb.GrpcServiceName('fleetkanban.v1.ScratchpadService')
class ScratchpadServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ScratchpadServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListPendingResponse> listPending(
    $0.ListPendingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listPending, request, options: options);
  }

  $grpc.ResponseFuture<$0.ScratchpadEntry> getEntry(
    $0.EntryIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getEntry, request, options: options);
  }

  $grpc.ResponseFuture<$0.ContextNode> promoteEntry(
    $0.EntryIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$promoteEntry, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> rejectEntry(
    $0.RejectEntryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rejectEntry, request, options: options);
  }

  $grpc.ResponseFuture<$0.ContextNode> editAndPromote(
    $0.EditAndPromoteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$editAndPromote, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> snoozeEntry(
    $0.SnoozeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$snoozeEntry, request, options: options);
  }

  $grpc.ResponseStream<$0.ScratchpadChangeEvent> watchPending(
    $0.RepoIdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchPending, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$listPending =
      $grpc.ClientMethod<$0.ListPendingRequest, $0.ListPendingResponse>(
          '/fleetkanban.v1.ScratchpadService/ListPending',
          ($0.ListPendingRequest value) => value.writeToBuffer(),
          $0.ListPendingResponse.fromBuffer);
  static final _$getEntry =
      $grpc.ClientMethod<$0.EntryIdRequest, $0.ScratchpadEntry>(
          '/fleetkanban.v1.ScratchpadService/GetEntry',
          ($0.EntryIdRequest value) => value.writeToBuffer(),
          $0.ScratchpadEntry.fromBuffer);
  static final _$promoteEntry =
      $grpc.ClientMethod<$0.EntryIdRequest, $0.ContextNode>(
          '/fleetkanban.v1.ScratchpadService/PromoteEntry',
          ($0.EntryIdRequest value) => value.writeToBuffer(),
          $0.ContextNode.fromBuffer);
  static final _$rejectEntry =
      $grpc.ClientMethod<$0.RejectEntryRequest, $1.Empty>(
          '/fleetkanban.v1.ScratchpadService/RejectEntry',
          ($0.RejectEntryRequest value) => value.writeToBuffer(),
          $1.Empty.fromBuffer);
  static final _$editAndPromote =
      $grpc.ClientMethod<$0.EditAndPromoteRequest, $0.ContextNode>(
          '/fleetkanban.v1.ScratchpadService/EditAndPromote',
          ($0.EditAndPromoteRequest value) => value.writeToBuffer(),
          $0.ContextNode.fromBuffer);
  static final _$snoozeEntry = $grpc.ClientMethod<$0.SnoozeRequest, $1.Empty>(
      '/fleetkanban.v1.ScratchpadService/SnoozeEntry',
      ($0.SnoozeRequest value) => value.writeToBuffer(),
      $1.Empty.fromBuffer);
  static final _$watchPending =
      $grpc.ClientMethod<$0.RepoIdRequest, $0.ScratchpadChangeEvent>(
          '/fleetkanban.v1.ScratchpadService/WatchPending',
          ($0.RepoIdRequest value) => value.writeToBuffer(),
          $0.ScratchpadChangeEvent.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.ScratchpadService')
abstract class ScratchpadServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.ScratchpadService';

  ScratchpadServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListPendingRequest, $0.ListPendingResponse>(
            'ListPending',
            listPending_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListPendingRequest.fromBuffer(value),
            ($0.ListPendingResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EntryIdRequest, $0.ScratchpadEntry>(
        'GetEntry',
        getEntry_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EntryIdRequest.fromBuffer(value),
        ($0.ScratchpadEntry value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EntryIdRequest, $0.ContextNode>(
        'PromoteEntry',
        promoteEntry_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EntryIdRequest.fromBuffer(value),
        ($0.ContextNode value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RejectEntryRequest, $1.Empty>(
        'RejectEntry',
        rejectEntry_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RejectEntryRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EditAndPromoteRequest, $0.ContextNode>(
        'EditAndPromote',
        editAndPromote_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.EditAndPromoteRequest.fromBuffer(value),
        ($0.ContextNode value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SnoozeRequest, $1.Empty>(
        'SnoozeEntry',
        snoozeEntry_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SnoozeRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RepoIdRequest, $0.ScratchpadChangeEvent>(
        'WatchPending',
        watchPending_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.RepoIdRequest.fromBuffer(value),
        ($0.ScratchpadChangeEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListPendingResponse> listPending_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListPendingRequest> $request) async {
    return listPending($call, await $request);
  }

  $async.Future<$0.ListPendingResponse> listPending(
      $grpc.ServiceCall call, $0.ListPendingRequest request);

  $async.Future<$0.ScratchpadEntry> getEntry_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EntryIdRequest> $request) async {
    return getEntry($call, await $request);
  }

  $async.Future<$0.ScratchpadEntry> getEntry(
      $grpc.ServiceCall call, $0.EntryIdRequest request);

  $async.Future<$0.ContextNode> promoteEntry_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EntryIdRequest> $request) async {
    return promoteEntry($call, await $request);
  }

  $async.Future<$0.ContextNode> promoteEntry(
      $grpc.ServiceCall call, $0.EntryIdRequest request);

  $async.Future<$1.Empty> rejectEntry_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RejectEntryRequest> $request) async {
    return rejectEntry($call, await $request);
  }

  $async.Future<$1.Empty> rejectEntry(
      $grpc.ServiceCall call, $0.RejectEntryRequest request);

  $async.Future<$0.ContextNode> editAndPromote_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EditAndPromoteRequest> $request) async {
    return editAndPromote($call, await $request);
  }

  $async.Future<$0.ContextNode> editAndPromote(
      $grpc.ServiceCall call, $0.EditAndPromoteRequest request);

  $async.Future<$1.Empty> snoozeEntry_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SnoozeRequest> $request) async {
    return snoozeEntry($call, await $request);
  }

  $async.Future<$1.Empty> snoozeEntry(
      $grpc.ServiceCall call, $0.SnoozeRequest request);

  $async.Stream<$0.ScratchpadChangeEvent> watchPending_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RepoIdRequest> $request) async* {
    yield* watchPending($call, await $request);
  }

  $async.Stream<$0.ScratchpadChangeEvent> watchPending(
      $grpc.ServiceCall call, $0.RepoIdRequest request);
}

/// OllamaService wraps the local Ollama HTTP API (default
/// http://localhost:11434) so the UI can detect installation, list and
/// pull embedding / LLM models, and stream pull progress. Used by the
/// Settings onboarding flow when the user selects Ollama as the
/// embedding or LLM provider.
@$pb.GrpcServiceName('fleetkanban.v1.OllamaService')
class OllamaServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  OllamaServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.OllamaStatus> getOllamaStatus(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getOllamaStatus, request, options: options);
  }

  /// ListInstalledModels rather than ListModels — ModelService.ListModels
  /// already claims the Go method name ListModels on the sidecar Server
  /// struct, so the names must be unique for method resolution.
  $grpc.ResponseFuture<$0.OllamaListModelsResponse> listInstalledModels(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listInstalledModels, request, options: options);
  }

  $grpc.ResponseFuture<$0.OllamaListRecommendedResponse> getRecommendedModels(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getRecommendedModels, request, options: options);
  }

  $grpc.ResponseStream<$0.OllamaPullProgressEvent> pullOllamaModel(
    $0.PullModelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$pullOllamaModel, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getOllamaStatus =
      $grpc.ClientMethod<$1.Empty, $0.OllamaStatus>(
          '/fleetkanban.v1.OllamaService/GetOllamaStatus',
          ($1.Empty value) => value.writeToBuffer(),
          $0.OllamaStatus.fromBuffer);
  static final _$listInstalledModels =
      $grpc.ClientMethod<$1.Empty, $0.OllamaListModelsResponse>(
          '/fleetkanban.v1.OllamaService/ListInstalledModels',
          ($1.Empty value) => value.writeToBuffer(),
          $0.OllamaListModelsResponse.fromBuffer);
  static final _$getRecommendedModels =
      $grpc.ClientMethod<$1.Empty, $0.OllamaListRecommendedResponse>(
          '/fleetkanban.v1.OllamaService/GetRecommendedModels',
          ($1.Empty value) => value.writeToBuffer(),
          $0.OllamaListRecommendedResponse.fromBuffer);
  static final _$pullOllamaModel =
      $grpc.ClientMethod<$0.PullModelRequest, $0.OllamaPullProgressEvent>(
          '/fleetkanban.v1.OllamaService/PullOllamaModel',
          ($0.PullModelRequest value) => value.writeToBuffer(),
          $0.OllamaPullProgressEvent.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.OllamaService')
abstract class OllamaServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.OllamaService';

  OllamaServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.OllamaStatus>(
        'GetOllamaStatus',
        getOllamaStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.OllamaStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.OllamaListModelsResponse>(
        'ListInstalledModels',
        listInstalledModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.OllamaListModelsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.OllamaListRecommendedResponse>(
        'GetRecommendedModels',
        getRecommendedModels_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.OllamaListRecommendedResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.PullModelRequest, $0.OllamaPullProgressEvent>(
            'PullOllamaModel',
            pullOllamaModel_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.PullModelRequest.fromBuffer(value),
            ($0.OllamaPullProgressEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.OllamaStatus> getOllamaStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getOllamaStatus($call, await $request);
  }

  $async.Future<$0.OllamaStatus> getOllamaStatus(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.OllamaListModelsResponse> listInstalledModels_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return listInstalledModels($call, await $request);
  }

  $async.Future<$0.OllamaListModelsResponse> listInstalledModels(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.OllamaListRecommendedResponse> getRecommendedModels_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getRecommendedModels($call, await $request);
  }

  $async.Future<$0.OllamaListRecommendedResponse> getRecommendedModels(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Stream<$0.OllamaPullProgressEvent> pullOllamaModel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PullModelRequest> $request) async* {
    yield* pullOllamaModel($call, await $request);
  }

  $async.Stream<$0.OllamaPullProgressEvent> pullOllamaModel(
      $grpc.ServiceCall call, $0.PullModelRequest request);
}

@$pb.GrpcServiceName('fleetkanban.v1.ArtifactService')
class ArtifactServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ArtifactServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListArtifactsResponse> list(
    $0.ListArtifactsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$list, request, options: options);
  }

  $grpc.ResponseFuture<$0.Artifact> get(
    $0.GetArtifactRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$get, request, options: options);
  }

  $grpc.ResponseStream<$0.ArtifactChunk> getContent(
    $0.GetArtifactContentRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$getContent, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$list =
      $grpc.ClientMethod<$0.ListArtifactsRequest, $0.ListArtifactsResponse>(
          '/fleetkanban.v1.ArtifactService/List',
          ($0.ListArtifactsRequest value) => value.writeToBuffer(),
          $0.ListArtifactsResponse.fromBuffer);
  static final _$get = $grpc.ClientMethod<$0.GetArtifactRequest, $0.Artifact>(
      '/fleetkanban.v1.ArtifactService/Get',
      ($0.GetArtifactRequest value) => value.writeToBuffer(),
      $0.Artifact.fromBuffer);
  static final _$getContent =
      $grpc.ClientMethod<$0.GetArtifactContentRequest, $0.ArtifactChunk>(
          '/fleetkanban.v1.ArtifactService/GetContent',
          ($0.GetArtifactContentRequest value) => value.writeToBuffer(),
          $0.ArtifactChunk.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.ArtifactService')
abstract class ArtifactServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.ArtifactService';

  ArtifactServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListArtifactsRequest, $0.ListArtifactsResponse>(
            'List',
            list_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListArtifactsRequest.fromBuffer(value),
            ($0.ListArtifactsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetArtifactRequest, $0.Artifact>(
        'Get',
        get_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetArtifactRequest.fromBuffer(value),
        ($0.Artifact value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetArtifactContentRequest, $0.ArtifactChunk>(
            'GetContent',
            getContent_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.GetArtifactContentRequest.fromBuffer(value),
            ($0.ArtifactChunk value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListArtifactsResponse> list_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListArtifactsRequest> $request) async {
    return list($call, await $request);
  }

  $async.Future<$0.ListArtifactsResponse> list(
      $grpc.ServiceCall call, $0.ListArtifactsRequest request);

  $async.Future<$0.Artifact> get_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetArtifactRequest> $request) async {
    return get($call, await $request);
  }

  $async.Future<$0.Artifact> get(
      $grpc.ServiceCall call, $0.GetArtifactRequest request);

  $async.Stream<$0.ArtifactChunk> getContent_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetArtifactContentRequest> $request) async* {
    yield* getContent($call, await $request);
  }

  $async.Stream<$0.ArtifactChunk> getContent(
      $grpc.ServiceCall call, $0.GetArtifactContentRequest request);
}

@$pb.GrpcServiceName('fleetkanban.v1.HarnessService')
class HarnessServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HarnessServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.HarnessSkill> getActiveSkill(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getActiveSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListSkillVersionsResponse> listSkillVersions(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSkillVersions, request, options: options);
  }

  $grpc.ResponseFuture<$0.ValidateSkillResponse> validateSkill(
    $0.ValidateSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$validateSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.HarnessSkill> updateSkill(
    $0.UpdateSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateSkill, request, options: options);
  }

  $grpc.ResponseFuture<$0.HarnessSkill> rollbackSkill(
    $0.RollbackSkillRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rollbackSkill, request, options: options);
  }

  // method descriptors

  static final _$getActiveSkill = $grpc.ClientMethod<$1.Empty, $0.HarnessSkill>(
      '/fleetkanban.v1.HarnessService/GetActiveSkill',
      ($1.Empty value) => value.writeToBuffer(),
      $0.HarnessSkill.fromBuffer);
  static final _$listSkillVersions =
      $grpc.ClientMethod<$1.Empty, $0.ListSkillVersionsResponse>(
          '/fleetkanban.v1.HarnessService/ListSkillVersions',
          ($1.Empty value) => value.writeToBuffer(),
          $0.ListSkillVersionsResponse.fromBuffer);
  static final _$validateSkill =
      $grpc.ClientMethod<$0.ValidateSkillRequest, $0.ValidateSkillResponse>(
          '/fleetkanban.v1.HarnessService/ValidateSkill',
          ($0.ValidateSkillRequest value) => value.writeToBuffer(),
          $0.ValidateSkillResponse.fromBuffer);
  static final _$updateSkill =
      $grpc.ClientMethod<$0.UpdateSkillRequest, $0.HarnessSkill>(
          '/fleetkanban.v1.HarnessService/UpdateSkill',
          ($0.UpdateSkillRequest value) => value.writeToBuffer(),
          $0.HarnessSkill.fromBuffer);
  static final _$rollbackSkill =
      $grpc.ClientMethod<$0.RollbackSkillRequest, $0.HarnessSkill>(
          '/fleetkanban.v1.HarnessService/RollbackSkill',
          ($0.RollbackSkillRequest value) => value.writeToBuffer(),
          $0.HarnessSkill.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.HarnessService')
abstract class HarnessServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.HarnessService';

  HarnessServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.HarnessSkill>(
        'GetActiveSkill',
        getActiveSkill_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.HarnessSkill value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.ListSkillVersionsResponse>(
        'ListSkillVersions',
        listSkillVersions_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.ListSkillVersionsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ValidateSkillRequest, $0.ValidateSkillResponse>(
            'ValidateSkill',
            validateSkill_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ValidateSkillRequest.fromBuffer(value),
            ($0.ValidateSkillResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateSkillRequest, $0.HarnessSkill>(
        'UpdateSkill',
        updateSkill_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateSkillRequest.fromBuffer(value),
        ($0.HarnessSkill value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RollbackSkillRequest, $0.HarnessSkill>(
        'RollbackSkill',
        rollbackSkill_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RollbackSkillRequest.fromBuffer(value),
        ($0.HarnessSkill value) => value.writeToBuffer()));
  }

  $async.Future<$0.HarnessSkill> getActiveSkill_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getActiveSkill($call, await $request);
  }

  $async.Future<$0.HarnessSkill> getActiveSkill(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.ListSkillVersionsResponse> listSkillVersions_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return listSkillVersions($call, await $request);
  }

  $async.Future<$0.ListSkillVersionsResponse> listSkillVersions(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.ValidateSkillResponse> validateSkill_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ValidateSkillRequest> $request) async {
    return validateSkill($call, await $request);
  }

  $async.Future<$0.ValidateSkillResponse> validateSkill(
      $grpc.ServiceCall call, $0.ValidateSkillRequest request);

  $async.Future<$0.HarnessSkill> updateSkill_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateSkillRequest> $request) async {
    return updateSkill($call, await $request);
  }

  $async.Future<$0.HarnessSkill> updateSkill(
      $grpc.ServiceCall call, $0.UpdateSkillRequest request);

  $async.Future<$0.HarnessSkill> rollbackSkill_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RollbackSkillRequest> $request) async {
    return rollbackSkill($call, await $request);
  }

  $async.Future<$0.HarnessSkill> rollbackSkill(
      $grpc.ServiceCall call, $0.RollbackSkillRequest request);
}

@$pb.GrpcServiceName('fleetkanban.v1.HarnessAttemptService')
class HarnessAttemptServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HarnessAttemptServiceClient(super.channel,
      {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListHarnessAttemptsResponse> listPending(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listPending, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListHarnessAttemptsResponse> listForTask(
    $0.ListHarnessAttemptsForTaskRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listForTask, request, options: options);
  }

  $grpc.ResponseFuture<$0.HarnessAttempt> approve(
    $0.ApproveHarnessAttemptRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$approve, request, options: options);
  }

  $grpc.ResponseFuture<$0.HarnessAttempt> reject(
    $0.RejectHarnessAttemptRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reject, request, options: options);
  }

  // method descriptors

  static final _$listPending =
      $grpc.ClientMethod<$1.Empty, $0.ListHarnessAttemptsResponse>(
          '/fleetkanban.v1.HarnessAttemptService/ListPending',
          ($1.Empty value) => value.writeToBuffer(),
          $0.ListHarnessAttemptsResponse.fromBuffer);
  static final _$listForTask = $grpc.ClientMethod<
          $0.ListHarnessAttemptsForTaskRequest, $0.ListHarnessAttemptsResponse>(
      '/fleetkanban.v1.HarnessAttemptService/ListForTask',
      ($0.ListHarnessAttemptsForTaskRequest value) => value.writeToBuffer(),
      $0.ListHarnessAttemptsResponse.fromBuffer);
  static final _$approve =
      $grpc.ClientMethod<$0.ApproveHarnessAttemptRequest, $0.HarnessAttempt>(
          '/fleetkanban.v1.HarnessAttemptService/Approve',
          ($0.ApproveHarnessAttemptRequest value) => value.writeToBuffer(),
          $0.HarnessAttempt.fromBuffer);
  static final _$reject =
      $grpc.ClientMethod<$0.RejectHarnessAttemptRequest, $0.HarnessAttempt>(
          '/fleetkanban.v1.HarnessAttemptService/Reject',
          ($0.RejectHarnessAttemptRequest value) => value.writeToBuffer(),
          $0.HarnessAttempt.fromBuffer);
}

@$pb.GrpcServiceName('fleetkanban.v1.HarnessAttemptService')
abstract class HarnessAttemptServiceBase extends $grpc.Service {
  $core.String get $name => 'fleetkanban.v1.HarnessAttemptService';

  HarnessAttemptServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.ListHarnessAttemptsResponse>(
        'ListPending',
        listPending_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.ListHarnessAttemptsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListHarnessAttemptsForTaskRequest,
            $0.ListHarnessAttemptsResponse>(
        'ListForTask',
        listForTask_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListHarnessAttemptsForTaskRequest.fromBuffer(value),
        ($0.ListHarnessAttemptsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ApproveHarnessAttemptRequest, $0.HarnessAttempt>(
            'Approve',
            approve_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ApproveHarnessAttemptRequest.fromBuffer(value),
            ($0.HarnessAttempt value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RejectHarnessAttemptRequest, $0.HarnessAttempt>(
            'Reject',
            reject_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RejectHarnessAttemptRequest.fromBuffer(value),
            ($0.HarnessAttempt value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListHarnessAttemptsResponse> listPending_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return listPending($call, await $request);
  }

  $async.Future<$0.ListHarnessAttemptsResponse> listPending(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Future<$0.ListHarnessAttemptsResponse> listForTask_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListHarnessAttemptsForTaskRequest> $request) async {
    return listForTask($call, await $request);
  }

  $async.Future<$0.ListHarnessAttemptsResponse> listForTask(
      $grpc.ServiceCall call, $0.ListHarnessAttemptsForTaskRequest request);

  $async.Future<$0.HarnessAttempt> approve_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ApproveHarnessAttemptRequest> $request) async {
    return approve($call, await $request);
  }

  $async.Future<$0.HarnessAttempt> approve(
      $grpc.ServiceCall call, $0.ApproveHarnessAttemptRequest request);

  $async.Future<$0.HarnessAttempt> reject_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RejectHarnessAttemptRequest> $request) async {
    return reject($call, await $request);
  }

  $async.Future<$0.HarnessAttempt> reject(
      $grpc.ServiceCall call, $0.RejectHarnessAttemptRequest request);
}
