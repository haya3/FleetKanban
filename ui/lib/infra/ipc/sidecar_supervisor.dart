// SidecarSupervisor launches `fleetkanban-sidecar.exe` as a child process,
// parses its READY handshake from stdout, and exposes the negotiated
// (port, token) pair to the rest of the Flutter app.
//
// The sidecar protocol (see sidecar/cmd/fleetkanban-sidecar/main.go):
//   - stdout emits exactly one line: `READY port=<N> token=<base64>\n`
//     before any other output. stderr carries arbitrary logs before / after.
//   - gRPC calls must carry metadata `x-auth-token: <token>`.
//   - Shutdown is requested via SystemService.Shutdown; the sidecar then
//     exits within a few seconds.
//
// Windows Job Object: the Flutter runner (C++) is responsible for binding
// this process to a Job Object so a crashed UI cannot leak the sidecar.
// Dart-side, we additionally call `process.kill` on app shutdown as belt
// and suspenders.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    show Empty;

import '../../app/version.dart';
import 'generated/fleetkanban/v1/fleetkanban.pbgrpc.dart' as pb;

/// Negotiated endpoint info emitted by the sidecar's READY line.
class SidecarEndpoint {
  SidecarEndpoint({required this.port, required this.token});
  final int port;
  final String token;

  @override
  String toString() =>
      'SidecarEndpoint(port=$port, token=${token.substring(0, 6)}…)';
}

/// Exception thrown when the sidecar refuses to start or fails to emit a
/// well-formed handshake within the timeout.
class SidecarStartException implements Exception {
  SidecarStartException(this.message, [this.stderrTail]);
  final String message;
  final String? stderrTail;

  @override
  String toString() {
    if (stderrTail == null) return 'SidecarStartException: $message';
    return 'SidecarStartException: $message\n--- sidecar stderr ---\n$stderrTail';
  }
}

class SidecarSupervisor {
  SidecarSupervisor({
    required this.binaryPath,
    this.startupTimeout = const Duration(seconds: 20),
  });

  /// Absolute path to fleetkanban-sidecar.exe.
  final String binaryPath;

  /// How long to wait for the READY line before giving up.
  final Duration startupTimeout;

  Process? _process;
  SidecarEndpoint? _endpoint;
  final List<String> _stderrBuffer = <String>[];

  /// The current endpoint once [start] has completed successfully.
  SidecarEndpoint get endpoint {
    final e = _endpoint;
    if (e == null) {
      throw StateError('SidecarSupervisor.endpoint accessed before start()');
    }
    return e;
  }

  /// Spawns the sidecar, reads the handshake, and returns the endpoint.
  /// Throws [SidecarStartException] on any failure mode (missing binary,
  /// timeout, malformed READY line, sidecar already running, etc.).
  ///
  /// Before spawning, the supervisor first checks for an existing endpoint
  /// file written by a prior sidecar (same user, same machine). This lets
  /// Flutter hot restart — which re-runs main() and thus reaches this code
  /// path — reconnect to the already-running sidecar instead of fighting
  /// its singleton mutex.
  Future<SidecarEndpoint> start() async {
    if (_process != null) {
      throw StateError('SidecarSupervisor.start() called twice');
    }

    // Reconnect path: an alive sidecar, started by a previous run, wrote
    // its port/token to sidecar-endpoint.json. Validate the record, probe
    // its protocol version, and hand back the endpoint only when the
    // version matches this UI build. A mismatch (typical after a rebuild
    // where the old binary is still running) causes the old process to
    // be killed, the endpoint file removed, and execution falls through
    // to the spawn path below.
    final reused = await _tryReuseExisting();
    if (reused != null) {
      _endpoint = reused;
      return reused;
    }

    if (!File(binaryPath).existsSync()) {
      throw SidecarStartException('sidecar binary not found at $binaryPath');
    }

    final proc = await Process.start(
      binaryPath,
      const <String>['--log-level=info'],
      mode: ProcessStartMode.normal,
      runInShell: false,
    );
    _process = proc;

    // Drain stderr into a bounded ring buffer so start errors surface with
    // context and runtime logs don't fill memory.
    proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_recordStderr, onError: (_) {});

    // Watch for an unexpected exit during startup.
    final exitFuture = proc.exitCode;

