import 'package:flutter/material.dart';
import '../../theme.dart';

/// Virtualized number line painter.
///
/// Only ticks in the visible viewport are drawn — never the full 2M range.
/// At pixelsPerUnit=80, a 1200px tablet shows ~15 ticks maximum.
///
/// Visual zones:
///   Negative side — soft teal wash (NColors.numberLine)
///   Zero          — gold circle + tall tick
///   Positive side — soft blue wash (NColors.million)
class NumberLinePainter extends CustomPainter {
  final double viewOffset;    // number-space position of viewport centre
  final int current;
  final double pixelsPerUnit;

  static const double _axisY     = 0.58; // fraction of height for axis
  static const double _tickMajor = 32.0; // multiples of 10
  static const double _tickMinor = 18.0; // other integers
  static const double _tickZero  = 48.0; // zero
  static const double _tickCur   = 36.0; // current (if not 0 or ×10)

  const NumberLinePainter({
    required this.viewOffset,
    required this.current,
    required this.pixelsPerUnit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * _axisY;
    final zeroX = size.width / 2 - viewOffset * pixelsPerUnit;

    // ── Background colour zones ───────────────────────────────────────────
    _paintZones(canvas, size, cy, zeroX);

    // ── Axis line ─────────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      Paint()
        ..color = NColors.inkSoft.withAlpha(60)
        ..strokeWidth = 2.5,
    );

    // ── Compute visible range ─────────────────────────────────────────────
    final half = (size.width / 2) / pixelsPerUnit;
    final first = (viewOffset - half - 2).floor().clamp(-1000000, 1000000);
    final last  = (viewOffset + half + 2).ceil().clamp(-1000000, 1000000);

    // ── Ticks + labels ────────────────────────────────────────────────────
    final tickPaint = Paint()..strokeWidth = 2.5;

    for (int n = first; n <= last; n++) {
      final x = size.width / 2 + (n - viewOffset) * pixelsPerUnit;

      double tickH;
      Color tickColor;

      if (n == 0) {
        tickH = _tickZero;
        tickColor = NColors.zero;
      } else if (n == current && n % 10 != 0) {
        tickH = _tickCur;
        tickColor = n < 0 ? NColors.numberLine : NColors.million;
      } else if (n % 10 == 0) {
        tickH = _tickMajor;
        tickColor = n < 0
            ? NColors.numberLine.withAlpha(180)
            : NColors.million.withAlpha(180);
      } else {
        tickH = _tickMinor;
        tickColor = NColors.inkSoft.withAlpha(90);
      }

      // Brighten further for the current position
      if (n == current && n != 0) tickColor = tickColor.withAlpha(255);

      tickPaint.color = tickColor;
      canvas.drawLine(
        Offset(x, cy - tickH / 2),
        Offset(x, cy + tickH / 2),
        tickPaint,
      );

      // Labels
      final showLabel = n == 0 ||
          n == current ||
          n % 10 == 0 ||
          (pixelsPerUnit >= 110 && n % 5 == 0);

      if (showLabel) {
        final style = _labelStyle(n);
        _drawText(canvas, n.toString(), x, cy + tickH / 2 + 5, style);
      }
    }

    // ── Zero circle ───────────────────────────────────────────────────────
    if (zeroX >= -20 && zeroX <= size.width + 20) {
      canvas.drawCircle(
        Offset(zeroX, cy),
        7,
        Paint()..color = NColors.zero,
      );
    }

    // ── Current-number marker (downward triangle) ─────────────────────────
    final curX = size.width / 2 + (current - viewOffset) * pixelsPerUnit;
    final markerColor = current == 0
        ? NColors.zero
        : (current < 0 ? NColors.numberLine : NColors.million);
    _drawMarker(canvas, curX, cy - _markerTop(current), markerColor);
  }

  double _markerTop(int n) {
    if (n == 0) return _tickZero / 2 + 6;
    if (n % 10 == 0) return _tickMajor / 2 + 6;
    if (n == current) return _tickCur / 2 + 6;
    return _tickMinor / 2 + 6;
  }

  void _paintZones(Canvas canvas, Size size, double cy, double zeroX) {
    // Negative zone (left of zero) — teal wash
    if (zeroX > 0) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, zeroX.clamp(0, size.width), cy),
        Paint()..color = NColors.numberLine.withAlpha(14),
      );
    }
    // Positive zone (right of zero) — blue wash
    if (zeroX < size.width) {
      canvas.drawRect(
        Rect.fromLTRB(zeroX.clamp(0, size.width), 0, size.width, cy),
        Paint()..color = NColors.million.withAlpha(14),
      );
    }
  }

  TextStyle _labelStyle(int n) {
    if (n == 0) {
      return const TextStyle(
        color: NColors.zero,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      );
    }
    if (n == current) {
      return TextStyle(
        color: n < 0 ? NColors.numberLine : NColors.million,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      );
    }
    return TextStyle(
      color: n < 0
          ? NColors.numberLine.withAlpha(180)
          : NColors.inkSoft.withAlpha(180),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
  }

  void _drawText(Canvas canvas, String text, double x, double y, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  void _drawMarker(Canvas canvas, double x, double top, Color color) {
    final path = Path()
      ..moveTo(x, top + 12) // tip pointing down toward the axis
      ..lineTo(x - 9, top)
      ..lineTo(x + 9, top)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(NumberLinePainter old) =>
      old.viewOffset != viewOffset ||
      old.current != current ||
      old.pixelsPerUnit != pixelsPerUnit;
}
