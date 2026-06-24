import 'dart:math' as math;
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';

/// A soft, slightly grainy spectrum gradient painted behind a room's content.
/// Each room blends the shared spectrum (blue → teal → lavender → pink) toward
/// its own accent colour, softened with white and dusted with fine grain so it
/// reads as a calm, tactile backdrop — never competing with the foreground.
class SceneBackground extends StatelessWidget {
  final Color color;
  final Widget child;
  const SceneBackground({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _GradientGrainPainter(color))),
        child,
      ],
    );
  }
}

class _GradientGrainPainter extends CustomPainter {
  final Color tint;
  _GradientGrainPainter(this.tint);

  // shared soft spectrum (matches the wordmark / brand)
  static const _spectrum = <Color>[
    Color(0xFF4F8EF7), // blue
    Color(0xFF2DC9A0), // teal
    Color(0xFFA78BFA), // lavender
    Color(0xFFFF6B9D), // pink
  ];

  /// Soften a stop: lift well toward white (light backdrop), then a faint
  /// nudge toward the room accent.
  Color _soft(Color c) =>
      Color.lerp(Color.lerp(c, Colors.white, 0.78)!, tint, 0.11)!;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft diagonal spectrum gradient.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [for (final c in _spectrum) _soft(c)],
        ).createShader(rect),
    );

    // A gentle radial lift in the upper area for depth.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.7),
          radius: 1.2,
          colors: [Colors.white.withAlpha(46), Colors.white.withAlpha(0)],
        ).createShader(rect),
    );

    _grain(canvas, size);
  }

  /// Fine film grain — deterministic per tint so it stays stable across
  /// repaints. Two passes (light specks + dark specks) at very low alpha.
  void _grain(Canvas canvas, Size size) {
    final rng = math.Random(tint.hashCode);
    final n = ((size.width * size.height) / 90).clamp(1500, 9000).toInt();
    final light = <Offset>[];
    final dark = <Offset>[];
    for (int i = 0; i < n; i++) {
      final o = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      (rng.nextBool() ? light : dark).add(o);
    }
    canvas.drawPoints(PointMode.points, light,
        Paint()
          ..color = Colors.white.withAlpha(20)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round);
    canvas.drawPoints(PointMode.points, dark,
        Paint()
          ..color = const Color(0xFF1A1F36).withAlpha(9)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_GradientGrainPainter old) => old.tint != tint;
}
