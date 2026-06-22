import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import '../../widgets/scene_background.dart';

/// Make It — build a number from pieces. A target is shown ("Make the 13!");
/// the child taps number pieces (+1, +2, +5, +10) to stack blocks, composing
/// the exact target (− removes one, ↺ clears). When the tower matches it does a
/// happy bounce, a chime plays, and a new target appears. Overshooting is fine
/// — just take some away. No timer, no score, no fail.
class MakeItScreen extends StatefulWidget {
  const MakeItScreen({super.key});

  @override
  State<MakeItScreen> createState() => _MakeItScreenState();
}

class _MakeItScreenState extends State<MakeItScreen>
    with SingleTickerProviderStateMixin {
  static const int _max = 30;
  static const List<int> _pieces = [1, 2, 5, 10];
  final _rng = math.Random();
  int _target = 5;
  int _current = 0;
  bool _won = false;
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _target = 3 + _rng.nextInt(18); // 3..20
    _pop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _addN(int n) async {
    if (_won || _current >= _max) return;
    setState(() => _current = math.min(_current + n, _max));
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
        next = 3 + _rng.nextInt(18);
      } while (next == _target);
      _target = next;
      _current = 0;
      _won = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final matched = _won;
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
              // ── Pieces to add (+1 +2 +5 +10) + remove / clear ────────
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.lg, top: Gap.xs),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Gap.sm,
                  runSpacing: Gap.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SoftButton(
                      color: NColors.inkSoft,
                      onTap: (_won || _current <= 0) ? null : _remove,
                      width: 58,
                      height: 58,
                      radius: Radii.md,
                      child: const Icon(Icons.remove, size: 30),
                    ),
                    SoftButton(
                      color: NColors.inkSoft,
                      onTap: (_won || _current == 0) ? null : _clear,
                      width: 58,
                      height: 58,
                      radius: Radii.md,
                      child: const Icon(Icons.refresh_rounded, size: 26),
                    ),
                    const SizedBox(width: Gap.md),
                    for (final p in _pieces)
                      SoftButton(
                        color: NColors.numBlockColor(p),
                        onTap: (_won || _current >= _max) ? null : () => _addN(p),
                        width: 68,
                        height: 68,
                        radius: Radii.lg,
                        child: Text('+$p',
                            style: const TextStyle(fontSize: 22)),
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
