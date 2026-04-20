// Velopack-compatible updater for FleetKanban.
//
// The Velopack CLI (`vpk`) produces an install layout like:
//
//   <root>\Update.exe
//   <root>\current\fleetkanban_ui.exe       <- Platform.resolvedExecutable
//   <root>\packages\*.nupkg                  <- prior releases (for delta)
//
// Update.exe's CLI only exposes `apply | start | patch | uninstall` — it
// does not download updates itself. Velopack's own libraries (C#, Rust, ...)
// do that via an embedded HTTP client. Flutter/Dart has no official binding,
// and the community `velopack_flutter` package is 17 months stale, so we
// talk to GitHub Releases directly and hand a downloaded `-full.nupkg` to
// `Update.exe apply -p <path>`.
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
  VelopackUpdater({
    required this.currentVersion,
    String? installRootOverride,
  }) : _installRootOverride = installRootOverride;

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
    final updater = File('${candidate.path}${Platform.pathSeparator}Update.exe');
    return updater.existsSync() ? candidate : null;
  }

  bool get isDeployed => resolveInstallRoot() != null;

  /// Hits `GET /repos/:owner/:repo/releases/latest` and returns whether a
  /// newer tag is available alongside the `-full.nupkg` URL. Skips
  /// pre-releases because GitHub's `/latest` endpoint already does.
  Future<UpdateCheckResult> checkForUpdates() async {
    if (!isDeployed) {
      return UpdateCheckResult(
        available: false,
        currentVersion: currentVersion,
      );
    }
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
      final fullAsset = assets.firstWhere(
        (a) {
          final name = (a['name'] as String?) ?? '';
          return name.startsWith('$_packageId-') && name.endsWith('-full.nupkg');
        },
        orElse: () => <String, dynamic>{},
      );
      final downloadUrl = fullAsset['browser_download_url'] as String?;
      final isNewer = latest.isNotEmpty &&
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
  /// `<root>\packages\` and returns the local path.
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
    final leaf = url.split('/').last;
    final dest = File('${pkgDir.path}${Platform.pathSeparator}$leaf');

    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
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

  /// Hands [pkgPath] to `Update.exe apply --waitPid <us> -p <pkg>` and
  /// exits the current process so the updater can swap binaries.
  Future<Never> applyAndRestart(File pkgPath) async {
    final root = resolveInstallRoot();
    if (root == null) {
      throw VelopackUpdaterException('install root not found');
    }
    final updater = '${root.path}${Platform.pathSeparator}Update.exe';
    await Process.start(
      updater,
      [
        'apply',
        '--waitPid',
        '$pid',
        '-p',
        pkgPath.path,
      ],
      mode: ProcessStartMode.detached,
    );
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
