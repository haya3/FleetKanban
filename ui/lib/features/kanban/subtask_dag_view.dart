// SubtaskDagView: visualizes the whole task execution pipeline with a
// Sugiyama layout.
//
//   * Vertical axis = sequential (Plan → Code subtasks → Review)
//   * Horizontal axis = parallel (subtasks in the same layer run side by side)
//   * Plan / Review are meta-stages of the parent task, so they are inserted
//     as synthetic nodes before and after the subtask DAG. Plan is the root;
//     leaves connect to Review.
//
// The graphview package is used only for layout (SugiyamaAlgorithm) and
// edge rendering (SugiyamaEdgeRenderer). The `GraphView` widget has a known
// behavior of unmounting all children on the layout pass when
// `_isInitialized=true`, so we render manually with Stack + CustomPaint +
// InteractiveViewer. That keeps the graph visible even after wheel scroll
// stops.

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:graphview/GraphView.dart';

import '../../infra/ipc/generated/fleetkanban/v1/fleetkanban.pb.dart' as pb;

const double _nodeWidth = 220;
const double _nodeHeight = 76;
const double _canvasMargin = 24;

// Synthetic IDs for meta-stage nodes. Chosen so they can't collide with a
// real subtask id (which is a ULID).
const String _planNodeId = '__stage_plan__';
const String _reviewNodeId = '__stage_review__';

enum _Stage { plan, code, review }

String _stageLabelOf(_Stage s) => switch (s) {
  _Stage.plan => 'Plan',
  _Stage.code => 'Code',
  _Stage.review => 'Review',
};

class _StageNode {
  const _StageNode({
    required this.id,
    required this.stage,
    required this.title,
    required this.status,
    required this.model,
  });
  final String id;
  final _Stage stage;
  final String title;
  final String status; // pending | doing | done | failed
  final String model;
}

class SubtaskDagView extends StatefulWidget {
  const SubtaskDagView({super.key, required this.task, required this.subtasks});
  final pb.Task task;
  final List<pb.Subtask> subtasks;

  @override
  State<SubtaskDagView> createState() => _SubtaskDagViewState();
}

class _SubtaskDagViewState extends State<SubtaskDagView> {
  late final SugiyamaConfiguration _config;
  late SugiyamaAlgorithm _algorithm;
  Graph _graph = Graph();
  Map<String, _StageNode> _byId = {};
  Size _graphSize = Size.zero;
  final TransformationController _xform = TransformationController();

  // Version counter used by CustomPainter.shouldRepaint. Bumped only when
  // the layout is recomputed or edge.paint changes. Unlike the previous
  // implementation (which passed a fresh Object() every frame), this avoids
  // unnecessary repaints.
  int _paintVersion = 0;

  @override
  void initState() {
    super.initState();
    _config = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
      ..levelSeparation = 56
      ..nodeSeparation = 24
      ..coordinateAssignment = CoordinateAssignment.Average
      ..bendPointShape = CurvedBendPointShape(curveLength: 12);
    _runLayout();
  }

  @override
  void dispose() {
    _xform.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Edge color depends on theme (OS accent color, light/dark). This
    // callback also runs once right after initState to seed the paint.
    _applyEdgePaints(FluentTheme.of(context));
    _paintVersion++;
  }

  @override
  void didUpdateWidget(covariant SubtaskDagView old) {
    super.didUpdateWidget(old);
    if (_topologyChanged(old)) {
      setState(() {
        _runLayout();
        _applyEdgePaints(FluentTheme.of(context));
        _paintVersion++;
      });
    } else if (_metadataChanged(old)) {
      // Visual-only changes (title / model / status). Keep the layout but
      // refresh node colors and edge paints.
      setState(() {
        _byId = _buildStageNodes();
        _applyEdgePaints(FluentTheme.of(context));
        _paintVersion++;
      });
    }
  }

  // Topology = the set of nodes and edges. Only re-run Sugiyama when
  // that changes. subtask.status / task.status only affect paint, so they
  // must not return true here.
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

