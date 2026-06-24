import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Seven wears the rainbow — one colour per block, violet (top) to red
/// (bottom), matching the Numberblocks character.
const List<Color> kSevenRainbow = [
  Color(0xFF9B59B6), // violet (top — the face block)
  Color(0xFF5C6BC0), // indigo
  Color(0xFF40C4FF), // blue
  Color(0xFF34C759), // green
  Color(0xFFFFD740), // yellow
  Color(0xFFF7941E), // orange
  Color(0xFFED1C24), // red (bottom)
];

/// Block colour for the square at [row] of value [n]. Seven is a rainbow;
/// every other number uses its single character colour [base].
Color _squareColor(int n, int row, Color base) =>
    (n == 7 && row >= 0 && row < kSevenRainbow.length)
        ? kSevenRainbow[row]
        : base;

/// An original "number character" — N unit squares packed into a compact,
/// near-square block (like real number characters: 4 = 2×2, 9 = 3×3,
/// 6 = 2×3, 8 = 2×4). Composite numbers form clean rectangles; primes form
/// a balanced ragged grid (5 = 3+2, 7 = 3+3+1). The top-left unit wears a
/// friendly face; the bottom-right unit shows the count.
///
/// Each number 0–10 has its own pastel colour (see NColors.numBlock).
/// Zero is a hollow ring with a face. Negatives show abs(n) with a "−" badge.
/// Values above 100 fall back to a compact numbered badge.
///
/// Original design — not affiliated with or derived from any existing IP.
class NumBlock extends StatelessWidget {
  final int value;
  final double unit;     // size of one square
  final bool showSign;   // show "−" label for negatives
  final bool face;       // draw a face on the top-left block

  const NumBlock({
    super.key,
    required this.value,
    this.unit = 26,
    this.showSign = true,
    this.face = true,
  });

  /// Dimensions [rows, cols] that pack [n] into the canonical number-character
  /// rectangle: taller than wide, vertical first. rows = the smallest divisor
  /// of n that is >= sqrt(n); cols = n / rows. Primes become a single tall
  /// column (7 → 7×1); 8 → 4×2, 6 → 3×2, 4 → 2×2, 9 → 3×3.
  static List<int> dimsFor(int n) {
    if (n <= 1) return [n, n == 0 ? 0 : 1];
    final root = math.sqrt(n).ceil();
    for (int r = root; r <= n; r++) {
      if (n % r == 0) return [r, n ~/ r];
    }
    return [n, 1]; // prime fallback (root..n found n itself)
  }

  /// Row lengths (top → bottom). Every number is a clean rectangle, so this is
  /// `rows` copies of `cols`.
  static List<int> rowsFor(int n) {
    if (n <= 1) return [n];
    final d = dimsFor(n);
    return List.filled(d[0], d[1]);
  }

