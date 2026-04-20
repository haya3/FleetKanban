// Shared device-flow sign-in dialog.
//
// Triggered from both the Onboarding page (first-run sign-in) and the
// Settings page (re-sign-in / account switch). The widget owns the full
// lifecycle of a single login attempt:
//
//   1. Calls BeginCopilotLogin on the sidecar → gets a device code +
//      pre-filled verification URL. The sidecar has already opened that
//      URL in the user's default browser by the time we receive the
//      challenge, so the user usually lands on the GitHub "Authorize"
//      page without touching the UI further.
//   2. Shows the code (large, selectable, copy-friendly) and the URL
//      ("Reopen browser" button) while polling GetCopilotLoginSession
//      on a short cadence. We deliberately do NOT poll CheckCopilotAuth:
//      on account-switch the SDK client still reports authenticated=true
//      from the previous session until ReloadAuth runs, which would
//      close the dialog before the user has even read the device code.
//      The login-session RPC only reports SUCCEEDED once the subprocess
//      has exited cleanly AND ReloadAuth has completed.
//   3. Resolves with `true` when the session state becomes SUCCEEDED;
//      the caller is expected to dismiss the dialog and move on (AuthGate
//      will swap the shell automatically once copilotAuthProvider is
//      invalidated by the caller).
//   4. On user dismissal, sends CancelCopilotLogin to kill the lingering
//      subprocess so a second Begin is not rejected with "in progress".

import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/error_display.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../settings/providers.dart';

/// Show the sign-in dialog and return `true` when authentication
/// succeeded, `false` when the user dismissed it.
Future<bool> showCopilotSignInDialog(BuildContext context, WidgetRef ref) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CopilotSignInDialog(),
  ).then((v) => v ?? false);
}

class _CopilotSignInDialog extends ConsumerStatefulWidget {
  const _CopilotSignInDialog();

  @override
  ConsumerState<_CopilotSignInDialog> createState() =>
      _CopilotSignInDialogState();
}

enum _Phase { starting, waiting, failed, success }