    // Read stdout line-by-line looking for the READY line. The sidecar
    // emits exactly one line on stdout then goes silent.
    final stdoutLines = proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    try {
      final ready = await Future.any<String?>([
        stdoutLines.firstWhere(
          (line) => line.startsWith('READY '),
          orElse: () => '',
        ),
        exitFuture.then<String?>((code) {
          throw SidecarStartException(
            'sidecar exited with code $code before emitting READY',
            _stderrTail(),
          );
        }),
        Future<String?>.delayed(startupTimeout, () {
          throw SidecarStartException(
            'timed out after ${startupTimeout.inSeconds}s waiting for READY',
            _stderrTail(),
          );
        }),
      ]);

      if (ready == null || ready.isEmpty) {
        throw SidecarStartException(
          'sidecar stdout closed without READY line',
          _stderrTail(),
        );
      }

      final ep = _parseHandshake(ready);
      _endpoint = ep;
      return ep;
    } catch (_) {
      // If startup failed, make sure the child is not left dangling.
      proc.kill(ProcessSignal.sigterm);
      rethrow;
    }
  }

  /// Sends SIGTERM to the sidecar. Call after SystemService.Shutdown has
  /// returned (or timed out) to guarantee the process is gone.
  Future<int> kill() async {
    final p = _process;
    if (p == null) return 0;
    p.kill(ProcessSignal.sigterm);
    return p.exitCode;
  }

  /// Access to the child's exitCode future for lifecycle hookups.
  Future<int> get exitCode => _process?.exitCode ?? Future<int>.value(0);

  /// Returns the endpoint of an already-running sidecar by reading
  /// `%APPDATA%\FleetKanban\sidecar-endpoint.json`, or null when no live
  /// instance is found. Three-step validation:
  ///
  ///   1. JSON parse — corrupt file → delete + return null.
  ///   2. TCP probe  — port refuses → delete + return null.
  ///   3. Version probe — GetVersion RPC must return expectedSidecar
  ///      ProtocolVersion. Any mismatch (older sidecar missing the RPC,
  ///      different protocol number, etc.) is treated as "old process";
  ///      we ask it to Shutdown, force-kill any leftovers via taskkill,
  ///      delete the endpoint file, and return null so the caller spawns
  ///      a fresh instance.
  Future<SidecarEndpoint?> _tryReuseExisting() async {
    final file = File(_endpointFilePath());
    if (!file.existsSync()) return null;

    SidecarEndpoint? endpoint;
    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final port = (json['port'] as num?)?.toInt();
      final token = json['token'] as String?;
      if (port == null || token == null || token.isEmpty) {
        await _safeDelete(file);
        return null;
      }
      endpoint = SidecarEndpoint(port: port, token: token);
    } catch (_) {
      // Corrupt JSON, permission error, etc. — treat as "no record".
      await _safeDelete(file);
      return null;
    }

    // TCP probe: if the port refuses, the record is stale; remove it and
    // fall through to a fresh spawn.
    final socket = await Socket.connect(
      '127.0.0.1',
      endpoint.port,
      timeout: const Duration(seconds: 1),
    ).then<Socket?>((s) => s, onError: (_) => null);
    if (socket == null) {
      await _safeDelete(file);
      return null;
    }
    await socket.close();

    // Version probe.
    final versionOk = await _probeVersion(endpoint);
    if (!versionOk) {
      await _evictStaleSidecar(endpoint, file);
      return null;
    }
    return endpoint;
  }

  /// Opens a short-lived gRPC channel to the given endpoint and calls
  /// SystemService.GetVersion. Returns true when the reported protocol
  /// matches [expectedSidecarProtocolVersion], false on any mismatch or
  /// RPC failure (unimplemented, timeout, transport error). The channel
  /// is shut down before returning so the real client gets a clean slate.
  Future<bool> _probeVersion(SidecarEndpoint ep) async {
    final channel = ClientChannel(
      '127.0.0.1',
      port: ep.port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        idleTimeout: Duration(seconds: 5),
      ),
    );
    try {
      final stub = pb.SystemServiceClient(
        channel,
        options: CallOptions(
          metadata: {'x-auth-token': ep.token},
          timeout: const Duration(seconds: 3),
        ),
      );
      final info = await stub.getVersion(Empty());
      return info.protocolVersion == expectedSidecarProtocolVersion;
    } catch (_) {
      return false;
    } finally {
      await channel.shutdown();
    }
  }

  /// Terminates an old sidecar instance whose version didn't match.
  /// Tries the polite path first (SystemService.Shutdown with a short
  /// timeout), then falls back to taskkill to guarantee the process is
  /// gone before the caller spawns its replacement.
  Future<void> _evictStaleSidecar(SidecarEndpoint ep, File endpointFile) async {
    final channel = ClientChannel(
      '127.0.0.1',
      port: ep.port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        idleTimeout: Duration(seconds: 3),
      ),
    );
    try {
      final stub = pb.SystemServiceClient(
        channel,
        options: CallOptions(
          metadata: {'x-auth-token': ep.token},
          timeout: const Duration(seconds: 2),
        ),
      );
      await stub.shutdown(Empty()).catchError((_) => Empty());
    } catch (_) {
      // Ignore — we'll force-kill below.
    } finally {
      await channel.shutdown();
    }

    // Belt and suspenders: kill any lingering processes by image name.
    // The old binary may be frozen (ignoring Shutdown) or the call may
    // have raced against process exit. taskkill succeeds even when no
    // matching process is found (exit code 128) — its failure mode is
    // not actionable from here, so errors are swallowed.
    try {
      await Process.run('taskkill', const [
        '/F',
        '/IM',
        'fleetkanban-sidecar.exe',
      ], runInShell: false);
    } catch (_) {}

    await _safeDelete(endpointFile);
  }

  static Future<void> _safeDelete(File f) async {
    try {
      await f.delete();
    } catch (_) {}
  }

  /// Returns the absolute path where the sidecar persists its handshake.
  /// Mirrors the sidecar's `os.UserConfigDir()` logic so both agree on the
  /// location under Folder Redirection / Enterprise configs.
  static String _endpointFilePath() {
    final appData =
        Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        Directory.systemTemp.path;
    return '$appData${Platform.pathSeparator}FleetKanban${Platform.pathSeparator}sidecar-endpoint.json';
  }

  void _recordStderr(String line) {
    const maxLines = 200;
    _stderrBuffer.add(line);
    if (_stderrBuffer.length > maxLines) {
      _stderrBuffer.removeRange(0, _stderrBuffer.length - maxLines);
    }
  }

  String? _stderrTail() =>
      _stderrBuffer.isEmpty ? null : _stderrBuffer.join('\n');

  /// Parses `READY port=12345 token=abcdef`. Tolerates additional whitespace
  /// but requires both fields. Unknown extra fields are ignored so the
  /// protocol can be extended without breaking old clients.
  static SidecarEndpoint _parseHandshake(String line) {
    int? port;
    String? token;
    for (final part in line.trim().split(RegExp(r'\s+'))) {
      if (part == 'READY') continue;
      final eq = part.indexOf('=');
      if (eq <= 0) continue;
      final key = part.substring(0, eq);
      final value = part.substring(eq + 1);
      switch (key) {
        case 'port':
          port = int.tryParse(value);
        case 'token':
          token = value;
      }
    }
    if (port == null || token == null || token.isEmpty) {
      throw SidecarStartException('malformed handshake: "$line"');
    }
    return SidecarEndpoint(port: port, token: token);
  }
}

