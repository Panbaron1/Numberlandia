import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

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
                    color: color,
                    face: face && r == 0 && c == 0,
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

  const _Square({
    required this.size,
    required this.color,
    this.label,
    this.face = false,
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
          ? _Face(size: size)
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

/// Simple friendly face: two googly eyes + a small smile.
class _Face extends StatelessWidget {
  final double size;
  const _Face({required this.size});

  @override
  Widget build(BuildContext context) {
    final eye = size * 0.22;
    final pupil = eye * 0.5;
    return Padding(
      padding: EdgeInsets.only(top: size * 0.14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Eye(eye: eye, pupil: pupil),
              SizedBox(width: size * 0.14),
              _Eye(eye: eye, pupil: pupil),
            ],
          ),
          SizedBox(height: size * 0.07),
          Container(
            width: size * 0.34,
            height: size * 0.16,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: NColors.ink.withAlpha(160), width: size * 0.05),
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(size * 0.2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  final double eye;
  final double pupil;
  const _Eye({required this.eye, required this.pupil});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: eye,
      height: eye,
      decoration: const BoxDecoration(
          color: Colors.white, shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: pupil,
          height: pupil,
          decoration: const BoxDecoration(
              color: NColors.ink, shape: BoxShape.circle),
        ),
      ),
    );
  }
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
