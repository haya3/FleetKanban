// Subtask summary dialog: aggregates TaskEvents into a per-subtask digest so
// the user can see what each subtask actually did without trawling through
// the raw event log. The sidecar wraps each Code subtask in a
// subtask.start/end pair and emits assistant.delta / tool.start / tool.end
// events between them; we bucket those events by subtask_id and render:
//
//   * Status / agent role / model / duration
//   * The final assistant message (per prompt.go the agent is asked to
//     return a concise "what was done" summary on completion)
//   * Tool calls invoked during the subtask
//   * Any error payload recorded by subtask.end
//
// Invoked from two surfaces: _SubtaskRow (list view) in task_detail_dialog
// and _StageNodeCard (graph view) in subtask_dag_view for Code-stage nodes.

import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/ui_utils.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import '../../infra/ipc/providers.dart';

class SubtaskExecution {
  SubtaskExecution({required this.subtaskId});

  final String subtaskId;
  DateTime? startAt;
  DateTime? endAt;
  // Chronological log of the subtask's session events — reasoning
  // deltas, assistant text, tool calls — in arrival order. Drives the
  // unified "log view" in the detail dialog; the last assistant entry
  // is treated as the final summary.
  final List<LogEntry> log = <LogEntry>[];
  // Mutable bucket state used during bucketing. Exposed only so the
  // provider can drive buffering without re-implementing the state
  // machine per call site.
  final LogBucket bucket = LogBucket();
  final List<String> errors = <String>[];
  bool? ok;
  String? err;
  // Usage totals from the session.usage event matching this subtask. Null
  // when the runner reported no usage (free-tier model, or aborted before
  // first LLM call) so the dialog can suppress the row instead of
  // showing meaningless zeros.
  StageUsage? usage;

  List<ToolCall> get toolCalls => bucket.tools;

  /// Final assistant message — the summary by prompt contract. Derived
  /// from the last AssistantLogEntry in [log].
  String get assistantText {
    for (var i = log.length - 1; i >= 0; i--) {
      final e = log[i];
      if (e is AssistantLogEntry) return e.text;
    }
    return '';
  }

  Duration? get duration {
    if (startAt == null || endAt == null) return null;
    return endAt!.difference(startAt!);
  }
}

/// Single chronological entry in a session log. Subclasses cover the
/// three kinds of event the UI cares about: reasoning (model thinking
/// channel), assistant text (user-visible response), and tool call
/// (with args + outcome).
sealed class LogEntry {
  LogEntry(this.at);
  final DateTime? at;
}

class ReasoningLogEntry extends LogEntry {
  ReasoningLogEntry(super.at, this.text);
  final String text;
}

class AssistantLogEntry extends LogEntry {
  AssistantLogEntry(super.at, this.text);
  final String text;
}

class ToolLogEntry extends LogEntry {
  ToolLogEntry(this.call) : super(call.at);
  final ToolCall call;
}

/// Stateful helper that turns the sidecar's event stream into a
/// chronological [LogEntry] list. Buffers consecutive delta events of
/// the same kind into a single entry so the UI renders "paragraphs"
/// instead of a shredded per-line log. Call [add] for each event and
/// [finalize] once the bucket is done (e.g. subtask.end) to flush any
/// trailing buffered text.
class LogBucket {
  final List<LogEntry> entries = <LogEntry>[];
  final List<ToolCall> tools = <ToolCall>[];
  final Map<String, ToolCall> _toolsById = <String, ToolCall>{};

  final StringBuffer _reasonBuf = StringBuffer();
  DateTime? _reasonStart;
  final StringBuffer _assistantBuf = StringBuffer();
  DateTime? _assistantStart;

  void addReasoning(String text, DateTime? at) {
    _flushAssistant();
    _reasonStart ??= at;
    if (_reasonBuf.isNotEmpty) _reasonBuf.writeln();
    _reasonBuf.write(text);
  }

  void addAssistant(String text, DateTime? at) {
    _flushReasoning();
    _assistantStart ??= at;
    if (_assistantBuf.isNotEmpty) _assistantBuf.writeln();
    _assistantBuf.write(text);
  }

  ToolCall addToolStart({
    required String name,
    required String args,
    required String? id,
    required DateTime? at,
  }) {
    _flushReasoning();
    _flushAssistant();
    final call = ToolCall(name: name, args: args, at: at);
    tools.add(call);
    if (id != null && id.isNotEmpty) _toolsById[id] = call;
    entries.add(ToolLogEntry(call));
    return call;
  }

  ToolCall? applyToolEnd({
    required String? id,
    required bool? ok,
    required String? err,
    required String? result,
    required DateTime? at,
  }) {
    if (id == null || id.isEmpty) return null;
    final call = _toolsById[id];
    if (call == null) return null;
    call.ok = ok;
    call.err = err;
    call.result = result;
    call.endAt = at;
    return call;
  }