/// Resolves the sidecar binary path for the current run.
///
///   * Release build: `<exeDir>/fleetkanban-sidecar.exe` (copied by the MSIX /
///     packaging step; see Taskfile.yml flutter:build).
///   * Debug build  : `<repo>/build/bin/fleetkanban-sidecar.exe` (produced
///     by `task build:sidecar`).
///
/// The debug path is resolved by walking up from [Platform.script] and
/// looking for `build/bin/fleetkanban-sidecar.exe` under each ancestor. It is
/// intentionally lenient: if the script is somewhere unexpected we fall back
/// to the release layout so `flutter build windows` artifacts keep working.
String resolveSidecarBinary() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final releasePath = '$exeDir${Platform.pathSeparator}fleetkanban-sidecar.exe';

  // For Debug builds, prefer the canonical <repo>/build/bin/ binary so
  // a stale copy next to fleetkanban_ui.exe never overrides a freshly
  // rebuilt sidecar. Release builds (exe dir outside the Debug /
  // Release runner tree) keep the existing "colocated binary wins"
  // behaviour since MSIX packaging places the sidecar there.
  final isDebug =
      exeDir.contains('${Platform.pathSeparator}Debug') ||
      exeDir.contains('${Platform.pathSeparator}Profile');
  if (!isDebug && File(releasePath).existsSync()) return releasePath;

  final dir = Directory(exeDir);
  Directory? probe = dir;
  for (var i = 0; i < 8 && probe != null; i++) {
    final candidate =
        '${probe.path}${Platform.pathSeparator}build${Platform.pathSeparator}bin${Platform.pathSeparator}fleetkanban-sidecar.exe';
    if (File(candidate).existsSync()) return candidate;
    probe = probe.parent.path == probe.path ? null : probe.parent;
  }
  // Final fallback: colocated binary, even for Debug — at least surfaces
  // a sensible error message with the expected Debug-dir path.
  if (File(releasePath).existsSync()) return releasePath;
  return releasePath;
}
