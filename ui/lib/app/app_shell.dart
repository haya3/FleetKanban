// AppShell is the FluentApp root: NavigationView sidebar (7 main + 3 footer
// items). Unimplemented panes render a ComingSoonPage so the final navigation
// structure is visible from Phase 1.

import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_banner.dart';
import '../infra/ipc/providers.dart';
import 'version.dart';
import '../features/auth/auth_gate.dart';
import '../features/context/context_page.dart';
import '../features/insights/insights_page.dart';
import '../features/kanban/kanban_page.dart';
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

// Windows caption buttons rendered inside our custom TitleBar. bitsdojo_window
// ships stock buttons already; we just tint them to match the Fluent theme
// so the close button still turns red on hover and the rest tint via accent.
class _CaptionButtons extends StatelessWidget {
  const _CaptionButtons({required this.theme});
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
      iconNormal: theme.resources.textFillColorPrimary,
      mouseOver: theme.resources.subtleFillColorSecondary,
      mouseDown: theme.resources.subtleFillColorTertiary,
      iconMouseOver: theme.resources.textFillColorPrimary,
      iconMouseDown: theme.resources.textFillColorPrimary,
    );
    final closeColors = WindowButtonColors(
      iconNormal: theme.resources.textFillColorPrimary,
      mouseOver: const Color(0xFFC42B1C),
      mouseDown: const Color(0xFF8A1C12),
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeColors),
      ],
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
        WindowTitleBarBox(
          child: Container(
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
                  child: MoveWindow(
                    onDoubleTap: appWindow.maximizeOrRestore,
                  ),
                ),
                _CaptionButtons(theme: theme),
              ],
            ),
          ),
        ),
        const _VersionMismatchBanner(),
        const _UpdateAvailableBanner(),
        Expanded(
          child: _buildNavigation(context, ref, selected),
        ),
      ],
    );
  }

  Widget _buildNavigation(BuildContext context, WidgetRef ref, int selected) {
    return NavigationView(
      pane: NavigationPane(
        selected: selected,
        onChanged: (i) => ref.read(paneIndexProvider.notifier).state = i,
        displayMode: PaneDisplayMode.compact,
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

class _UpdateAvailableBannerState extends ConsumerState<_UpdateAvailableBanner> {
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