  void finalize() {
    _flushReasoning();
    _flushAssistant();
  }

  void _flushReasoning() {
    if (_reasonBuf.isEmpty) return;
    entries.add(ReasoningLogEntry(_reasonStart, _reasonBuf.toString()));
    _reasonBuf.clear();
    _reasonStart = null;
  }

  void _flushAssistant() {
    if (_assistantBuf.isEmpty) return;
    entries.add(AssistantLogEntry(_assistantStart, _assistantBuf.toString()));
    _assistantBuf.clear();
    _assistantStart = null;
  }
}

/// Single tool invocation observed during a subtask or planning
/// session: the tool name, a compact argument preview, a start-time
/// timestamp, and the outcome after the matching tool.end event
/// back-fills it. Rendered as a log-style row so users can see
/// WHAT was done and WHEN without trawling the raw event stream.
class ToolCall {
  ToolCall({required this.name, required this.args, this.at, this.endAt});
  final String name;
  String args;
  // Start-time of the tool.start event. Null only for legacy events
  // that lacked an occurred_at timestamp — those render without the
  // leading time stamp.
  DateTime? at;
  // Completion-time from the matching tool.end event. Used to show
  // duration on long-running tool calls.
  DateTime? endAt;
  bool? ok;
  String? err;
  String? result;

  Duration? get duration {
    if (at == null || endAt == null) return null;
    return endAt!.difference(at!);
  }
}

/// StageUsage mirrors task.SessionUsage on the wire so the UI can display
/// per-stage premium-request consumption surfaced via session.usage events.
class StageUsage {
  StageUsage({
    required this.model,
    required this.premiumRequests,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.durationMs,
    required this.calls,
  });

  final String model;
  final double premiumRequests;
  final int inputTokens;
  final int outputTokens;
  final int cacheReadTokens;
  final int durationMs;
  final int calls;

  /// Adds another StageUsage's totals into this one (in-place sum). The
  /// model field follows last-write-wins, which is fine for aggregates
  /// where the caller doesn't care about per-call attribution.
  StageUsage plus(StageUsage other) => StageUsage(
    model: other.model.isNotEmpty ? other.model : model,
    premiumRequests: premiumRequests + other.premiumRequests,
    inputTokens: inputTokens + other.inputTokens,
    outputTokens: outputTokens + other.outputTokens,
    cacheReadTokens: cacheReadTokens + other.cacheReadTokens,
    durationMs: durationMs + other.durationMs,
    calls: calls + other.calls,
  );

