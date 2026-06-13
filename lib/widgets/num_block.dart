import 'package:flutter/material.dart';
import '../theme.dart';

/// An original "number character" — a tower of N coloured unit squares.
///
/// Each number 0–10 has its own pastel colour (see NColors.numBlock).
/// Numbers > 10 tile into two columns; > 20 shows a compact badge.
/// Negative numbers show the character of abs(n) with a "−" prefix badge.
///
/// This is an original design — not affiliated with or derived from
/// any existing IP.
class NumBlock extends StatelessWidget {
  final int value;
  final double unit; // size of one square, default 26
  final bool showSign; // show "−" label for negatives

  const NumBlock({
    super.key,
    required this.value,
    this.unit = 26,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final abs = value.abs();
    final color = NColors.numBlockColor(abs);
    final isNeg = value < 0;

    Widget tower;
    if (abs == 0) {
      tower = _zeroBlock(color);
    } else if (abs <= 10) {
      tower = _singleColumn(abs, color);
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
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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

  Widget _zeroBlock(Color color) {
    return Container(
      width: unit,
      height: unit,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: Text(
          '0',
          style: TextStyle(
            fontSize: unit * 0.45,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _singleColumn(int n, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < n; i++) ...[
          if (i > 0) SizedBox(height: unit * 0.1),
          _Square(size: unit, color: color, label: i == n - 1 ? '$n' : null),
        ],
      ],
    );
  }

  Widget _doubleColumn(int n, Color color) {
    // Left column: always 10 squares; right column: n - 10 squares
    final right = n - 10;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _singleColumn(10, color),
        SizedBox(width: unit * 0.1),
        _singleColumn(right, color),
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

class _Square extends StatelessWidget {
  final double size;
  final Color color;
  final String? label; // shown in the bottom square

  const _Square({required this.size, required this.color, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: label != null
          ? Center(
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            )
          : null,
    );
  }
}
