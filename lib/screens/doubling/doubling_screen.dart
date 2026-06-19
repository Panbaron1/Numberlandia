import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/scene_background.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import 'doubling_notifier.dart';

class DoublingScreen extends StatefulWidget {
  const DoublingScreen({super.key});

  @override
  State<DoublingScreen> createState() => _DoublingScreenState();
}

class _DoublingScreenState extends State<DoublingScreen> {
  final _n = DoublingNotifier();

  Future<void> _step(int d) async {
    _n.step(d);
    await HapticsService.instance.selection();
    await AudioService.instance.playPop();
  }

  void _set(int v) => _n.set(v);

  Future<void> _double() async {
    _n.doubleIt();
    await HapticsService.instance.medium();
    await AudioService.instance.playChime();
  }

  @override
  void dispose() {
    _n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RoomHeader(
        title: 'Doubling',
        color: NColors.doubling,
        assetImage: 'assets/cards/doubling.png',
      ),
      body: SceneBackground(
        color: NColors.doubling,
        child: AnimatedBuilder(
        animation: _n,
        builder: (context, _) => SafeArea(
          child: LayoutBuilder(
            builder: (context, cons) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: cons.maxHeight),
                child: Column(
            children: [
              const SizedBox(height: Gap.lg),
              // ── Equation ─────────────────────────────────────────────
              _EquationLabel(notifier: _n),
              const SizedBox(height: Gap.lg),
              // ── Block towers ─────────────────────────────────────────
              SizedBox(
                height: (cons.maxHeight * 0.45).clamp(160.0, 520.0),
                child: _TowerView(notifier: _n),
              ),
              // ── Controls ─────────────────────────────────────────────
              _Controls(
                notifier: _n,
                onStep: _step,
                onSet: _set,
                onDouble: _double,
              ),
              const SizedBox(height: Gap.lg),
            ],
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EquationLabel extends StatelessWidget {
  final DoublingNotifier notifier;
  const _EquationLabel({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final c1 = NColors.numBlockColor(notifier.value);
    final c2 = NColors.numBlockColor(notifier.doubled);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${notifier.value}',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: c1,
            letterSpacing: -1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          child: const Text(
            '×2 =',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: NColors.inkSoft,
            ),
          ),
        ),
        Text(
          '${notifier.doubled}',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: c2,
            letterSpacing: -1,
          ),
        ),
      ],
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TowerView extends StatelessWidget {
  final DoublingNotifier notifier;
  const _TowerView({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: _BlockSide(
                  value: notifier.value, color: NColors.numBlockColor(notifier.value))),
          const SizedBox(width: Gap.md),
          // Arrow between the two
          const Center(
            child: Icon(Icons.arrow_forward_rounded,
                color: NColors.inkSoft, size: 32),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
              child: _BlockSide(
                  value: notifier.doubled,
                  color: NColors.numBlockColor(notifier.doubled))),
        ],
      ),
    );
  }
}

class _BlockSide extends StatelessWidget {
  final int value;
  final Color color;
  const _BlockSide({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: Gap.xs),
        // NumBlockView scales: widget+faces when small, painter up to 100×100.
        Expanded(child: NumBlockView(value: value)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final DoublingNotifier notifier;
  final Future<void> Function(int) onStep;
  final void Function(int) onSet;
  final Future<void> Function() onDouble;

  const _Controls({
    required this.notifier,
    required this.onStep,
    required this.onSet,
    required this.onDouble,
  });

  @override
  Widget build(BuildContext context) {
    // Slider uses a sqrt scale so the lower (kid-friendly) range is easy to
    // land on while still reaching 5000.
    final maxD = DoublingNotifier.max.toDouble();
    // Inverse of the square mapping below, so the thumb sits at the real value.
    final sliderVal =
        ((notifier.value - 1) / (maxD - 1)).clamp(0.0, 1.0).toDouble();
    final thumbPos = sliderVal <= 0 ? 0.0 : math.sqrt(sliderVal);

    return Column(
      children: [
        // ── −1 / Double it! / +1 ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          child: Row(
            children: [
              SoftButton(
                color: NColors.doubling,
                onTap: notifier.value > DoublingNotifier.min
                    ? () => onStep(-1)
                    : null,
                width: 72,
                height: 72,
                radius: Radii.lg,
                child: const Icon(Icons.remove, size: 34),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: SoftButton(
                  color: NColors.doubling,
                  onTap: notifier.value < DoublingNotifier.max ? onDouble : null,
                  height: 72,
                  radius: Radii.lg,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Double it!  ×2',
                        style: TextStyle(fontSize: 22)),
                  ),
                ),
              ),
              const SizedBox(width: Gap.md),
              SoftButton(
                color: NColors.doubling,
                onTap: notifier.value < DoublingNotifier.max
                    ? () => onStep(1)
                    : null,
                width: 72,
                height: 72,
                radius: Radii.lg,
                child: const Icon(Icons.add, size: 34),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        // ── Slider 1..5000 ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: NColors.doubling,
              thumbColor: NColors.doubling,
              inactiveTrackColor: NColors.doubling.withAlpha(40),
              overlayColor: NColors.doubling.withAlpha(30),
              trackHeight: 6,
            ),
            child: Slider(
              value: thumbPos.clamp(0.0, 1.0),
              onChanged: (v) {
                // Map 0..1 → 1..5000 on a square curve for finer low-end control.
                final mapped = (v * v) * (maxD - 1) + 1;
                onSet(mapped.round());
              },
            ),
          ),
        ),
      ],
    );
  }
}
