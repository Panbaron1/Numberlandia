import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import '../../widgets/scene_background.dart';

/// Pop! — a calm number-recognition popper. A target numberblock is shown
/// ("Pop the 4!"); a field of bobbing numberblock characters drifts around.
/// Tap any to make it burst into confetti and vanish; the field refills.
/// Popping the target plays a chime and picks a new target. No timer, no
/// score, no fail — pure sandbox.
class PopScreen extends StatefulWidget {
  const PopScreen({super.key});

  @override
  State<PopScreen> createState() => _PopScreenState();
}

class _Bubble {
  final int id;
  final int value;
  final double fx; // 0..1 horizontal centre
  final double fy; // 0..1 vertical centre
  final double phase; // bob offset
  _Bubble(this.id, this.value, this.fx, this.fy, this.phase);
}

class _Boom {
  final int id;
  final Alignment at;
  final Color color;
  _Boom(this.id, this.at, this.color);
}

class _PopScreenState extends State<PopScreen> {
  static const int _count = 7; // blocks on screen
  final _rng = math.Random();
  final List<_Bubble> _bubbles = [];
  final List<_Boom> _booms = [];
  int _seq = 0;
  int _target = 3;
  int _popped = 0;

  @override
  void initState() {
    super.initState();
    _target = 1 + _rng.nextInt(9);
    for (int i = 0; i < _count; i++) {
      _bubbles.add(_spawn(ensure: i == 0 ? _target : null));
    }
  }

  _Bubble _spawn({int? ensure}) {
    final value = ensure ?? _rng.nextInt(11); // 0..10
    final fx = 0.10 + _rng.nextDouble() * 0.80;
    final fy = 0.14 + _rng.nextDouble() * 0.74;
    return _Bubble(_seq++, value, fx, fy, _rng.nextDouble() * math.pi * 2);
  }

  bool get _targetOnField => _bubbles.any((b) => b.value == _target);

  Future<void> _pop(_Bubble b) async {
    setState(() {
      _bubbles.remove(b);
      _booms.add(_Boom(b.id, Alignment(b.fx * 2 - 1, b.fy * 2 - 1),
          NColors.numBlockColor(b.value)));
      _popped++;
    });

    if (b.value == _target) {
      await HapticsService.instance.medium();
      await AudioService.instance.playChime();
      // pick a fresh target and make sure one exists on the field
      setState(() => _target = 1 + _rng.nextInt(9));
    } else {
      await HapticsService.instance.light();
      await AudioService.instance.playPop();
    }

    // refill after a short beat so the field stays lively
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() {
      final needTarget = !_targetOnField && _bubbles.length >= _count - 1;
      _bubbles.add(_spawn(ensure: needTarget ? _target : null));
    });
  }

  void _removeBoom(int id) {
    if (!mounted) return;
    setState(() => _booms.removeWhere((x) => x.id == id));
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
                    // Block size scales with the field; smaller when cramped.
                    final unit =
                        (math.min(c.maxWidth, c.maxHeight) / 11).clamp(16.0, 30.0);
                    return Stack(
                      children: [
                        for (final b in _bubbles)
                          _BubbleView(
                            key: ValueKey(b.id),
                            bubble: b,
                            unit: unit.toDouble(),
                            onTap: () => _pop(b),
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
          // Gentle popped tally — celebratory, not a score to beat.
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

// ── a single bobbing, tappable numberblock ───────────────────────────────────

class _BubbleView extends StatefulWidget {
  final _Bubble bubble;
  final double unit;
  final VoidCallback onTap;
  const _BubbleView(
      {super.key, required this.bubble, required this.unit, required this.onTap});

  @override
  State<_BubbleView> createState() => _BubbleViewState();
}

class _BubbleViewState extends State<_BubbleView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bubble;
    return Align(
      alignment: Alignment(b.fx * 2 - 1, b.fy * 2 - 1),
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) {
          final t = _bob.value * math.pi * 2 + b.phase;
          return Transform.translate(
            offset: Offset(math.sin(t) * 6, math.cos(t) * 5),
            child: child,
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          // BouncyNumBlock springs in on appear for a lively "pop in".
          child: BouncyNumBlock(
              value: b.value, unit: widget.unit, showSign: false),
        ),
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

    // a quick flash ring at the start
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
      final dy = center.dy + math.sin(p.angle) * dist + t * t * 26; // gravity
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
