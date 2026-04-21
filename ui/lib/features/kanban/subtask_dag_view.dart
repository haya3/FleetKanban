// SubtaskDagView: visualizes the whole task execution pipeline as three
// vertical swimlanes — Plan on the left, the Code subtask DAG in the
// middle (wrapping into multiple physical rows when long), Review on
// the right.
//
// Layout rationale:
//   * No horizontal scroll. The Code lane wraps to additional rows when
//     a parallelism layer (or a long sequential chain) would exceed
//     the available width.
//   * Subtasks are grouped by topological depth. Each depth becomes one
//     "logical row" of parallel siblings; a logical row that exceeds
//     the lane width breaks into multiple physical rows.
//   * Plan and Review pin to the lane edges, top-aligned.
//
// We previously used the graphview Sugiyama algorithm, but Sugiyama
// produces a strict layered DAG that requires arbitrary horizontal
// space — exactly the behavior the user asked us to drop. Custom
// layout + cubic-bezier edges give us full control over wrapping.

import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/ui_utils.dart';
import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;
import 'providers.dart';
import 'subtask_summary_dialog.dart';

// Base (1.0× font-scale) dimensions. The actual rendered dimensions are
// these multiplied by the user-controlled DAG font scale, so larger text
// gets a proportionally larger card to live in.
const double _baseNodeWidth = 220;
const double _baseNodeHeight = 76;
const double _canvasMargin = 24;
// Reserved at the top of the canvas for the swimlane headers
// ("Plan" / "Code" / "Review"). Independent of _canvasMargin so the
// nodes are positioned below the headers cleanly.
const double _laneHeaderHeight = 28;

// Synthetic ID prefixes for per-round meta-stage nodes. Real subtask ids
// are ULIDs (26 chars, alphanumeric) so the `__stage_…__` shape can't
// collide.
String _planNodeId(int round) => '__stage_plan_r${round}__';
String _aiReviewNodeId(int round) => '__stage_ai_review_r${round}__';
String _humanReviewNodeId(int round) => '__stage_human_review_r${round}__';

enum _Stage { plan, code, aiReview, humanReview }

String _stageLabelOf(_Stage s) => switch (s) {
  _Stage.plan => 'Plan',
  _Stage.code => 'Code',
  _Stage.aiReview => 'AI Review',
  _Stage.humanReview => 'Human Review',
};

/// Treats a subtask's round as 1 when the field hasn't been set yet
/// (legacy rows pre-migration default to 0 on the wire).
int _subtaskRound(pb.Subtask s) => s.round <= 0 ? 1 : s.round;

class _StageNode {
  const _StageNode({
    required this.id,
    required this.stage,
    required this.round,
    required this.title,
    required this.status,
    required this.model,
  });
  final String id;
  final _Stage stage;
  final int round;
  final String title;
  // pending | doing | done | failed | skipped | rework
  // 'rework' is a UI-only status applied to past-round Review nodes
  // whose verdict was REWORK; rendered with an orange accent.
  final String status;
  final String model;
}

class SubtaskDagView extends ConsumerStatefulWidget {
  const SubtaskDagView({super.key, required this.task, required this.subtasks});
  final pb.Task task;
  final List<pb.Subtask> subtasks;

  @override
  ConsumerState<SubtaskDagView> createState() => _SubtaskDagViewState();
}

class _SubtaskDagViewState extends ConsumerState<SubtaskDagView> {
  Map<String, _StageNode> _byId = {};

  // Last layout snapshot. Recomputed on viewport-width / topology /
  // font-scale change in build(); painters depend on _paintVersion to
  // know when to redraw.
  _LayoutResult? _layout;

  // Cached layout inputs — re-run layout only when these change.
  double? _layoutWidth;
  double _layoutScale = 1.0;
  bool _layoutDirty = true;

  // Version counter consumed by painters. Bumped on every layout
  // regeneration so CustomPainter.shouldRepaint triggers cleanly
  // without comparing big maps by identity.
  int _paintVersion = 0;

  // Explicit vertical scroll controller. Required because the outer
  // Scrollbar would otherwise attach to PrimaryScrollController, which
  // is unattached on desktop for vertical scrolls and crashes with
  // "ScrollController has no ScrollPosition attached".
  final ScrollController _vScroll = ScrollController();

  double get _nodeWidth => _baseNodeWidth * _layoutScale;
  double get _nodeHeight => _baseNodeHeight * _layoutScale;

  @override
  void initState() {
    super.initState();
    _byId = _buildStageNodes();
  }

  @override
  void dispose() {
    _vScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SubtaskDagView old) {
    super.didUpdateWidget(old);
    if (_topologyChanged(old) || _metadataChanged(old)) {
      _byId = _buildStageNodes();
      _layoutDirty = true;
      _paintVersion++;
    }
  }

  // Topology = the set of nodes and edges. metadataChanged also
  // invalidates the layout because edge colours depend on per-node
  // status. Both paths fold into "rebuild stage nodes + repaint".
  bool _topologyChanged(SubtaskDagView old) {
    if (old.subtasks.length != widget.subtasks.length) return true;
    for (var i = 0; i < old.subtasks.length; i++) {
      final a = old.subtasks[i];
      final b = widget.subtasks[i];
      if (a.id != b.id || !listEquals(a.dependsOn, b.dependsOn)) {
        return true;
      }
    }
    return false;
  }

