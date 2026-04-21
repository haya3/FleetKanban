// AppShell is the FluentApp root: NavigationView sidebar (7 main + 3 footer
// items). Unimplemented panes render a ComingSoonPage so the final navigation
// structure is visible from Phase 1.

import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:window_manager/window_manager.dart';

import '../features/auth/auth_banner.dart';
import '../infra/ipc/providers.dart';
import 'error_display.dart';
import 'version.dart';
import '../features/auth/auth_gate.dart';
import '../features/context/context_page.dart';
import '../features/harness/harness_page.dart';
import '../features/insights/insights_page.dart';
import '../features/kanban/kanban_page.dart';
import '../features/kanban/providers.dart' as kanban;
import '../features/placeholder/coming_soon_page.dart';
import '../features/preconditions/precondition_dialog.dart';
import '../features/review/review_page.dart';
import '../features/settings/settings_page.dart';
import '../features/status/status_page.dart';
import '../features/worktrees/worktrees_page.dart';
import 'theme.dart';
import 'updater/updater_service.dart';

/// Currently selected NavigationView pane index.
final paneIndexProvider = StateProvider<int>((_) => 0);

class FleetKanbanApp extends ConsumerWidget {
  const FleetKanbanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      title: 'FleetKanban',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: buildFluentTheme(Brightness.light),
      darkTheme: buildFluentTheme(Brightness.dark),
      home: const PreconditionHost(child: AuthGate(child: _AppScaffold())),
    );
  }
}

// Windows-11-style caption buttons (min / max / close). Draws its own
// hover / press states so the close button can go red while the other two
// pick up the Fluent subtle fills. Size matches the OS default (46×32).
class _CaptionButtons extends StatefulWidget {
  const _CaptionButtons({required this.theme});
  final FluentThemeData theme;

  @override
  State<_CaptionButtons> createState() => _CaptionButtonsState();
}