  static StageUsage? fromPayload(String payload) {
    if (payload.isEmpty) return null;
    try {
      final m = jsonDecode(payload);
      if (m is! Map<String, dynamic>) return null;
      return StageUsage(
        model: (m['model'] as String?) ?? '',
        premiumRequests: _asDouble(m['premium_requests']),
        inputTokens: _asInt(m['input_tokens']),
        outputTokens: _asInt(m['output_tokens']),
        cacheReadTokens: _asInt(m['cache_read_tokens']),
        durationMs: _asInt(m['duration_ms']),
        calls: _asInt(m['calls']),
      );
    } catch (_) {
      return null;
    }
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

/// Aggregates per-subtask execution summaries from the parent task's event
/// stream. Family key = parent task id. autoDispose so reopening the dialog
/// refetches; the sidecar keeps events in SQLite so the cost is a single
/// cheap unary call.
final subtaskExecutionsProvider = FutureProvider.autoDispose
    .family<Map<String, SubtaskExecution>, String>((ref, taskId) async {
      final client = ref.watch(ipcClientProvider);
      final resp = await client.task.taskEvents(
        pb.TaskEventsRequest(taskId: taskId),
      );
      return _bucketEvents(resp.events);
    });

/// Fetches the persisted system+user prompt and injected context for a
/// single subtask run. Round 0 (the UI default) asks the sidecar for the
/// latest recorded round. autoDispose so reopening the dialog refetches,
/// matching subtaskExecutionsProvider semantics. Returns null on any
/// transport error so the UI renders "context unavailable" instead of
/// bubbling a raw gRPC exception into the dialog body.
final subtaskContextProvider = FutureProvider.autoDispose
    .family<pb.CopilotSubtaskContext?, String>((ref, subtaskId) async {
      final client = ref.watch(ipcClientProvider);
      try {
        return await client.subtask.getSubtaskContext(
          pb.GetSubtaskContextRequest(subtaskId: subtaskId),
        );
      } catch (_) {
        return null;
      }
    });

/// Review history for a parent task: every AI Reviewer verdict plus every
/// human SubmitReview decision, in chronological order. Surfaced in the
/// subtask summary dialog so the user can see what feedback came back
/// from past review cycles.
class ReviewEntry {
  ReviewEntry({
    required this.at,
    required this.source,
    required this.action,
    required this.feedback,
    required this.summary,
    required this.reworkCount,
    required this.round,
    required this.model,
  });
  final DateTime? at;
  final ReviewSource source;
  // For AI: 'approve' | 'rework'. For human: 'approve' | 'rework' | 'reject'.
  final String action;
  final String feedback;
  // AI: reviewer rationale preceding the APPROVE/REWORK marker. Empty
  // for humans (no rationale field on the SubmitReview path).
  final String summary;
  final int reworkCount;
  // Round the review was issued against. 1-indexed. Legacy events
  // without a round field default to 1.
  final int round;
  final String model;
}

enum ReviewSource { ai, human }

final taskReviewsProvider = FutureProvider.autoDispose
    .family<List<ReviewEntry>, String>((ref, taskId) async {
      final client = ref.watch(ipcClientProvider);
      final resp = await client.task.taskEvents(
        pb.TaskEventsRequest(taskId: taskId),
      );
      final out = <ReviewEntry>[];
      for (final ev in resp.events) {
        final at = ev.hasOccurredAt()
            ? ev.occurredAt.toDateTime().toLocal()
            : null;
        final m = _tryDecode(ev.payload);
        if (m == null) continue;
        if (ev.kind == 'ai_review.decision') {
          final approve = m['approve'] == true;
          final reworkCount = (m['rework_count'] as num?)?.toInt() ?? 0;
          final round = (m['round'] as num?)?.toInt() ?? (reworkCount + 1);
          out.add(
            ReviewEntry(
              at: at,
              source: ReviewSource.ai,
              action: approve ? 'approve' : 'rework',
              feedback: (m['feedback'] as String?) ?? '',
              summary: (m['summary'] as String?) ?? '',
              reworkCount: reworkCount,
              round: round < 1 ? 1 : round,
              model: (m['model'] as String?) ?? '',
            ),
          );
        } else if (ev.kind == 'review.submitted') {
          final round = (m['round'] as num?)?.toInt() ?? 1;
          out.add(
            ReviewEntry(
              at: at,
              source: ReviewSource.human,
              action: (m['action'] as String?) ?? '',
              feedback: (m['feedback'] as String?) ?? '',
              summary: '',
              reworkCount: 0,
              round: round < 1 ? 1 : round,
              model: '',
            ),
          );
        }
      }
      return out;
    });

Map<String, SubtaskExecution> _bucketEvents(Iterable<pb.AgentEvent> events) {
  final out = <String, SubtaskExecution>{};
  String? current;
  for (final ev in events) {
    final at = ev.hasOccurredAt() ? ev.occurredAt.toDateTime().toLocal() : null;
    switch (ev.kind) {
      case 'subtask.start':
        final id = _readStringField(ev.payload, 'subtask_id');
        if (id == null) continue;
        current = id;
        final bucket = out.putIfAbsent(
          id,
          () => SubtaskExecution(subtaskId: id),
        );
        if (at != null) bucket.startAt = at;
      case 'subtask.end':
        final id = _readStringField(ev.payload, 'subtask_id') ?? current;
        if (id == null) continue;
        final exec = out.putIfAbsent(id, () => SubtaskExecution(subtaskId: id));
        if (at != null) exec.endAt = at;
        final decoded = _tryDecode(ev.payload);
        exec.ok = decoded?['ok'] as bool?;
        final errVal = decoded?['err'];
        if (errVal is String && errVal.isNotEmpty) exec.err = errVal;
        current = null;
      case 'assistant.reasoning.delta':
        if (current == null) continue;
        out[current]?.bucket.addReasoning(ev.payload, at);
      case 'assistant.delta':
        if (current == null) continue;
        out[current]?.bucket.addAssistant(ev.payload, at);
      case 'tool.start':
        if (current == null) continue;
        final name = _readStringField(ev.payload, 'name');
        if (name == null || name.isEmpty) continue;
        final exec = out[current];
        if (exec == null) continue;
        final args = _readStringField(ev.payload, 'args') ?? '';
        final id = _readStringField(ev.payload, 'id');
        exec.bucket.addToolStart(name: name, args: args, id: id, at: at);
      case 'tool.end':
        if (current == null) continue;
        final exec = out[current];
        if (exec == null) continue;
        exec.bucket.applyToolEnd(
          id: _readStringField(ev.payload, 'id'),
          ok: _readBoolField(ev.payload, 'ok'),
          err: _readStringField(ev.payload, 'err'),
          result: _readStringField(ev.payload, 'result'),
          at: at,
        );
      case 'session.usage':
        // Code-stage usage events carry the subtask_id field; plan/review
        // usage doesn't and is consumed by the task-level aggregate
        // instead. Skip when subtask_id is missing here.
        final id = _readStringField(ev.payload, 'subtask_id');
        if (id == null) continue;
        final exec = out.putIfAbsent(id, () => SubtaskExecution(subtaskId: id));
        exec.usage = StageUsage.fromPayload(ev.payload);
      case 'error':
      case 'security.path_escape':
        if (current == null) continue;
        out[current]?.errors.add(ev.payload);
    }
  }
  // Flush trailing buffered text into the log once per subtask, so the
  // in-progress view is not blank mid-session and the final view
  // captures the last assistant/reasoning block.
  for (final exec in out.values) {
    exec.bucket.finalize();
    exec.log
      ..clear()
      ..addAll(exec.bucket.entries);
  }
  return out;
}

/// Builds a [LogBucket] containing all planner session events that
/// fired before the first `subtask.start` of the given round. Reworks
/// produce a fresh planning pass per round; the bucket resets each
/// time it crosses an `ai_review.decision` (end of previous round) so
/// round-N Plan events don't get mixed into round-(N+1).
LogBucket buildPlanLogForRound(Iterable<pb.AgentEvent> events, int round) {
  final bucket = LogBucket();
  int currentRound = 1;
  bool inPlan = true; // pre-subtask events are always plan-phase
  for (final ev in events) {
    final at = ev.hasOccurredAt() ? ev.occurredAt.toDateTime().toLocal() : null;
    switch (ev.kind) {
      case 'subtask.start':
        // Fence: plan for currentRound is done once execution begins.
        if (currentRound == round) {
          return bucket;
        }
        inPlan = false;
      case 'subtask.end':
        // no-op; plan phase remains closed until next round's reset.
        break;
      case 'ai_review.decision':
        // Round boundary. Next events belong to the following round's
        // Plan phase (if a rework is issued). Reset buffers so the
        // new round's planner log starts fresh.
        final m = _tryDecode(ev.payload);
        final reworkCount = (m?['rework_count'] as num?)?.toInt() ?? 0;
        final decisionRound =
            (m?['round'] as num?)?.toInt() ?? (reworkCount + 1);
        currentRound = decisionRound + 1;
        inPlan = true;
        if (currentRound > round) {
          return bucket;
        }
        // Clear any accumulated events for previous rounds.
        bucket.entries.clear();
        bucket.tools.clear();
      case 'assistant.reasoning.delta':
        if (inPlan && currentRound == round) {
          bucket.addReasoning(ev.payload, at);
        }
      case 'assistant.delta':
        if (inPlan && currentRound == round) {
          bucket.addAssistant(ev.payload, at);
        }
      case 'tool.start':
        if (inPlan && currentRound == round) {
          final name = _readStringField(ev.payload, 'name');
          if (name == null || name.isEmpty) continue;
          bucket.addToolStart(
            name: name,
            args: _readStringField(ev.payload, 'args') ?? '',
            id: _readStringField(ev.payload, 'id'),
            at: at,
          );
        }
      case 'tool.end':
        if (inPlan && currentRound == round) {
          bucket.applyToolEnd(
            id: _readStringField(ev.payload, 'id'),
            ok: _readBoolField(ev.payload, 'ok'),
            err: _readStringField(ev.payload, 'err'),
            result: _readStringField(ev.payload, 'result'),
            at: at,
          );
        }
    }
  }
  bucket.finalize();
  return bucket;
}

/// Builds a [LogBucket] for the AI Review session of [round]. Events
/// between `ai_review.start` (matching round) and the next
/// `ai_review.decision` of the same round are captured.
LogBucket buildReviewLogForRound(Iterable<pb.AgentEvent> events, int round) {
  final bucket = LogBucket();
  bool active = false;
  for (final ev in events) {
    final at = ev.hasOccurredAt() ? ev.occurredAt.toDateTime().toLocal() : null;
    switch (ev.kind) {
      case 'ai_review.start':
        final m = _tryDecode(ev.payload);
        final r = (m?['round'] as num?)?.toInt() ?? 1;
        if (r == round) {
          active = true;
          bucket.entries.clear();
          bucket.tools.clear();
        }
      case 'ai_review.decision':
        if (!active) continue;
        final m = _tryDecode(ev.payload);
        final reworkCount = (m?['rework_count'] as num?)?.toInt() ?? 0;
        final r = (m?['round'] as num?)?.toInt() ?? (reworkCount + 1);
        if (r == round) {
          bucket.finalize();
          return bucket;
        }
      case 'assistant.reasoning.delta':
        if (active) bucket.addReasoning(ev.payload, at);
      case 'assistant.delta':
        if (active) bucket.addAssistant(ev.payload, at);
      case 'tool.start':
        if (!active) continue;
        final name = _readStringField(ev.payload, 'name');
        if (name == null || name.isEmpty) continue;
        bucket.addToolStart(
          name: name,
          args: _readStringField(ev.payload, 'args') ?? '',
          id: _readStringField(ev.payload, 'id'),
          at: at,
        );
      case 'tool.end':
        if (!active) continue;
        bucket.applyToolEnd(
          id: _readStringField(ev.payload, 'id'),
          ok: _readBoolField(ev.payload, 'ok'),
          err: _readStringField(ev.payload, 'err'),
          result: _readStringField(ev.payload, 'result'),
          at: at,
        );
    }
  }
  bucket.finalize();
  return bucket;
}

String? _readStringField(String payload, String key) {
  final m = _tryDecode(payload);
  final v = m?[key];
  return v is String ? v : null;
}

bool? _readBoolField(String payload, String key) {
  final m = _tryDecode(payload);
  final v = m?[key];
  return v is bool ? v : null;
}

Map<String, dynamic>? _tryDecode(String payload) {
  if (payload.isEmpty) return null;
  try {
    final v = jsonDecode(payload);
    return v is Map<String, dynamic> ? v : null;
  } catch (_) {
    return null;
  }
}

Future<void> showSubtaskSummaryDialog(
  BuildContext context, {
  required String taskId,
  required pb.Subtask subtask,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SubtaskSummaryDialog(taskId: taskId, subtask: subtask),
  );
}

class _SubtaskSummaryDialog extends ConsumerWidget {
  const _SubtaskSummaryDialog({required this.taskId, required this.subtask});

  final String taskId;
  final pb.Subtask subtask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final executionsAsync = ref.watch(subtaskExecutionsProvider(taskId));
    final reviewsAsync = ref.watch(taskReviewsProvider(taskId));

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
      title: Row(
        children: [
          Expanded(
            child: Text(
              subtask.title.isEmpty ? '(no title)' : subtask.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          clickable(
            IconButton(
              icon: const Icon(FluentIcons.chrome_close, size: 14),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 680,
        height: 500,
        child: executionsAsync.when(
          loading: () => const Center(child: ProgressRing()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Failed to load events: $e'),
          ),
          data: (bucketed) {
            final exec = bucketed[subtask.id];
            return _SummaryBody(
              subtask: subtask,
              exec: exec,
              reviews: reviewsAsync.value ?? const [],
              theme: theme,
            );
          },
        ),
      ),
      actions: [
        clickable(
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({
    required this.subtask,
    required this.exec,
    required this.reviews,
    required this.theme,
  });

  final pb.Subtask subtask;
  final SubtaskExecution? exec;
  final List<ReviewEntry> reviews;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = exec?.usage;
    final kv = <(String, String)>[
      ('Status', subtask.status),
      if (subtask.agentRole.isNotEmpty) ('Agent role', subtask.agentRole),
      if (subtask.round > 0) ('Round', '${subtask.round}'),
      if (subtask.codeModel.isNotEmpty) ('Code model', subtask.codeModel),
      if (exec?.startAt != null) ('Started', _fmt(exec!.startAt!)),
      if (exec?.endAt != null) ('Finished', _fmt(exec!.endAt!)),
      if (exec?.duration != null) ('Duration', _fmtDuration(exec!.duration!)),
      if (usage != null)
        ('Premium req.', usage.premiumRequests.toStringAsFixed(2)),
      if (usage != null && (usage.inputTokens > 0 || usage.outputTokens > 0))
        (
          'Tokens',
          'in ${_fmtTokens(usage.inputTokens)} / out ${_fmtTokens(usage.outputTokens)}'
              '${usage.cacheReadTokens > 0 ? ' (cache ${_fmtTokens(usage.cacheReadTokens)})' : ''}',
        ),
      if (usage != null && usage.calls > 0) ('LLM calls', '${usage.calls}'),
      if (exec?.err != null) ('Error', exec!.err!),
    ];
    final logEntries = exec?.log ?? const <LogEntry>[];
    final summary = exec?.assistantText.trim() ?? '';
    final errors = exec?.errors ?? const <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in kv)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      r.$1,
                      style: theme.typography.caption?.copyWith(
                        color: theme.resources.textFillColorSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      r.$2,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (subtask.prompt.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader('Planner instruction', theme),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.accentColor.normal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.accentColor.normal.withValues(alpha: 0.35),
                ),
              ),
              child: MarkdownBody(
                data: subtask.prompt,
                selectable: true,
                styleSheet: _markdownStyle(theme),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionHeader('Agent context (as the agent saw it)', theme),
          const SizedBox(height: 4),
          _ContextSection(subtaskId: subtask.id, theme: theme),
          const SizedBox(height: 16),
          _SectionHeader('Log', theme),
          const SizedBox(height: 4),
          if (logEntries.isEmpty)
            Text(
              exec == null
                  ? 'This subtask has not run yet.'
                  : 'No log output was recorded.',
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorTertiary,
              ),
            )
          else
            LogView(entries: logEntries, theme: theme),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader('Summary', theme),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.resources.subtleFillColorSecondary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.resources.controlStrokeColorDefault,
                ),
              ),
              child: MarkdownBody(
                data: summary,
                selectable: true,
                styleSheet: _markdownStyle(theme),
              ),
            ),
          ],
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader('Errors (${errors.length})', theme),
            const SizedBox(height: 4),
            for (final e in errors)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SelectableText(
                  e,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Consolas',
                    color: Color(0xFFC42B1C),
                  ),
                ),
              ),
          ],
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader('Review feedback (${reviews.length})', theme),
            const SizedBox(height: 4),
            for (final r in reviews) ReviewCard(entry: r, theme: theme),
          ],
        ],
      ),
    );
  }

  static String _fmt(DateTime t) => t.toString().substring(0, 19);
  static String _fmtDuration(Duration d) {
    if (d.inSeconds < 1) return '${d.inMilliseconds} ms';
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    final m = d.inMinutes;
    final s = d.inSeconds - m * 60;
    return '${m}m ${s}s';
  }

  static String _fmtTokens(int n) {
    if (n < 1000) return '$n';
    if (n < 1_000_000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1_000_000).toStringAsFixed(2)}M';
  }
}