  bool _metadataChanged(SubtaskDagView old) {
    if (old.task.status != widget.task.status) return true;
    if (old.task.planModel != widget.task.planModel) return true;
    if (old.task.reviewModel != widget.task.reviewModel) return true;
    for (var i = 0; i < old.subtasks.length; i++) {
      final a = old.subtasks[i];
      final b = widget.subtasks[i];
      if (a.status != b.status ||
          a.title != b.title ||
          a.codeModel != b.codeModel) {
        return true;
      }
    }
    return false;
  }

  // Derive Plan meta-stage status for a given round.
  //
  // For past rounds we know planning succeeded (otherwise no subtasks
  // would have been emitted under that round) so they always render as
  // 'done'. For the latest round the status mirrors the parent task:
  // planning in flight → doing, no subtasks + failed/aborted → failed/
  // skipped, else done.
  String _planStatusForRound(
    int round,
    bool isLatest,
    List<pb.Subtask> roundSubs,
  ) {
    if (!isLatest) return 'done';
    final s = widget.task.status;
    if (s == 'planning') return 'doing';
    if (roundSubs.isEmpty) {
      if (s == 'failed') return 'failed';
      if (s == 'cancelled' || s == 'aborted') return 'skipped';
    }
    return 'done';
  }

  // Derive AI Review status for a given round.
  //
  // Past rounds: a new round only exists because Review demanded REWORK,
  // so render the prior AI Review as 'rework' (orange). The latest round
  // tracks the parent task's review state.
  String _aiReviewStatusForRound(
    int round,
    bool isLatest,
    List<pb.Subtask> roundSubs,
  ) {
    if (!isLatest) return 'rework';
    final s = widget.task.status;
    if (s == 'ai_review') return 'doing';
    // Anything beyond ai_review — human_review / done — means AI approved
    // and handed off. Render AI Review as done in those states.
    if (s == 'human_review' || s == 'done') return 'done';
    final allSubtasksDone =
        roundSubs.isNotEmpty && roundSubs.every((x) => x.status == 'done');
    if (s == 'failed') {
      return allSubtasksDone ? 'failed' : 'skipped';
    }
    if (s == 'cancelled' || s == 'aborted') return 'skipped';
    return 'pending';
  }

  // Derive Human Review status for a given round.
  //
  // Past rounds: historical — if a new round exists, the user must have
  // sent the task back somehow (REWORK). Render as 'rework' too so the
  // past column mirrors AI Review semantics. Latest round: waiting on
  // the user when task is in human_review, done when Keep/Merge landed,
  // pending otherwise.
  String _humanReviewStatusForRound(
    int round,
    bool isLatest,
    List<pb.Subtask> roundSubs,
  ) {
    if (!isLatest) return 'rework';
    final s = widget.task.status;
    if (s == 'human_review') return 'doing';
    if (s == 'done') return 'done';
    if (s == 'cancelled' || s == 'aborted') return 'skipped';
    if (s == 'failed') {
      final allSubtasksDone =
          roundSubs.isNotEmpty && roundSubs.every((x) => x.status == 'done');
      return allSubtasksDone ? 'failed' : 'skipped';
    }
    return 'pending';
  }

  // Computes the set of stage nodes for every round present in
  // widget.subtasks (or a synthetic round 1 when no subtasks yet
  // exist). Indexed by the synthetic node id.
  Map<String, _StageNode> _buildStageNodes() {
    final t = widget.task;
    final byRound = _subtasksByRound();
    final rounds = byRound.keys.toList()..sort();
    if (rounds.isEmpty) {
      rounds.add(1);
      byRound[1] = const [];
    }
    final latest = rounds.last;

    final nodes = <String, _StageNode>{};
    for (final r in rounds) {
      final isLatest = r == latest;
      final roundSubs = byRound[r] ?? const <pb.Subtask>[];
      nodes[_planNodeId(r)] = _StageNode(
        id: _planNodeId(r),
        stage: _Stage.plan,
        round: r,
        title: 'Plan',
        status: _planStatusForRound(r, isLatest, roundSubs),
        // PlanModel is task-scoped (not per-round) in Phase 1, so the
        // same id appears on every round's Plan card. Phase 2 may
        // record per-round models.
        model: t.planModel,
      );
      for (final s in roundSubs) {
        nodes[s.id] = _StageNode(
          id: s.id,
          stage: _Stage.code,
          round: r,
          title: s.title,
          status: s.status,
          model: s.codeModel,
        );
      }
      nodes[_aiReviewNodeId(r)] = _StageNode(
        id: _aiReviewNodeId(r),
        stage: _Stage.aiReview,
        round: r,
        title: 'AI Review',
        status: _aiReviewStatusForRound(r, isLatest, roundSubs),
        model: t.reviewModel,
      );
      nodes[_humanReviewNodeId(r)] = _StageNode(
        id: _humanReviewNodeId(r),
        stage: _Stage.humanReview,
        round: r,
        title: 'Human Review',
        status: _humanReviewStatusForRound(r, isLatest, roundSubs),
        model: '',
      );
    }
    return nodes;
  }

