import 'package:flutter/material.dart';
import '../../theme.dart';

/// Virtualized number line painter.
///
/// Only ticks that fall within the visible viewport are drawn —
/// never iterates the full -1,000,000 to +1,000,000 range.
/// At pixelsPerUnit=80, a 1200px-wide tablet shows ~15 ticks at most.
class NumberLinePainter extends CustomPainter {
  final double viewOffset;   // center of viewport in number-space
  final int current;
  final double pixelsPerUnit; // px per integer step

  static const double _tickHeightMajor = 28.0;  // multiples of 10
  static const double _tickHeightMinor = 16.0;  // other integers
  static const double _tickHeightZero  = 40.0;  // zero
  static const double _lineY = 0.6;             // fraction of height for the axis

  const NumberLinePainter({
    required this.viewOffset,
    required this.current,
    required this.pixelsPerUnit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * _lineY;

    // Draw horizontal axis line
    final linePaint = Paint()
      ..color = NColors.inkSoft.withAlpha(80)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), linePaint);

    // Compute visible integer range (add 2 on each side for safety)
    final halfVisible = (size.width / 2) / pixelsPerUnit;
    final firstVisible = (viewOffset - halfVisible - 2).floor()
        .clamp(-1000000, 1000000);
    final lastVisible = (viewOffset + halfVisible + 2).ceil()
        .clamp(-1000000, 1000000);

    final tickPaint = Paint()..strokeWidth = 2;
    final labelStyle = TextStyle(
      color: NColors.inkSoft,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
    final currentLabelStyle = TextStyle(
      color: NColors.primary,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );
    final zeroLabelStyle = TextStyle(
      color: NColors.zero,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );

    // Draw only the visible ticks
    for (int n = firstVisible; n <= lastVisible; n++) {
      final x = size.width / 2 + (n - viewOffset) * pixelsPerUnit;

      double tickH;
      Color tickColor;

      if (n == 0) {
        tickH = _tickHeightZero;
        tickColor = NColors.zero;
      } else if (n == current) {
        tickH = _tickHeightMajor;
        tickColor = NColors.primary;
      } else if (n % 10 == 0) {
        tickH = _tickHeightMajor;
        tickColor = NColors.inkSoft.withAlpha(160);
      } else {
        tickH = _tickHeightMinor;
        tickColor = NColors.inkSoft.withAlpha(100);
      }

      tickPaint.color = tickColor;
      canvas.drawLine(
        Offset(x, cy - tickH / 2),
        Offset(x, cy + tickH / 2),
        tickPaint,
      );

      // Labels: show zero, multiples of 5 (when zoomed), and current
      final showLabel = n == 0 ||
          n == current ||
          (n % 10 == 0) ||
          (pixelsPerUnit >= 100 && n % 5 == 0);

      if (showLabel) {
        final style = n == 0
            ? zeroLabelStyle
            : (n == current ? currentLabelStyle : labelStyle);

        _drawLabel(canvas, n.toString(), x, cy + tickH / 2 + 6, style);
      }
    }

    // Draw current-number marker (triangle pointer above the axis)
    final markerX =
        size.width / 2 + (current - viewOffset) * pixelsPerUnit;
    _drawMarker(canvas, markerX, cy - _tickHeightMajor / 2 - 4);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y,
      TextStyle style) {
    final span = TextSpan(text: text, style: style);
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  void _drawMarker(Canvas canvas, double x, double top) {
    final paint = Paint()..color = NColors.primary;
    final path = Path()
      ..moveTo(x, top + 10)   // bottom point (pointing down at the tick)
      ..lineTo(x - 8, top)
      ..lineTo(x + 8, top)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NumberLinePainter old) =>
      old.viewOffset != viewOffset ||
      old.current != current ||
      old.pixelsPerUnit != pixelsPerUnit;
}
