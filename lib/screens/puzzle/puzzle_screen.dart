import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import '../../widgets/scene_background.dart';

/// Puzzle — build a big block. A big rectangular outline is shown; the child
/// drags numberblocks from the sides (1–5 left, 6–10 right) and *any* blocks
/// that add up fill it in (the colours show the parts — the number bond). When
/// it's full, the pieces merge into one big numberblock that bursts: gentle
/// shake + confetti. No fail states — a block that would overflow bounces back.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

const _color = NColors.puzzle;

class _Drop {
  final int value;
  final Color color;
  _Drop(this.value, this.color);
}

enum _Phase { building, done }

class _PuzzleScreenState extends State<PuzzleScreen>
    with TickerProviderStateMixin {
  final _rng = math.Random();
  int _rows = 4, _cols = 6;
  final List<_Drop> _drops = [];
  _Phase _phase = _Phase.building;

  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _confetti = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));

  int get _area => _rows * _cols;
  int get _sum => _drops.fold(0, (a, d) => a + d.value);
  bool get building => _phase == _Phase.building;

  @override
  void initState() {
    super.initState();
    _newPuzzle();
  }

  @override
  void dispose() {
    _shake.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _newPuzzle() {
    setState(() {
      _rows = 4 + _rng.nextInt(7); // 4..10
      _cols = 4 + _rng.nextInt(7); // 4..10 — any rectangle up to 10×10
      _drops.clear();
      _phase = _Phase.building;
    });
  }

  bool _willAccept(int v) => building && _sum + v <= _area;

  Future<void> _drop(int v) async {
    if (!_willAccept(v)) return;
    setState(() => _drops.add(_Drop(v, NColors.numBlockColor(v))));
    await HapticsService.instance.selection();
    await AudioService.instance.playPop();
    if (_sum == _area) _complete();
  }

  // Block complete: form the 3D block, burst, then linger (equation + Next).
  Future<void> _complete() async {
    setState(() => _phase = _Phase.done);
    _shake.forward(from: 0);
    _confetti.forward(from: 0);
    await HapticsService.instance.medium();
    await AudioService.instance.playChime();
  }

  /// One colour per filled unit, in drop order (so 5 + 4 shows five of one
  /// colour then four of another — the number bond).
  List<Color> _filledColors() {
    final out = <Color>[];
    for (final d in _drops) {
      if (d.value == 7) {
        out.addAll(kSevenRainbow); // Seven keeps its rainbow (7 cells)
      } else {
        for (int i = 0; i < d.value; i++) {
          out.add(d.color);
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RoomHeader(
        title: 'Puzzle',
        color: _color,
        actions: [
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.refresh_rounded, color: _color),
            tooltip: 'New puzzle',
            onPressed: _newPuzzle,
          ),
        ],
      ),
      body: SceneBackground(
        color: _color,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final t = _shake.value;
              final dx =
                  t == 0 ? 0.0 : math.sin(t * math.pi * 8) * 7 * (1 - t);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Stack(
              children: [
                Row(
                  children: [
                    // Inset from the edge so grabbing a block doesn't trigger
                    // the system back-swipe.
                    const Padding(
                      padding: EdgeInsets.only(left: 28),
                      child: _Palette(values: [1, 2, 3, 4, 5]),
                    ),
                    Expanded(child: _Centre(state: this)),
                    const Padding(
                      padding: EdgeInsets.only(right: 28),
                      child: _Palette(values: [6, 7, 8, 9, 10]),
                    ),
                  ],
                ),
                if (!_confetti.isDismissed)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _confetti,
                        builder: (context, _) => CustomPaint(
                            painter: _ConfettiPainter(_confetti.value)),
                      ),
                    ),
                  ),
                // Equation lingers over the finished block until "Next".
                if (!building) Positioned.fill(child: _DonePanel(state: this)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Side palette of draggable numberblocks ───────────────────────────────────

class _Palette extends StatelessWidget {
  final List<int> values;
  const _Palette({required this.values});

  @override
  Widget build(BuildContext context) {
    final enabled =
        context.findAncestorStateOfType<_PuzzleScreenState>()?.building ?? true;
    return SizedBox(
      width: 92,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.sm),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _DragBlock(value: v, enabled: enabled),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragBlock extends StatelessWidget {
  final int value;
  final bool enabled;
  const _DragBlock({required this.value, required this.enabled});

  static const double _unit = 30; // bigger = easier for little hands to grab

  @override
  Widget build(BuildContext context) {
    final block = NumBlock(value: value, unit: _unit, showSign: false);
    if (!enabled) return Opacity(opacity: 0.45, child: block);
    return Draggable<int>(
      data: value,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: const Offset(-38, -38),
        child: NumBlock(value: value, unit: _unit * 1.25, showSign: false),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: block),
      child: block,
    );
  }
}

// ── Centre: title, big block, progress ───────────────────────────────────────

class _Centre extends StatelessWidget {
  final _PuzzleScreenState state;
  const _Centre({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Gap.sm),
        const Text('Build the big block!',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: NColors.ink)),
        const SizedBox(height: Gap.xs),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: state._cols / state._rows,
              child: DragTarget<int>(
                onWillAcceptWithDetails: (d) => state._willAccept(d.data),
                onAcceptWithDetails: (d) => state._drop(d.data),
                builder: (context, cand, rej) => _BoardView(state: state),
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.xs),
        SizedBox(
          height: 46,
          child: state.building
              ? Text(
                  '${state._sum} / ${state._area}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: NColors.ink),
                )
              : null,
        ),
        const SizedBox(height: Gap.sm),
      ],
    );
  }
}

// ── The big block: filling up, then one unified block ────────────────────────

class _BoardView extends StatelessWidget {
  final _PuzzleScreenState state;
  const _BoardView({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = state._rows, cols = state._cols;
    return LayoutBuilder(
      builder: (context, c) {
        final cell = math.min(c.maxWidth / cols, c.maxHeight / rows);
        final w = cols * cell, h = rows * cell;

        if (state._phase == _Phase.building) {
          return SizedBox(
            width: w,
            height: h,
            child: CustomPaint(
              painter: _FillPainter(
                  rows: rows, cols: cols, cell: cell, filled: state._filledColors()),
            ),
          );
        }

        // Full — merge into one big numberblock and bounce it in.
        return TweenAnimationBuilder<double>(
          key: ValueKey('${rows}x$cols'),
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, s, child) =>
              Transform.scale(scale: s, child: child),
          child: SizedBox(
            width: w,
            height: h,
            child: CustomPaint(
              painter: _FillPainter(
                  rows: rows,
                  cols: cols,
                  cell: cell,
                  filled: const [],
                  unified: NColors.numBlockColor(rows * cols)),
            ),
          ),
        );
      },
    );
  }
}

class _FillPainter extends CustomPainter {
  final int rows, cols;
  final double cell;
  final List<Color> filled; // colour per filled cell, row-major (length == sum)
  final Color? unified; // non-null when the block is complete

  _FillPainter(
      {required this.rows,
      required this.cols,
      required this.cell,
      required this.filled,
      this.unified});

  @override
  void paint(Canvas canvas, Size size) {
    final gap = cell * 0.04; // tighter — cells sit close together
    final r = Radius.circular(cell * 0.18);

    if (unified != null) {
      _paint3D(canvas, gap, r);
      return;
    }

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final i = row * cols + col;
        final rect = Rect.fromLTWH(
            col * cell + gap, row * cell + gap, cell - gap * 2, cell - gap * 2);
        final rr = RRect.fromRectAndRadius(rect, r);
        final fill = i < filled.length ? filled[i] : null;
        if (fill != null) {
          canvas.drawRRect(
              rr, Paint()..color = Color.lerp(fill, Colors.white, 0.12)!);
        } else {
          canvas.drawRRect(rr, Paint()..color = Colors.white.withAlpha(120));
          canvas.drawRRect(
              rr,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = math.max(2, cell * 0.05)
                ..color = _color.withAlpha(110));
        }
      }
    }
  }

  /// The finished block, extruded: a darker base under each cell + a top-lit
  /// gradient face, so the whole thing reads as a chunky 3D numberblock.
  void _paint3D(Canvas canvas, double gap, Radius r) {
    final c = unified!;
    final lip = cell * 0.16;
    final s = cell - gap * 2;
    final base = Paint()..color = Color.lerp(c, Colors.black, 0.30)!;

    // Bases first (peek out as the bottom edge / seams).
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final rect =
            Rect.fromLTWH(col * cell + gap, row * cell + gap + lip, s, s);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, r), base);
      }
    }
    // Lit faces on top.
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final rect = Rect.fromLTWH(col * cell + gap, row * cell + gap, s, s);
        final face = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(c, Colors.white, 0.32)!, c],
          ).createShader(rect);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, r), face);
      }
    }
    if (cell >= 16) paintNumberFace(canvas, Offset(gap, gap), s);
  }

  @override
  bool shouldRepaint(_FillPainter old) =>
      old.filled.length != filled.length ||
      old.unified != unified ||
      old.cell != cell ||
      old.rows != rows ||
      old.cols != cols;
}