  /// Groups subtasks by round (legacy round=0 normalised to 1).
  Map<int, List<pb.Subtask>> _subtasksByRound() {
    final out = <int, List<pb.Subtask>>{};
    for (final s in widget.subtasks) {
      out.putIfAbsent(_subtaskRound(s), () => <pb.Subtask>[]).add(s);
    }
    return out;
  }

  // _runLayout performs the custom 4-lane wrapping layout, repeated
  // for every round so the rework history stacks vertically. Each
  // round is a horizontal "band":
  //
  //   Round 1: [Plan]  [code subtasks wrap…]  [AI Review]  [Human Review]
  //   Round 2: [Plan]  [code subtasks wrap…]  [AI Review]  [Human Review]
  //   ...
  //
  // Plan pins to the left edge, Human Review pins to the right edge,
  // AI Review sits between Code and Human Review, and Code subtasks
  // fill the middle, wrapping to additional physical rows when a
  // parallelism layer / sequential chain is wider than the Code lane.
  //
  // Returns null when totalWidth is too small to fit even the meta
  // columns (caller falls back to a "view too narrow" message).
  _LayoutResult? _runLayout(double totalWidth) {
    const laneGap = 24.0;
    const colGap = 18.0;
    const rowGap = 18.0;
    const roundGap = 28.0; // vertical gap between rework rounds

    final planColW = _nodeWidth;
    final aiReviewColW = _nodeWidth;
    final humanReviewColW = _nodeWidth;
    // Code lane fills whatever's left after the three meta columns
    // + three inter-lane gaps.
    final codeAvail =
        totalWidth - planColW - aiReviewColW - humanReviewColW - laneGap * 3;
    if (codeAvail < _nodeWidth) {
      return null;
    }
    final codeOriginX = planColW + laneGap;
    final aiReviewOriginX =
        totalWidth - humanReviewColW - laneGap - aiReviewColW;
    final humanReviewOriginX = totalWidth - humanReviewColW;

    final byRound = _subtasksByRound();
    final rounds = byRound.keys.toList()..sort();
    if (rounds.isEmpty) {
      rounds.add(1);
      byRound[1] = const [];
    }

    final positions = <String, Rect>{};
    final rowOf = <String, int>{};
    final edges = <_Edge>[];
    final roundBands = <int, ({double top, double bottom})>{};

    double bandTop = 0;

    for (final r in rounds) {
      final roundSubs = byRound[r] ?? const <pb.Subtask>[];
      final layoutForRound = _layoutOneRound(
        subs: roundSubs,
        bandTop: bandTop,
        codeOriginX: codeOriginX,
        codeAvail: codeAvail,
        rowGap: rowGap,
        colGap: colGap,
      );

      // Place meta-stage nodes aligned to the band top so they stay
      // visually anchored to their lanes.
      positions[_planNodeId(r)] = Rect.fromLTWH(
        0,
        bandTop,
        planColW,
        _nodeHeight,
      );
      positions[_aiReviewNodeId(r)] = Rect.fromLTWH(
        aiReviewOriginX,
        bandTop,
        aiReviewColW,
        _nodeHeight,
      );
      positions[_humanReviewNodeId(r)] = Rect.fromLTWH(
        humanReviewOriginX,
        bandTop,
        humanReviewColW,
        _nodeHeight,
      );
      // Merge code subtask positions and rowOf into the global maps.
      positions.addAll(layoutForRound.positions);
      rowOf.addAll(layoutForRound.rowOf);

      // Edges within this round: Plan → first-row codes, code deps,
      // last-row codes → AI Review → Human Review. When the round
      // has no codes, draw Plan → AI Review directly.
      final realIds = {for (final s in roundSubs) s.id};
      if (roundSubs.isEmpty) {
        edges.add(_Edge(_planNodeId(r), _aiReviewNodeId(r)));
      } else {
        final hasIncoming = <String>{};
        final hasOutgoing = <String>{};
        for (final s in roundSubs) {
          for (final dep in s.dependsOn) {
            if (!realIds.contains(dep)) continue;
            edges.add(_Edge(dep, s.id));
            hasIncoming.add(s.id);
            hasOutgoing.add(dep);
          }
        }
        for (final s in roundSubs) {
          if (!hasIncoming.contains(s.id)) {
            edges.add(_Edge(_planNodeId(r), s.id));
          }
          if (!hasOutgoing.contains(s.id)) {
            edges.add(_Edge(s.id, _aiReviewNodeId(r)));
          }
        }
      }
      // AI Review → Human Review within the same round.
      edges.add(_Edge(_aiReviewNodeId(r), _humanReviewNodeId(r)));

      final bandBottom =
          bandTop + math.max(layoutForRound.codeBlockH, _nodeHeight);
      roundBands[r] = (top: bandTop, bottom: bandBottom);
      bandTop = bandBottom + roundGap;
    }

    // Inter-round loop edges: Human Review of round r → Plan of
    // round r+1. Visualises the rework cycle so the user can see
    // the loop, not just disconnected bands.
    for (var i = 0; i < rounds.length - 1; i++) {
      edges.add(
        _Edge(_humanReviewNodeId(rounds[i]), _planNodeId(rounds[i + 1])),
      );
    }

    final canvasH = bandTop > 0 ? bandTop - roundGap : _nodeHeight;
    final planLaneEnd = planColW + laneGap / 2;
    final codeLaneEnd = aiReviewOriginX - laneGap / 2;
    final aiReviewLaneEnd = humanReviewOriginX - laneGap / 2;

    return _LayoutResult(
      positions: positions,
      rowOf: rowOf,
      edges: edges,
      canvasW: totalWidth,
      canvasH: canvasH,
      planLaneEnd: planLaneEnd,
      codeLaneEnd: codeLaneEnd,
      aiReviewLaneEnd: aiReviewLaneEnd,
      roundBands: roundBands,
    );
  }

