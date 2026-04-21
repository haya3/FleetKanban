// AuthBanner: compact panel shown in the NavigationPane header. Two modes:
//   * not authenticated  → red InfoBar
//   * authenticated      → account card with login, plan hint, and a note
//     that premium-request quotas are not exposed via GitHub's public API.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';

class AuthBanner extends ConsumerWidget {
  const AuthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(copilotAuthProvider);
    return auth.maybeWhen(
      data: (a) {
        if (!a.authenticated) {
          return ErrorInfoBar(
            title: 'Copilot not authenticated',
            message: a.message.isEmpty ? 'Sign-in required' : a.message,
            severity: InfoBarSeverity.warning,
          );
        }
        return _AccountCard(authUser: a.user);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.authUser});
  final String authUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    // Resolve to a local once so a rebuild between the null-check and the
    // read cannot turn `.value` back into null (loading / error transitions
    // in riverpod 3 make `.value` null instead of throwing).
    final info = ref.watch(githubAccountInfoProvider).value;
    final displayName = (info?.name.isNotEmpty ?? false) ? info!.name : authUser;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(url: info?.avatarUrl ?? ''),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.typography.bodyStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${info?.login ?? authUser}',
                      style: theme.typography.caption?.copyWith(
                        color: resources.textFillColorSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _PlanLine(info: info),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const CircleAvatar(
        radius: 14,
        child: Icon(FluentIcons.contact, size: 14),
      );
    }
    return ClipOval(
      child: Image.network(
        url,
        width: 28,
        height: 28,
        errorBuilder: (_, _, _) => const Icon(FluentIcons.contact, size: 20),
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.info});
  final pb.GitHubAccountInfo? info;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final caption = theme.typography.caption?.copyWith(
      color: resources.textFillColorSecondary,
    );
    if (info == null) {
      return Tooltip(
        message: 'Add a PAT in Settings to fetch plan info',
        child: Text('Plan: not fetched (no PAT configured)', style: caption),
      );
    }
    final plan = info!.planName.isEmpty ? '—' : info!.planName;
    return Tooltip(
      message:
          'The official GitHub API does not expose remaining Copilot premium requests. '
          'Check github.com/settings/copilot for details.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('GitHub plan: $plan', style: caption),
          const SizedBox(width: 6),
          Icon(
            FluentIcons.info,
            size: 11,
            color: resources.textFillColorTertiary,
          ),
        ],
      ),
    );
  }
}
