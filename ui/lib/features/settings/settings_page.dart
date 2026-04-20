// Settings page: concurrency, PAT, default model, Copilot login.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';
import '../auth/sign_in_dialog.dart';
import '../housekeeping/housekeeping_section.dart';
import '../kanban/providers.dart'
    show kanbanRepositoriesProvider, repositoryBranchesProvider;
import 'providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

/// Copilot SDK only accepts `gho_`, `ghu_`, and `github_pat_` prefixed
/// tokens (classic `ghp_` PATs are explicitly not supported — see
/// https://github.com/github/copilot-sdk/blob/main/docs/auth/index.md).
/// The sidecar enforces the same allow-list and will reject bad tokens
/// with InvalidArgument; we validate client-side as well so the user gets
/// feedback before making an RPC round-trip.
const _supportedTokenPrefixes = <String>['gho_', 'ghu_', 'github_pat_'];

String? _validateTokenInput(String token) {
  if (token.isEmpty) return 'Enter a token';
  for (final p in _supportedTokenPrefixes) {
    if (token.startsWith(p)) return null;
  }
  return 'Unsupported format. The Copilot SDK only accepts gho_ / ghu_ / github_pat_ '
      '(classic ghp_ PATs are not supported).';
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _labelController = TextEditingController();
  final _addTokenController = TextEditingController();
  bool _addSetActive = true;
  String? _addError;
  bool _adding = false;

  @override
  void dispose() {
    _labelController.dispose();
    _addTokenController.dispose();
    super.dispose();
  }

  Future<void> _submitAddToken() async {
    final label = _labelController.text.trim();
    final token = _addTokenController.text.trim();
    setState(() => _addError = null);
    if (label.isEmpty) {
      setState(() => _addError = 'Enter a label');
      return;
    }
    final tokenErr = _validateTokenInput(token);
    if (tokenErr != null) {
      setState(() => _addError = tokenErr);
      return;
    }
    setState(() => _adding = true);
    try {
      await addGithubToken(
        ref,
        label: label,
        token: token,
        setActive: _addSetActive,
      );
      if (!mounted) return;
      _labelController.clear();
      _addTokenController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _addError = '$e');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final concurrency = ref.watch(concurrencyProvider);
    final tokenList = ref.watch(githubTokenListProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Settings')),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ListView(
          children: [
            _Section(
              title: 'Concurrency',
              child: concurrency.when(
                loading: () => const SizedBox(height: 40, child: ProgressBar()),
                error: (e, _) => CopyableErrorText(
                  text: '$e',
                  reportTitle: 'Settings / concurrency fetch',
                ),
                data: (n) => Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '$n',
                        value: n.toDouble(),
                        onChanged: (_) {},
                        onChangeEnd: (v) => setConcurrency(ref, v.round()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 36,
                      child: Text('$n', textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            ),
            const _Section(
              title: 'Registered repositories',
              subtitle:
                  'Without a pinned base branch, FleetKanban falls back to auto-detection '
                  '(origin/HEAD → main → master → HEAD). Only pin repositories where you '
                  'always want to branch off a specific base.',
              child: _RegisteredRepositoryList(),
            ),
            const _Section(
              title: 'Models (per stage)',
              subtitle:
                  'In Phase 1 only the Code stage model is used at runtime. '
                  'Plan / Review values are stored in preparation for future stage separation.',
              child: _StageModelPickers(),
            ),
            _Section(
              title: 'GitHub access tokens (multiple saved, labeled)',
              subtitle:
                  'Encrypted locally with DPAPI. The token with the active label is passed to the Copilot SDK.\n'
                  'Supported formats: gho_ (OAuth user) / ghu_ (GitHub App user) / github_pat_ (fine-grained PAT). '
                  'Classic ghp_ PATs are rejected because the Copilot SDK does not support them.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tokenList.when(
                    loading: () =>
                        const SizedBox(height: 40, child: ProgressBar()),
                    error: (e, _) => CopyableErrorText(
                      text: '$e',
                      reportTitle: 'Settings / GitHub token list fetch',
                    ),
                    data: (resp) => _TokenTable(
                      tokens: resp.tokens,
                      onSetActive: (label) async =>
                          setActiveGithubToken(ref, label),
                      onRemove: (label) async => removeGithubToken(ref, label),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextBox(
                          controller: _labelController,
                          placeholder: 'Label (e.g. work)',
                          enabled: !_adding,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextBox(
                          controller: _addTokenController,
                          placeholder: 'gho_... / github_pat_...',
                          obscureText: true,
                          enabled: !_adding,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        checked: _addSetActive,
                        onChanged: _adding
                            ? null
                            : (v) => setState(() => _addSetActive = v ?? false),
                        content: const Text('Make active'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _adding ? null : _submitAddToken,
                        child: _adding
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: ProgressRing(strokeWidth: 2),
                              )
                            : const Text('Add'),
                      ),
                    ],
                  ),
                  if (_addError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ErrorInfoBar(
                        title: 'Could not add token',
                        message: _addError!,
                      ),
                    ),
                ],
              ),
            ),
            const _CopilotAuthSection(),
            const HousekeepingSection(),
          ],
        ),
      ),
    );
  }
}