  @override
  Widget build(BuildContext context) {
    final abs = value.abs();
    final color = NColors.numBlockColor(abs);
    final isNeg = value < 0;

    Widget block;
    if (abs == 0) {
      block = _ZeroBlock(unit: unit, color: color, face: face);
    } else if (abs <= 100) {
      block = _grid(abs, color);
    } else {
      block = _badge(abs, color);
    }

    if (isNeg && showSign) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('−',
                style: TextStyle(
                    fontSize: unit * 0.55,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1)),
          ),
          const SizedBox(height: 3),
          block,
        ],
      );
    }
    return block;
  }

  Widget _grid(int n, Color color) {
    final rows = rowsFor(n);
    final gap = unit * 0.08;
    final maxCols = rows.reduce(math.max);
    final fullWidth = maxCols * unit + (maxCols - 1) * gap;
    // Index of the last cell (bottom-right) for the count label.
    final lastRow = rows.length - 1;
    final lastCol = rows[lastRow] - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: gap),
          // Centre partial rows under the full-width rows.
          SizedBox(
            width: fullWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int c = 0; c < rows[r]; c++) ...[
                  if (c > 0) SizedBox(width: gap),
                  _Square(
                    size: unit,
                    color: _squareColor(n, r, color),
                    face: face && r == 0 && c == 0,
                    // One has a single eye in the middle (like the character).
                    oneEye: n == 1,
                    // Count on the bottom-right block (unless it's the face
                    // block, e.g. n == 1).
                    label: (r == lastRow && c == lastCol && !(r == 0 && c == 0))
                        ? '$n'
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _badge(int n, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color, width: 2),
      ),
      child: Text('$n',
          style: TextStyle(
              fontSize: unit * 0.65,
              fontWeight: FontWeight.w900,
              color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Square extends StatelessWidget {
  final double size;
  final Color color;
  final String? label; // count, shown on the bottom-right square
  final bool face;     // eyes + smile, shown on the top-left square
  final bool oneEye;   // single centred eye (used by One)

  const _Square({
    required this.size,
    required this.color,
    this.label,
    this.face = false,
    this.oneEye = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(90),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: face
          ? _Face(size: size, eyes: oneEye ? 1 : 2)
          : (label != null
              ? Center(
                  child: Text(label!,
                      style: TextStyle(
                          fontSize: size * 0.42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1)))
              : null),
    );
  }
}

/// The friendly face on a unit square — same look everywhere via
/// [paintNumberFace].
class _Face extends StatelessWidget {
  final double size;
  final int eyes;
  const _Face({required this.size, this.eyes = 2});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _FacePainter(eyes));
  }
}

class _FacePainter extends CustomPainter {
  final int eyes;
  _FacePainter(this.eyes);

  @override
  void paint(Canvas canvas, Size size) =>
      paintNumberFace(canvas, Offset.zero, size.width, eyes: eyes);

  @override
  bool shouldRepaint(_FacePainter old) => old.eyes != eyes;
}

/// Zero is special — a hollow ring with a face, not a block.
class _ZeroBlock extends StatelessWidget {
  final double unit;
  final Color color;
  final bool face;
  const _ZeroBlock(
      {required this.unit, required this.color, required this.face});

  @override
  Widget build(BuildContext context) {
    final d = unit * 1.4;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: unit * 0.16),
      ),
      child: face
          ? _Face(size: unit)
          : Center(
              child: Text('0',
                  style: TextStyle(
                      fontSize: unit * 0.5,
                      fontWeight: FontWeight.w900,
                      color: color))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Renders [value] as a number-character block sized to fill the given box.
/// Small values (≤ 100 units) use the widget NumBlock with faces; larger values
/// (up to 10,000 = 100×100) switch to a pure-canvas painter for performance.
class NumBlockView extends StatelessWidget {
  final int value;
  final bool face;
  const NumBlockView({super.key, required this.value, this.face = true});

  static const int maxUnits = 10000; // 100 × 100

  @override
  Widget build(BuildContext context) {
    final abs = value.abs();
    if (abs > maxUnits) {
      return Center(
        child: Text('$value',
            style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: NColors.numBlockColor(abs))),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final dims = NumBlock.dimsFor(abs == 0 ? 0 : abs);
        final rows = dims[0].clamp(1, 100);
        final cols = dims[1].clamp(1, 100);
        // Fit a unit cell to the box (leave a little margin).
        final boxW = c.maxWidth * 0.9;
        final boxH = c.maxHeight * 0.9;
        final unit = math.min(boxW / cols, boxH / rows);

        // Small numbers: charming widget version with faces.
        if (abs <= 100 && unit >= 14) {
          return Center(
            child: NumBlock(value: value, unit: unit.clamp(14, 64).toDouble(),
                face: face),
          );
        }
        // Large numbers: fast canvas grid.
        return Center(
          child: CustomPaint(
            size: Size(boxW, boxH),
            painter: NumBlockPainter(
              rows: rows,
              cols: cols,
              color: NColors.numBlockColor(abs),
            ),
          ),
        );
      },
    );
  }
}

/// Pure-canvas grid of [rows]×[cols] squares, centred and fit to the box.
/// Handles up to 100×100 = 10,000 cells with no per-cell widgets.
class NumBlockPainter extends CustomPainter {
  final int rows;
  final int cols;
  final Color color;

  const NumBlockPainter(
      {required this.rows, required this.cols, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || cols <= 0) return;
    final density = rows * cols;
    final gap = density > 400 ? 1.0 : (density > 100 ? 2.0 : 4.0);
    final byW = (size.width - (cols - 1) * gap) / cols;
    final byH = (size.height - (rows - 1) * gap) / rows;
    final cell = byW < byH ? byW : byH;
    final gridW = cols * cell + (cols - 1) * gap;
    final gridH = rows * cell + (rows - 1) * gap;
    final ox = (size.width - gridW) / 2;
    final oy = (size.height - gridH) / 2;

    final fill = Paint()..color = color;
    final rounded = cell > 5;
    final radius = Radius.circular(cell * 0.2);

    for (int r = 0; r < rows; r++) {
      for (int col = 0; col < cols; col++) {
        final rect = Rect.fromLTWH(
            ox + col * (cell + gap), oy + r * (cell + gap), cell, cell);
        if (rounded) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), fill);
        } else {
          canvas.drawRect(rect, fill);
        }
      }
    }

    // Friendly face on the top-left cell when it's big enough to read.
    // One (a single cell) gets its single centred eye here too.
    if (cell >= 22) {
      paintNumberFace(canvas, Offset(ox, oy), cell,
          eyes: rows * cols == 1 ? 1 : 2);
    }
  }

  @override
  bool shouldRepaint(NumBlockPainter old) =>
      old.rows != rows || old.cols != cols || old.color != color;
}

