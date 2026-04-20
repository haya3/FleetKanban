// Shell-launch helpers for opening worktree directories from the Task
// detail dialog. Windows-only: FleetKanban does not target other OSes,
// so we shell out to native Windows commands directly without a
// cross-platform abstraction layer.
//
// Both helpers are best-effort: failures bubble up as exceptions so the
// caller can surface a banner. We don't try to detect VSCode presence
// up-front because `where` lookups add latency to every dialog open and
// the user-facing failure of "code not found" is descriptive enough.

import 'dart:io';

class ShellOpenException implements Exception {
  ShellOpenException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Opens [path] in Windows Explorer. Spawns a detached `explorer.exe`
/// process so closing FleetKanban doesn't take the Explorer window with
/// it. Throws [ShellOpenException] when explorer fails to start.
Future<void> openInExplorer(String path) async {
  if (path.isEmpty) {
    throw ShellOpenException('Worktree path is empty.');
  }
  // Sync existsSync — async exists is flagged by avoid_slow_async_io
  // because dart:io's async stat path is slower than the sync one;
  // the existence check here is a single stat, not worth the cost.
  if (!Directory(path).existsSync()) {
    throw ShellOpenException('Worktree directory no longer exists: $path');
  }
  try {
    await Process.start('explorer.exe', [
      path,
    ], mode: ProcessStartMode.detached);
  } catch (e) {
    throw ShellOpenException('Failed to launch Explorer: $e');
  }
}

/// Opens [path] in VSCode via the `code` CLI shim. The shim ships as
/// `code.cmd` on Windows and is normally on PATH for any user who
/// installed VSCode with the default options. Routed through `cmd /c`
/// so PATHEXT resolution finds the .cmd extension; spawning `code`
/// directly with Process.start fails because Dart only respects
/// PATHEXT for the bare executable when going through the shell.
Future<void> openInVSCode(String path) async {
  if (path.isEmpty) {
    throw ShellOpenException('Worktree path is empty.');
  }
  // Sync existsSync — async exists is flagged by avoid_slow_async_io
  // because dart:io's async stat path is slower than the sync one;
  // the existence check here is a single stat, not worth the cost.
  if (!Directory(path).existsSync()) {
    throw ShellOpenException('Worktree directory no longer exists: $path');
  }
  try {
    await Process.start(
      'cmd.exe',
      ['/c', 'code', path],
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
  } catch (e) {
    throw ShellOpenException(
      'Failed to launch VSCode (is the `code` CLI on PATH?): $e',
    );
  }
}
