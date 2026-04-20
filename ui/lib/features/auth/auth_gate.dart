// AuthGate is the widget that decides whether the main app shell is
// visible. It watches the Copilot auth status; while unauthenticated the
// user only sees the onboarding page, which blocks every other screen
// (kanban, settings, etc.) behind a mandatory sign-in step.
//
// Rationale: any Copilot-dependent action (creating a task, re-running a
// reviewer) will fail without an authenticated session, and the server-
// side gate (CopilotAuthGateUnary in the sidecar) already rejects those
// RPCs. Showing the usual UI behind a "you cannot actually use this"
// state is worse than hiding it outright — the user would fill in forms
// that only fail on submit.
//
// The status call is expected to be fast (local to the sidecar, which
// owns a long-lived SDK client). First-launch loading state is shown as
// a compact progress ring so the window does not flash empty.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/providers.dart';
import 'onboarding_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  /// The widget shown once Copilot authentication succeeds. Typically the
  /// main app shell (NavigationView).
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(copilotAuthProvider);
    return auth.when(
      loading: () => const _AuthLoadingScreen(),
      error: (err, _) => _AuthErrorScreen(
        error: err,
        onRetry: () => ref.invalidate(copilotAuthProvider),
      ),
      data: (status) {
        if (status.authenticated) {
          return child;
        }
        return OnboardingPage(lastKnownMessage: status.message);
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      content: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: ProgressRing(strokeWidth: 3),
            ),
            SizedBox(height: 12),
            Text('Copilot の状態を確認しています…'),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorInfoBar(
              title: 'Copilot 状態の取得に失敗しました',
              message: '$error',
              severity: InfoBarSeverity.error,
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(onPressed: onRetry, child: const Text('再試行')),
            ),
          ],
        ),
      ),
    );
  }
}