// ── Lingering equation + Next button (over the finished block) ───────────────

class _DonePanel extends StatelessWidget {
  final _PuzzleScreenState state;
  const _DonePanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final eq =
        '${state._drops.map((d) => d.value).join(' + ')} = ${state._area}';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding:
                const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: BorderRadius.circular(Radii.lg),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                eq,
                style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: NColors.ink),
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          SoftButton(
            color: _color,
            width: 200,
            height: 64,
            onTap: state._newPuzzle,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Next puzzle', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full-screen confetti burst ───────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double t; // 0..1
  _ConfettiPainter(this.t);

  static final _rng = math.Random(7);
  static const _colors = [
    Color(0xFFED1C24),
    Color(0xFFF7941E),
    Color(0xFFFFD740),
    Color(0xFF34C759),
    Color(0xFF40C4FF),
    Color(0xFF5C6BC0),
    Color(0xFF9B59B6),
    Color(0xFFEC407A),
  ];
  static final _pieces = List.generate(80, (i) {
    return [
      _rng.nextDouble(),
      -_rng.nextDouble() * 0.3,
      0.6 + _rng.nextDouble() * 0.8,
      _rng.nextDouble() * math.pi * 2,
      6.0 + _rng.nextDouble() * 8,
    ];
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0) return;
    final fade = t > 0.85 ? (1 - t) / 0.15 : 1.0;
    for (int i = 0; i < _pieces.length; i++) {
      final p = _pieces[i];
      final x = p[0] * size.width + math.sin((t + p[3]) * math.pi * 2) * 18;
      final y = (p[1] + t * p[2]) * size.height + t * size.height * 0.4;
      if (y < -20 || y > size.height + 20) continue;
      final s = p[4];
      final paint = Paint()
        ..color = _colors[i % _colors.length].withAlpha((fade * 230).round());
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t + p[3]) * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.6),
            Radius.circular(s * 0.2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
