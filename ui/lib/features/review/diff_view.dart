// DiffView: renders a list of DiffFile. Side-by-side layout when the
// available width > 900px, unified otherwise. Kept intentionally simple —
// hunk virtualization and syntax highlighting are hooks for Phase F polish.

import 'package:fluent_ui/fluent_ui.dart';

import 'unified_diff_parser.dart';

class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.files});
  final List<DiffFile> files;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(child: Text('差分はまだありません。タスクの進行を待ってください。'));
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        final sideBySide = constraints.maxWidth >= 900;
        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (_, i) =>
              _FileCard(file: files[i], sideBySide: sideBySide),
        );
      },
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.file, required this.sideBySide});
  final DiffFile file;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Expander(
        initiallyExpanded: true,
        leading: const Icon(FluentIcons.file_code, size: 14),
        header: Row(
          children: [
            Expanded(
              child: Text(
                file.displayPath,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.bodyStrong,
              ),
            ),
            if (file.isBinary)
              _Chip(label: 'binary', color: const Color(0xFF8A8A8A)),
            if (file.isRename)
              _Chip(label: 'rename', color: const Color(0xFFC29C00)),
            _Chip(label: '+${file.additions}', color: const Color(0xFF2E8B57)),
            const SizedBox(width: 4),
            _Chip(label: '-${file.deletions}', color: const Color(0xFFC42B1C)),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (file.isBinary)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('バイナリファイル (内容表示はスキップ)'),
              )
            else
              for (final h in file.hunks)
                _HunkBlock(hunk: h, sideBySide: sideBySide),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _HunkBlock extends StatelessWidget {
  const _HunkBlock({required this.hunk, required this.sideBySide});
  final DiffHunk hunk;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).resources.subtleFillColorTertiary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Text(
              hunk.header,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: Color(0xFF5A5A5A),
              ),
            ),
          ),
          if (sideBySide) _SideBySide(hunk: hunk) else _Unified(hunk: hunk),
        ],
      ),
    );
  }
}

class _Unified extends StatelessWidget {
  const _Unified({required this.hunk});
  final DiffHunk hunk;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in hunk.lines) _LineRow(line: line, side: _Side.both),
      ],
    );
  }
}

enum _Side { both, old, newSide }

class _SideBySide extends StatelessWidget {
  const _SideBySide({required this.hunk});
  final DiffHunk hunk;

  @override
  Widget build(BuildContext context) {
    // Pair removed and added lines by order so side-by-side shows them side by
    // side. Context lines span both columns.
    final left = <DiffLine?>[];
    final right = <DiffLine?>[];
    int pending = 0; // net removed lines waiting to be paired with adds.
    for (final l in hunk.lines) {
      switch (l.kind) {
        case DiffLineKind.removed:
          left.add(l);
          right.add(null);
          pending++;
        case DiffLineKind.added:
          if (pending > 0) {
            // Fill right slot for the first unpaired remove above.
            final idx = right.length - pending;
            right[idx] = l;
            pending--;
          } else {
            left.add(null);
            right.add(l);
          }
        case DiffLineKind.context:
        case DiffLineKind.noNewline:
          left.add(l);
          right.add(l);
          pending = 0;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final l in left)
                l == null
                    ? const _EmptyLine()
                    : _LineRow(line: l, side: _Side.old),
            ],
          ),
        ),
        Container(width: 1, color: const Color(0x22000000)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final l in right)
                l == null
                    ? const _EmptyLine()
                    : _LineRow(line: l, side: _Side.newSide),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.side});
  final DiffLine line;
  final _Side side;

  @override
  Widget build(BuildContext context) {
    Color? background;
    switch (line.kind) {
      case DiffLineKind.added:
        if (side == _Side.old) {
          background = null;
        } else {
          background = const Color(0x3036E080);
        }
      case DiffLineKind.removed:
        if (side == _Side.newSide) {
          background = null;
        } else {
          background = const Color(0x30FF6060);
        }
      case DiffLineKind.context:
      case DiffLineKind.noNewline:
        background = null;
    }

    final prefix = _prefixChar(line, side);
    final lineNo = side == _Side.newSide
        ? line.newLineNo
        : side == _Side.old
        ? line.oldLineNo
        : (line.newLineNo ?? line.oldLineNo);

    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              lineNo?.toString() ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: Color(0xFF888888),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            child: Text(
              prefix,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                color: Color(0xFF555555),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              line.text,
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _prefixChar(DiffLine line, _Side side) {
    switch (line.kind) {
      case DiffLineKind.added:
        return side == _Side.old ? '' : '+';
      case DiffLineKind.removed:
        return side == _Side.newSide ? '' : '-';
      case DiffLineKind.context:
        return ' ';
      case DiffLineKind.noNewline:
        return r'\';
    }
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 18);
  }
}
