// DiffView — unified-diff renderer backed by the diff_match_patch
// package. Red/green gutters use fluent theme critical/success fills
// so dark mode stays legible.

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:fluent_ui/fluent_ui.dart';

class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.before, required this.after});

  /// The baseline text (e.g. the stored version of the skill).
  final String before;

  /// The proposed text (e.g. the editor buffer).
  final String after;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(before, after);
    dmp.diffCleanupSemantic(diffs);

    final spans = <TextSpan>[];
    for (final d in diffs) {
      Color? bg;
      switch (d.operation) {
        case DIFF_INSERT:
          bg = const Color(0x3322C55E); // green tint
          break;
        case DIFF_DELETE:
          bg = const Color(0x33EF4444); // red tint
          break;
        case DIFF_EQUAL:
          bg = null;
          break;
      }
      spans.add(
        TextSpan(
          text: d.text,
          style: TextStyle(
            fontFamily: 'Cascadia Code',
            fontSize: 11.5,
            height: 1.4,
            backgroundColor: bg,
            color: theme.resources.textFillColorPrimary,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText.rich(TextSpan(children: spans)),
    );
  }
}
