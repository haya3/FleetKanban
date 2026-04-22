// Riverpod wiring for the in-app one-click update flow.
//
// - [velopackUpdaterProvider] owns the VelopackUpdater instance.
// - [updateCheckProvider] is a StreamProvider that runs an initial check
//   after app start and then polls every [_pollInterval].
// - [applyUpdateAndRestart] downloads the full nupkg and hands it to
//   Update.exe; shuts the sidecar down first so the binary swap doesn't
//   race with an open gRPC channel.
// - [sourceRebuildProvider] (self-built installs only) drives
//   git-pull + build-from-source.ps1 from the Settings UI, so developers
//   never have to drop into a terminal to ship themselves a new version.
//   On success, invalidates [updateCheckProvider] so the InfoBar appears
//   at the next ≈20 s startupDelay tick instead of on the hourly poll.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ipc/providers.dart';
import '../version.dart';
import 'source_rebuild_service.dart';
import 'velopack_updater.dart';

const _pollInterval = Duration(hours: 1);
const _startupDelay = Duration(seconds: 20);

final velopackUpdaterProvider = Provider<VelopackUpdater>((_) {
  return VelopackUpdater(currentVersion: appVersion);
});

/// Emits the latest update check result. First check runs [_startupDelay]
/// after app boot to avoid competing with the sidecar handshake, then
/// every [_pollInterval]. Errors surface as AsyncError to the UI; the
/// InfoBar only renders on `available == true` so transient GitHub API
/// failures are silent.
final updateCheckProvider = StreamProvider<UpdateCheckResult>((ref) async* {
  final updater = ref.watch(velopackUpdaterProvider);

  if (!updater.isDeployed) {
    yield UpdateCheckResult(
      available: false,
      currentVersion: updater.currentVersion,
    );
    return;
  }

  await Future<void>.delayed(_startupDelay);
  while (true) {
    try {
      yield await updater.checkForUpdates();
    } catch (_) {
      yield UpdateCheckResult(
        available: false,
        currentVersion: updater.currentVersion,
      );
    }
    await Future<void>.delayed(_pollInterval);
  }
});

/// Downloads the update, shuts the sidecar down, and hands off to
/// Update.exe. Returns normally only on failure — on success the process
/// exits inside [VelopackUpdater.applyAndRestart].
Future<void> applyUpdateAndRestart(
  WidgetRef ref,
  UpdateCheckResult result,
) async {
  final updater = ref.read(velopackUpdaterProvider);
  final pkg = await updater.downloadUpdate(result);
  try {
    await ref.read(supervisorProvider).kill();
  } catch (_) {
    // Best-effort: Update.exe will --waitPid us out either way.
  }
  await updater.applyAndRestart(pkg);
}

// ---- self-build rebuild flow ----

final sourceRebuildServiceProvider = Provider<SourceRebuildService>((ref) {
  return SourceRebuildService(updater: ref.watch(velopackUpdaterProvider));
});

/// Drives `git pull --ff-only` followed by `build-from-source.ps1
/// -SkipPrereqs`. Both processes' stdout/stderr stream into
/// [SourceRebuildState.logLines] so the Settings UI can tail the build.
/// Only does anything on installs that originated from
/// scripts/build-from-source.ps1 (detected via update-feed.txt).
class SourceRebuildNotifier extends Notifier<SourceRebuildState> {
  static const _maxLogLines = 500;

  @override
  SourceRebuildState build() {
    // Keep the notifier alive for the app lifetime so a build that
    // started on the Settings page survives the user navigating away,
    // and so logLines stay readable when they navigate back. Cost is
    // a few KB and one idle instance — negligible compared to losing
    // a two-minute build's progress.
    //
    // The KeepAliveLink is intentionally discarded: this provider must
    // stay pinned forever. A future maintainer reintroducing conditional
    // keep-alive needs to store the link and call `.close()` on it.
    ref.keepAlive();
    return const SourceRebuildState();
  }

  Future<void> run() async {
    if (state.isRunning) return;

    final service = ref.read(sourceRebuildServiceProvider);
    final root = service.resolveSourceRepoRoot();
    if (root == null) {
      state = state.copyWith(
        phase: SourceRebuildPhase.failure,
        errorMessage:
            'Source repo not found. This install did not come from '
            'build-from-source.ps1.',
      );
      return;
    }

    state = const SourceRebuildState(phase: SourceRebuildPhase.pulling);
    _append('> git pull --ff-only  (in ${root.path})');

    final pulled = await _runProcess(
      'git',
      ['-C', root.path, 'pull', '--ff-only'],
    );
    if (!pulled.ok) {
      state = state.copyWith(
        phase: SourceRebuildPhase.failure,
        errorMessage:
            'git pull --ff-only failed (exit ${pulled.exitCode}). '
            'Resolve the conflict or local changes manually and retry.',
      );
      return;
    }

    state = state.copyWith(phase: SourceRebuildPhase.building);
    final script =
        '${root.path}${Platform.pathSeparator}scripts'
        '${Platform.pathSeparator}build-from-source.ps1';
    _append('> powershell -Command "& \'$script\' -SkipPrereqs" *>&1');

    // -Command + *>&1 instead of -File: the script uses Write-Host for
    // section headers which writes to PowerShell's Information stream
    // (stream 6), *not* stdout. -File runs the script but leaves
    // stream 6 unmerged, so Process.start's stdout pipe only catches
    // the rare Write-Output lines. Wrapping with *>&1 collapses
    // streams 2-6 into 1 so _append gets the full build trace.
    final escapedScript = script.replaceAll("'", "''");
    final built = await _runProcess(
      'powershell.exe',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        "& '$escapedScript' -SkipPrereqs *>&1",
      ],
      workingDirectory: root.path,
    );
    if (!built.ok) {
      state = state.copyWith(
        phase: SourceRebuildPhase.failure,
        errorMessage:
            'build-from-source.ps1 failed (exit ${built.exitCode}). '
            'See the log above for the failing step.',
      );
      return;
    }

    state = state.copyWith(
      phase: SourceRebuildPhase.success,
      errorMessage: null,
    );

    // Invalidates the stream so the next poll runs at the next
    // _startupDelay tick (≈20 s) rather than at the hourly boundary.
    // Not instantaneous, but acceptable against a 1–3 minute rebuild.
    ref.invalidate(updateCheckProvider);
  }

  void reset() {
    state = const SourceRebuildState();
  }

  Future<({bool ok, int exitCode})> _runProcess(
    String exe,
    List<String> args, {
    String? workingDirectory,
  }) async {
    late Process proc;
    try {
      proc = await Process.start(
        exe,
        args,
        workingDirectory: workingDirectory,
      );
    } catch (e) {
      _append('[spawn error] $exe: $e');
      return (ok: false, exitCode: -1);
    }

    final stdoutDone = Completer<void>();
    final stderrDone = Completer<void>();
    proc.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(_append, onDone: stdoutDone.complete);
    proc.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((l) => _append('[stderr] $l'), onDone: stderrDone.complete);

    final exit = await proc.exitCode;
    await stdoutDone.future;
    await stderrDone.future;
    return (ok: exit == 0, exitCode: exit);
  }

  void _append(String line) {
    final next = List<String>.of(state.logLines)..add(line);
    if (next.length > _maxLogLines) {
      next.removeRange(0, next.length - _maxLogLines);
    }
    state = state.copyWith(logLines: next);
  }
}

final sourceRebuildProvider =
    NotifierProvider<SourceRebuildNotifier, SourceRebuildState>(
      SourceRebuildNotifier.new,
    );
