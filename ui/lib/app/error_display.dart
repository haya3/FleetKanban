// Error display primitives: widgets that surface errors in a way the user
// can actually copy. Fluent's ContentDialog and InfoBar both use plain
// Text by default, which blocks text selection — making it impossible to
// paste a stack trace into an issue report. Every error surface in the
// app should go through one of the helpers below.
//
//   * showErrorDialog   — one-shot modal with title + body + copy button
//   * ErrorInfoBar      — inline InfoBar replacement with the same guarantees
//   * CopyableErrorText — bare SelectableText + copy icon for custom layouts
//
// All three wrap the clipboard write through [buildErrorReport] so the
// copied text includes context (title, timestamp, protocol version) that a
// user can paste directly into a chat with an AI assistant. The visible
// body stays the raw message; the structured report is only materialized
// at copy time.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import 'version.dart';

/// Builds the clipboard payload for an error surface. The format is
/// markdown so it renders nicely in GitHub issues / Slack / Claude chat,
/// but the plain-text alternative (ignoring the `#` prefixes) stays
/// readable for humans skimming the buffer.
///
/// [title] is the short human-readable label ("削除に失敗しました", etc.).
/// [message] is the raw error body. Both are included verbatim; callers
/// are responsible for making sure they don't leak secrets.
String buildErrorReport({required String? title, required String message}) {
  final ts = DateTime.now().toIso8601String();
  final buf = StringBuffer();
  buf.writeln('# FleetKanban エラー');
  buf.writeln('- 日時: $ts');
  buf.writeln('- Protocol version: $expectedSidecarProtocolVersion');
  if (title != null && title.trim().isNotEmpty) {
    buf.writeln('- 発生箇所: ${title.trim()}');
  }
  buf.writeln();
  buf.writeln('## 詳細');
  buf.writeln();
  buf.writeln('```');
  buf.writeln(message.trim());
  buf.writeln('```');
  return buf.toString();
}

/// Shows a modal error dialog whose body is a [CopyableErrorText] so the
/// user can select the message and drag to copy, and tap the copy icon to
/// send it to the clipboard in one click. Returns after the dialog is
/// dismissed.
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
      title: Text(title),
      content: SingleChildScrollView(
        child: CopyableErrorText(text: message, reportTitle: title),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}

/// Inline error surface that replaces Fluent's InfoBar when the content is
/// an error the user might want to copy. Mirrors InfoBar's visual weight
/// but uses SelectableText and appends a copy icon.
class ErrorInfoBar extends StatelessWidget {
  const ErrorInfoBar({
    super.key,
    required this.title,
    required this.message,
    this.severity = InfoBarSeverity.error,
  });

  final String title;
  final String message;
  final InfoBarSeverity severity;

  @override
  Widget build(BuildContext context) {
    return InfoBar(
      title: Text(title),
      content: CopyableErrorText(text: message, reportTitle: title),
      severity: severity,
    );
  }
}

/// Raw building block: a SelectableText with a trailing copy button that
/// flashes an inline "コピーしました" confirmation for ~1.2s. Designed to
/// drop into existing dialog / InfoBar bodies without restructuring them.
///
/// When [reportTitle] is non-null, the clipboard payload is the structured
/// [buildErrorReport] output (title + timestamp + version + body). When
/// null, the raw [text] is copied as-is — useful for contexts where the
/// caller does its own framing.
class CopyableErrorText extends StatefulWidget {
  const CopyableErrorText({
    super.key,
    required this.text,
    this.maxLines,
    this.reportTitle,
  });

  final String text;
  final int? maxLines;

  /// When non-null, [buildErrorReport] wraps the copied payload so it can
  /// be pasted directly into an AI chat or issue tracker. Most callers
  /// should pass the same string they use for the dialog / InfoBar title.
  final String? reportTitle;

  @override
  State<CopyableErrorText> createState() => _CopyableErrorTextState();
}

class _CopyableErrorTextState extends State<CopyableErrorText> {
  bool _justCopied = false;

  Future<void> _copy() async {
    final payload = widget.reportTitle == null
        ? widget.text
        : buildErrorReport(title: widget.reportTitle, message: widget.text);
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    setState(() => _justCopied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _justCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableText(
            widget.text,
            maxLines: widget.maxLines,
            style: theme.typography.body?.copyWith(fontFamily: 'Consolas'),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: _justCopied
              ? 'AI 貼り付け用の形式でコピーしました'
              : widget.reportTitle != null
              ? 'タイトル + 詳細 + 版数をまとめてコピー (AI に貼り付けられる markdown 形式)'
              : 'クリップボードにコピー',
          child: IconButton(
            icon: Icon(
              _justCopied ? FluentIcons.check_mark : FluentIcons.copy,
              size: 14,
              color: _justCopied
                  ? const Color(0xFF107C10)
                  : theme.resources.textFillColorSecondary,
            ),
            onPressed: _copy,
          ),
        ),
      ],
    );
  }
}
