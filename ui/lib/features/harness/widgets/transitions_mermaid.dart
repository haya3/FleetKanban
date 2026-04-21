// TransitionsMermaid — renders the skill's `transitions:` block as a
// Mermaid flowchart source string inside a SelectableText. The user can
// copy the source and paste it into any external Mermaid renderer to
// inspect the FSM graphically.
//
// TODO(phaseB+): inline Mermaid renderer (e.g. via a WebView2 shim or
// a Dart-side DAG layout) once the harness editor leaves the initial
// text-oriented MVP.

import 'package:fluent_ui/fluent_ui.dart';

/// Converts a list of transitions (as parsed from the frontmatter) into
/// a Mermaid flowchart source string. Each transition is expected to
/// have `from`, `to`, and optionally `on` keys. Unknown shapes fall
/// back to a comment line so the caller can still copy the partial
/// graph.
String buildMermaidSource(List<Map<String, Object?>> transitions) {
  final buf = StringBuffer();
  buf.writeln('flowchart LR');
  if (transitions.isEmpty) {
    buf.writeln('  %% no transitions defined');
    return buf.toString();
  }
  for (final t in transitions) {
    final from = (t['from'] ?? '').toString().trim();
    final to = (t['to'] ?? '').toString().trim();
    final on = (t['on'] ?? '').toString().trim();
    if (from.isEmpty || to.isEmpty) {
      buf.writeln('  %% malformed transition: $t');
      continue;
    }
    if (on.isEmpty) {
      buf.writeln('  $from --> $to');
    } else {
      // Mermaid labels must not contain newlines or unescaped pipes.
      final label = on.replaceAll('|', '/').replaceAll('\n', ' ');
      buf.writeln('  $from -->|$label| $to');
    }
  }
  return buf.toString();
}

class TransitionsMermaid extends StatelessWidget {
  const TransitionsMermaid({super.key, required this.transitions});

  final List<Map<String, Object?>> transitions;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final source = buildMermaidSource(transitions);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.resources.controlStrokeColorDefault,
          width: 1,
        ),
      ),
      child: SelectableText(
        source,
        style: const TextStyle(
          fontFamily: 'Cascadia Code',
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }
}
