// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalyzerState)
final analyzerStateProvider = AnalyzerStateProvider._();

final class AnalyzerStateProvider
    extends $NotifierProvider<AnalyzerState, AnalyzerStatus> {
  AnalyzerStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyzerStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyzerStateHash();

  @$internal
  @override
  AnalyzerState create() => AnalyzerState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyzerStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyzerStatus>(value),
    );
  }
}

String _$analyzerStateHash() => r'3a355c57232060d89bb6941da82c225542804848';

abstract class _$AnalyzerState extends $Notifier<AnalyzerStatus> {
  AnalyzerStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AnalyzerStatus, AnalyzerStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnalyzerStatus, AnalyzerStatus>,
              AnalyzerStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