  // _layoutOneRound packs one round's Code subtasks into wrapping rows
  // starting at bandTop. Returns the per-id positions, per-id physical
  // row, and the total vertical span so the caller can advance to the
  // next band.
  ({Map<String, Rect> positions, Map<String, int> rowOf, double codeBlockH})
  _layoutOneRound({
    required List<pb.Subtask> subs,
    required double bandTop,
    required double codeOriginX,
    required double codeAvail,
    required double rowGap,
    required double colGap,
  }) {
    final positions = <String, Rect>{};
    final rowOf = <String, int>{};

    // Topological depth within this round: subtask with no in-round
    // deps starts at 0; otherwise 1 + max(in-round dep depth).
    final depthBy = <String, int>{for (final s in subs) s.id: 0};
    final inRound = {for (final s in subs) s.id};
    bool changed = true;
    int safety = subs.length + 1;
    while (changed && safety-- > 0) {
      changed = false;
      for (final s in subs) {
        int d = 0;
        for (final dep in s.dependsOn) {
          if (!inRound.contains(dep)) continue;
          final dd = depthBy[dep];
          if (dd != null && dd + 1 > d) d = dd + 1;
        }
        if (d != depthBy[s.id]) {
          depthBy[s.id] = d;
          changed = true;
        }
      }
    }
    final byDepth = <int, List<pb.Subtask>>{};
    for (final s in subs) {
      byDepth.putIfAbsent(depthBy[s.id]!, () => []).add(s);
    }
    final depthsSorted = byDepth.keys.toList()..sort();

    double curX = 0;
    double curY = bandTop;
    int rowCounter = 0;

    void placeCode(pb.Subtask s, {required bool startNewLogicalRow}) {
      final wouldOverflow = curX > 0 && curX + _nodeWidth > codeAvail;
      if (wouldOverflow || (startNewLogicalRow && curX > 0)) {
        curY += _nodeHeight + rowGap;
        curX = 0;
        rowCounter++;
      }
      positions[s.id] = Rect.fromLTWH(
        codeOriginX + curX,
        curY,
        _nodeWidth,
        _nodeHeight,
      );
      rowOf[s.id] = rowCounter;
      curX += _nodeWidth + colGap;
    }

    bool firstLayer = true;
    for (final d in depthsSorted) {
      final layer = byDepth[d]!;
      bool firstInLayer = true;
      for (final s in layer) {
        placeCode(s, startNewLogicalRow: firstInLayer && !firstLayer);
        firstInLayer = false;
      }
      firstLayer = false;
    }
    final codeBlockH = subs.isEmpty
        ? _nodeHeight
        : (curY + _nodeHeight) - bandTop;
    return (positions: positions, rowOf: rowOf, codeBlockH: codeBlockH);
  }

  Color _statusColor(FluentThemeData theme, String status) {
    switch (status) {
      case 'done':
        return const Color(0xFF107C10);
      case 'doing':
        return theme.accentColor.normal;
      case 'failed':
        return const Color(0xFFC42B1C);
      case 'rework':
        return const Color(0xFFE08A00);
      default:
        // Pending edges used theme.controlStrokeColorDefault, which is
        // tuned for separator hairlines and reads as nearly invisible
        // against the lane backgrounds. Use a stronger neutral so the
        // graph topology stays legible even when most subtasks are
        // still pending.
        return theme.resources.textFillColorSecondary;
    }
  }

  double _strokeFor(String status) {
    switch (status) {
      case 'doing':
        return 3.2;
      case 'done':
      case 'failed':
      case 'rework':
        return 2.6;
      default:
        return 2.2;
    }
  }

