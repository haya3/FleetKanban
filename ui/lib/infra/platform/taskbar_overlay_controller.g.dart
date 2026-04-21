// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taskbar_overlay_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Count of tasks currently in the `in_progress` state across all repos.
/// Refreshes on relevant AgentEvent.kind values via ref.invalidateSelf.

@ProviderFor(RunningTaskCount)
final runningTaskCountProvider = RunningTaskCountProvider._();

/// Count of tasks currently in the `in_progress` state across all repos.
/// Refreshes on relevant AgentEvent.kind values via ref.invalidateSelf.
final class RunningTaskCountProvider
    extends $AsyncNotifierProvider<RunningTaskCount, int> {
  /// Count of tasks currently in the `in_progress` state across all repos.
  /// Refreshes on relevant AgentEvent.kind values via ref.invalidateSelf.
  RunningTaskCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runningTaskCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runningTaskCountHash();

  @$internal
  @override
  RunningTaskCount create() => RunningTaskCount();
}

String _$runningTaskCountHash() => r'5a12f2ca4710d9bfbe31c1bfee7f7e1c6f70ba10';

/// Count of tasks currently in the `in_progress` state across all repos.
/// Refreshes on relevant AgentEvent.kind values via ref.invalidateSelf.

abstract class _$RunningTaskCount extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
