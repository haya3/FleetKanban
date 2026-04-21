// FrontmatterPanel — parses the YAML frontmatter from a harness skill's
// content_md and renders the well-known NLAH keys (stages,
// max_rework_count, transitions, failure_taxonomy) in Fluent Expanders.
// Malformed or missing frontmatter renders an InfoBar instead of
// throwing so the user can keep editing.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:yaml/yaml.dart';

import 'transitions_mermaid.dart';

/// Extracts the `---`-delimited YAML frontmatter from a Markdown body.
/// Returns null when no frontmatter is present.
String? _extractFrontmatter(String contentMd) {
  final normalized = contentMd.replaceAll('\r\n', '\n');
  if (!normalized.startsWith('---')) return null;
  final end = normalized.indexOf('\n---', 3);
  if (end < 0) return null;
  return normalized.substring(3, end).trim();
}

/// Coerces a parsed YAML value into a plain Dart `List<Map>` for the
/// transitions table. Returns `[]` when the shape is unexpected.
List<Map<String, Object?>> _asListOfMaps(Object? raw) {
  if (raw is! YamlList) return const [];
  final out = <Map<String, Object?>>[];
  for (final entry in raw) {
    if (entry is YamlMap) {
      out.add({for (final k in entry.keys) k.toString(): entry[k]});
    }
  }
  return out;
}

/// Coerces a parsed YAML value into a plain Dart `List<String>`.
/// Strings, ints, and maps (first key) are all accepted.
List<String> _asListOfStrings(Object? raw) {
  if (raw is! YamlList) return const [];
  final out = <String>[];
  for (final entry in raw) {
    if (entry is String) {
      out.add(entry);
    } else if (entry is YamlMap && entry.isNotEmpty) {
      out.add(entry.keys.first.toString());
    } else if (entry != null) {
      out.add(entry.toString());
    }
  }
  return out;
}

class FrontmatterPanel extends StatelessWidget {
  const FrontmatterPanel({super.key, required this.contentMd});

  final String contentMd;

  @override
  Widget build(BuildContext context) {
    final fm = _extractFrontmatter(contentMd);
    if (fm == null || fm.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: InfoBar(
          title: Text('No frontmatter'),
          content: Text(
            'The skill content must start with a YAML frontmatter block '
            'delimited by --- on the first line.',
          ),
          severity: InfoBarSeverity.warning,
        ),
      );
    }

    YamlMap? doc;
    String? parseError;
    try {
      final parsed = loadYaml(fm);
      if (parsed is YamlMap) {
        doc = parsed;
      } else {
        parseError = 'Frontmatter root must be a YAML mapping.';
      }
    } catch (e) {
      parseError = '$e';
    }

    if (parseError != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: InfoBar(
          title: const Text('Frontmatter parse error'),
          content: SelectableText(parseError),
          severity: InfoBarSeverity.error,
        ),
      );
    }

    final stages = _asListOfStrings(doc!['stages']);
    final transitions = _asListOfMaps(doc['transitions']);
    final taxonomy = _asListOfStrings(doc['failure_taxonomy']);
    final maxRework = doc['max_rework_count'];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _KeyValueRow(
          label: 'max_rework_count',
          value: maxRework?.toString() ?? '(unset)',
        ),
        const SizedBox(height: 12),
        Expander(
          header: Text('stages (${stages.length})'),
          content: stages.isEmpty
              ? const Text('(none)')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in stages)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(FluentIcons.circle_fill, size: 6),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SelectableText(
                                s,
                                style: const TextStyle(
                                  fontFamily: 'Cascadia Code',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Expander(
          header: Text('transitions (${transitions.length})'),
          content: transitions.isEmpty
              ? const Text('(none)')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in transitions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(
                          '${t['from'] ?? '?'} '
                          '-${t['on'] != null ? '[${t['on']}]' : ''}-> '
                          '${t['to'] ?? '?'}',
                          style: const TextStyle(
                            fontFamily: 'Cascadia Code',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mermaid source (copy into mermaid.live):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TransitionsMermaid(transitions: transitions),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Expander(
          header: Text('failure_taxonomy (${taxonomy.length})'),
          content: taxonomy.isEmpty
              ? const Text('(none)')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in taxonomy)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(
                          f,
                          style: const TextStyle(
                            fontFamily: 'Cascadia Code',
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'Cascadia Code', fontSize: 12),
          ),
        ),
      ],
    );
  }
}
