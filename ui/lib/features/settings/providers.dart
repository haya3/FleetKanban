// Settings feature state: concurrency, GitHub PAT, default model.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;
import 'package:shared_preferences/shared_preferences.dart';

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';
import '../kanban/providers.dart'
    show kanbanRepositoriesProvider, repositoryBranchesProvider;

/// Built-in default agent prompts, fetched from the sidecar. Used by
/// the Settings page to pre-populate each editor with the full default
/// text so the user can see exactly what the planner / runner /
/// reviewer will use when no override is saved.
final defaultAgentPromptsProvider = FutureProvider<pb.AgentSettings>((
  ref,
) async {
  final client = ref.watch(ipcClientProvider);
  return client.system.getDefaultAgentPrompts(Empty());
});

/// Agent prompt + output language overrides. Persisted on the sidecar
/// (SettingsStore) so changes apply to every Copilot session without a
/// restart. The UI exposes 3 multi-line text fields and 1 single-line
/// language field.
final agentSettingsProvider =
    AsyncNotifierProvider<AgentSettingsNotifier, pb.AgentSettings>(
      AgentSettingsNotifier.new,
    );

class AgentSettingsNotifier extends AsyncNotifier<pb.AgentSettings> {
  @override
  Future<pb.AgentSettings> build() async {
    final client = ref.watch(ipcClientProvider);
    return client.system.getAgentSettings(Empty());
  }

  Future<void> save({
    String? planPrompt,
    String? codePrompt,
    String? reviewPrompt,
    String? outputLanguage,
  }) async {
    final client = ref.read(ipcClientProvider);
    final current = state.valueOrNull ?? pb.AgentSettings();
    final next = pb.AgentSettings(
      planPrompt: planPrompt ?? current.planPrompt,
      codePrompt: codePrompt ?? current.codePrompt,
      reviewPrompt: reviewPrompt ?? current.reviewPrompt,
      outputLanguage: outputLanguage ?? current.outputLanguage,
    );
    state = const AsyncLoading();
    try {
      final saved = await client.system.setAgentSettings(next);
      state = AsyncData(saved);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// Concurrency value as reported by the orchestrator.
final concurrencyProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(ipcClientProvider);
  final v = await client.system.getConcurrency(Empty());
  return v.value;
});

/// Full list of labelled tokens + active label (for the account switcher).
final githubTokenListProvider = FutureProvider<pb.ListGitHubTokensResponse>((
  ref,
) async {
  final client = ref.watch(ipcClientProvider);
  return client.auth.listGitHubTokens(Empty());
});

/// Pipeline stage → SharedPreferences key. Phase 1 only consumes the Code
/// model at task-run time; Plan and Review models are stored so we can wire
/// them up to dedicated SDK sessions in a future phase without another
/// settings migration.
enum ModelStage { plan, code, review }

const Map<ModelStage, String> _modelPrefKey = {
  ModelStage.plan: 'fleetkanban.model.plan',
  ModelStage.code: 'fleetkanban.model.code',
  ModelStage.review: 'fleetkanban.model.review',
};

/// Live catalog of models advertised by the Copilot SDK. Fetched via the
/// sidecar's ModelService; empty list on error so the UI can render a
/// fallback picker with the stored value highlighted. Each entry carries
/// the premium-request multiplier so the picker can flag Free vs Premium ×N.
final availableModelsProvider = FutureProvider<List<pb.ModelInfo>>((ref) async {
  final client = ref.watch(ipcClientProvider);
  try {
    final resp = await client.model.listModels(Empty());
    return resp.models;
  } catch (_) {
    return const <pb.ModelInfo>[];
  }
});

/// Per-stage model selection. Defaults to empty string meaning "server
/// picks" — the sidecar's Runner already has a preference/fallback list.
final modelForStageProvider =
    AsyncNotifierProvider.family<StageModelNotifier, String, ModelStage>(
      StageModelNotifier.new,
    );

class StageModelNotifier extends FamilyAsyncNotifier<String, ModelStage> {
  @override
  Future<String> build(ModelStage stage) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelPrefKey[stage]!) ?? '';
  }

  Future<void> set(String value) async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPrefKey[arg]!, value);
    state = AsyncData(value);
  }
}

/// Backwards-compat alias: legacy callers that asked for "the default
/// model" get the Code stage, which is the one the Phase 1 runner actually
/// uses when creating a Copilot session.
final defaultModelProvider = modelForStageProvider(ModelStage.code);

