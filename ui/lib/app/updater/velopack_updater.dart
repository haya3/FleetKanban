// Velopack-compatible updater for FleetKanban.
//
// The Velopack CLI (`vpk`) produces an install layout like:
//
//   <root>\Update.exe
//   <root>\current\fleetkanban_ui.exe       <- Platform.resolvedExecutable
//   <root>\current\update-feed.txt          <- optional: local-feed override
//   <root>\packages\*.nupkg                  <- prior releases (for delta)
//
// Update.exe's CLI only exposes `apply | start | patch | uninstall` — it
// does not download updates itself. Velopack's own libraries (C#, Rust, ...)
// do that via an embedded HTTP client. Flutter/Dart has no official binding,
// and the community `velopack_flutter` package is 17 months stale, so we
// talk to the configured feed directly and hand a downloaded `-full.nupkg`
// to `Update.exe apply -p <path>`.
//
// Two feed sources are supported:
//
//   1. GitHub Releases (default) — hits `/releases/latest` on the canonical
//      repo. Used by public installer downloads.
//   2. Local / LAN Velopack feed — triggered when `<current>/update-feed.txt`
//      exists, containing a URI (file:// or http[s]://) pointing at a
//      directory that serves a Velopack `RELEASES` text file plus the
//      referenced `-full.nupkg`. `scripts/build-from-source.ps1` writes
//      this file so self-built installs keep receiving one-click updates
//      from `build/release/` instead of GitHub.
//
// If Velopack ships an official Dart binding later, swap this implementation
// out — the public API here (checkForUpdates / downloadUpdate /
// applyAndRestart) stays stable.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Owner / repo that hosts GitHub Releases. Tags are `v<semver>`; assets
/// follow Velopack's naming (`com.fleetkanban.FleetKanban-<ver>-full.nupkg`).
const _releaseOwner = 'FleetKanban';
const _releaseRepo = 'fleetkanban';
const _packageId = 'com.fleetkanban.FleetKanban';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.available,
    required this.currentVersion,
    this.latestVersion,
    this.downloadUrl,
  });

  final bool available;
  final String currentVersion;
  final String? latestVersion;

  /// URL of the `-full.nupkg` asset on the matched Release. Null when no
  /// update is available or the assets don't include a full package.
  final String? downloadUrl;
}

class VelopackUpdaterException implements Exception {
  VelopackUpdaterException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'VelopackUpdaterException: $message${cause != null ? ' ($cause)' : ''}';
}

class VelopackUpdater {
  VelopackUpdater({required this.currentVersion, String? installRootOverride})
    : _installRootOverride = installRootOverride;

  final String currentVersion;
  final String? _installRootOverride;

  /// `<root>` directory containing Update.exe, or null when running
  /// outside an installed build (e.g. `flutter run`).
  Directory? resolveInstallRoot() {
    if (_installRootOverride != null) {
      return Directory(_installRootOverride);
    }
    final self = File(Platform.resolvedExecutable);
    final candidate = self.parent.parent;
    final updater = File(
      '${candidate.path}${Platform.pathSeparator}Update.exe',
    );
    return updater.existsSync() ? candidate : null;
  }

  bool get isDeployed => resolveInstallRoot() != null;

  /// Reads `<current>/update-feed.txt` if present, returning a URI pointing
  /// at a directory that serves a Velopack `RELEASES` file. Self-built
  /// installs use this to receive updates from a local `build/release/`
  /// directory instead of GitHub. Returns null when absent or malformed.
  ///
  /// Only `file://` and `https://` are accepted. Plain `http://` is
  /// rejected deliberately because the downloaded nupkg is executed
  /// verbatim — a LAN MITM on an http feed would be an arbitrary-code
  /// execution vector. LAN sharing requires terminating with https
  /// (self-signed is fine).
  Uri? resolveLocalFeed() {
    final exeDir = File(Platform.resolvedExecutable).parent;
    final marker = File(
      '${exeDir.path}${Platform.pathSeparator}update-feed.txt',
    );
    if (!marker.existsSync()) return null;
    var raw = marker.readAsStringSync().trim();
    if (raw.startsWith('﻿')) raw = raw.substring(1);
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return null;
    if (uri.scheme != 'file' && uri.scheme != 'https') return null;
    return uri;
  }

  /// Local-feed or GitHub-Releases check, depending on whether
  /// `<current>/update-feed.txt` is present. Returns a no-op result when
  /// the app is running from a non-installed build (e.g. `flutter run`).
  Future<UpdateCheckResult> checkForUpdates() async {
    if (!isDeployed) {
      return UpdateCheckResult(
        available: false,
        currentVersion: currentVersion,
      );
    }
    final localFeed = resolveLocalFeed();
    if (localFeed != null) {
      return _checkLocalFeed(localFeed);
    }
    return _checkGithubReleases();
  }