  Widget _buildPositionedNode(String id, Rect rect) {
    final stageNode = _byId[id]!;
    pb.Subtask? subtask;
    if (stageNode.stage == _Stage.code) {
      for (final s in widget.subtasks) {
        if (s.id == id) {
          subtask = s;
          break;
        }
      }
    }
    return Positioned(
      left: _canvasMargin + rect.left,
      top: _canvasMargin + _laneHeaderHeight + rect.top,
      width: rect.width,
      height: rect.height,
      child: _StageNodeCard(
        node: stageNode,
        scale: _layoutScale,
        onTap: () {
          if (stageNode.stage == _Stage.code && subtask != null) {
            showSubtaskSummaryDialog(
              context,
              taskId: widget.task.id,
              subtask: subtask,
            );
          } else {
            _showStageDetail(context, stageNode, widget.task.id);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    // React to font-scale changes from the toolbar. When the value
    // drifts, mark the layout dirty so it gets recomputed below.
    final scaleAsync = ref.watch(dagFontScaleProvider);
    final desiredScale = scaleAsync.value ?? dagFontScaleDefault;
    if ((desiredScale - _layoutScale).abs() > 0.001) {
      _layoutScale = desiredScale;
      _layoutDirty = true;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure the layout fits the actual viewport width. Account
        // for the canvas margins so edges don't get clipped.
        final layoutWidth = constraints.maxWidth - _canvasMargin * 2;
        if (_layoutDirty || _layoutWidth != layoutWidth || _layout == null) {
          _layout = _runLayout(layoutWidth);
          _layoutWidth = layoutWidth;
          _layoutDirty = false;
          _paintVersion++;
        }

        final layout = _layout;
        if (layout == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Window too narrow to render the subtask graph.',
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorTertiary,
                ),
              ),
            ),
          );
        }

        final canvasW = layout.canvasW + _canvasMargin * 2;
        final canvasH = layout.canvasH + _canvasMargin * 2 + _laneHeaderHeight;

        // Edge colours follow the destination node's status (green =
        // done, accent = doing, red = failed, neutral = pending). Stroke
        // width tracks importance: doing edges get the thickest line so
        // the active branch jumps out, pending stays modestly thick so
        // the topology is readable without competing for attention.
        final edgePaints = <_Edge, Paint>{
          for (final e in layout.edges)
            e: Paint()
              ..color = _statusColor(theme, _byId[e.to]?.status ?? 'pending')
              ..strokeWidth = _strokeFor(_byId[e.to]?.status ?? 'pending')
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round,
        };

        final canvas = SizedBox(
          width: canvasW,
          height: canvasH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LanePainter(
                    planEnd: _canvasMargin + layout.planLaneEnd,
                    codeEnd: _canvasMargin + layout.codeLaneEnd,
                    aiReviewEnd: _canvasMargin + layout.aiReviewLaneEnd,
                    totalEnd: canvasW - _canvasMargin / 2,
                    canvasH: canvasH,
                    headerHeight: _laneHeaderHeight,
                    planColor: theme.accentColor.normal,
                    codeColor: const Color(0xFF0E7A0D),
                    aiReviewColor: const Color(0xFF8764B8),
                    humanReviewColor: const Color(0xFFE08A00),
                    divider: theme.resources.controlStrokeColorDefault,
                    version: _paintVersion,
                  ),
                ),
              ),
              for (final h in _buildLaneHeaders(theme, layout)) h,
              Positioned.fill(
                child: CustomPaint(
                  painter: _EdgePainter(
                    layout: layout,
                    paints: edgePaints,
                    offset: const Offset(
                      _canvasMargin,
                      _canvasMargin + _laneHeaderHeight,
                    ),
                    version: _paintVersion,
                  ),
                ),
              ),
              for (final entry in layout.positions.entries)
                _buildPositionedNode(entry.key, entry.value),
            ],
          ),
        );

        // Vertical scroll only — Code lane wrapping handles the
        // horizontal direction by design, so users never need to
        // shift-scroll sideways. Both Scrollbar and SingleChildScrollView
        // share an explicit controller because PrimaryScrollController
        // isn't attached for vertical axes on desktop.
        return Scrollbar(
          thumbVisibility: true,
          controller: _vScroll,
          child: SingleChildScrollView(
            controller: _vScroll,
            scrollDirection: Axis.vertical,
            child: canvas,
          ),
        );
      },
    );
  }

  List<Widget> _buildLaneHeaders(FluentThemeData theme, _LayoutResult layout) {
    final planEndAbs = _canvasMargin + layout.planLaneEnd;
    final codeEndAbs = _canvasMargin + layout.codeLaneEnd;
    final aiReviewEndAbs = _canvasMargin + layout.aiReviewLaneEnd;
    final totalEndAbs = layout.canvasW + _canvasMargin * 2 - _canvasMargin / 2;
    Widget header(String label, double left, double right, Color accent) {
      return Positioned(
        left: left,
        top: 4,
        width: math.max(0, right - left),
        height: _laneHeaderHeight - 4,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: theme.typography.caption?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
    }

    return [
      header(
        'PLAN',
        _canvasMargin / 2,
        planEndAbs - 4,
        theme.accentColor.normal,
      ),
      header('CODE', planEndAbs + 4, codeEndAbs - 4, const Color(0xFF0E7A0D)),
      header(
        'AI REVIEW',
        codeEndAbs + 4,
        aiReviewEndAbs - 4,
        const Color(0xFF8764B8),
      ),
      header(
        'HUMAN REVIEW',
        aiReviewEndAbs + 4,
        totalEndAbs,
        const Color(0xFFE08A00),
      ),
    ];
  }
}

