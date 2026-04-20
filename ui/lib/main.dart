// FleetKanban Flutter entry point.
//
// Boot order:
//   1. Ensure Flutter bindings and system_theme (OS accent colour cache).
//   2. Configure bitsdojo_window minimum size + center.
//   3. Apply Mica via flutter_acrylic so Fluent UI Acrylic layers composite
//      onto the OS Mica backdrop instead of an opaque canvas.
//   4. Spawn the Go sidecar and wait for the READY handshake.
//   5. Hand off to the widget tree with the endpoint injected into
//      sidecarEndpointProvider.

import 'dart:io';
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_theme/system_theme.dart';

import 'app/app_shell.dart';
import 'app/error_display.dart';
import 'infra/ipc/providers.dart';
import 'infra/ipc/sidecar_supervisor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentColor.load();
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.mica,
    dark: PlatformDispatcher.instance.platformBrightness == Brightness.dark,
  );

  // Global error plumbing. ErrorWidget.builder renders a copyable red
  // screen so users can paste the stack trace into an issue / AI chat;
  // FlutterError.onError also echoes to stderr so the log tail picks
  // it up alongside sidecar messages.
  ErrorWidget.builder = (details) => _GlobalErrorScreen(details: details);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    try {
      stderr.writeln('=== FlutterError ===');
      stderr.writeln(details.exceptionAsString());
      if (details.stack != null) {
        stderr.writeln(details.stack.toString());
      }
    } catch (_) {
      // stderr is best-effort; do not escalate.
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      stderr.writeln('=== PlatformDispatcher.onError ===');
      stderr.writeln('$error');
      stderr.writeln('$stack');
    } catch (_) {}
    return true;
  };

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(960, 640);
    // Kanban has 6 columns + NavigationView compact rail + per-card stage
    // stepper: 1280 leaves cards clipped and the detail dialog (900 wide)
    // barely fits. 1600×1000 lands the default inside a reasonable chunk of
    // the FHD viewport without overflowing common 1920×1080 setups.
    win.size = const Size(1600, 1000);
    win.alignment = Alignment.center;
    win.title = 'FleetKanban';
    win.show();
  });

  final supervisor = SidecarSupervisor(binaryPath: resolveSidecarBinary());
  try {
    final endpoint = await supervisor.start();
    runApp(
      ProviderScope(
        overrides: [
          sidecarEndpointProvider.overrideWithValue(endpoint),
          supervisorProvider.overrideWithValue(supervisor),
        ],
        child: const _MicaAwareApp(),
      ),
    );
  } catch (e, st) {
    // Surface startup failures through a minimal FluentApp so users see what
    // went wrong instead of a blank window.
    runApp(
      FluentApp(
        debugShowCheckedModeBanner: false,
        home: _StartupErrorScreen(error: e, stack: st),
      ),
    );
  }
}

/// Observes OS brightness changes and re-applies the Mica effect so the
/// backdrop matches the new theme without a visible flash.
class _MicaAwareApp extends StatefulWidget {
  const _MicaAwareApp();
  @override
  State<_MicaAwareApp> createState() => _MicaAwareAppState();
}

class _MicaAwareAppState extends State<_MicaAwareApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final dark =
        PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    Window.setEffect(effect: WindowEffect.mica, dark: dark);
  }

  @override
  Widget build(BuildContext context) => const FleetKanbanApp();
}

/// Replaces Flutter's default red error banner with a Fluent-themed
/// panel whose body is a CopyableErrorText. Fires for any uncaught
/// build / layout / paint exception in any widget in the tree.
class _GlobalErrorScreen extends StatelessWidget {
  const _GlobalErrorScreen({required this.details});
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final body =
        '${details.exceptionAsString()}\n\n${details.stack ?? 'no stack available'}';
    return FluentTheme(
      data: FluentThemeData(brightness: Brightness.light),
      child: Container(
        color: const Color(0xFFFFF4F4),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(FluentIcons.error, color: Color(0xFFC42B1C)),
                SizedBox(width: 8),
                Text(
                  'Widget error',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: SingleChildScrollView(
                child: CopyableErrorText(
                  text: body,
                  reportTitle: 'Flutter widget error',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error, required this.stack});
  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('FleetKanban: Startup failed')),
      content: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ErrorInfoBar(
              title: 'Could not start sidecar',
              message: '$error',
              severity: InfoBarSeverity.error,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  stack.toString(),
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => exit(1), child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}
