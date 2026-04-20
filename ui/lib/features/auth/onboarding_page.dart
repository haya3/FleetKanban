// OnboardingPage is shown in place of the main app shell while Copilot
// authentication has not been established. The "サインイン" button opens a
// device-flow sign-in dialog that talks to the sidecar's BeginCopilotLogin
// RPC — the sidecar spawns `copilot login` headless, parses the device
// code, opens the pre-filled GitHub verification URL in the default
// browser, and auto-reloads the SDK client when the user completes auth.
// No terminal window is involved: Device Flow approval happens in the
// browser, with an optional 2FA push on the Mobile App only if GitHub
// requires it.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ipc/providers.dart';
import 'sign_in_dialog.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, required this.lastKnownMessage});

  /// Free-form status text from the most recent CheckCopilotAuth. Shown
  /// under the explainer so the user understands why sign-in is required
  /// (expired token, no account selected, etc.).
  final String lastKnownMessage;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _dialogOpen = false;

  Future<void> _openSignIn() async {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);
    try {
      final ok = await showCopilotSignInDialog(context, ref);
      if (!mounted) return;
      if (ok) {
        // AuthGate watches copilotAuthProvider; as soon as the next poll
        // returns authenticated=true the shell swaps in automatically.
        ref.invalidate(copilotAuthProvider);
      }
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resources = theme.resources;
    return ScaffoldPage(
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  FluentIcons.shield,
                  size: 48,
                  color: theme.accentColor.defaultBrushFor(theme.brightness),
                ),
                const SizedBox(height: 16),
                Text(
                  'GitHub Copilot にサインイン',
                  style: theme.typography.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'FleetKanban はタスク実行に GitHub Copilot を使用します。'
                  '「サインイン」を押すとブラウザが自動で開き、'
                  '表示されたダイアログ内のコードがあらかじめ入力された状態で'
                  'GitHub の承認ページが表示されます。',
                  style: theme.typography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ブラウザで Authorize を押すだけで完了します。'
                  'Mobile App だけではサインインは終わりません（2FA が要求'
                  'された場合にだけプッシュが届きます）。',
                  style: theme.typography.caption?.copyWith(
                    color: resources.textFillColorSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.lastKnownMessage.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'sidecar: ${widget.lastKnownMessage.trim()}',
                    style: theme.typography.caption?.copyWith(
                      color: resources.textFillColorTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _dialogOpen ? null : _openSignIn,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('サインイン'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Copilot が有効な GitHub アカウントが必要です。',
                  style: theme.typography.caption?.copyWith(
                    color: resources.textFillColorTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