// _markdownStyle produces a MarkdownStyleSheet that matches the Fluent
// UI typography so the planner's summary, review feedback, and per-
// subtask prompts render with proper line breaks / bullets / code
// blocks instead of as a run-on blob. Tuned for body-level text (not
// headline sizes) since these blocks live inside dialogs.
MarkdownStyleSheet _markdownStyle(FluentThemeData theme) {
  final base = MarkdownStyleSheet(
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
  return base;
}

// ---------------------------------------------------------------------------
// Layout result + edge model
// ---------------------------------------------------------------------------

class _LayoutResult {
  _LayoutResult({
    required this.positions,
    required this.rowOf,
    required this.edges,
    required this.canvasW,
    required this.canvasH,
    required this.planLaneEnd,
    required this.codeLaneEnd,
    required this.aiReviewLaneEnd,
    required this.roundBands,
  });

  final Map<String, Rect> positions;
  final Map<String, int> rowOf;
  final List<_Edge> edges;
  final double canvasW;
  final double canvasH;
  // Right-edge x of each lane in layout-local coordinates. Lane widths
  // go [0, planLaneEnd] | (planLaneEnd, codeLaneEnd] |
  // (codeLaneEnd, aiReviewLaneEnd] | (aiReviewLaneEnd, canvasW].
  final double planLaneEnd;
  final double codeLaneEnd;
  final double aiReviewLaneEnd;
  final Map<int, ({double top, double bottom})> roundBands;
}

class _Edge {
  const _Edge(this.from, this.to);
  final String from;
  final String to;

  @override
  bool operator ==(Object other) =>
      other is _Edge && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(from, to);
}

// ---------------------------------------------------------------------------
// Lane painter — swimlane backgrounds + dividers under the DAG.
// ---------------------------------------------------------------------------

class _LanePainter extends CustomPainter {
  _LanePainter({
    required this.planEnd,
    required this.codeEnd,
    required this.aiReviewEnd,
    required this.totalEnd,
    required this.canvasH,
    required this.headerHeight,
    required this.planColor,
    required this.codeColor,
    required this.aiReviewColor,
    required this.humanReviewColor,
    required this.divider,
    required this.version,
  });

  final double planEnd;
  final double codeEnd;
  final double aiReviewEnd;
  final double totalEnd;
  final double canvasH;
  final double headerHeight;
  final Color planColor;
  final Color codeColor;
  final Color aiReviewColor;
  final Color humanReviewColor;
  final Color divider;
  final int version;

  @override
  void paint(Canvas canvas, Size size) {
    final laneTop = headerHeight;
    void fillLane(double left, double right, Color color) {
      if (right <= left) return;
      canvas.drawRect(
        Rect.fromLTRB(left, laneTop, right, canvasH),
        Paint()..color = color.withValues(alpha: 0.08),
      );
    }

    fillLane(0, planEnd, planColor);
    fillLane(planEnd, codeEnd, codeColor);
    fillLane(codeEnd, aiReviewEnd, aiReviewColor);
    fillLane(aiReviewEnd, totalEnd, humanReviewColor);

    final dividerPaint = Paint()
      ..color = divider
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final x in [planEnd, codeEnd, aiReviewEnd]) {
      canvas.drawLine(Offset(x, laneTop), Offset(x, canvasH), dividerPaint);
    }
    canvas.drawLine(
      Offset(0, laneTop),
      Offset(totalEnd, laneTop),
      dividerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LanePainter old) =>
      old.version != version ||
      old.planEnd != planEnd ||
      old.codeEnd != codeEnd ||
      old.aiReviewEnd != aiReviewEnd ||
      old.totalEnd != totalEnd ||
      old.canvasH != canvasH ||
      old.planColor != planColor ||
      old.codeColor != codeColor ||
      old.aiReviewColor != aiReviewColor ||
      old.humanReviewColor != humanReviewColor ||
      old.divider != divider;
}

// ---------------------------------------------------------------------------
// Edge painter — cubic bezier curves between node anchor points.
// ---------------------------------------------------------------------------

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.layout,
    required this.paints,
    required this.offset,
    required this.version,
  });

  final _LayoutResult layout;
  final Map<_Edge, Paint> paints;
  final Offset offset;
  final int version;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    for (final edge in layout.edges) {
      final from = layout.positions[edge.from];
      final to = layout.positions[edge.to];
      if (from == null || to == null) continue;
      final p =
          paints[edge] ??
          (Paint()
            ..color = const Color(0x66888888)
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Anchors: from = right-centre, to = left-centre. When the
      // destination wraps to a row below the source (or to the
      // first/last row touching Plan/Review), this still produces
      // a smooth diagonal curve.
      final start = Offset(from.right, from.center.dy);
      final end = Offset(to.left, to.center.dy);
      final dx = (end.dx - start.dx).abs();
      // Pull the bezier handles outward proportionally to the
      // horizontal distance, with a floor for very short edges so
      // the curve still bends visibly.
      final handle = math.max(dx * 0.45, 32);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + handle,
          start.dy,
          end.dx - handle,
          end.dy,
          end.dx,
          end.dy,
        );
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) =>
      old.version != version || old.layout != layout || old.offset != offset;
}

// ---------------------------------------------------------------------------
// Node card
// ---------------------------------------------------------------------------