class _CaptionButtonsState extends State<_CaptionButtons> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _isMaximized = v);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CaptionButton(
          icon: '\uE921', // Segoe Fluent Icons: ChromeMinimize
          theme: widget.theme,
          onPressed: () => windowManager.minimize(),
        ),
        _CaptionButton(
          icon: _isMaximized ? '\uE923' : '\uE922', // Restore : Maximize
          theme: widget.theme,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _CaptionButton(
          icon: '\uE8BB', // ChromeClose
          theme: widget.theme,
          isClose: true,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.theme,
    required this.onPressed,
    this.isClose = false,
  });
  final String icon;
  final FluentThemeData theme;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final hoverFill = widget.isClose
        ? const Color(0xFFC42B1C)
        : theme.resources.subtleFillColorSecondary;
    final pressFill = widget.isClose
        ? const Color(0xFF8A1C12)
        : theme.resources.subtleFillColorTertiary;
    final bg = _press
        ? pressFill
        : _hover
        ? hoverFill
        : Colors.transparent;
    final fg = (widget.isClose && (_hover || _press))
        ? Colors.white
        : theme.resources.textFillColorPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _press = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _press = true),
        onTapCancel: () => setState(() => _press = false),
        onTap: () {
          setState(() => _press = false);
          widget.onPressed();
        },
        child: Container(
          width: 46,
          height: 32,
          color: bg,
          alignment: Alignment.center,
          child: Text(
            widget.icon,
            style: TextStyle(
              fontFamily: 'Segoe Fluent Icons',
              fontSize: 10,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppScaffold extends ConsumerWidget {
  const _AppScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(paneIndexProvider);

    final theme = FluentTheme.of(context);
    // bitsdojo_window strips the native Windows chrome, so the min / max /
    // close buttons are gone unless we render them ourselves. Using
    // NavigationView's `titleBar` slot with a Row of caption buttons runs
    // afoul of fluent_ui's internal _TitleSubtitleOverflow (it dry-lays the
    // title against unbounded width, which Expanded children reject), so we
    // stack the custom caption row above a NavigationView that has no
    // titleBar of its own.
    return Column(
      children: [
        Container(
          height: 32,
          color: theme.micaBackgroundColor,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Center(
                  child: Text(
                    'FleetKanban',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () async {
                    if (await windowManager.isMaximized()) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                  },
                  child: const DragToMoveArea(child: SizedBox.expand()),
                ),
              ),
              _CaptionButtons(theme: theme),
            ],
          ),
        ),
        const _VersionMismatchBanner(),
        const _UpdateAvailableBanner(),
        const _StreamHealthBanner(),
        const _ActionErrorBanners(),
        Expanded(child: _buildNavigation(context, ref, selected)),
      ],
    );
  }

  Widget _buildNavigation(BuildContext context, WidgetRef ref, int selected) {
    return NavigationView(
      pane: NavigationPane(
        selected: selected,
        onChanged: (i) => ref.read(paneIndexProvider.notifier).state = i,
        displayMode: PaneDisplayMode.expanded,
        toggleable: false,
        toggleButton: null,
        // headerHeight must be set explicitly whenever size is non-null:
        // fluent_ui defaults it to kOneLineTileHeight (~40 px), which is
        // too short for our AuthBanner (avatar row + quota line ≈ 80 px),
        // clipping the user info and producing a vertical RenderFlex
        // overflow warning.
        size: const NavigationPaneSize(openWidth: 200, headerHeight: 100),
        header: const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: AuthBanner(),
        ),
        items: <NavigationPaneItem>[
          PaneItem(
            icon: const Icon(FluentIcons.task_group),
            title: const Text('Kanban Board'),
            body: const KanbanPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.b_i_dashboard),
            title: const Text('Insights'),
            body: const InsightsPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.library),
            title: const Text('Context'),
            body: const ContextPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.plug_connected),
            title: const Text('MCP Overview'),
            body: const ComingSoonPage(
              title: 'MCP Overview',
              phase: 'Planned for Phase 2',
              description:
                  'GUI for viewing and editing the MCP server configuration at ~/.copilot/mcp-config.json. Shows per-server status, exposed tools, and recent invocations.',
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.branch_fork),
            title: const Text('Worktrees'),
            body: const WorktreesPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.bug),
            title: const Text('GitHub Issues'),
            body: const ComingSoonPage(
              title: 'GitHub Issues',
              phase: 'Planned for Phase 2',
              description:
                  'Import GitHub Issues and link them to Kanban tasks. Auto-close on completion is disabled by default and opt-in only.',
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.git_graph),
            title: const Text('GitHub PRs'),
            body: const ComingSoonPage(
              title: 'GitHub PRs',
              phase: 'Planned for Phase 2',
              description:
                  'Drafts PR bodies from the agent summary and diff highlights. Creation only runs on explicit user approval — the app never pushes or opens PRs on its own.',
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.edit_note),
            title: const Text('Harness'),
            body: const HarnessPage(),
          ),
        ],
        footerItems: <NavigationPaneItem>[
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.diff_inline),
            title: const Text('Review'),
            body: const ReviewPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.health),
            title: const Text('Status'),
            body: const StatusPage(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: const SettingsPage(),
          ),
        ],
      ),
    );
  }
}

/// _VersionMismatchBanner renders an InfoBar when the running sidecar's
/// ProtocolVersion differs from the UI's compiled-in expectation. The
/// supervisor auto-kills mismatched sidecars on startup, so this banner
/// mostly catches the "binary replaced mid-run" case (user rebuilt the
/// sidecar while the UI was still running). The Restart button closes
/// the UI; the user's Start-menu / taskbar shortcut relaunches it, and
/// the fresh UI then spawns the fresh sidecar.
class _VersionMismatchBanner extends ConsumerWidget {
  const _VersionMismatchBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(versionInfoProvider);
    return versionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (v) {
        if (v.protocolVersion == expectedSidecarProtocolVersion) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: InfoBar(
            title: const Text('Sidecar protocol version mismatch'),
            content: Text(
              'UI expects v$expectedSidecarProtocolVersion but the running sidecar '
              'reports v${v.protocolVersion}. Some features may misbehave or '
              'silently drop data. Restart FleetKanban to pick up the fresh binary.',
            ),
            severity: InfoBarSeverity.warning,
            isIconVisible: true,
            action: FilledButton(
              onPressed: () async {
                try {
                  await ref.read(supervisorProvider).kill();
                } catch (_) {
                  // Best-effort; we're exiting anyway.
                }
                exit(0);
              },
              child: const Text('Restart'),
            ),
          ),
        );
      },
    );
  }
}