class _TokenTable extends StatelessWidget {
  const _TokenTable({
    required this.tokens,
    required this.onSetActive,
    required this.onRemove,
  });

  final List<pb.GitHubTokenEntry> tokens;
  final Future<void> Function(String label) onSetActive;
  final Future<void> Function(String label) onRemove;

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No saved PATs'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in tokens)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: t.active ? const Icon(FluentIcons.check_mark) : null,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(t.label)),
                Button(
                  onPressed: t.active ? null : () => onSetActive(t.label),
                  child: const Text('Make active'),
                ),
                const SizedBox(width: 4),
                Button(
                  onPressed: () => onRemove(t.label),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StageModelPickers extends ConsumerWidget {
  const _StageModelPickers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(availableModelsProvider);
    return available.when(
      loading: () => const SizedBox(height: 40, child: ProgressBar()),
      error: (e, _) => CopyableErrorText(
        text: 'Failed to load model list: $e',
        reportTitle: 'Settings / model list fetch',
      ),
      data: (models) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (models.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InfoBar(
                  title: const Text('Cannot load model list'),
                  content: const Text(
                    'Either Copilot is not signed in, or ListModels from the SDK failed. Manually entered IDs are still saved, but will fall back to ListModels at runtime.',
                  ),
                  severity: InfoBarSeverity.warning,
                ),
              ),
            for (final stage in ModelStage.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _StagePickerRow(stage: stage, available: models),
              ),
          ],
        );
      },
    );
  }
}