  // Derive the Plan meta-stage status from task.status.
  //
  //   * planning              → doing (drafting the plan)
  //   * 0 subtasks & failed   → failed (plan generation itself failed)
  //   * 0 subtasks & terminal → skipped (aborted before reaching Plan)
  //   * otherwise             → done (plan is assumed complete)
  String _planStatus() {
    final s = widget.task.status;
    if (s == 'planning') return 'doing';
    if (widget.subtasks.isEmpty) {
      if (s == 'failed') return 'failed';
      if (s == 'cancelled' || s == 'aborted') return 'skipped';
    }
    return 'done';
  }

  // Derive the Review meta-stage status from task.status.
  //
  //   * ai_review / human_review → doing
  //   * done                     → done
  //   * failed                   → failed when every subtask is done (Review
  //                                ran and failed); otherwise skipped (Code
  //                                failed and Review was never reached)
  //   * cancelled / aborted      → skipped (aborted before Review)
  //   * otherwise                → pending (not yet reached)
  String _reviewStatus() {
    final s = widget.task.status;
    if (s == 'ai_review' || s == 'human_review') return 'doing';
    if (s == 'done') return 'done';
    final allSubtasksDone =
        widget.subtasks.isNotEmpty &&
        widget.subtasks.every((x) => x.status == 'done');
    if (s == 'failed') {
      return allSubtasksDone ? 'failed' : 'skipped';
    }
    if (s == 'cancelled' || s == 'aborted') return 'skipped';
    return 'pending';
  }

  Map<String, _StageNode> _buildStageNodes() {
    final t = widget.task;
    final nodes = <String, _StageNode>{
      _planNodeId: _StageNode(
        id: _planNodeId,
        stage: _Stage.plan,
        title: 'Plan',
        status: _planStatus(),
        model: t.planModel,
      ),
    };
    for (final s in widget.subtasks) {
      nodes[s.id] = _StageNode(
        id: s.id,
        stage: _Stage.code,
        title: s.title,
        status: s.status,
        model: s.codeModel,
      );
    }
    nodes[_reviewNodeId] = _StageNode(
      id: _reviewNodeId,
      stage: _Stage.review,
      title: 'Review',
      status: _reviewStatus(),
      model: t.reviewModel,
    );
    return nodes;
  }

  void _runLayout() {
    _byId = _buildStageNodes();
    _graph = Graph();

    final nodeMap = <String, Node>{};
    for (final id in _byId.keys) {
      final n = Node.Id(id)..size = const Size(_nodeWidth, _nodeHeight);
      _graph.addNode(n);
      nodeMap[id] = n;
    }

    final realIds = {for (final s in widget.subtasks) s.id};
    final hasIncoming = <String>{};
    final hasOutgoing = <String>{};

    for (final s in widget.subtasks) {
      for (final dep in s.dependsOn) {
        if (!realIds.contains(dep)) continue;
        _graph.addEdge(nodeMap[dep]!, nodeMap[s.id]!);
        hasIncoming.add(s.id);
        hasOutgoing.add(dep);
      }
    }

    if (widget.subtasks.isEmpty) {
      _graph.addEdge(nodeMap[_planNodeId]!, nodeMap[_reviewNodeId]!);
    } else {
      for (final s in widget.subtasks) {
        if (!hasIncoming.contains(s.id)) {
          _graph.addEdge(nodeMap[_planNodeId]!, nodeMap[s.id]!);
        }
        if (!hasOutgoing.contains(s.id)) {
          _graph.addEdge(nodeMap[s.id]!, nodeMap[_reviewNodeId]!);
        }
      }
    }

    // SugiyamaAlgorithm accumulates nodeData / edgeData on the instance,
    // so rebuild it whenever topology changes. reset() would also work,
    // but allocating a fresh one is safer (no residual state).
    _algorithm = SugiyamaAlgorithm(_config);
    _graphSize = _algorithm.run(_graph, 0, 0);
  }

  // SugiyamaEdgeRenderer prefers edge.paint when present, so color each
  // edge individually based on its destination's status. Iterate over
  // _algorithm.graph.edges so we also cover the synthetic edges the
  // algorithm adds during denormalization.
  void _applyEdgePaints(FluentThemeData theme) {
    for (final e in _algorithm.graph.edges) {
      final key = e.destination.key;
      final destId = key is ValueKey ? key.value as String? : null;
      final s = destId == null
          ? 'pending'
          : (_byId[destId]?.status ?? 'pending');
      e.paint = _edgePaintFor(theme, s);
    }
  }

