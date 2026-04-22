// Self-build update orchestration.
//
// For installs that came out of scripts/build-from-source.ps1, the
// VelopackUpdater reads a local `build/release/` feed via update-feed.txt.
// This service adds the missing step: triggering `git pull` + a rebuild
// from inside the running app, so a developer never has to drop into a
// terminal to ship themselves a new version. The rebuild writes the new
// nupkg into the same build/release/ directory that updateCheckProvider
// is already polling, so the in-app Update InfoBar lights up through the
// existing one-click flow.
//
// Derived-not-configured: the source-repo root is inferred from the feed
// URI (<repo>/build/release/ → up two dirs). No UI setting, no stored
// path — if the user didn't self-build, the feature silently hides.

import 'dart:io';

import 'velopack_updater.dart';

enum SourceRebuildPhase { idle, pulling, building, success, failure }

class SourceRebuildState {
  const SourceRebuildState({
    this.phase = SourceRebuildPhase.idle,
    this.logLines = const [],
    this.errorMessage,
  });

  final SourceRebuildPhase phase;
  final List<String> logLines;
  final String? errorMessage;

  bool get isRunning =>
      phase == SourceRebuildPhase.pulling ||
      phase == SourceRebuildPhase.building;

  SourceRebuildState copyWith({
    SourceRebuildPhase? phase,
    List<String>? logLines,
    Object? errorMessage = _unset,
  }) {
    return SourceRebuildState(
      phase: phase ?? this.phase,
      logLines: logLines ?? this.logLines,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const _unset = Object();
}

/// Resolves the source-repo root from the VelopackUpdater's local feed.
/// The rebuild Notifier consumes this; split out so it can be tested
/// (and swapped with an override) without constructing a Notifier.
///
/// The resolved root is cached on first call — install paths and the
/// bundled script don't change at runtime, and the Settings widget
/// calls this on every rebuild, which adds up to several existsSync
/// calls per frame without caching.
class SourceRebuildService {
  SourceRebuildService({required this.updater});

  final VelopackUpdater updater;

  Directory? _cachedRoot;
  bool _resolved = false;

  /// The <repo> directory when the running app was installed from a
  /// local Velopack feed at <repo>/build/release/ (i.e. produced by
  /// scripts/build-from-source.ps1). Returns null for public-release
  /// installs (GitHub feed) or when the script is missing.
  Directory? resolveSourceRepoRoot() {
    if (_resolved) return _cachedRoot;
    _resolved = true;
    final feed = updater.resolveLocalFeed();
    if (feed == null || feed.scheme != 'file') return null;
    final releaseDir = Directory.fromUri(feed);
    final repoRoot = releaseDir.parent.parent;
    final script = File(
      '${repoRoot.path}${Platform.pathSeparator}scripts'
      '${Platform.pathSeparator}build-from-source.ps1',
    );
    _cachedRoot = script.existsSync() ? repoRoot : null;
    return _cachedRoot;
  }

  bool get isAvailable => resolveSourceRepoRoot() != null;
}
