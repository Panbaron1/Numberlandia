import 'package:flutter/material.dart';

/// A calm, full-screen numberblock scene painted behind a room's content:
/// pale sky → grassy hills with little numberblock trees, soft clouds and a
/// low sun. Tinted subtly by the room's accent colour and laid under a white
/// veil so it never competes with the foreground activity (readability first).
class SceneBackground extends StatelessWidget {
  final Color color;
  final Widget child;
  const SceneBackground({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _ScenePainter(color)),
        ),
        child,
      ],
    );
  }
}

class _ScenePainter extends CustomPainter {
  final Color tint;
  _ScenePainter(this.tint);

  // base palette (matches the card art)
  static const _skyTop = Color(0xFFCDE9FF);
  static const _skyBot = Color(0xFFE9F7FF);
  static const _grassTop = Color(0xFFB7E4A8);
  static const _grassBot = Color(0xFF97D18C);
  static const _foliage = Color(0xFF8ACD96);
  static const _foliage2 = Color(0xFF6EBC8A);
  static const _trunk = Color(0xFFB58C63);
  static const _sun = Color(0xFFFFEAA0);

  Color _mix(Color base, double t) => Color.lerp(base, tint, t)!;

  void _rsq(Canvas c, double x, double y, double u, Color col) {
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, u, u), Radius.circular(u * 0.22)),
      Paint()..color = col,
    );
  }

  void _tree(Canvas c, double cx, double base, double u) {
    final tw = u * 0.5;
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - tw / 2, base - u * 1.1, tw, u * 1.1),
          Radius.circular(tw * 0.3)),
      Paint()..color = _trunk,
    );
    final cy = base - u * 1.1;
    _rsq(c, cx - u / 2, cy - u, u, _foliage2);
    _rsq(c, cx - u * 1.05, cy - u * 1.9, u, _foliage);
    _rsq(c, cx + u * 0.05, cy - u * 1.9, u, _foliage);
    _rsq(c, cx - u / 2, cy - u * 2.7, u, _foliage);
  }

  void _cloud(Canvas c, double cx, double cy, double s) {
    final p = Paint()..color = Colors.white;
    for (final o in [
      Offset(-34 * s, 4 * s),
      Offset(0, -17 * s),
      Offset(34 * s, 4 * s),
      Offset(0, 8 * s),
    ]) {
      c.drawCircle(Offset(cx + o.dx, cy + o.dy), (o.dy == -17 * s ? 42 : 34) * s, p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.74;

    // sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_mix(_skyTop, 0.10), _mix(_skyBot, 0.06)],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon)),
    );
    // grass
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, w, h - horizon),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_mix(_grassTop, 0.14), _mix(_grassBot, 0.18)],
        ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon)),
    );
    // rolling hills
    final hill = Paint()..color = _mix(const Color(0xFFA8DE9C), 0.12);
    canvas.drawOval(
        Rect.fromLTWH(-w * 0.2, horizon - 60, w * 0.7, 220), hill);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.45, horizon - 44, w * 0.8, 240), hill);

    // sun (top-right, pale)
    canvas.drawCircle(Offset(w - 70, 84), 48, Paint()..color = _sun);

    // clouds
    _cloud(canvas, w * 0.22, 92, 0.85);
    _cloud(canvas, w * 0.62, 60, 0.6);

    // a couple of little trees along the horizon, at the edges
    final u = (w * 0.05).clamp(26.0, 46.0);
    _tree(canvas, w * 0.08, horizon + 30, u);
    _tree(canvas, w * 0.93, horizon + 34, u * 1.1);

    // white veil → push the whole scene back so content stays readable
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white.withAlpha(120));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.tint != tint;
}