class _StageNodeCard extends StatefulWidget {
  const _StageNodeCard({
    required this.node,
    required this.scale,
    required this.onTap,
  });
  final _StageNode node;
  // Same value as _SubtaskDagViewState._layoutScale; folded into every
  // text size and icon dimension so the visual content matches the
  // card box that Sugiyama sized with the scaled bounds.
  final double scale;
  final VoidCallback onTap;

  @override
  State<_StageNodeCard> createState() => _StageNodeCardState();
}

class _StageNodeCardState extends State<_StageNodeCard> {
  bool _hover = false;

  (IconData, Color) _statusVisual(FluentThemeData t) {
    switch (widget.node.status) {
      case 'doing':
        return (FluentIcons.play_resume, const Color(0xFF0067C0));
      case 'done':
        return (FluentIcons.check_mark, const Color(0xFF107C10));
      case 'failed':
        return (FluentIcons.error_badge, const Color(0xFFC42B1C));
      case 'rework':
        // Past-round Review nodes whose verdict was REWORK. Orange
        // distinguishes them from outright failures (red) — the rework
        // produced a new round, not a terminal error.
        return (FluentIcons.refresh, const Color(0xFFE08A00));
      case 'skipped':
        return (FluentIcons.blocked2, t.resources.textFillColorTertiary);
      case 'pending':
      default:
        return (FluentIcons.circle_ring, t.resources.textFillColorTertiary);
    }
  }

  // Plan = accent, Code = green, AI Review = purple, Human Review =
  // orange. Matches the lane tints so the card stripe reinforces the
  // swimlane it lives in.
  Color _stageColor(FluentThemeData t) => switch (widget.node.stage) {
    _Stage.plan => t.accentColor.normal,
    _Stage.code => const Color(0xFF0E7A0D),
    _Stage.aiReview => const Color(0xFF8764B8),
    _Stage.humanReview => const Color(0xFFE08A00),
  };

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final n = widget.node;
    final s = widget.scale;
    final (statusIcon, statusColor) = _statusVisual(theme);
    final stageColor = _stageColor(theme);
    final done = n.status == 'done';
    final running = n.status == 'doing';
    final skipped = n.status == 'skipped';
    final isMeta = n.stage != _Stage.code;
    // For skipped nodes, both text and title render in grey to convey
    // "never ran". Unlike done, no strikethrough is applied (nothing
    // actually completed).
    final mutedText = done || skipped;