/// Renders a chronological [LogEntry] list. Each entry occupies one
/// log row prefixed by its timestamp — reasoning in italics, assistant
/// text in body colour, tool calls via [ToolCallRow]. Designed so the
/// user can scan a session top-to-bottom and see EVERY step (think →
/// tool use → think → summary) without toggling collapsed sections.
class LogView extends StatelessWidget {
  const LogView({super.key, required this.entries, required this.theme});
  final List<LogEntry> entries;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final e in entries) _renderEntry(e)],
    );
  }

  Widget _renderEntry(LogEntry e) {
    return switch (e) {
      ReasoningLogEntry(:final at, :final text) => _TimestampedText(
        at: at,
        text: text,
        prefix: '… ',
        color: theme.resources.textFillColorSecondary,
        italic: true,
      ),
      AssistantLogEntry(:final at, :final text) => _TimestampedText(
        at: at,
        text: text,
        prefix: '» ',
        color: theme.resources.textFillColorPrimary,
        italic: false,
      ),
      ToolLogEntry(:final call) => ToolCallRow(call: call, theme: theme),
    };
  }
}

class _TimestampedText extends StatelessWidget {
  const _TimestampedText({
    required this.at,
    required this.text,
    required this.prefix,
    required this.color,
    required this.italic,
  });