/// The app's one canonical numberblock face — big white eyes with navy pupils
/// and a warm brown smile. Drawn on a unit cell whose top-left corner is
/// [cellTopLeft] and side length is [cell]. Used by every block (widget and
/// canvas) and the times-tables array, so the face is identical everywhere.
void paintNumberFace(Canvas canvas, Offset cellTopLeft, double cell,
    {int eyes = 2}) {
  final cx = cellTopLeft.dx + cell / 2;
  final eyeY = cellTopLeft.dy + cell * 0.40;
  final white = Paint()..color = Colors.white;
  final navy = Paint()..color = const Color(0xFF14213D);
  // One has a single, slightly larger eye in the middle; others have two.
  final single = eyes == 1;
  final eyeR = cell * (single ? 0.20 : 0.16);
  final pupilR = cell * (single ? 0.11 : 0.09);
  final offsets = single ? <double>[0.0] : <double>[-cell * 0.20, cell * 0.20];
  for (final dx in offsets) {
    canvas.drawCircle(Offset(cx + dx, eyeY), eyeR, white);
    canvas.drawCircle(Offset(cx + dx, eyeY), pupilR, navy);
  }
  final smile = Paint()
    ..color = const Color(0xFF6B4A2B) // warm brown
    ..style = PaintingStyle.stroke
    ..strokeWidth = cell * 0.075
    ..strokeCap = StrokeCap.round;
  final rect = Rect.fromCircle(
      center: Offset(cx, cellTopLeft.dy + cell * 0.55), radius: cell * 0.20);
  canvas.drawArc(rect, 0.25, 2.64, false, smile);
}

// ─────────────────────────────────────────────────────────────────────────────

/// A NumBlock that springs in on appear and re-bounces when its value changes.
class BouncyNumBlock extends StatefulWidget {
  final int value;
  final double unit;
  final bool showSign;
  final bool face;

  const BouncyNumBlock({
    super.key,
    required this.value,
    this.unit = 26,
    this.showSign = true,
    this.face = true,
  });

  @override
  State<BouncyNumBlock> createState() => _BouncyNumBlockState();
}

class _BouncyNumBlockState extends State<BouncyNumBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void didUpdateWidget(BouncyNumBlock old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.7, end: 1.0)
          .animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut)),
      child: NumBlock(
        value: widget.value,
        unit: widget.unit,
        showSign: widget.showSign,
        face: widget.face,
      ),
    );
  }
}
