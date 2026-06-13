import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
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
      body: AnimatedBuilder(
        animation: _n,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: Gap.lg),
              // ── Equation ─────────────────────────────────────────────
              _EquationLabel(notifier: _n),
              const SizedBox(height: Gap.lg),
              // ── Block towers ─────────────────────────────────────────
              Expanded(
                child: _TowerView(notifier: _n),
              ),
              // ── Controls ─────────────────────────────────────────────
              _Controls(onStep: _step, notifier: _n),
              const SizedBox(height: Gap.xl),
            ],
          ),
        ),
      ),
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

    return Row(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TowerView extends StatelessWidget {
  final DoublingNotifier notifier;
  const _TowerView({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final n = notifier.value;
    final d = notifier.doubled;
    final c1 = NColors.numBlockColor(n);
    final c2 = NColors.numBlockColor(d);

    // Dynamic unit size: fit both square-packed blocks in the available space.
    // Height is driven by the number of rows in the (taller) doubled block,
    // and width by its widest row — clamp to whichever is tighter.
    final size = MediaQuery.of(context).size;
    final rows = NumBlock.rowsFor(d).length;
    final cols = NumBlock.rowsFor(d).first;
    final byHeight = (size.height * 0.42) / (rows + 0.6);
    final byWidth = (size.width * 0.40) / (cols + 0.6);
    final unit = math.min(byHeight, byWidth).clamp(20.0, 54.0).toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left tower: value n
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(n.toString(),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: c1)),
            const SizedBox(height: Gap.xs),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: NumBlock(key: ValueKey('left-$n'), value: n, unit: unit),
            ),
          ],
        ),
        const SizedBox(width: Gap.xxl),
        // Right tower: doubled
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(d.toString(),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: c2)),
            const SizedBox(height: Gap.xs),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: NumBlock(key: ValueKey('right-$d'), value: d, unit: unit),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final Future<void> Function(int) onStep;
  final DoublingNotifier notifier;

  const _Controls({required this.onStep, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      child: Row(
        children: [
          ChunkyButton(
            color: NColors.doubling,
            onTap: notifier.value > DoublingNotifier.min ? () => onStep(-1) : null,
            width: 84,
            height: 84,
            radius: Radii.lg,
            child: const Icon(Icons.remove, size: 38),
          ),
          const Spacer(),
          Text(
            '${notifier.value}',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: NColors.ink,
              letterSpacing: -1,
            ),
          ),
          const Spacer(),
          ChunkyButton(
            color: NColors.doubling,
            onTap: notifier.value < DoublingNotifier.max ? () => onStep(1) : null,
            width: 84,
            height: 84,
            radius: Radii.lg,
            child: const Icon(Icons.add, size: 38),
          ),
        ],
      ),
    );
  }
}
