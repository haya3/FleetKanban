// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DagFontScale)
final dagFontScaleProvider = DagFontScaleProvider._();

final class DagFontScaleProvider
    extends $AsyncNotifierProvider<DagFontScale, double> {
  DagFontScaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dagFontScaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dagFontScaleHash();

  @$internal
  @override
  DagFontScale create() => DagFontScale();
}

String _$dagFontScaleHash() => r'ef48f33ffaf42292a21cdc8561cecf9e8bbc6fa6';

abstract class _$DagFontScale extends $AsyncNotifier<double> {
  FutureOr<double> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<double>, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<double>, double>,
              AsyncValue<double>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Tasks scoped to a repository. Family key = repoId; an empty string means
/// "all repos" (mostly useful for diagnostics, not Kanban).
///
/// The WatchEvents subscription auto-reconnects with exponential backoff
/// (1 → 32 s, capped at 30 s) and keeps a per-task high-water-mark of
/// `seq` in [_sinceByTask] so the sidecar can suppress duplicates on
/// reconnect. Every successful reconnect triggers [ref.invalidateSelf]
/// so the post-disconnect state converges on the server-of-truth even if
/// some status events were missed during the gap.

@ProviderFor(Tasks)
final tasksProvider = TasksFamily._();

/// Tasks scoped to a repository. Family key = repoId; an empty string means
/// "all repos" (mostly useful for diagnostics, not Kanban).
///
/// The WatchEvents subscription auto-reconnects with exponential backoff
/// (1 → 32 s, capped at 30 s) and keeps a per-task high-water-mark of
/// `seq` in [_sinceByTask] so the sidecar can suppress duplicates on
/// reconnect. Every successful reconnect triggers [ref.invalidateSelf]
/// so the post-disconnect state converges on the server-of-truth even if
/// some status events were missed during the gap.
final class TasksProvider extends $AsyncNotifierProvider<Tasks, List<pb.Task>> {
  /// Tasks scoped to a repository. Family key = repoId; an empty string means
  /// "all repos" (mostly useful for diagnostics, not Kanban).
  ///
  /// The WatchEvents subscription auto-reconnects with exponential backoff
  /// (1 → 32 s, capped at 30 s) and keeps a per-task high-water-mark of
  /// `seq` in [_sinceByTask] so the sidecar can suppress duplicates on
  /// reconnect. Every successful reconnect triggers [ref.invalidateSelf]
  /// so the post-disconnect state converges on the server-of-truth even if
  /// some status events were missed during the gap.
  TasksProvider._({
    required TasksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tasksProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tasksHash();

  @override
  String toString() {
    return r'tasksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Tasks create() => Tasks();

  @override
  bool operator ==(Object other) {
    return other is TasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tasksHash() => r'c98aebf2577ec091da2b099413789e2ad99108b7';

/// Tasks scoped to a repository. Family key = repoId; an empty string means
/// "all repos" (mostly useful for diagnostics, not Kanban).
///
/// The WatchEvents subscription auto-reconnects with exponential backoff
/// (1 → 32 s, capped at 30 s) and keeps a per-task high-water-mark of
/// `seq` in [_sinceByTask] so the sidecar can suppress duplicates on
/// reconnect. Every successful reconnect triggers [ref.invalidateSelf]
/// so the post-disconnect state converges on the server-of-truth even if
/// some status events were missed during the gap.

final class TasksFamily extends $Family
    with
        $ClassFamilyOverride<
          Tasks,
          AsyncValue<List<pb.Task>>,
          List<pb.Task>,
          FutureOr<List<pb.Task>>,
          String
        > {
  TasksFamily._()
    : super(
        retry: null,
        name: r'tasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Tasks scoped to a repository. Family key = repoId; an empty string means
  /// "all repos" (mostly useful for diagnostics, not Kanban).
  ///
  /// The WatchEvents subscription auto-reconnects with exponential backoff
  /// (1 → 32 s, capped at 30 s) and keeps a per-task high-water-mark of
  /// `seq` in [_sinceByTask] so the sidecar can suppress duplicates on
  /// reconnect. Every successful reconnect triggers [ref.invalidateSelf]
  /// so the post-disconnect state converges on the server-of-truth even if
  /// some status events were missed during the gap.

  TasksProvider call(String repoId) =>
      TasksProvider._(argument: repoId, from: this);

  @override
  String toString() => r'tasksProvider';
}

/// Tasks scoped to a repository. Family key = repoId; an empty string means
/// "all repos" (mostly useful for diagnostics, not Kanban).
///
/// The WatchEvents subscription auto-reconnects with exponential backoff
/// (1 → 32 s, capped at 30 s) and keeps a per-task high-water-mark of
/// `seq` in [_sinceByTask] so the sidecar can suppress duplicates on
/// reconnect. Every successful reconnect triggers [ref.invalidateSelf]
/// so the post-disconnect state converges on the server-of-truth even if
/// some status events were missed during the gap.

abstract class _$Tasks extends $AsyncNotifier<List<pb.Task>> {
  late final _$args = ref.$arg as String;
  String get repoId => _$args;

  FutureOr<List<pb.Task>> build(String repoId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<pb.Task>>, List<pb.Task>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<pb.Task>>, List<pb.Task>>,
              AsyncValue<List<pb.Task>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Generic mutation notifier. Records failures into the shared
/// [actionErrorLogProvider] so the app shell can surface them via an
/// InfoBar — callers should NOT wrap run() in .catchError((_) {}) any more,
/// the notifier owns the error lifecycle.
///
/// State transitions on the notifier are kept so per-card spinners still
/// work (watch state.isLoading). The old contract rethrew the error; we
/// stopped doing that because the caller typically couldn't do anything
/// useful with it and the surfacing now happens globally.

@ProviderFor(TaskMutation)
final taskMutationProvider = TaskMutationFamily._();

/// Generic mutation notifier. Records failures into the shared
/// [actionErrorLogProvider] so the app shell can surface them via an
/// InfoBar — callers should NOT wrap run() in .catchError((_) {}) any more,
/// the notifier owns the error lifecycle.
///
/// State transitions on the notifier are kept so per-card spinners still
/// work (watch state.isLoading). The old contract rethrew the error; we
/// stopped doing that because the caller typically couldn't do anything
/// useful with it and the surfacing now happens globally.
final class TaskMutationProvider
    extends $AsyncNotifierProvider<TaskMutation, void> {
  /// Generic mutation notifier. Records failures into the shared
  /// [actionErrorLogProvider] so the app shell can surface them via an
  /// InfoBar — callers should NOT wrap run() in .catchError((_) {}) any more,
  /// the notifier owns the error lifecycle.
  ///
  /// State transitions on the notifier are kept so per-card spinners still
  /// work (watch state.isLoading). The old contract rethrew the error; we
  /// stopped doing that because the caller typically couldn't do anything
  /// useful with it and the surfacing now happens globally.
  TaskMutationProvider._({
    required TaskMutationFamily super.from,
    required Mutation super.argument,
  }) : super(
         retry: null,
         name: r'taskMutationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskMutationHash();

  @override
  String toString() {
    return r'taskMutationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TaskMutation create() => TaskMutation();

  @override
  bool operator ==(Object other) {
    return other is TaskMutationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskMutationHash() => r'54804de24611488551d5c72c861cfbc94a2a4a99';

/// Generic mutation notifier. Records failures into the shared
/// [actionErrorLogProvider] so the app shell can surface them via an
/// InfoBar — callers should NOT wrap run() in .catchError((_) {}) any more,
/// the notifier owns the error lifecycle.
///
/// State transitions on the notifier are kept so per-card spinners still
/// work (watch state.isLoading). The old contract rethrew the error; we
/// stopped doing that because the caller typically couldn't do anything
/// useful with it and the surfacing now happens globally.

final class TaskMutationFamily extends $Family
    with
        $ClassFamilyOverride<
          TaskMutation,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          Mutation
        > {
  TaskMutationFamily._()
    : super(
        retry: null,
        name: r'taskMutationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Generic mutation notifier. Records failures into the shared
  /// [actionErrorLogProvider] so the app shell can surface them via an
  /// InfoBar — callers should NOT wrap run() in .catchError((_) {}) any more,
  /// the notifier owns the error lifecycle.
  ///
  /// State transitions on the notifier are kept so per-card spinners still
  /// work (watch state.isLoading). The old contract rethrew the error; we
  /// stopped doing that because the caller typically couldn't do anything
  /// useful with it and the surfacing now happens globally.

  TaskMutationProvider call(Mutation kind) =>
      TaskMutationProvider._(argument: kind, from: this);

  @override
  String toString() => r'taskMutationProvider';
}

/// Generic mutation notifier. Records failures into the shared
/// [actionErrorLogProvider] so the app shell can surface them via an
/// InfoBar — callers should NOT wrap run() in .catchError((_) {}) any more,
/// the notifier owns the error lifecycle.
///
/// State transitions on the notifier are kept so per-card spinners still
/// work (watch state.isLoading). The old contract rethrew the error; we
/// stopped doing that because the caller typically couldn't do anything
/// useful with it and the surfacing now happens globally.

abstract class _$TaskMutation extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as Mutation;
  Mutation get kind => _$args;

  FutureOr<void> build(Mutation kind);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Wraps SubmitReview in a stateful Notifier. Errors are recorded into the
/// shared [actionErrorLogProvider] and the notifier's state.error; callers
/// no longer need to .catchError because the app shell surfaces failures
/// globally via an InfoBar.
///
/// Feedback is a required field when action == rework (enforced by sidecar).

@ProviderFor(SubmitReview)
final submitReviewProvider = SubmitReviewProvider._();

/// Wraps SubmitReview in a stateful Notifier. Errors are recorded into the
/// shared [actionErrorLogProvider] and the notifier's state.error; callers
/// no longer need to .catchError because the app shell surfaces failures
/// globally via an InfoBar.
///
/// Feedback is a required field when action == rework (enforced by sidecar).
final class SubmitReviewProvider
    extends $AsyncNotifierProvider<SubmitReview, void> {
  /// Wraps SubmitReview in a stateful Notifier. Errors are recorded into the
  /// shared [actionErrorLogProvider] and the notifier's state.error; callers
  /// no longer need to .catchError because the app shell surfaces failures
  /// globally via an InfoBar.
  ///
  /// Feedback is a required field when action == rework (enforced by sidecar).
  SubmitReviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitReviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitReviewHash();

  @$internal
  @override
  SubmitReview create() => SubmitReview();
}

String _$submitReviewHash() => r'111e555368465dc6392785734c4a3af7c2717c6d';

/// Wraps SubmitReview in a stateful Notifier. Errors are recorded into the
/// shared [actionErrorLogProvider] and the notifier's state.error; callers
/// no longer need to .catchError because the app shell surfaces failures
/// globally via an InfoBar.
///
/// Feedback is a required field when action == rework (enforced by sidecar).

abstract class _$SubmitReview extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