  final DateTime? at;
  final String text;
  final String prefix;
  final Color color;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final timeLabel = at == null ? '        ' : _fmtTime(at!);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: SelectableText.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: 'Consolas',
            fontSize: 12,
            height: 1.5,
            color: color,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
          children: [
            TextSpan(
              text: '$timeLabel ',
              style: TextStyle(
                color: theme.resources.textFillColorSecondary,
                fontStyle: FontStyle.normal,
              ),
            ),
            TextSpan(text: prefix),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    String p2(int n) => n.toString().padLeft(2, '0');
    String p3(int n) => n.toString().padLeft(3, '0');
    return '${p2(t.hour)}:${p2(t.minute)}:${p2(t.second)}.${p3(t.millisecond)}';
  }
}

/// Log-style renderer for a single [ToolCall]. Layout:
///
///     21:51:37.099 [view] ok (104 ms)
///         path: C:\…\README.md
///         → 1. # TestRepo\n2. …
///
/// Designed to fill the role of a terminal log line so users can
/// scan WHEN + WHAT + OUTCOME without toggling collapsed sections.
class ToolCallRow extends StatelessWidget {
  const ToolCallRow({super.key, required this.call, required this.theme});
  final ToolCall call;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    final accent = theme.accentColor.normal;
    final hasErr = call.err != null && call.err!.isNotEmpty;
    final okColor = hasErr
        ? const Color(0xFFC42B1C)
        : call.ok == true
        ? const Color(0xFF107C10)
        : theme.resources.textFillColorTertiary;
    final okLabel = hasErr
        ? 'ERR'
        : call.ok == true
        ? 'ok'
        : call.ok == false
        ? 'fail'
        : '…';
    final timeLabel = call.at == null ? '        ' : _fmtTime(call.at!);
    final durLabel = call.duration == null
        ? ''
        : ' (${_fmtDuration(call.duration!)})';
    final outcome = hasErr ? call.err! : (call.result ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorTertiary,
        borderRadius: BorderRadius.circular(2),
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.35), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: theme.resources.textFillColorPrimary,
              ),
              children: [
                TextSpan(
                  text: timeLabel,
                  style: TextStyle(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: '[${call.name}]',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: okLabel,
                  style: TextStyle(color: okColor, fontWeight: FontWeight.w600),
                ),
                if (durLabel.isNotEmpty)
                  TextSpan(
                    text: durLabel,
                    style: TextStyle(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (call.args.isNotEmpty) ...[
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: SelectableText(
                call.args,
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  color: theme.resources.textFillColorPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          if (outcome.isNotEmpty) ...[
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: SelectableText(
                '→ $outcome',
                maxLines: 3,
                style: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  color: hasErr
                      ? const Color(0xFFC42B1C)
                      : theme.resources.textFillColorSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    String p2(int n) => n.toString().padLeft(2, '0');
    String p3(int n) => n.toString().padLeft(3, '0');
    return '${p2(t.hour)}:${p2(t.minute)}:${p2(t.second)}.${p3(t.millisecond)}';
  }

  static String _fmtDuration(Duration d) {
    if (d.inMilliseconds < 1000) return '${d.inMilliseconds} ms';
    if (d.inSeconds < 60) {
      return '${d.inSeconds}.${((d.inMilliseconds % 1000) / 100).floor()}s';
    }
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.entry, required this.theme});
  final ReviewEntry entry;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isAI = entry.source == ReviewSource.ai;
    final approved = entry.action == 'approve';
    final accent = approved
        ? const Color(0xFF107C10)
        : entry.action == 'reject'
        ? const Color(0xFFC42B1C)
        : theme.accentColor.normal;
    final actionLabel = entry.action.toUpperCase();
    final sourceLabel = isAI ? 'AI' : 'Human';
    final timeLabel = entry.at == null
        ? ''
        : entry.at!.toString().substring(0, 19);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$sourceLabel · $actionLabel',
                  style: theme.typography.caption?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              if (entry.reworkCount > 0) ...[
                const SizedBox(width: 6),
                Text(
                  'rework #${entry.reworkCount}',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
              if (entry.model.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  entry.model,
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorTertiary,
                    fontFamily: 'Consolas',
                    fontSize: 10,
                  ),
                ),
              ],
              const Spacer(),
              if (timeLabel.isNotEmpty)
                Text(
                  timeLabel,
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorTertiary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          if (entry.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            MarkdownBody(
              data: entry.summary,
              selectable: true,
              styleSheet: _markdownStyle(theme),
            ),
          ],
          if (entry.feedback.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.source == ReviewSource.ai ? 'Feedback' : 'Input',
              style: theme.typography.caption?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            MarkdownBody(
              data: entry.feedback,
              selectable: true,
              styleSheet: _markdownStyle(theme),
            ),
          ],
        ],
      ),
    );
  }
}

// _markdownStyle matches the Fluent UI typography so planner
// instructions, run summaries, and reviewer feedback render with
// real paragraph breaks / bullets / code blocks instead of as a
// run-on string.
MarkdownStyleSheet _markdownStyle(FluentThemeData theme) {
  return MarkdownStyleSheet(
    p: theme.typography.body?.copyWith(fontSize: 12, height: 1.5),
    h1: theme.typography.bodyStrong?.copyWith(fontSize: 15),
    h2: theme.typography.bodyStrong?.copyWith(fontSize: 14),
    h3: theme.typography.bodyStrong?.copyWith(fontSize: 13),
    listBullet: theme.typography.body?.copyWith(fontSize: 12, height: 1.5),
    code: TextStyle(
      fontFamily: 'Consolas',
      fontSize: 11,
      backgroundColor: theme.resources.subtleFillColorTertiary,
    ),
    codeblockDecoration: BoxDecoration(
      color: theme.resources.subtleFillColorTertiary,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: theme.resources.controlStrokeColorDefault),
    ),
    codeblockPadding: const EdgeInsets.all(8),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: theme.accentColor.normal.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
    ),
    blockquotePadding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, this.theme);
  final String label;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.typography.bodyStrong?.copyWith(fontSize: 13),
    );
  }
}

