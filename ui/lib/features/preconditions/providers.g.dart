// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current list of precondition states from the sidecar. Family-free: the
/// server returns every known precondition in one call. Autodispose so
/// the next invalidate triggers a fresh check (used by the install flow
/// to re-fetch after winget finishes).

@ProviderFor(preconditions)
final preconditionsProvider = PreconditionsProvider._();

/// Current list of precondition states from the sidecar. Family-free: the
/// server returns every known precondition in one call. Autodispose so
/// the next invalidate triggers a fresh check (used by the install flow
/// to re-fetch after winget finishes).

final class PreconditionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<pb.Precondition>>,
          List<pb.Precondition>,
          FutureOr<List<pb.Precondition>>
        >
    with
        $FutureModifier<List<pb.Precondition>>,
        $FutureProvider<List<pb.Precondition>> {
  /// Current list of precondition states from the sidecar. Family-free: the
  /// server returns every known precondition in one call. Autodispose so
  /// the next invalidate triggers a fresh check (used by the install flow
  /// to re-fetch after winget finishes).
  PreconditionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preconditionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preconditionsHash();

  @$internal
  @override
  $FutureProviderElement<List<pb.Precondition>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<pb.Precondition>> create(Ref ref) {
    return preconditions(ref);
  }
}

String _$preconditionsHash() => r'a3a8dab7493c581859577ad3e2b58f0147740547';

/// Runs the sidecar-side auto-install for [kind]. The RPC blocks until
/// winget (or the equivalent installer) finishes, which can take 1–3
/// minutes — callers must not race with other provider invalidations
/// over that window.

@ProviderFor(InstallPrecondition)
final installPreconditionProvider = InstallPreconditionProvider._();

/// Runs the sidecar-side auto-install for [kind]. The RPC blocks until
/// winget (or the equivalent installer) finishes, which can take 1–3
/// minutes — callers must not race with other provider invalidations
/// over that window.
final class InstallPreconditionProvider
    extends $AsyncNotifierProvider<InstallPrecondition, pb.Precondition?> {
  /// Runs the sidecar-side auto-install for [kind]. The RPC blocks until
  /// winget (or the equivalent installer) finishes, which can take 1–3
  /// minutes — callers must not race with other provider invalidations
  /// over that window.
  InstallPreconditionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installPreconditionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installPreconditionHash();

  @$internal
  @override
  InstallPrecondition create() => InstallPrecondition();
}

String _$installPreconditionHash() =>
    r'b15a1408bcf0139390b5c046ee31c7f74e5be416';

/// Runs the sidecar-side auto-install for [kind]. The RPC blocks until
/// winget (or the equivalent installer) finishes, which can take 1–3
/// minutes — callers must not race with other provider invalidations
/// over that window.

abstract class _$InstallPrecondition extends $AsyncNotifier<pb.Precondition?> {
  FutureOr<pb.Precondition?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<pb.Precondition?>, pb.Precondition?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<pb.Precondition?>, pb.Precondition?>,
              AsyncValue<pb.Precondition?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