class _StagePickerRow extends ConsumerWidget {
  const _StagePickerRow({required this.stage, required this.available});
  final ModelStage stage;
  final List<pb.ModelInfo> available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(modelForStageProvider(stage));
    final label = switch (stage) {
      ModelStage.plan => 'Plan',
      ModelStage.code => 'Code',
      ModelStage.review => 'Review',
    };
    // Dropdown includes every available model plus a "(auto)" option that
    // clears the stored value and lets the sidecar runner pick. The stored
    // value is preserved even if it's no longer in the live catalog so the
    // user sees the rotted-out ID and can deliberately re-select.
    final ids = available.map((m) => m.id).toList(growable: false);
    final options = <String>['', ...ids];
    final savedValue = saved.valueOrNull;
    if (savedValue != null &&
        savedValue.isNotEmpty &&
        !ids.contains(savedValue)) {
      options.add(savedValue);
    }
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: FluentTheme.of(context).typography.body),
        ),
        Expanded(
          child: saved.when(
            loading: () => const ProgressBar(),
            error: (e, _) => CopyableErrorText(
              text: '$e',
              reportTitle: 'Settings / model ($label)',
            ),
            data: (current) => ComboBox<String>(
              value: options.contains(current) ? current : '',
              isExpanded: true,
              items: [
                for (final id in options)
                  ComboBoxItem(
                    value: id,
                    child: _ModelOptionRow(
                      id: id,
                      info: id.isEmpty
                          ? null
                          : available.firstWhere(
                              (m) => m.id == id,
                              orElse: () => pb.ModelInfo(id: id),
                            ),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(modelForStageProvider(stage).notifier).set(v);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

// _ModelOptionRow renders one ComboBoxItem for the stage picker. Layout:
//
//   [model name / id ............. trailing....] [Free | ×N]
//
// The trailing badge encodes Copilot's premium-request multiplier so the
// user can pick a model with full awareness of billing impact:
//   • multiplier == 0 → green "Free"   (no premium request charged)
//   • multiplier  < 1 → blue  "×0.33"  (fractional premium request)
//   • multiplier == 1 → orange "×1"    (one premium request per call)
//   • multiplier  > 1 → red    "×N"    (multiple premium requests per call,
//                                         e.g. Claude Opus 4.x at ×10)
class _ModelOptionRow extends StatelessWidget {
  const _ModelOptionRow({required this.id, required this.info});
  final String id;
  final pb.ModelInfo? info;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    if (id.isEmpty) {
      return const Text('(auto-select)');
    }
    final i = info!;
    final display = i.name.isNotEmpty ? i.name : i.id;
    return Row(
      children: [
        Expanded(child: Text(display, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        _MultiplierBadge(multiplier: i.multiplier, theme: theme),
      ],
    );
  }
}

class _MultiplierBadge extends StatelessWidget {
  const _MultiplierBadge({required this.multiplier, required this.theme});
  final double multiplier;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _badgeFor(multiplier);
    return Tooltip(
      message: multiplier == 0
          ? 'Does not consume a premium request (included in plan)'
          : 'Consumes ×$multiplier premium request(s) per call',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  static (String, Color) _badgeFor(double m) {
    if (m == 0) return ('Free', const Color(0xFF107C10));
    if (m < 1) return ('×${_fmt(m)}', const Color(0xFF005FB8));
    if (m == 1) return ('×1', const Color(0xFFC29C00));
    return ('×${_fmt(m)}', const Color(0xFFC42B1C));
  }

  // _fmt drops the trailing ".0" on whole-number multipliers (×10 not ×10.0)
  // while keeping precision on fractional ones (×0.33 stays ×0.33).
  static String _fmt(double m) {
    if (m == m.truncateToDouble()) return m.toStringAsFixed(0);
    return m.toString();
  }
}

class _RegisteredRepositoryList extends ConsumerWidget {
  const _RegisteredRepositoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositories = ref.watch(kanbanRepositoriesProvider);
    return repositories.when(
      loading: () => const SizedBox(height: 40, child: ProgressBar()),
      error: (e, _) =>
          CopyableErrorText(text: '$e', reportTitle: 'Settings / registered repositories fetch'),
      data: (repos) {
        if (repos.isEmpty) {
          return const Text('No repositories registered yet.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final r in repos) _RepoPinRow(repo: r)],
        );
      },
    );
  }
}

class _RepoPinRow extends ConsumerStatefulWidget {
  const _RepoPinRow({required this.repo});
  final pb.Repository repo;

  @override
  ConsumerState<_RepoPinRow> createState() => _RepoPinRowState();
}

class _RepoPinRowState extends ConsumerState<_RepoPinRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.repo.defaultBaseBranch,
  );
  bool _busy = false;
  bool _seeding = false;
  String? _error;

  @override
  void didUpdateWidget(_RepoPinRow old) {
    super.didUpdateWidget(old);
    if (old.repo.defaultBaseBranch != widget.repo.defaultBaseBranch &&
        _controller.text != widget.repo.defaultBaseBranch) {
      _controller.text = widget.repo.defaultBaseBranch;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply(String branch) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await updateDefaultBaseBranch(
        ref,
        repositoryId: widget.repo.id,
        branch: branch,
      );
      if (mounted) {
        setState(() {
          _busy = false;
          if (branch.isEmpty) _controller.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  Future<void> _createInitialCommit() async {
    setState(() {
      _seeding = true;
      _error = null;
    });
    try {
      await createInitialCommit(ref, repositoryId: widget.repo.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final pinned = widget.repo.defaultBaseBranch.isNotEmpty;
    final branches = ref.watch(repositoryBranchesProvider(widget.repo.id));
    // Treat loading / errors as "assume normal repo" so the banner doesn't
    // flicker on every rebuild — the actual git probe is cheap but runs async.
    final hasCommits = branches.maybeWhen(
      data: (r) => r.hasCommits,
      orElse: () => true,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.repo.displayName,
                      style: theme.typography.bodyStrong,
                    ),
                    Text(
                      widget.repo.path,
                      style: theme.typography.caption?.copyWith(
                        color: theme.resources.textFillColorSecondary,
                        fontFamily: 'Consolas',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: TextBox(
                  controller: _controller,
                  placeholder: pinned ? null : 'auto-detect',
                  enabled: !_busy,
                  onSubmitted: (v) => _apply(v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => _apply(_controller.text.trim()),
                child: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: ProgressRing(strokeWidth: 2),
                      )
                    : const Text('Save pin'),
              ),
              const SizedBox(width: 4),
              Button(
                onPressed: (_busy || !pinned) ? null : () => _apply(''),
                child: const Text('Reset to auto-detect'),
              ),
            ],
          ),
          if (!hasCommits)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InfoBar(
                title: const Text('This repository has no commits'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The repository is fresh from `git init`. Without a commit, '
                      'no base branch can be resolved and tasks cannot be created. '
                      'Seed an empty commit authored by FleetKanban to initialize it.',
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _seeding ? null : _createInitialCommit,
                      child: _seeding
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: ProgressRing(strokeWidth: 2),
                            )
                          : const Text('Create initial commit'),
                    ),
                  ],
                ),
                severity: InfoBarSeverity.warning,
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ErrorInfoBar(title: 'Failed to update base branch', message: _error!),
            ),
        ],
      ),
    );
  }
}

/// Copilot /login /logout controls. Kept out of the main SettingsPage
/// [build] because the buttons need per-action busy state and need to
/// surface sidecar / gRPC errors (previously swallowed, which looked like
/// "the buttons do nothing" to the user).
class _CopilotAuthSection extends ConsumerStatefulWidget {
  const _CopilotAuthSection();

  @override
  ConsumerState<_CopilotAuthSection> createState() =>
      _CopilotAuthSectionState();
}

enum _AuthBusy { none, login, logout, recheck }

class _CopilotAuthSectionState extends ConsumerState<_CopilotAuthSection> {
  _AuthBusy _busy = _AuthBusy.none;
  String? _actionError;
  String? _actionErrorTitle;

  Future<void> _run(
    _AuthBusy kind,
    String errorTitle,
    Future<void> Function() action,
  ) async {
    if (_busy != _AuthBusy.none) return;
    setState(() {
      _busy = kind;
      _actionError = null;
      _actionErrorTitle = null;
    });
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(copilotAuthProvider);
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _actionErrorTitle = errorTitle;
        _actionError = '$e\n$st';
      });
    } finally {
      if (mounted) setState(() => _busy = _AuthBusy.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(copilotAuthProvider);
    final subtitle = auth.when(
      data: (a) => a.authenticated
          ? 'Signed in as ${a.user}'
          : (a.message.isNotEmpty ? 'Not authenticated — ${a.message}' : 'Not authenticated'),
      loading: () => 'Checking…',
      error: (e, _) => 'Failed to fetch status: $e',
    );
    final disabled = _busy != _AuthBusy.none;
    return _Section(
      title: 'Copilot authentication',
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (auth is AsyncError)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ErrorInfoBar(
                title: 'Failed to fetch Copilot auth status',
                message: '${auth.error}\n${auth.stackTrace}',
              ),
            ),
          if (_actionError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ErrorInfoBar(
                title: _actionErrorTitle ?? 'Action failed',
                message: _actionError!,
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: disabled
                    ? null
                    : () async {
                        setState(() {
                          _busy = _AuthBusy.login;
                          _actionError = null;
                          _actionErrorTitle = null;
                        });
                        try {
                          final ok = await showCopilotSignInDialog(
                            context,
                            ref,
                          );
                          if (!mounted) return;
                          if (ok) ref.invalidate(copilotAuthProvider);
                        } finally {
                          if (mounted) {
                            setState(() => _busy = _AuthBusy.none);
                          }
                        }
                      },
                child: _AuthButtonLabel(
                  text: 'Sign in',
                  busy: _busy == _AuthBusy.login,
                ),
              ),
              Button(
                onPressed: disabled
                    ? null
                    : () => _run(
                        _AuthBusy.logout,
                        'Failed to launch sign-out terminal',
                        () async => startCopilotLogout(ref),
                      ),
                child: _AuthButtonLabel(
                  text: '/logout in terminal',
                  busy: _busy == _AuthBusy.logout,
                ),
              ),
              Button(
                onPressed: disabled
                    ? null
                    : () =>
                          _run(_AuthBusy.recheck, 'Failed to re-check auth status', () async {
                            ref.invalidate(copilotAuthProvider);
                            await ref.read(copilotAuthProvider.future);
                          }),
                child: _AuthButtonLabel(
                  text: 'Re-check',
                  busy: _busy == _AuthBusy.recheck,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sign-in uses Device Flow. Pressing the button opens your '
            'browser automatically with the code already filled in on the '
            'authorize page. Sign-out is the only flow without a headless '
            'path in the Copilot CLI, so it still drops into a short-lived '
            'terminal to run /logout.',
            style: FluentTheme.of(context).typography.caption?.copyWith(
              color: FluentTheme.of(context).resources.textFillColorSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButtonLabel extends StatelessWidget {
  const _AuthButtonLabel({required this.text, required this.busy});
  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (!busy) return Text(text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: ProgressRing(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.typography.subtitle),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
            ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
