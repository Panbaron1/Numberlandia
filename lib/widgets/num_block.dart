import 'package:flutter/material.dart';
import '../theme.dart';

/// An original "number character" — a tower of N coloured unit squares
/// with a friendly face on the top block (eyes + smile).
///
/// Each number 0–10 has its own pastel colour (see NColors.numBlock).
/// Numbers 11–20 tile into two columns; > 20 shows a compact badge.
/// Negative numbers show the character of abs(n) with a "−" badge.
///
/// Original design — not affiliated with or derived from any existing IP.
class NumBlock extends StatelessWidget {
  final int value;
  final double unit;     // size of one square, default 26
  final bool showSign;   // show "−" label for negatives
  final bool face;       // draw eyes + smile on the top block

  const NumBlock({
    super.key,
    required this.value,
    this.unit = 26,
    this.showSign = true,
    this.face = true,
  });

  @override
  Widget build(BuildContext context) {
    final abs = value.abs();
    final color = NColors.numBlockColor(abs);
    final isNeg = value < 0;

    Widget tower;
    if (abs == 0) {
      tower = _ZeroBlock(unit: unit, color: color, face: face);
    } else if (abs <= 10) {
      tower = _singleColumn(abs, color, faceOnTop: face);
    } else if (abs <= 20) {
      tower = _doubleColumn(abs, color);
    } else {
      tower = _badge(abs, color);
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
            child: Text(
              '−',
              style: TextStyle(
                fontSize: unit * 0.55,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          tower,
        ],
      );
    }
    return tower;
  }

  Widget _singleColumn(int n, Color color, {required bool faceOnTop}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < n; i++) ...[
          if (i > 0) SizedBox(height: unit * 0.08),
          _Square(
            size: unit,
            color: color,
            // top block (i == 0) carries the face; bottom carries the count
            face: faceOnTop && i == 0,
            label: i == n - 1 ? '$n' : null,
          ),
        ],
      ],
    );
  }

  Widget _doubleColumn(int n, Color color) {
    final right = n - 10;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _singleColumn(10, color, faceOnTop: face),
        SizedBox(width: unit * 0.1),
        _singleColumn(right, color, faceOnTop: false),
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
      child: Text(
        '$n',
        style: TextStyle(
          fontSize: unit * 0.65,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Square extends StatelessWidget {
  final double size;
  final Color color;
  final String? label; // count, shown in the bottom square
  final bool face;     // eyes + smile, shown on the top square

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
          colors: [
            Color.lerp(color, Colors.white, 0.18)!,
            color,
          ],
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
                  child: Text(
                    label!,
                    style: TextStyle(
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                )
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
      padding: EdgeInsets.only(top: size * 0.16),
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
          SizedBox(height: size * 0.08),
          // Smile
          Container(
            width: size * 0.34,
            height: size * 0.17,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: NColors.ink.withAlpha(160),
                  width: size * 0.05,
                ),
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(size * 0.2),
              ),
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
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: pupil,
          height: pupil,
          decoration: const BoxDecoration(
            color: NColors.ink,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Zero is special — a hollow ring with a face, not a tower.
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
                      color: color)),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// A NumBlock that bounces in when it first appears, and re-bounces
/// whenever its [value] changes. Wraps NumBlock with a spring scale.
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
      scale: Tween(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      ),
      child: NumBlock(
        value: widget.value,
        unit: widget.unit,
        showSign: widget.showSign,
        face: widget.face,
      ),
    );
  }
}
