// AuthBanner: compact panel shown in the NavigationPane header. Two modes:
//   * not authenticated  → red InfoBar
//   * authenticated      → account card with login, GitHub plan, and Copilot
//     premium-request quota (sourced from the SDK's account.getQuota RPC).

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
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            // Long GitHub display names / logins ellipsize at the pane
            // width (200 px); the tooltip surfaces the full value on
            // hover so the ellipsis is never an information loss.
            message: '$displayName\n@${info?.login ?? authUser}',
            child: Row(
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
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${info?.login ?? authUser}',
                        style: theme.typography.caption?.copyWith(
                          color: resources.textFillColorSecondary,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const _QuotaLine(),
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

/// _QuotaLine renders the Copilot premium-request counter sourced from
/// the SDK's account.getQuota RPC. We pick the "premium_interactions"
/// snapshot when present (the number users actually care about) and fall
/// back to the first available snapshot otherwise so the line still shows
/// something informative on accounts where that specific key is absent.
class _QuotaLine extends ConsumerWidget {
  const _QuotaLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    final caption = theme.typography.caption?.copyWith(
      color: resources.textFillColorSecondary,
    );
    final quota = ref.watch(copilotQuotaProvider).value;
    final snapshot = _pickSnapshot(quota);
    if (snapshot == null) {
      return Tooltip(
        message:
            'Sign in to Copilot (or wait for the CLI to boot) to see remaining premium requests.',
        child: Text('Premium: —', style: caption),
      );
    }
    final rawRemaining =
        snapshot.entitlementRequests - snapshot.usedRequests;
    final remaining = rawRemaining < 0 ? 0.0 : rawRemaining;
    // The SDK's remainingPercentage is already on a 0-100 scale despite its
    // doc comment claiming "0.0 to 1.0" — verified against the live Copilot
    // CLI. Do not multiply here, or the banner shows e.g. "5850%" for 58.5%.
    final pct = snapshot.remainingPercentage.toStringAsFixed(1);
    final reset = snapshot.resetDate.isEmpty
        ? ''
        : ' · resets ${snapshot.resetDate.split("T").first}';
    return Tooltip(
      message:
          'Used ${_fmt(snapshot.usedRequests)} of ${_fmt(snapshot.entitlementRequests)} premium requests'
          '${snapshot.overage > 0 ? " (+${_fmt(snapshot.overage)} overage)" : ""}'
          '$reset',
      child: Text(
        'Premium: ${_fmt(remaining)} left ($pct%)',
        style: caption,
      ),
    );
  }

  static pb.CopilotQuotaSnapshot? _pickSnapshot(pb.CopilotQuotaInfo? info) {
    if (info == null || info.snapshots.isEmpty) return null;
    final preferred = info.snapshots['premium_interactions'];
    if (preferred != null) return preferred;
    return info.snapshots.values.first;
  }

  static String _fmt(double v) {
    if (v >= 100 && v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