Future<int> setConcurrency(WidgetRef ref, int n) async {
  final client = ref.read(ipcClientProvider);
  final v = await client.system.setConcurrency(pb.IntValue(value: n));
  ref.invalidate(concurrencyProvider);
  return v.value;
}

Future<void> addGithubToken(
  WidgetRef ref, {
  required String label,
  required String token,
  required bool setActive,
}) async {
  final client = ref.read(ipcClientProvider);
  await client.auth.addGitHubToken(
    pb.AddGitHubTokenRequest(label: label, token: token, setActive: setActive),
  );
  ref.invalidate(githubTokenListProvider);
  ref.invalidate(copilotAuthProvider);
}

Future<void> removeGithubToken(WidgetRef ref, String label) async {
  final client = ref.read(ipcClientProvider);
  await client.auth.removeGitHubToken(pb.GitHubTokenLabelRequest(label: label));
  ref.invalidate(githubTokenListProvider);
  ref.invalidate(copilotAuthProvider);
}

Future<void> setActiveGithubToken(WidgetRef ref, String label) async {
  final client = ref.read(ipcClientProvider);
  await client.auth.setActiveGitHubToken(
    pb.GitHubTokenLabelRequest(label: label),
  );
  ref.invalidate(githubTokenListProvider);
  ref.invalidate(copilotAuthProvider);
}

/// Starts a headless `copilot login` on the sidecar and returns the device
/// code + verification URL the UI should display. The sidecar has already
/// opened the pre-filled URL in the default browser by the time this
/// returns; the button in the dialog is just a retry / manual-open hook.
///
/// The caller polls [copilotAuthProvider] to detect completion, and MUST
/// call [cancelCopilotLogin] if the user dismisses the dialog before
/// completing — otherwise the subprocess lingers in the background.
Future<pb.CopilotLoginChallenge> beginCopilotLogin(WidgetRef ref) async {
  final client = ref.read(ipcClientProvider);
  return client.auth.beginCopilotLogin(Empty());
}

Future<void> cancelCopilotLogin(WidgetRef ref) async {
  final client = ref.read(ipcClientProvider);
  await client.auth.cancelCopilotLogin(Empty());
}

/// Polls the sidecar for the current `copilot login` subprocess state. The
/// sign-in dialog uses this instead of [copilotAuthProvider] because the SDK
/// client can still report authenticated=true from the previous session
/// while a new login is in flight (ReloadAuth only runs on subprocess
/// success) — polling subprocess state avoids that false-positive close.
Future<pb.CopilotLoginSessionInfo> getCopilotLoginSession(WidgetRef ref) async {
  final client = ref.read(ipcClientProvider);
  return client.auth.getCopilotLoginSession(Empty());
}

Future<void> startCopilotLogout(WidgetRef ref) async {
  final client = ref.read(ipcClientProvider);
  await client.auth.startCopilotLogout(Empty());
}

/// Pin (or clear) a repository's default base branch. Empty [branch] returns
/// the repo to auto-detect mode (sidecar picks origin/HEAD → main → master
/// → HEAD at CreateTask time). Non-empty values are validated server-side;
/// the call throws if the branch doesn't exist in the repository.
Future<void> updateDefaultBaseBranch(
  WidgetRef ref, {
  required String repositoryId,
  required String branch,
}) async {
  final client = ref.read(ipcClientProvider);
  await client.repository.updateDefaultBaseBranch(
    pb.UpdateDefaultBaseBranchRequest(
      repositoryId: repositoryId,
      defaultBaseBranch: branch,
    ),
  );
  ref.invalidate(kanbanRepositoriesProvider);
}

/// Seed an unborn-HEAD repository with an empty root commit so CreateTask
/// can resolve a base branch. Throws (FailedPrecondition) if the repo
/// already has commits; callers should refresh [repositoryBranchesProvider]
/// (defined in features/kanban/providers.dart — shared with the new-task
/// dialog) to get the updated hasCommits flag.
Future<void> createInitialCommit(
  WidgetRef ref, {
  required String repositoryId,
}) async {
  final client = ref.read(ipcClientProvider);
  await client.repository.createInitialCommit(pb.IdRequest(id: repositoryId));
  ref.invalidate(repositoryBranchesProvider(repositoryId));
  ref.invalidate(kanbanRepositoriesProvider);
}
