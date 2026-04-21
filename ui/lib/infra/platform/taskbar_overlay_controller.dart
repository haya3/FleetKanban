// Taskbar overlay controller: glues runningTaskCountProvider to the
// TaskbarOverlay FFI wrapper. Keeps the concerns separated so the FFI code
// is platform-only (no Riverpod / Flutter types) and the controller is UI-
// layer (no win32 imports).

import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32/win32.dart';

import '../ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../ipc/providers.dart';
import 'taskbar_overlay.dart';

part 'taskbar_overlay_controller.g.dart';

/// Count of tasks currently in the `in_progress` state across all repos.
/// Refreshes on relevant AgentEvent.kind values via ref.invalidateSelf.
@Riverpod(keepAlive: true)
class RunningTaskCount extends _$RunningTaskCount {
  StreamSubscription<pb.AgentEvent>? _sub;

  @override
  Future<int> build() async {
    final client = ref.read(ipcClientProvider);
    _sub = client.task.watchEvents(pb.WatchEventsRequest()).listen((ev) {
      if (ev.kind == 'status' || ev.kind == 'session.start') {
        ref.invalidateSelf();
      }
    }, onError: (_) {});
    ref.onDispose(() {
      _sub?.cancel();
    });
    final resp = await client.task.listTasks(
      pb.ListTasksRequest(statuses: const ['in_progress']),
    );
    return resp.tasks.length;
  }
}

/// Zero-sized widget that listens to [runningTaskCountProvider] and pushes
/// every change down to the Win32 ITaskbarList3 overlay. Mount it somewhere
/// inside the FluentApp once so the overlay stays in sync for the whole
/// session. Safe to ignore on non-Windows platforms (it compiles but the
/// underlying FFI call no-ops when init fails).
class TaskbarOverlayHost extends ConsumerStatefulWidget {
  const TaskbarOverlayHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<TaskbarOverlayHost> createState() => _TaskbarOverlayHostState();
}

class _TaskbarOverlayHostState extends ConsumerState<TaskbarOverlayHost> {
  @override
  void initState() {
    super.initState();
    // Defer init to the next frame: the Flutter Windows runner window is
    // created just before the first build, so FindWindowW can find its
    // class name ('FLUTTER_RUNNER_WIN32_WINDOW') only from postFrame on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hwnd = _findFlutterHwnd();
      if (hwnd != 0) {
        TaskbarOverlay.instance.init(hwnd);
      }
    });
  }

  int _findFlutterHwnd() {
    final cls = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
    try {
      return FindWindow(cls, nullptr);
    } finally {
      calloc.free(cls);
    }
  }

  @override
  void dispose() {
    TaskbarOverlay.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<int>>(runningTaskCountProvider, (_, next) {
      final count = next.value;
      if (count != null) {
        TaskbarOverlay.instance.update(count);
      }
    });
    return widget.child;
  }
}
