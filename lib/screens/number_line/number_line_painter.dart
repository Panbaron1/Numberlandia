import 'package:flutter/material.dart';
import '../../theme.dart';

/// A thick, colourful number-line slider.
///
/// Virtualized: only ticks in the visible viewport are drawn — never the full
/// 2M range. The track is a fat rounded bar, teal on the negative side and blue
/// on the positive side, split at a gold zero. A large round thumb sits on the
/// current number.
class NumberLinePainter extends CustomPainter {
  final double viewOffset;    // number-space position of viewport centre
  final int current;
  final double pixelsPerUnit;

  static const double _trackH = 22.0; // thick track
  static const double _tickMajor = 22.0;
  static const double _tickMinor = 12.0;

  const NumberLinePainter({
    required this.viewOffset,
    required this.current,
    required this.pixelsPerUnit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.5;
    final zeroX = size.width / 2 - viewOffset * pixelsPerUnit;

    // ── Ticks above the track (drawn first, behind) ───────────────────────
    final half = (size.width / 2) / pixelsPerUnit;
    final first = (viewOffset - half - 2).floor().clamp(-1000000, 1000000);
    final last = (viewOffset + half + 2).ceil().clamp(-1000000, 1000000);
    final tickPaint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int n = first; n <= last; n++) {
      if (n % 5 != 0 && pixelsPerUnit < 70) continue; // thin out when zoomed out
      final x = size.width / 2 + (n - viewOffset) * pixelsPerUnit;
      final major = n % 10 == 0;
      final h = n == 0 ? _tickMajor + 8 : (major ? _tickMajor : _tickMinor);
      tickPaint.color = n == 0
          ? NColors.zero
          : (n < 0
              ? NColors.numberLine.withAlpha(major ? 200 : 110)
              : NColors.million.withAlpha(major ? 200 : 110));
      canvas.drawLine(
        Offset(x, cy - _trackH / 2 - 6 - h),
        Offset(x, cy - _trackH / 2 - 6),
        tickPaint,
      );
      if (n == 0 || major) {
        _label(canvas, '$n', x, cy - _trackH / 2 - 10 - h, n);
      }
    }

    // ── The thick track ───────────────────────────────────────────────────
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cy - _trackH / 2, size.width, _trackH),
      const Radius.circular(_trackH / 2),
    );
    canvas.save();
    canvas.clipRRect(trackRect);
    // Negative half (teal) and positive half (blue), split at zero.
    final clampedZero = zeroX.clamp(0.0, size.width);
    canvas.drawRect(
      Rect.fromLTRB(0, cy - _trackH / 2, clampedZero, cy + _trackH / 2),
      Paint()..shader = const LinearGradient(
              colors: [Color(0xFF1FB89A), NColors.numberLine])
          .createShader(Rect.fromLTWH(0, cy - _trackH / 2, size.width, _trackH)),
    );
    canvas.drawRect(
      Rect.fromLTRB(clampedZero, cy - _trackH / 2, size.width, cy + _trackH / 2),
      Paint()..shader = const LinearGradient(
              colors: [NColors.million, Color(0xFF7FB2FF)])
          .createShader(Rect.fromLTWH(0, cy - _trackH / 2, size.width, _trackH)),
    );
    canvas.restore();

    // Zero gold band on the track
    if (zeroX >= -8 && zeroX <= size.width + 8) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(zeroX, cy), width: 10, height: _trackH),
          const Radius.circular(5),
        ),
        Paint()..color = NColors.zero,
      );
    }

    // ── Thumb on the current number ───────────────────────────────────────
    final curX = size.width / 2 + (current - viewOffset) * pixelsPerUnit;
    final thumbColor = current == 0
        ? NColors.zero
        : (current < 0 ? NColors.numberLine : NColors.million);
    // White halo + coloured core
    canvas.drawCircle(Offset(curX, cy), 20, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(curX, cy),
        20,
        Paint()
          ..color = thumbColor.withAlpha(60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(Offset(curX, cy), 14, Paint()..color = thumbColor);
    canvas.drawCircle(Offset(curX, cy), 5, Paint()..color = Colors.white);
  }

  void _label(Canvas canvas, String text, double x, double bottomY, int n) {
    final style = TextStyle(
      color: n == 0
          ? NColors.zero
          : (n < 0 ? NColors.numberLine : NColors.inkSoft),
      fontSize: 12,
      fontWeight: n == 0 ? FontWeight.w800 : FontWeight.w600,
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, bottomY - tp.height));
  }

  @override
  bool shouldRepaint(NumberLinePainter old) =>
      old.viewOffset != viewOffset ||
      old.current != current ||
      old.pixelsPerUnit != pixelsPerUnit;
}
