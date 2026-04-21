// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Snapshot of every worktree across all registered repositories. The list is
/// re-fetched via `ref.invalidate(worktreesProvider)` — there is no streaming
/// source for worktree state (unlike task events).

@ProviderFor(worktrees)
final worktreesProvider = WorktreesProvider._();

/// Snapshot of every worktree across all registered repositories. The list is
/// re-fetched via `ref.invalidate(worktreesProvider)` — there is no streaming
/// source for worktree state (unlike task events).

final class WorktreesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<pb.WorktreeEntry>>,
          List<pb.WorktreeEntry>,
          FutureOr<List<pb.WorktreeEntry>>
        >
    with
        $FutureModifier<List<pb.WorktreeEntry>>,
        $FutureProvider<List<pb.WorktreeEntry>> {
  /// Snapshot of every worktree across all registered repositories. The list is
  /// re-fetched via `ref.invalidate(worktreesProvider)` — there is no streaming
  /// source for worktree state (unlike task events).
  WorktreesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'worktreesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$worktreesHash();

  @$internal
  @override
  $FutureProviderElement<List<pb.WorktreeEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<pb.WorktreeEntry>> create(Ref ref) {
    return worktrees(ref);
  }
}

String _$worktreesHash() => r'0684f36734f0522aa81af330d753799025db9df0';

/// Remove mutation. Handles both fleetkanban/ worktrees (optionally deleting
/// the branch too) and orphan directories. Callers can `await` to block on
/// completion and surface errors.

@ProviderFor(RemoveWorktree)
final removeWorktreeProvider = RemoveWorktreeProvider._();

/// Remove mutation. Handles both fleetkanban/ worktrees (optionally deleting
/// the branch too) and orphan directories. Callers can `await` to block on
/// completion and surface errors.
final class RemoveWorktreeProvider
    extends $AsyncNotifierProvider<RemoveWorktree, void> {
  /// Remove mutation. Handles both fleetkanban/ worktrees (optionally deleting
  /// the branch too) and orphan directories. Callers can `await` to block on
  /// completion and surface errors.
  RemoveWorktreeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'removeWorktreeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$removeWorktreeHash();

  @$internal
  @override
  RemoveWorktree create() => RemoveWorktree();
}

String _$removeWorktreeHash() => r'9a3109ba82dff0180cf1bba48c894c920f97c7ab';

/// Remove mutation. Handles both fleetkanban/ worktrees (optionally deleting
/// the branch too) and orphan directories. Callers can `await` to block on
/// completion and surface errors.

abstract class _$RemoveWorktree extends $AsyncNotifier<void> {
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
