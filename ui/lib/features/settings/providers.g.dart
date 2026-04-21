// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Output-language preference. Persisted on the sidecar (SettingsStore)
/// so changes apply to every Copilot session without a restart. Per-stage
/// prompt customisation lives in the IHR Charter (harness-skill/SKILL.md);
/// this provider only owns the free-form language directive.

@ProviderFor(AgentSettings)
final agentSettingsProvider = AgentSettingsProvider._();

/// Output-language preference. Persisted on the sidecar (SettingsStore)
/// so changes apply to every Copilot session without a restart. Per-stage
/// prompt customisation lives in the IHR Charter (harness-skill/SKILL.md);
/// this provider only owns the free-form language directive.
final class AgentSettingsProvider
    extends $AsyncNotifierProvider<AgentSettings, pb.AgentSettings> {
  /// Output-language preference. Persisted on the sidecar (SettingsStore)
  /// so changes apply to every Copilot session without a restart. Per-stage
  /// prompt customisation lives in the IHR Charter (harness-skill/SKILL.md);
  /// this provider only owns the free-form language directive.
  AgentSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentSettingsHash();

  @$internal
  @override
  AgentSettings create() => AgentSettings();
}

String _$agentSettingsHash() => r'0bd5c116b54434943d97cd84ad6ece344fd51e5d';

/// Output-language preference. Persisted on the sidecar (SettingsStore)
/// so changes apply to every Copilot session without a restart. Per-stage
/// prompt customisation lives in the IHR Charter (harness-skill/SKILL.md);
/// this provider only owns the free-form language directive.

abstract class _$AgentSettings extends $AsyncNotifier<pb.AgentSettings> {
  FutureOr<pb.AgentSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<pb.AgentSettings>, pb.AgentSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<pb.AgentSettings>, pb.AgentSettings>,
              AsyncValue<pb.AgentSettings>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Per-stage model selection. Defaults to empty string meaning "server
/// picks" — the sidecar's Runner already has a preference/fallback list.

@ProviderFor(ModelForStage)
final modelForStageProvider = ModelForStageFamily._();

/// Per-stage model selection. Defaults to empty string meaning "server
/// picks" — the sidecar's Runner already has a preference/fallback list.
final class ModelForStageProvider
    extends $AsyncNotifierProvider<ModelForStage, String> {
  /// Per-stage model selection. Defaults to empty string meaning "server
  /// picks" — the sidecar's Runner already has a preference/fallback list.
  ModelForStageProvider._({
    required ModelForStageFamily super.from,
    required ModelStage super.argument,
  }) : super(
         retry: null,
         name: r'modelForStageProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$modelForStageHash();

  @override
  String toString() {
    return r'modelForStageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ModelForStage create() => ModelForStage();

  @override
  bool operator ==(Object other) {
    return other is ModelForStageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$modelForStageHash() => r'8b99084f232c2030d7e96d99c5c9f1a190f98867';

/// Per-stage model selection. Defaults to empty string meaning "server
/// picks" — the sidecar's Runner already has a preference/fallback list.

final class ModelForStageFamily extends $Family
    with
        $ClassFamilyOverride<
          ModelForStage,
          AsyncValue<String>,
          String,
          FutureOr<String>,
          ModelStage
        > {
  ModelForStageFamily._()
    : super(
        retry: null,
        name: r'modelForStageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Per-stage model selection. Defaults to empty string meaning "server
  /// picks" — the sidecar's Runner already has a preference/fallback list.

  ModelForStageProvider call(ModelStage stage) =>
      ModelForStageProvider._(argument: stage, from: this);

  @override
  String toString() => r'modelForStageProvider';
}

/// Per-stage model selection. Defaults to empty string meaning "server
/// picks" — the sidecar's Runner already has a preference/fallback list.

abstract class _$ModelForStage extends $AsyncNotifier<String> {
  late final _$args = ref.$arg as ModelStage;
  ModelStage get stage => _$args;

  FutureOr<String> build(ModelStage stage);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