/// _ContextSection renders the persisted "what the agent saw" for a
/// subtask run inside four collapsible Expanders (system prompt / user
/// prompt / injected context / harness). Uses the subtaskContextProvider
/// so a sidecar that predates the v18 schema, or a subtask that hasn't
/// been executed under v18+ yet, degrades to a single "not recorded"
/// notice instead of swallowing the whole section.
class _ContextSection extends ConsumerWidget {
  const _ContextSection({required this.subtaskId, required this.theme});

  final String subtaskId;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subtaskContextProvider(subtaskId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: ProgressRing(strokeWidth: 2),
        ),
      ),
      error: (e, _) =>
          _ContextFallback(message: 'Context unavailable: $e', theme: theme),
      data: (ctx) {
        if (ctx == null) {
          return _ContextFallback(
            message:
                'The sidecar returned no context snapshot for this subtask.',
            theme: theme,
          );
        }
        if (ctx.notRecorded) {
          return _ContextFallback(
            message:
                'This subtask ran before the sidecar started recording '
                'prompts (schema v18+). The agent saw the stage template + '
                'planner instruction shown above, plus any memory block and '
                'prior-subtask summaries available at run time, but the '
                'exact text was not persisted.',
            theme: theme,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ContextExpander(
              header: 'System prompt (SDK SystemMessage)',
              hint:
                  'Stage template + output-language addendum sent as the '
                  'session-level system message.',
              body: ctx.systemPrompt,
              theme: theme,
            ),
            _ContextExpander(
              header: 'User prompt (SDK first message)',
              hint:
                  'Memory block (if any) + composed subtask prompt: parent '
                  'goal, plan summary, prior-subtask summaries, role, title, '
                  'and the planner-authored instruction.',
              body: ctx.userPrompt,
              theme: theme,
            ),
            _ContextExpander(
              header: 'Injected context pieces',
              hint:
                  'The individual ingredients the user prompt was built '
                  'from — useful when the composed prompt is long and you '
                  'want to find one specific piece.',
              body: _formatInjected(ctx),
              theme: theme,
            ),
            _ContextExpander(
              header: _harnessHeader(ctx),
              hint: ctx.harnessSkillVersionId.isEmpty
                  ? 'No harness_skill_version row was attached to this run '
                        '(user has not saved a SKILL.md edit yet). The body '
                        'below is the live harness-skill/SKILL.md on disk — '
                        'which falls back to the embedded default when no '
                        'file exists.'
                  : 'The IHR Charter (SKILL.md) that was active when this '
                        'subtask ran. Edits made to harness-skill/SKILL.md '
                        'after this row was recorded are NOT reflected here.',
              body: ctx.harnessSkillMd.isEmpty
                  ? '(SKILL.md content unavailable — the sidecar could not '
                        'read harness-skill/SKILL.md from disk nor the '
                        'embedded seed. Check the sidecar log for the '
                        'underlying error.)'
                  : ctx.harnessSkillMd,
              theme: theme,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Snapshot round ${ctx.round}'
                '${ctx.harnessSkillVersionId.isEmpty ? '' : ' · harness ${ctx.harnessSkillVersionId}'}',
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorTertiary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _harnessHeader(pb.CopilotSubtaskContext ctx) {
    if (ctx.harnessSkillVersionId.isEmpty) {
      return 'Harness (embedded default)';
    }
    return 'Harness (SKILL.md v${ctx.harnessSkillVersionId.substring(0, 8)})';
  }

  static String _formatInjected(pb.CopilotSubtaskContext ctx) {
    final parts = <String>[];
    parts.add(
      '# Stage prompt template (raw, pre-addendum)\n${ctx.stagePromptTemplate}',
    );
    parts.add(
      '# Output language addendum\n'
      '${ctx.outputLanguage.isEmpty ? '(none — defaults to the model preference)' : ctx.outputLanguage}',
    );
    parts.add(
      '# Plan summary\n'
      '${ctx.planSummary.isEmpty ? '(no plan summary was available)' : ctx.planSummary}',
    );
    if (ctx.priorSummaries.isEmpty) {
      parts.add('# Prior subtask summaries\n(this was the first subtask run)');
    } else {
      final buf = StringBuffer('# Prior subtask summaries\n');
      for (var i = 0; i < ctx.priorSummaries.length; i++) {
        buf.writeln('${i + 1}. ${ctx.priorSummaries[i]}');
      }
      parts.add(buf.toString().trimRight());
    }
    parts.add(
      '# Memory block (Passive injection)\n'
      '${ctx.memoryBlock.isEmpty ? '(memory injection was disabled or empty for this repo)' : ctx.memoryBlock}',
    );
    return parts.join('\n\n');
  }
}

class _ContextExpander extends StatelessWidget {
  const _ContextExpander({
    required this.header,
    required this.hint,
    required this.body,
    required this.theme,
  });

  final String header;
  final String hint;
  final String body;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Expander(
        header: Text(header, style: theme.typography.body),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hint,
              style: theme.typography.caption?.copyWith(
                color: theme.resources.textFillColorTertiary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.resources.subtleFillColorSecondary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.resources.controlStrokeColorDefault,
                ),
              ),
              child: SelectableText(
                body.isEmpty ? '(empty)' : body,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextFallback extends StatelessWidget {
  const _ContextFallback({required this.message, required this.theme});
  final String message;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.resources.controlStrokeColorDefault),
      ),
      child: Text(
        message,
        style: theme.typography.caption?.copyWith(
          color: theme.resources.textFillColorSecondary,
        ),
      ),
    );
  }
}