    final iconSize = 14 * s;
    final stageBadgeFont = 10 * s;
    final titleFont = 12 * s;
    final modelFont = 10 * s;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.resources.layerOnMicaBaseAltFillColorDefault,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hover
                  ? theme.accentColor.normal.withValues(alpha: 0.7)
                  : theme.resources.controlStrokeColorDefault,
              width: _hover ? 1.4 : 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: theme.accentColor.normal.withValues(alpha: 0.18),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: stageColor),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 8 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (running)
                            SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: const ProgressRing(strokeWidth: 1.6),
                            )
                          else
                            Icon(
                              statusIcon,
                              size: iconSize,
                              color: statusColor,
                            ),
                          SizedBox(width: 6 * s),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5 * s,
                              vertical: 1 * s,
                            ),
                            decoration: BoxDecoration(
                              color: stageColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              _stageLabelOf(n.stage),
                              style: theme.typography.caption?.copyWith(
                                color: stageColor,
                                fontWeight: FontWeight.w600,
                                fontSize: stageBadgeFont,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4 * s),
                      Expanded(
                        child: Text(
                          n.title.isEmpty ? '(no title)' : n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body?.copyWith(
                            fontSize: titleFont,
                            fontWeight: isMeta
                                ? FontWeight.w600
                                : FontWeight.normal,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                            color: mutedText
                                ? theme.resources.textFillColorTertiary
                                : null,
                          ),
                        ),
                      ),
                      if (n.model.isNotEmpty)
                        Text(
                          n.model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.caption?.copyWith(
                            color: theme.resources.textFillColorTertiary,
                            fontFamily: 'Consolas',
                            fontSize: modelFont,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar — exposed as a public widget so the Subtasks tab can mount it
// next to the Graph/List toggle without reaching into private state.
// ---------------------------------------------------------------------------

/// SubtaskDagFontControls renders a +/- pair bound to dagFontScaleProvider.
/// Pure presentation; persistence + clamping lives in the notifier.
class SubtaskDagFontControls extends ConsumerWidget {
  const SubtaskDagFontControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final scaleAsync = ref.watch(dagFontScaleProvider);
    final scale = scaleAsync.value ?? dagFontScaleDefault;
    final canDecrease = scale > dagFontScaleMin + 0.001;
    final canIncrease = scale < dagFontScaleMax - 0.001;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Decrease text size',
          child: IconButton(
            icon: const Icon(FluentIcons.calculator_subtract, size: 12),
            onPressed: canDecrease
                ? () => ref.read(dagFontScaleProvider.notifier).decrement()
                : null,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(scale * 100).round()}%',
            textAlign: TextAlign.center,
            style: theme.typography.caption,
          ),
        ),
        Tooltip(
          message: 'Increase text size',
          child: IconButton(
            icon: const Icon(FluentIcons.calculator_addition, size: 12),
            onPressed: canIncrease
                ? () => ref.read(dagFontScaleProvider.notifier).increment()
                : null,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detail dialog
// ---------------------------------------------------------------------------

void _showStageDetail(BuildContext context, _StageNode n, String taskId) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _StageDetailDialog(node: n, taskId: taskId),
  );
}

class _StageDetailDialog extends ConsumerWidget {
  const _StageDetailDialog({required this.node, required this.taskId});
  final _StageNode node;
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final rows = <(String, String)>[
      ('Stage', _stageLabelOf(node.stage)),
      ('Round', '${node.round}'),
      ('Status', node.status),
      ('Model', node.model.isEmpty ? '(not recorded)' : node.model),
      if (node.stage == _Stage.code) ('Subtask ID', node.id),
    ];
    final planSummaryAsync = node.stage == _Stage.plan
        ? ref.watch(taskPlanSummaryProvider(taskId))
        : null;
    final planLogAsync = node.stage == _Stage.plan
        ? ref.watch(taskPlanLogProvider((taskId: taskId, round: node.round)))
        : null;
    final reviewLogAsync = node.stage == _Stage.aiReview
        ? ref.watch(taskReviewLogProvider((taskId: taskId, round: node.round)))
        : null;
    final reviewsAsync =
        (node.stage == _Stage.aiReview || node.stage == _Stage.humanReview)
        ? ref.watch(taskReviewsProvider(taskId))
        : null;
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
      title: Text(
        '${_stageLabelOf(node.stage)} · Round ${node.round}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
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
              if (planLogAsync != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Log',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                planLogAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: ProgressRing(strokeWidth: 1.6),
                    ),
                  ),
                  error: (e, _) => Text(
                    'Could not load plan log: $e',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorTertiary,
                    ),
                  ),
                  data: (bucket) => bucket.entries.isEmpty
                      ? Text(
                          'No planner activity recorded for this round.',
                          style: theme.typography.body?.copyWith(
                            color: theme.resources.textFillColorTertiary,
                          ),
                        )
                      : LogView(entries: bucket.entries, theme: theme),
                ),
              ],
              if (reviewLogAsync != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Log',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                reviewLogAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: ProgressRing(strokeWidth: 1.6),
                    ),
                  ),
                  error: (e, _) => Text(
                    'Could not load review log: $e',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorTertiary,
                    ),
                  ),
                  data: (bucket) => bucket.entries.isEmpty
                      ? Text(
                          'No reviewer activity recorded for this round yet.',
                          style: theme.typography.body?.copyWith(
                            color: theme.resources.textFillColorTertiary,
                          ),
                        )
                      : LogView(entries: bucket.entries, theme: theme),
                ),
              ],
              if (planSummaryAsync != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Plan summary',
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 340),
                  decoration: BoxDecoration(
                    color: theme.resources.subtleFillColorTertiary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.resources.controlStrokeColorDefault,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    child: planSummaryAsync.when(
                      loading: () => const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: ProgressRing(strokeWidth: 1.6),
                          ),
                          SizedBox(width: 8),
                          Text('Loading…'),
                        ],
                      ),
                      error: (e, _) => Text(
                        'Could not load plan summary: $e',
                        style: theme.typography.caption?.copyWith(
                          color: theme.resources.textFillColorTertiary,
                        ),
                      ),
                      data: (byRound) {
                        final summary = byRound[node.round] ?? '';
                        if (summary.isEmpty) {
                          return Text(
                            'No plan summary recorded for this round. The plan may have been generated by an older sidecar version, or the model skipped the PLAN_SUMMARY block.',
                            style: theme.typography.body?.copyWith(
                              color: theme.resources.textFillColorTertiary,
                            ),
                          );
                        }
                        return MarkdownBody(
                          data: summary,
                          selectable: true,
                          styleSheet: _markdownStyle(theme),
                        );
                      },
                    ),
                  ),
                ),
              ],
              if (reviewsAsync != null) ...[
                const SizedBox(height: 12),
                reviewsAsync.when(
                  loading: () => const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: ProgressRing(strokeWidth: 1.6),
                      ),
                      SizedBox(width: 8),
                      Text('Loading…'),
                    ],
                  ),
                  error: (e, _) => Text(
                    'Could not load reviews: $e',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorTertiary,
                    ),
                  ),
                  data: (all) {
                    final wantSource = node.stage == _Stage.aiReview
                        ? ReviewSource.ai
                        : ReviewSource.human;
                    final filtered = all
                        .where(
                          (e) =>
                              e.source == wantSource && e.round == node.round,
                        )
                        .toList();
                    if (filtered.isEmpty) {
                      return Text(
                        node.stage == _Stage.aiReview
                            ? 'No AI review has been recorded for round ${node.round} yet.'
                            : 'No human review input has been recorded for round ${node.round} yet.',
                        style: theme.typography.body?.copyWith(
                          color: theme.resources.textFillColorTertiary,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.stage == _Stage.aiReview
                              ? 'AI review'
                              : 'Human review input',
                          style: theme.typography.caption?.copyWith(
                            color: theme.resources.textFillColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final r in filtered)
                          ReviewCard(entry: r, theme: theme),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
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
