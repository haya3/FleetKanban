// Riverpod wiring for the in-app one-click update flow.
//
// - [velopackUpdaterProvider] owns the VelopackUpdater instance.
// - [updateCheckProvider] is a StreamProvider that runs an initial check
//   after app start and then polls every [_pollInterval].
// - [applyUpdateAndRestart] downloads the full nupkg and hands it to
//   Update.exe; shuts the sidecar down first so the binary swap doesn't
//   race with an open gRPC channel.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ipc/providers.dart';
import '../version.dart';
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