/// _UpdateAvailableBanner surfaces a Velopack-driven "update available"
/// prompt. It only fires inside an installed build (Update.exe next to
/// the install root); `flutter run` skips this banner entirely. Clicking
/// the button shuts the sidecar down and hands off to Update.exe, which
/// swaps the binaries and relaunches.
class _UpdateAvailableBanner extends ConsumerStatefulWidget {
  const _UpdateAvailableBanner();

  @override
  ConsumerState<_UpdateAvailableBanner> createState() =>
      _UpdateAvailableBannerState();
}

class _UpdateAvailableBannerState
    extends ConsumerState<_UpdateAvailableBanner> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    final asyncCheck = ref.watch(updateCheckProvider);
    return asyncCheck.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (result) {
        if (!result.available) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: InfoBar(
            title: const Text('Update available'),
            content: Text(
              'FleetKanban ${result.latestVersion ?? ''} is ready to install. '
              'The app will restart once the update applies.',
            ),
            severity: InfoBarSeverity.info,
            isIconVisible: true,
            action: FilledButton(
              onPressed: _applying
                  ? null
                  : () async {
                      setState(() => _applying = true);
                      try {
                        await applyUpdateAndRestart(ref, result);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _applying = false);
                        if (!context.mounted) return;
                        await displayInfoBar(
                          context,
                          builder: (context, close) => InfoBar(
                            title: const Text('Update failed'),
                            content: Text('$e'),
                            severity: InfoBarSeverity.error,
                            onClose: close,
                          ),
                        );
                      }
                    },
              child: Text(_applying ? 'Applying…' : 'Install and restart'),
            ),
          ),
        );
      },
    );
  }
}

/// _StreamHealthBanner renders an InfoBar while the WatchEvents stream is
/// disconnected or still coming up. Without this, a crashed stream would
/// leave the Kanban silently stale — card state wouldn't advance even
/// though the sidecar was still working.
class _StreamHealthBanner extends ConsumerWidget {
  const _StreamHealthBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(kanban.eventStreamHealthProvider);
    if (health.state != kanban.StreamHealthState.disconnected) {
      return const SizedBox.shrink();
    }
    final retryAt = health.nextRetryAt;
    final retryIn = retryAt == null
        ? ''
        : ' (retrying in ${retryAt.difference(DateTime.now()).inSeconds.clamp(0, 999)}s)';
    final errorMessage = health.error?.toString() ?? 'connection lost';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: InfoBar(
        title: const Text('Live events disconnected'),
        content: Text(
          'The sidecar event stream is not reachable$retryIn. '
          'Kanban columns may not reflect the latest status until the stream '
          'reconnects. ($errorMessage)',
        ),
        severity: InfoBarSeverity.warning,
        isIconVisible: true,
      ),
    );
  }
}

/// _ActionErrorBanners surfaces every failed Kanban mutation (Run, Cancel,
/// Finalize, DeleteBranch, SubmitReview, …) as a dismissible InfoBar. The
/// underlying log is a bounded ring so a runaway failure loop stays visible
/// without growing unbounded.
class _ActionErrorBanners extends ConsumerWidget {
  const _ActionErrorBanners();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(kanban.actionErrorLogProvider);
    if (errors.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final err in errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InfoBar(
                title: Text(err.title),
                content: CopyableErrorText(
                  text: err.message,
                  reportTitle: err.title,
                  maxLines: 4,
                ),
                severity: InfoBarSeverity.error,
                isIconVisible: true,
                onClose: () => ref.dismissActionError(err.id),
              ),
            ),
        ],
      ),
    );
  }
}
