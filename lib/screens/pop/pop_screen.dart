import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import '../../widgets/scene_background.dart';

/// Pop! — a number-recognition popper. A target numberblock is shown
/// ("Pop the 4!"). A field of numberblock characters DRIFTS around the screen;
/// only the ones matching the target pop (burst into confetti + vanish). Tap a
/// wrong one and it shakes with a little ✗ — no pop, no penalty. The blocks
/// speed up the more you pop. No timer, no score to lose — calm but tricky.
class PopScreen extends StatefulWidget {
  const PopScreen({super.key});

  @override
  State<PopScreen> createState() => _PopScreenState();
}

class _Bubble {
  final int id;
  int value;
  double fx, fy; // 0..1 centre
  double vx, vy; // fractional velocity / sec
  _Bubble(this.id, this.value, this.fx, this.fy, this.vx, this.vy);
}

class _Boom {
  final int id;
  final Alignment at;
  final Color color;
  _Boom(this.id, this.at, this.color);
}

class _Nope {
  final int id;
  final Alignment at;
  _Nope(this.id, this.at);
}

class _PopScreenState extends State<PopScreen>
    with SingleTickerProviderStateMixin {
  static const int _count = 8; // blocks on screen
  static const double _mx = 0.09, _my = 0.10; // margins so blocks stay on-screen
  final _rng = math.Random();
  final List<_Bubble> _bubbles = [];
  final List<_Boom> _booms = [];
  final List<_Nope> _nopes = [];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int _seq = 0;
  int _target = 3;
  int _popped = 0;

  double get _speed => (0.075 + _popped * 0.006).clamp(0.075, 0.24);

  @override
  void initState() {
    super.initState();
    _target = 1 + _rng.nextInt(9);
    for (int i = 0; i < _count; i++) {
      _bubbles.add(_spawn());
    }
    _ensureTargets();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  _Bubble _spawn({int? value}) {
    final v = value ?? _rng.nextInt(11); // 0..10
    final fx = _mx + _rng.nextDouble() * (1 - 2 * _mx);
    final fy = _my + _rng.nextDouble() * (1 - 2 * _my);
    final a = _rng.nextDouble() * math.pi * 2;
    return _Bubble(_seq++, v, fx, fy, math.cos(a) * _speed, math.sin(a) * _speed);
  }

  /// Guarantee at least two target blocks are on the field to find.
  void _ensureTargets() {
    int have = _bubbles.where((b) => b.value == _target).length;
    final pool = List<_Bubble>.from(_bubbles)..shuffle(_rng);
    for (final b in pool) {
      if (have >= 2) break;
      if (b.value != _target) {
        b.value = _target;
        have++;
      }
    }
  }

  void _tick(Duration elapsed) {
    final dt = (_last == Duration.zero)
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    for (final b in _bubbles) {
      b.fx += b.vx * dt;
      b.fy += b.vy * dt;
      if (b.fx < _mx) {
        b.fx = _mx;
        b.vx = b.vx.abs();
      } else if (b.fx > 1 - _mx) {
        b.fx = 1 - _mx;
        b.vx = -b.vx.abs();
      }
      if (b.fy < _my) {
        b.fy = _my;
        b.vy = b.vy.abs();
      } else if (b.fy > 1 - _my) {
        b.fy = 1 - _my;
        b.vy = -b.vy.abs();
      }
    }
    setState(() {});
  }

  Future<void> _tap(_Bubble b) async {
    final at = Alignment(b.fx * 2 - 1, b.fy * 2 - 1);
    if (b.value != _target) {
      // wrong block — a little shake + ✗, no pop
      await HapticsService.instance.light();
      setState(() => _nopes.add(_Nope(b.id, at)));
      return;
    }

    // correct — burst it and refill, then speed everything up a touch
    setState(() {
      _bubbles.remove(b);
      _booms.add(_Boom(b.id, at, NColors.numBlockColor(b.value)));
      _popped++;
      _bubbles.add(_spawn());
    });
    await HapticsService.instance.medium();
    await AudioService.instance.playPop();

    final remaining = _bubbles.where((x) => x.value == _target).length;
    if (remaining == 0) {
      // cleared them all — celebrate and pick a new target
      await AudioService.instance.playChime();
      setState(() => _target = 1 + _rng.nextInt(9));
    }
    setState(() {
      _ensureTargets();
      _retune();
    });
  }

  /// Bring every block up to the current (ramped) speed.
  void _retune() {
    for (final b in _bubbles) {
      final mag = math.sqrt(b.vx * b.vx + b.vy * b.vy);
      if (mag == 0) continue;
      b.vx = b.vx / mag * _speed;
      b.vy = b.vy / mag * _speed;
    }
  }

  void _removeBoom(int id) {
    if (!mounted) return;
    setState(() => _booms.removeWhere((x) => x.id == id));
  }

  void _removeNope(int id) {
    if (!mounted) return;
    setState(() => _nopes.removeWhere((x) => x.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RoomHeader(
        title: 'Pop!',
        color: NColors.pop,
        assetImage: 'assets/cards/pop.png',
      ),
      body: SceneBackground(
        color: NColors.pop,
        child: SafeArea(
          child: Column(
            children: [
              _TargetBanner(target: _target, popped: _popped),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final unit = (math.min(c.maxWidth, c.maxHeight) / 12)
                        .clamp(15.0, 26.0)
                        .toDouble();
                    return Stack(
                      children: [
                        for (final b in _bubbles)
                          _BubbleView(
                            key: ValueKey(b.id),
                            at: Alignment(b.fx * 2 - 1, b.fy * 2 - 1),
                            value: b.value,
                            unit: unit,
                            onTap: () => _tap(b),
                          ),
                        for (final n in _nopes)
                          Align(
                            key: ValueKey('nope${n.id}'),
                            alignment: n.at,
                            child: _Nudge(onDone: () => _removeNope(n.id)),
                          ),
                        for (final boom in _booms)
                          Align(
                            key: ValueKey('boom${boom.id}'),
                            alignment: boom.at,
                            child: _Explosion(
                              color: boom.color,
                              onDone: () => _removeBoom(boom.id),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── target banner ───────────────────────────────────────────────────────────

class _TargetBanner extends StatelessWidget {
  final int target;
  final int popped;
  const _TargetBanner({required this.target, required this.popped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.xs),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Text('Pop the ',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: NColors.ink)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: NumBlock(
                        key: ValueKey(target), value: target, unit: 17),
                  ),
                  const Text(' !',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: NColors.ink)),
                ],
              ),
            ),
          ),
          const SizedBox(width: Gap.sm),
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: NColors.pop, size: 22),
              const SizedBox(width: 4),
              Text('$popped',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: NColors.pop)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── a single drifting, tappable numberblock ─────────────────────────────────

class _BubbleView extends StatelessWidget {
  final Alignment at;
  final int value;
  final double unit;
  final VoidCallback onTap;
  const _BubbleView(
      {super.key,
      required this.at,
      required this.value,
      required this.unit,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: at,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: BouncyNumBlock(value: value, unit: unit, showSign: false),
      ),
    );
  }
}

// ── wrong-tap nudge (shake + fading ✗) ───────────────────────────────────────

class _Nudge extends StatefulWidget {
  final VoidCallback onDone;
  const _Nudge({required this.onDone});

  @override
  State<_Nudge> createState() => _NudgeState();
}

class _NudgeState extends State<_Nudge> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final shake = math.sin(t * math.pi * 6) * 8 * (1 - t);
          return Transform.translate(
            offset: Offset(shake, 0),
            child: Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Icon(Icons.close_rounded,
                  color: NColors.takeAway, size: 34),
            ),
          );
        },
      ),
    );
  }
}

// ── confetti burst ───────────────────────────────────────────────────────────

class _Explosion extends StatefulWidget {
  final Color color;
  final VoidCallback onDone;
  const _Explosion({required this.color, required this.onDone});

  @override
  State<_Explosion> createState() => _ExplosionState();
}

class _ExplosionState extends State<_Explosion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _parts;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _parts = List.generate(12, (i) {
      final a = (i / 12) * math.pi * 2 + rng.nextDouble() * 0.5;
      return _Particle(
        angle: a,
        speed: 40 + rng.nextDouble() * 46,
        size: 7 + rng.nextDouble() * 7,
        spin: (rng.nextDouble() - 0.5) * 6,
      );
    });
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 170,
        height: 170,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _BoomPainter(_c.value, _parts, widget.color),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle, speed, size, spin;
  _Particle(
      {required this.angle,
      required this.speed,
      required this.size,
      required this.spin});
}

class _BoomPainter extends CustomPainter {
  final double t; // 0..1
  final List<_Particle> parts;
  final Color color;
  _BoomPainter(this.t, this.parts, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fade = (1.0 - t).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withAlpha((fade * 255).round());

    if (t < 0.4) {
      final r = 10 + t * 60;
      canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6 * (1 - t / 0.4)
            ..color = color.withAlpha((fade * 160).round()));
    }

    final ease = Curves.easeOut.transform(t);
    for (final p in parts) {
      final dist = p.speed * ease * 1.6;
      final dx = center.dx + math.cos(p.angle) * dist;
      final dy = center.dy + math.sin(p.angle) * dist + t * t * 26;
      final s = p.size * (1 - 0.35 * t);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s, height: s),
            Radius.circular(s * 0.25)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BoomPainter old) => old.t != t;
}
