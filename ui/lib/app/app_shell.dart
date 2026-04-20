// AppShell is the FluentApp root: NavigationView sidebar (7 main + 3 footer
// items). Unimplemented panes render a ComingSoonPage so the final navigation
// structure is visible from Phase 1.

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_banner.dart';
import '../features/auth/auth_gate.dart';
import '../features/insights/insights_page.dart';
import '../features/kanban/kanban_page.dart';
import '../features/placeholder/coming_soon_page.dart';
import '../features/preconditions/precondition_dialog.dart';
import '../features/review/review_page.dart';
import '../features/settings/settings_page.dart';
import '../features/status/status_page.dart';
import '../features/worktrees/worktrees_page.dart';
import 'theme.dart';

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

class _AppScaffold extends ConsumerWidget {
  const _AppScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(paneIndexProvider);

    return NavigationView(
      titleBar: TitleBar(
        title: const Text(
          'FleetKanban',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        isBackButtonVisible: false,
        onDragStarted: () => appWindow.startDragging(),
        onDoubleTap: () => appWindow.maximizeOrRestore(),
      ),
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
            body: const ComingSoonPage(
              title: 'Context',
              phase: 'Phase 2 予定',
              description:
                  'リポジトリに紐づくコーディング規約・アーキテクチャ制約などを Copilot CLI に自動注入するための context 管理画面です。',
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.plug_connected),
            title: const Text('MCP Overview'),
            body: const ComingSoonPage(
              title: 'MCP Overview',
              phase: 'Phase 2 予定',
              description:
                  '~/.copilot/mcp-config.json の MCP サーバ設定を可視化・編集する GUI。サーバごとの状態、提供ツール、直近の呼び出しを一覧できます。',
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
              phase: 'Phase 2 予定',
              description:
                  'GitHub Issue をインポートして Kanban のタスクにリンクします。完了時の自動クローズは既定で無効、opt-in のみ。',
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.git_graph),
            title: const Text('GitHub PRs'),
            body: const ComingSoonPage(
              title: 'GitHub PRs',
              phase: 'Phase 2 予定',
              description:
                  'PR 本文の下書きをエージェントのサマリ + diff ハイライトから生成し、作成はユーザー明示承認で実行します。アプリが自発的に push / PR 作成することはありません。',
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
            title: const Text('設定'),
            body: const SettingsPage(),
          ),
        ],
      ),
    );
  }
}
