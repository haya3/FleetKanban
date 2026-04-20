// UnifiedDiffParser: splits a `git diff` unified patch into a list of
// DiffFile → DiffHunk → DiffLine. Intentionally minimal — only the features
// we use in the Review panel. Binary files and renames are represented by a
// DiffFile with no hunks plus an informational flag.

enum DiffLineKind { context, added, removed, noNewline }

class DiffLine {
  DiffLine({
    required this.kind,
    required this.text,
    this.oldLineNo,
    this.newLineNo,
  });
  final DiffLineKind kind;
  final String text;
  final int? oldLineNo;
  final int? newLineNo;
}

class DiffHunk {
  DiffHunk({
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
    required this.header,
    required this.lines,
  });
  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;
  final String header; // Full `@@ -a,b +c,d @@ section`
  final List<DiffLine> lines;
}

class DiffFile {
  DiffFile({
    required this.oldPath,
    required this.newPath,
    required this.hunks,
    this.isBinary = false,
    this.isRename = false,
  });
  final String oldPath;
  final String newPath;
  final List<DiffHunk> hunks;
  final bool isBinary;
  final bool isRename;

  /// Display path: prefers newPath unless the file was deleted.
  String get displayPath => newPath == '/dev/null' ? oldPath : newPath;

  int get additions => hunks.fold(
    0,
    (a, h) => a + h.lines.where((l) => l.kind == DiffLineKind.added).length,
  );
  int get deletions => hunks.fold(
    0,
    (a, h) => a + h.lines.where((l) => l.kind == DiffLineKind.removed).length,
  );
}

class UnifiedDiffParser {
  /// Parses a unified diff string into files. Robust to empty input and to
  /// input with or without trailing newline.
  static List<DiffFile> parse(String diff) {
    if (diff.trim().isEmpty) return <DiffFile>[];

    final lines = diff.split(RegExp(r'\r?\n'));
    final files = <DiffFile>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];

      // Start of a new file block.
      if (line.startsWith('diff --git ')) {
        final file = _parseFileBlock(lines, i);
        files.add(file.file);
        i = file.nextIndex;
        continue;
      }

      // Some diffs (e.g. `git diff HEAD -- path`) skip the `diff --git`
      // header and jump straight to `--- a/…` / `+++ b/…`.
      if (line.startsWith('--- ')) {
        final file = _parseHeadless(lines, i);
        files.add(file.file);
        i = file.nextIndex;
        continue;
      }

      i++;
    }
    return files;
  }
}

class _FileParseResult {
  _FileParseResult(this.file, this.nextIndex);
  final DiffFile file;
  final int nextIndex;
}

_FileParseResult _parseFileBlock(List<String> lines, int start) {
  // `diff --git a/<path> b/<path>` — we take the post-space path as a fallback
  // in case the `---`/`+++` block is missing.
  final firstLine = lines[start];
  String oldPath = '';
  String newPath = '';
  bool isBinary = false;
  bool isRename = false;
  final hunks = <DiffHunk>[];

  final pathMatch = RegExp(
    r'^diff --git a/(.+?) b/(.+)$',
  ).firstMatch(firstLine);
  if (pathMatch != null) {
    oldPath = pathMatch.group(1)!;
    newPath = pathMatch.group(2)!;
  }

  int i = start + 1;
  while (i < lines.length && !lines[i].startsWith('diff --git ')) {
    final line = lines[i];
    if (line.startsWith('Binary files ')) {
      isBinary = true;
      i++;
      continue;
    }
    if (line.startsWith('rename from ') || line.startsWith('rename to ')) {
      isRename = true;
      i++;
      continue;
    }
    if (line.startsWith('--- ')) {
      oldPath = _extractPath(line);
      i++;
      continue;
    }
    if (line.startsWith('+++ ')) {
      newPath = _extractPath(line);
      i++;
      continue;
    }
    if (line.startsWith('@@ ')) {
      final h = _parseHunk(lines, i);
      hunks.add(h.hunk);
      i = h.nextIndex;
      continue;
    }
    i++;
  }

  return _FileParseResult(
    DiffFile(
      oldPath: oldPath,
      newPath: newPath,
      hunks: hunks,
      isBinary: isBinary,
      isRename: isRename,
    ),
    i,
  );
}

_FileParseResult _parseHeadless(List<String> lines, int start) {
  String oldPath = _extractPath(lines[start]);
  String newPath = oldPath;
  final hunks = <DiffHunk>[];
  int i = start + 1;
  if (i < lines.length && lines[i].startsWith('+++ ')) {
    newPath = _extractPath(lines[i]);
    i++;
  }
  while (i < lines.length &&
      !lines[i].startsWith('diff --git ') &&
      !lines[i].startsWith('--- ')) {
    if (lines[i].startsWith('@@ ')) {
      final h = _parseHunk(lines, i);
      hunks.add(h.hunk);
      i = h.nextIndex;
    } else {
      i++;
    }
  }
  return _FileParseResult(
    DiffFile(oldPath: oldPath, newPath: newPath, hunks: hunks),
    i,
  );
}

class _HunkParseResult {
  _HunkParseResult(this.hunk, this.nextIndex);
  final DiffHunk hunk;
  final int nextIndex;
}

_HunkParseResult _parseHunk(List<String> lines, int start) {
  final header = lines[start];
  final m = RegExp(
    r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',
  ).firstMatch(header);
  final int oldStart = m != null ? int.parse(m.group(1)!) : 0;
  final int oldCount = m != null && m.group(2) != null
      ? int.parse(m.group(2)!)
      : 1;
  final int newStart = m != null ? int.parse(m.group(3)!) : 0;
  final int newCount = m != null && m.group(4) != null
      ? int.parse(m.group(4)!)
      : 1;

  int oldLine = oldStart;
  int newLine = newStart;
  final body = <DiffLine>[];
  int i = start + 1;
  while (i < lines.length) {
    final line = lines[i];
    if (line.startsWith('@@ ')) break;
    if (line.startsWith('diff --git ') || line.startsWith('--- ')) break;

    if (line.startsWith('+')) {
      body.add(
        DiffLine(
          kind: DiffLineKind.added,
          text: line.substring(1),
          newLineNo: newLine,
        ),
      );
      newLine++;
    } else if (line.startsWith('-')) {
      body.add(
        DiffLine(
          kind: DiffLineKind.removed,
          text: line.substring(1),
          oldLineNo: oldLine,
        ),
      );
      oldLine++;
    } else if (line.startsWith(r'\ ')) {
      body.add(DiffLine(kind: DiffLineKind.noNewline, text: line));
    } else {
      // Context line (leading space) or empty context line.
      final text = line.isEmpty ? '' : line.substring(1);
      body.add(
        DiffLine(
          kind: DiffLineKind.context,
          text: text,
          oldLineNo: oldLine,
          newLineNo: newLine,
        ),
      );
      oldLine++;
      newLine++;
    }
    i++;
  }
  return _HunkParseResult(
    DiffHunk(
      oldStart: oldStart,
      oldCount: oldCount,
      newStart: newStart,
      newCount: newCount,
      header: header,
      lines: body,
    ),
    i,
  );
}

String _extractPath(String headerLine) {
  // `--- a/src/foo.dart` / `+++ b/src/foo.dart` / `--- /dev/null`
  final parts = headerLine.split(RegExp(r'\s+'));
  if (parts.length < 2) return '';
  final path = parts[1];
  if (path.startsWith('a/') || path.startsWith('b/')) {
    return path.substring(2);
  }
  return path;
}
