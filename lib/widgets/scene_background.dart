import 'package:flutter/material.dart';

/// A calm, full-screen numberblock scene painted behind a room's content.
/// Each room gets a different blocky world — meadow, village, city, park, or
/// forest — picked deterministically from the room's accent colour, then
/// tinted by it. A translucent white veil keeps it soft so it never competes
/// with the foreground activity (readability first).
class SceneBackground extends StatelessWidget {
  final Color color;
  final Widget child;
  const SceneBackground({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _ScenePainter(color))),
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
  static const _pine = Color(0xFF7FC48A);
  static const _trunk = Color(0xFFB58C63);
  static const _sun = Color(0xFFFFEAA0);
  static const _wall = Color(0xFFFFE2B8);
  static const _wall2 = Color(0xFFFFD0C2);
  static const _roof = Color(0xFFFFA88E);
  static const _pond = Color(0xFF9BD4EB);
  static const _pondEdge = Color(0xFF78BEDC);
  static const _building1 = Color(0xFFBFD3E6);
  static const _building2 = Color(0xFFCFC2E6);
  static const _building3 = Color(0xFFE6C8D6);
  static const _window = Color(0xFFFFF1B8);

  Color _mix(Color base, double t) => Color.lerp(base, tint, t)!;

  void _rsq(Canvas c, double x, double y, double u, Color col, [double rf = 0.22]) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, u, u), Radius.circular(u * rf)),
      Paint()..color = col,
    );
  }

  // ── trees ──────────────────────────────────────────────────────────────
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

  void _roundTree(Canvas c, double cx, double base, double u) {
    final tw = u * 0.42;
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - tw / 2, base - u * 1.0, tw, u * 1.0),
          Radius.circular(tw * 0.3)),
      Paint()..color = _trunk,
    );
    final p = Paint()..color = _foliage;
    final cy = base - u * 1.6;
    c.drawCircle(Offset(cx, cy), u * 0.95, p);
    c.drawCircle(Offset(cx - u * 0.6, cy + u * 0.3), u * 0.6, Paint()..color = _foliage2);
    c.drawCircle(Offset(cx + u * 0.6, cy + u * 0.3), u * 0.6, Paint()..color = _foliage2);
  }

  void _pineTree(Canvas c, double cx, double base, double u) {
    final tw = u * 0.34;
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - tw / 2, base - u * 0.5, tw, u * 0.5),
          Radius.circular(tw * 0.3)),
      Paint()..color = _trunk,
    );
    final p = Paint()..color = _pine;
    for (int i = 0; i < 3; i++) {
      final ty = base - u * 0.5 - i * u * 0.7;
      final spread = u * (1.1 - i * 0.28);
      c.drawPath(
        Path()
          ..moveTo(cx - spread, ty)
          ..lineTo(cx, ty - u * 1.0)
          ..lineTo(cx + spread, ty)
          ..close(),
        p,
      );
    }
  }

  void _bush(Canvas c, double cx, double base, double u) {
    _rsq(c, cx - u * 0.95, base - u, u, _foliage, 0.45);
    _rsq(c, cx - u * 0.05, base - u, u, _foliage, 0.45);
    _rsq(c, cx - u * 0.5, base - u * 1.4, u, _foliage2, 0.45);
  }

  void _flower(Canvas c, double cx, double base, double u, Color petal) {
    c.drawRect(Rect.fromLTWH(cx - u * 0.05, base - u, u * 0.1, u), Paint()..color = _foliage2);
    final p = Paint()..color = petal;
    final cy = base - u;
    for (final o in [Offset(0, -u * 0.34), Offset(0, u * 0.34), Offset(-u * 0.34, 0), Offset(u * 0.34, 0)]) {
      c.drawCircle(Offset(cx + o.dx, cy + o.dy), u * 0.22, p);
    }
    c.drawCircle(Offset(cx, cy), u * 0.18, Paint()..color = _sun);
  }

  // ── buildings ──────────────────────────────────────────────────────────
  void _house(Canvas c, double cx, double base, double u, Color wall) {
    final wallTop = base - u;
    _rsq(c, cx - u / 2, wallTop, u, wall, 0.12);
    c.drawPath(
      Path()
        ..moveTo(cx - u * 0.62, wallTop + 4)
        ..lineTo(cx, wallTop - u * 0.5)
        ..lineTo(cx + u * 0.62, wallTop + 4)
        ..close(),
      Paint()..color = _roof,
    );
    // door
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - u * 0.13, base - u * 0.5, u * 0.26, u * 0.5),
          Radius.circular(u * 0.05)),
      Paint()..color = _trunk,
    );
    // window
    _rsq(c, cx + u * 0.16, wallTop + u * 0.16, u * 0.22, _window, 0.2);
  }

  void _skyline(Canvas c, double horizon, double w) {
    // a soft row of blocky buildings behind the grass line
    final cols = [_building1, _building2, _building3];
    double x = w * 0.04;
    int i = 0;
    while (x < w * 0.96) {
      final bw = w * (0.07 + (i % 3) * 0.018);
      final bh = horizon * (0.18 + ((i * 37) % 5) * 0.05);
      final top = horizon - bh;
      _rsq(c, x, top, bw, cols[i % 3].withAlpha(220), 0.06);
      // windows grid
      final wp = Paint()..color = _window.withAlpha(160);
      for (double wy = top + bw * 0.25; wy < horizon - bw * 0.2; wy += bw * 0.42) {
        for (double wx = x + bw * 0.2; wx < x + bw - bw * 0.2; wx += bw * 0.38) {
          c.drawRect(Rect.fromLTWH(wx, wy, bw * 0.16, bw * 0.22), wp);
        }
      }
      x += bw + w * 0.012;
      i++;
    }
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

  // ── critters ───────────────────────────────────────────────────────────
  void _duck(Canvas c, double cx, double base, double u) {
    _rsq(c, cx - u / 2, base - u, u, const Color(0xFFFFD54F), 0.3);
    c.drawPath(
      Path()
        ..moveTo(cx + u * 0.5, base - u * 0.55)
        ..lineTo(cx + u * 0.95, base - u * 0.4)
        ..lineTo(cx + u * 0.5, base - u * 0.25)
        ..close(),
      Paint()..color = const Color(0xFFFF9800),
    );
    c.drawCircle(Offset(cx + u * 0.15, base - u * 0.68), u * 0.08, Paint()..color = const Color(0xFF14213D));
  }

  void _cat(Canvas c, double cx, double base, double u) {
    final col = const Color(0xFFB388FF);
    final top = base - u;
    c.drawPath(Path()..moveTo(cx - u * 0.42, top)..lineTo(cx - u * 0.18, top - u * 0.35)..lineTo(cx - u * 0.02, top)..close(), Paint()..color = col);
    c.drawPath(Path()..moveTo(cx + u * 0.02, top)..lineTo(cx + u * 0.18, top - u * 0.35)..lineTo(cx + u * 0.42, top)..close(), Paint()..color = col);
    _rsq(c, cx - u / 2, top, u, col, 0.28);
    final eye = Paint()..color = const Color(0xFF14213D);
    c.drawCircle(Offset(cx - u * 0.18, top + u * 0.38), u * 0.07, eye);
    c.drawCircle(Offset(cx + u * 0.18, top + u * 0.38), u * 0.07, eye);
  }

  void _bird(Canvas c, double cx, double cy, double u, Color col) {
    _rsq(c, cx - u / 2, cy - u / 2, u, col, 0.32);
    c.drawPath(
      Path()
        ..moveTo(cx + u * 0.5, cy - u * 0.05)
        ..lineTo(cx + u * 0.85, cy + u * 0.02)
        ..lineTo(cx + u * 0.5, cy + u * 0.12)
        ..close(),
      Paint()..color = const Color(0xFFFF9800),
    );
    c.drawCircle(Offset(cx + u * 0.12, cy - u * 0.12), u * 0.07, Paint()..color = const Color(0xFF14213D));
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
    canvas.drawOval(Rect.fromLTWH(-w * 0.2, horizon - 60, w * 0.7, 220), hill);
    canvas.drawOval(Rect.fromLTWH(w * 0.45, horizon - 44, w * 0.8, 240), hill);

    // sun + clouds (shared)
    canvas.drawCircle(Offset(w - 70, 84), 48, Paint()..color = _sun);
    _cloud(canvas, w * 0.22, 92, 0.85);
    _cloud(canvas, w * 0.62, 60, 0.6);

    // pick one of five worlds from the room's accent colour
    final variant = tint.hashCode.abs() % 5;
    final u = (w * 0.05).clamp(28.0, 48.0);
    final g = horizon + 32; // ground line for objects

    switch (variant) {
      case 0: // meadow — round trees, flowers, a bird
        _roundTree(canvas, w * 0.09, g, u * 1.1);
        _roundTree(canvas, w * 0.92, g, u);
        _flower(canvas, w * 0.3, g + u * 0.4, u * 0.5, _roof);
        _flower(canvas, w * 0.7, g + u * 0.4, u * 0.5, _building2);
        _bird(canvas, w * 0.5, 130, u * 0.4, _building1);
        break;
      case 1: // village — houses + a tree
        _house(canvas, w * 0.12, g, u * 1.3, _wall);
        _house(canvas, w * 0.88, g, u * 1.15, _wall2);
        _tree(canvas, w * 0.5, g, u * 0.8);
        _flower(canvas, w * 0.34, g + u * 0.3, u * 0.45, _building3);
        break;
      case 2: // city — skyline + a couple of trees
        _skyline(canvas, horizon + 6, w);
        _roundTree(canvas, w * 0.06, g, u * 0.9);
        _roundTree(canvas, w * 0.94, g, u * 0.9);
        _bird(canvas, w * 0.42, 120, u * 0.36, _building2);
        _bird(canvas, w * 0.58, 150, u * 0.32, _building2);
        break;
      case 3: // park & pond — pond, duck, bush, tree
        canvas.drawOval(Rect.fromLTWH(w * 0.62 - 6, g - u * 0.6 - 6, w * 0.34 + 12, u * 1.2 + 12), Paint()..color = _pondEdge);
        canvas.drawOval(Rect.fromLTWH(w * 0.62, g - u * 0.6, w * 0.34, u * 1.2), Paint()..color = _pond);
        _duck(canvas, w * 0.74, g, u * 0.55);
        _tree(canvas, w * 0.1, g, u);
        _bush(canvas, w * 0.4, g, u * 0.5);
        break;
      default: // forest — pines + bush + cat
        _pineTree(canvas, w * 0.08, g, u * 1.2);
        _pineTree(canvas, w * 0.2, g, u * 0.9);
        _pineTree(canvas, w * 0.9, g, u * 1.1);
        _bush(canvas, w * 0.7, g, u * 0.55);
        _cat(canvas, w * 0.5, g, u * 0.6);
    }

    // white veil → push the whole scene back so content stays readable
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white.withAlpha(110));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.tint != tint;
}