  Paint _edgePaintFor(FluentThemeData theme, String destStatus) {
    final color = switch (destStatus) {
      'done' => const Color(0xFF107C10),
      'doing' => theme.accentColor.normal,
      'failed' => const Color(0xFFC42B1C),
      _ => theme.resources.controlStrokeColorDefault,
    };
    return Paint()
      ..color = color
      ..strokeWidth = destStatus == 'doing' ? 1.8 : 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    final defaultEdgePaint = Paint()
      ..color = theme.resources.controlStrokeColorDefault
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final canvasW = _graphSize.width + _canvasMargin * 2;
    final canvasH = _graphSize.height + _canvasMargin * 2;

    return ClipRect(
      child: InteractiveViewer(
        transformationController: _xform,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.3,
        maxScale: 3,
        child: SizedBox(
          width: canvasW,
          height: canvasH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _EdgePainter(
                    algorithm: _algorithm,
                    defaultPaint: defaultEdgePaint,
                    offset: const Offset(_canvasMargin, _canvasMargin),
                    version: _paintVersion,
                  ),
                ),
              ),
              for (final node in _graph.nodes)
                Positioned(
                  left: _canvasMargin + node.x,
                  top: _canvasMargin + node.y,
                  width: _nodeWidth,
                  height: _nodeHeight,
                  child: _StageNodeCard(
                    node: _byId[(node.key as ValueKey).value as String]!,
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
// Edge painter
// ---------------------------------------------------------------------------

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.algorithm,
    required this.defaultPaint,
    required this.offset,
    required this.version,
  });

  final SugiyamaAlgorithm algorithm;
  final Paint defaultPaint;
  final Offset offset;
  // Node positions and bend points only change in _runLayout, and
  // edge.paint only changes in _applyEdgePaints. The State bumps version
  // for both cases, so its delta is the sole repaint signal.
  final int version;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    for (final edge in algorithm.graph.edges) {
      algorithm.renderer?.renderEdge(canvas, edge, defaultPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) =>
      old.algorithm != algorithm ||
      old.version != version ||
      old.offset != offset;
}

// ---------------------------------------------------------------------------
// Node card
// ---------------------------------------------------------------------------

class _StageNodeCard extends StatefulWidget {
  const _StageNodeCard({required this.node});
  final _StageNode node;

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
      case 'skipped':
        return (FluentIcons.blocked2, t.resources.textFillColorTertiary);
      case 'pending':
      default:
        return (FluentIcons.circle_ring, t.resources.textFillColorTertiary);
    }
  }

  // Plan = accent, Code = green, Review = purple. Makes it obvious at a
  // glance which stage each layer belongs to when scanning vertically.
  Color _stageColor(FluentThemeData t) => switch (widget.node.stage) {
    _Stage.plan => t.accentColor.normal,
    _Stage.code => const Color(0xFF0E7A0D),
    _Stage.review => const Color(0xFF8764B8),
  };

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final n = widget.node;
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showStageDetail(context, n),
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
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (running)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: ProgressRing(strokeWidth: 1.6),
                            )
                          else
                            Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
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
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          n.title.isEmpty ? '(no title)' : n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body?.copyWith(
                            fontSize: 12,
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
                            fontSize: 10,
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
// Detail dialog
// ---------------------------------------------------------------------------

void _showStageDetail(BuildContext context, _StageNode n) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _StageDetailDialog(node: n),
  );
}

class _StageDetailDialog extends StatelessWidget {
  const _StageDetailDialog({required this.node});
  final _StageNode node;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final rows = <(String, String)>[
      ('Stage', _stageLabelOf(node.stage)),
      ('Status', node.status),
      ('Model', node.model.isEmpty ? '(not recorded)' : node.model),
      if (node.stage == _Stage.code) ('Subtask ID', node.id),
    ];
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 480),
      title: Text(
        node.title.isEmpty ? '(no title)' : node.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
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
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