  /// Hits `GET /repos/:owner/:repo/releases/latest` and returns whether a
  /// newer tag is available alongside the `-full.nupkg` URL. Skips
  /// pre-releases because GitHub's `/latest` endpoint already does.
  Future<UpdateCheckResult> _checkGithubReleases() async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$_releaseOwner/$_releaseRepo/releases/latest',
    );
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('User-Agent', 'FleetKanban-Updater/$currentVersion');
      final resp = await req.close();
      if (resp.statusCode == 404) {
        // No release cut yet; not an error from the user's perspective.
        return UpdateCheckResult(
          available: false,
          currentVersion: currentVersion,
        );
      }
      if (resp.statusCode != 200) {
        throw VelopackUpdaterException(
          'GitHub API returned ${resp.statusCode}',
        );
      }
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?) ?? '';
      final latest = tag.startsWith('v') ? tag.substring(1) : tag;
      final assets = (json['assets'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final fullAsset = assets.firstWhere((a) {
        final name = (a['name'] as String?) ?? '';
        return name.startsWith('$_packageId-') && name.endsWith('-full.nupkg');
      }, orElse: () => <String, dynamic>{});
      final downloadUrl = fullAsset['browser_download_url'] as String?;
      final isNewer =
          latest.isNotEmpty &&
          _compareSemver(latest, currentVersion) > 0 &&
          downloadUrl != null;
      return UpdateCheckResult(
        available: isNewer,
        currentVersion: currentVersion,
        latestVersion: latest.isEmpty ? null : latest,
        downloadUrl: downloadUrl,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads the full nupkg from [result.downloadUrl] into
  /// `<root>\packages\` and returns the local path. Supports `file://`
  /// (plain copy) in addition to `http(s)://` so local-feed installs can
  /// stage the package without a network round trip.
  Future<File> downloadUpdate(UpdateCheckResult result) async {
    final root = resolveInstallRoot();
    if (root == null) {
      throw VelopackUpdaterException('install root not found');
    }
    final url = result.downloadUrl;
    if (url == null) {
      throw VelopackUpdaterException('no download URL in check result');
    }
    final pkgDir = Directory('${root.path}${Platform.pathSeparator}packages');
    if (!pkgDir.existsSync()) pkgDir.createSync(recursive: true);

    final uri = Uri.parse(url);
    final leaf = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : url.split('/').last;
    final dest = File('${pkgDir.path}${Platform.pathSeparator}$leaf');

    if (uri.scheme == 'file') {
      final src = File.fromUri(uri);
      if (!src.existsSync()) {
        throw VelopackUpdaterException('local nupkg missing: ${src.path}');
      }
      await src.copy(dest.path);
      return dest;
    }

    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'FleetKanban-Updater/$currentVersion');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw VelopackUpdaterException(
          'download failed: HTTP ${resp.statusCode}',
        );
      }
      final sink = dest.openWrite();
      await resp.pipe(sink);
      return dest;
    } finally {
      client.close(force: true);
    }
  }

  /// Reads `<base>/RELEASES` from a Velopack-compatible feed, parses the
  /// `<sha1> <filename> <size>` rows, picks the highest `-full.nupkg`
  /// version, and returns a result pointing at it. Supports file:// and
  /// http(s):// base URIs.
  Future<UpdateCheckResult> _checkLocalFeed(Uri base) async {
    final baseNormalized = base.path.endsWith('/')
        ? base
        : base.replace(path: '${base.path}/');
    final releasesUri = baseNormalized.resolve('RELEASES');
    final body = await _readFeedResource(releasesUri);

    String? latest;
    String? latestAsset;
    for (final line in const LineSplitter().convert(body)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final filename = parts[1];
      if (!filename.startsWith('$_packageId-') ||
          !filename.endsWith('-full.nupkg')) {
        continue;
      }
      final version = filename.substring(
        '$_packageId-'.length,
        filename.length - '-full.nupkg'.length,
      );
      if (latest == null || _compareSemver(version, latest) > 0) {
        latest = version;
        latestAsset = filename;
      }
    }

    if (latest == null || latestAsset == null) {
      return UpdateCheckResult(
        available: false,
        currentVersion: currentVersion,
      );
    }
    final downloadUri = baseNormalized.resolve(latestAsset);
    final isNewer = _compareSemver(latest, currentVersion) > 0;
    return UpdateCheckResult(
      available: isNewer,
      currentVersion: currentVersion,
      latestVersion: latest,
      downloadUrl: isNewer ? downloadUri.toString() : null,
    );
  }

  Future<String> _readFeedResource(Uri uri) async {
    String body;
    if (uri.scheme == 'file') {
      final f = File.fromUri(uri);
      if (!f.existsSync()) {
        throw VelopackUpdaterException(
          'local feed RELEASES missing: ${f.path}',
        );
      }
      body = f.readAsStringSync();
    } else {
      final client = HttpClient();
      try {
        final req = await client.getUrl(uri);
        req.headers.set('User-Agent', 'FleetKanban-Updater/$currentVersion');
        final resp = await req.close();
        if (resp.statusCode != 200) {
          throw VelopackUpdaterException(
            'feed RELEASES HTTP ${resp.statusCode}',
          );
        }
        body = await resp.transform(utf8.decoder).join();
      } finally {
        client.close(force: true);
      }
    }
    // Strip UTF-8 BOM so the first RELEASES row parses correctly.
    return body.startsWith('﻿') ? body.substring(1) : body;
  }

  /// Hands [pkgPath] to `Update.exe apply --waitPid <us> -p <pkg>` and
  /// exits the current process so the updater can swap binaries.
  Future<Never> applyAndRestart(File pkgPath) async {
    final root = resolveInstallRoot();
    if (root == null) {
      throw VelopackUpdaterException('install root not found');
    }
    final updater = '${root.path}${Platform.pathSeparator}Update.exe';
    await Process.start(updater, [
      'apply',
      '--waitPid',
      '$pid',
      '-p',
      pkgPath.path,
    ], mode: ProcessStartMode.detached);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    exit(0);
  }

  int _compareSemver(String a, String b) {
    final ap = a.split(RegExp(r'[.+\-]')).map(int.tryParse).toList();
    final bp = b.split(RegExp(r'[.+\-]')).map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final av = (i < ap.length ? ap[i] : null) ?? 0;
      final bv = (i < bp.length ? bp[i] : null) ?? 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}
