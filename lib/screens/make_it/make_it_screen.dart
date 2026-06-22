import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import '../../widgets/scene_background.dart';

/// Make It — build a number. A target is shown ("Make the 7!"); the child taps
/// + to stack unit blocks (and − to take them away) until the tower matches.
/// When it does, the block does a happy bounce, a chime plays, and a new target
/// appears. No timer, no score, no fail — overshooting is fine, just adjust.
class MakeItScreen extends StatefulWidget {
  const MakeItScreen({super.key});

  @override
  State<MakeItScreen> createState() => _MakeItScreenState();
}

class _MakeItScreenState extends State<MakeItScreen>
    with SingleTickerProviderStateMixin {
  static const int _max = 20;
  final _rng = math.Random();
  int _target = 5;
  int _current = 0;
  bool _won = false;
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _target = 2 + _rng.nextInt(9); // 2..10
    _pop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_won || _current >= _max) return;
    setState(() => _current++);
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
    _check();
  }

  Future<void> _remove() async {
    if (_won || _current <= 0) return;
    setState(() => _current--);
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
  }

  Future<void> _clear() async {
    if (_won || _current == 0) return;
    setState(() => _current = 0);
    await HapticsService.instance.medium();
    await AudioService.instance.playPop();
  }

  Future<void> _check() async {
    if (_current != _target) return;
    setState(() => _won = true);
    _pop.forward(from: 0);
    await HapticsService.instance.medium();
    await AudioService.instance.playChime();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      int next;
      do {
        next = 2 + _rng.nextInt(9);
      } while (next == _target);
      _target = next;
      _current = 0;
      _won = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final matched = _won;
    final colour = NColors.numBlockColor(_current == 0 ? _target : _current);
    return Scaffold(
      appBar: const RoomHeader(
        title: 'Make It',
        color: NColors.makeIt,
        assetImage: 'assets/cards/makeit.png',
      ),
      body: SceneBackground(
        color: NColors.makeIt,
        child: SafeArea(
          child: Column(
            children: [
              _TargetBanner(target: _target, current: _current, won: _won),
              // ── The tower the child is building ──────────────────────
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Gap.lg, vertical: Gap.sm),
                      child: AnimatedBuilder(
                        animation: _pop,
                        builder: (context, child) {
                          // a springy wobble when the target is matched
                          final s = matched
                              ? 1 + 0.12 * math.sin(_pop.value * math.pi * 3)
                              : 1.0;
                          return Transform.scale(scale: s, child: child);
                        },
                        child: NumBlockView(value: _current),
                      ),
                    ),
                    if (matched)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('🎉',
                            style: TextStyle(fontSize: 64)),
                      ),
                  ],
                ),
              ),
              // ── Controls: − , clear , + ──────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.lg, top: Gap.xs),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Gap.md,
                  runSpacing: Gap.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SoftButton(
                      color: colour,
                      onTap: (_won || _current <= 0) ? null : _remove,
                      width: 76,
                      height: 76,
                      radius: Radii.lg,
                      child: const Icon(Icons.remove, size: 38),
                    ),
                    SoftButton(
                      color: NColors.inkSoft,
                      onTap: (_won || _current == 0) ? null : _clear,
                      width: 60,
                      height: 60,
                      radius: Radii.md,
                      child: const Icon(Icons.refresh_rounded, size: 26),
                    ),
                    SoftButton(
                      color: colour,
                      onTap: (_won || _current >= _max) ? null : _add,
                      width: 76,
                      height: 76,
                      radius: Radii.lg,
                      child: const Icon(Icons.add, size: 38),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TargetBanner extends StatelessWidget {
  final int target;
  final int current;
  final bool won;
  const _TargetBanner(
      {required this.target, required this.current, required this.won});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, Gap.xs),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            Text(won ? 'You made ' : 'Make the ',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: NColors.ink)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: NumBlock(key: ValueKey(target), value: target, unit: 18),
            ),
            Text(won ? ' !' : '  —  you have $current',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: NColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