class _CopilotSignInDialogState extends ConsumerState<_CopilotSignInDialog> {
  _Phase _phase = _Phase.starting;
  pb.CopilotLoginChallenge? _challenge;
  String? _errorMessage;
  Timer? _poll;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.starting;
      _errorMessage = null;
    });
    try {
      final challenge = await beginCopilotLogin(ref);
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _phase = _Phase.waiting;
      });
      _poll?.cancel();
      _poll = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _checkSession(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _errorMessage = '$e';
      });
    }
  }

  Future<void> _checkSession() async {
    // Poll the subprocess lifecycle directly. SUCCEEDED is only set after
    // `copilot login` has exited cleanly AND ReloadAuth has replaced the
    // SDK client, so there is no window where stale auth state can close
    // the dialog while the user is still reading the device code.
    try {
      final info = await getCopilotLoginSession(ref);
      if (!mounted) return;
      switch (info.state) {
        case pb.CopilotLoginSessionState.COPILOT_LOGIN_SESSION_STATE_SUCCEEDED:
          _poll?.cancel();
          setState(() => _phase = _Phase.success);
          // Brief success flash so the user sees confirmation, then close.
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          _closing = true;
          Navigator.of(context).pop(true);
        case pb.CopilotLoginSessionState.COPILOT_LOGIN_SESSION_STATE_FAILED:
          _poll?.cancel();
          setState(() {
            _phase = _Phase.failed;
            _errorMessage = info.errorMessage.isNotEmpty
                ? info.errorMessage
                : 'Sign-in failed';
          });
        case pb.CopilotLoginSessionState.COPILOT_LOGIN_SESSION_STATE_RUNNING:
        case pb.CopilotLoginSessionState.COPILOT_LOGIN_SESSION_STATE_IDLE:
        case pb
            .CopilotLoginSessionState
            .COPILOT_LOGIN_SESSION_STATE_UNSPECIFIED:
          // Keep polling. IDLE should not happen while the dialog is open
          // (Begin installs the session before returning); if it does,
          // treat it as "still pending" so a sidecar restart or similar
          // transient does not close the dialog out from under the user.
          break;
      }
    } catch (_) {
      // Transient errors (sidecar restart, etc.) — keep polling.
    }
  }

  Future<void> _reopenBrowser() async {
    final uri = _challenge?.verificationUri;
    if (uri == null || uri.isEmpty) return;
    // Windows-only: shell out to cmd.exe's `start` built-in. We stay
    // consistent with the sidecar's browser-launch path (client.go) and
    // avoid pulling url_launcher for a single-use action.
    await Process.start('cmd.exe', [
      '/c',
      'start',
      '',
      uri,
    ], mode: ProcessStartMode.detached);
  }

  Future<void> _copyCode() async {
    final code = _challenge?.userCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
  }

  Future<void> _cancel() async {
    if (_closing) return;
    _closing = true;
    _poll?.cancel();
    // Fire-and-forget; the RPC is idempotent and we do not want to block
    // the UI on it.
    unawaited(cancelCopilotLogin(ref).catchError((_) {}));
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Sign in to GitHub Copilot'),
      constraints: const BoxConstraints(maxWidth: 560),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    final theme = FluentTheme.of(context);
    final secondary = theme.resources.textFillColorSecondary;
    switch (_phase) {
      case _Phase.starting:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: ProgressRing(strokeWidth: 2.5),
              ),
              SizedBox(width: 12),
              Text('Preparing sign-in…'),
            ],
          ),
        );

      case _Phase.waiting:
        final code =
            _challenge?.userCode ??
            '----'
                '----';
        final uri = _challenge?.verificationUri ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your browser has been opened. The code below should already '
              'be filled in on the GitHub page. If not, paste it as-is and '
              'click **Continue** → **Authorize**.',
              style: theme.typography.body,
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.resources.cardBackgroundFillColorDefault,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.resources.dividerStrokeColorDefault,
                  ),
                ),
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: theme.accentColor.defaultBrushFor(theme.brightness),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Button(
                    onPressed: _copyCode,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.copy, size: 14),
                        SizedBox(width: 6),
                        Text('Copy code'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: _reopenBrowser,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.globe, size: 14),
                        SizedBox(width: 6),
                        Text('Reopen browser'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoBar(
              title: const Text('Mobile App alone is not enough'),
              content: const Text(
                'GitHub Device Flow requires browser approval by design. '
                'The mobile app is only used when a two-factor push is '
                'required.',
              ),
              severity: InfoBarSeverity.info,
              isIconVisible: true,
            ),
            const SizedBox(height: 10),
            Text(
              'This dialog closes automatically once you press Authorize in the browser.',
              style: theme.typography.caption?.copyWith(color: secondary),
            ),
            if (uri.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(
                  uri,
                  style: theme.typography.caption?.copyWith(
                    color: secondary,
                    fontFamily: 'Consolas',
                  ),
                ),
              ),
          ],
        );

      case _Phase.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorInfoBar(
              title: 'Could not start sign-in',
              message: _errorMessage ?? 'Unknown error',
            ),
            const SizedBox(height: 12),
            Text(
              'This is likely a Copilot CLI bundle mismatch or a network '
              'reachability problem. If retrying does not help, check the '
              'sidecar logs.',
              style: FluentTheme.of(context).typography.caption,
            ),
          ],
        );

      case _Phase.success:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.skype_circle_check, size: 22),
              SizedBox(width: 10),
              Text('Sign-in complete!'),
            ],
          ),
        );
    }
  }

  List<Widget> _buildActions() {
    switch (_phase) {
      case _Phase.starting:
        return [Button(onPressed: _cancel, child: const Text('Cancel'))];
      case _Phase.waiting:
        return [Button(onPressed: _cancel, child: const Text('Cancel'))];
      case _Phase.failed:
        return [
          Button(onPressed: _cancel, child: const Text('Close')),
          FilledButton(onPressed: _start, child: const Text('Retry')),
        ];
      case _Phase.success:
        return const [];
    }
  }
}
