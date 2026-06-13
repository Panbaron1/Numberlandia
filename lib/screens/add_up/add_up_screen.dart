import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import 'add_up_notifier.dart';

/// Add Up — two number characters combine into their sum.
/// A + B = C, shown live as three numberblocks (scales to 100×100).
class AddUpScreen extends StatefulWidget {
  const AddUpScreen({super.key});

  @override
  State<AddUpScreen> createState() => _AddUpScreenState();
}

class _AddUpScreenState extends State<AddUpScreen> {
  final _n = AddUpNotifier();

  @override
  void dispose() {
    _n.dispose();
    super.dispose();
  }

  Future<void> _changeA(int v) async {
    _n.setA(v);
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
  }

  Future<void> _changeB(int v) async {
    _n.setB(v);
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RoomHeader(
        title: 'Add Up',
        color: NColors.addUp,
        assetImage: 'assets/cards/addup.png',
      ),
      body: AnimatedBuilder(
        animation: _n,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: Gap.sm),
              _EquationRow(notifier: _n),
              const SizedBox(height: Gap.sm),
              // ── Three blocks: A + B = C ──────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          flex: 3,
                          child: _BlockPanel(
                              value: _n.a,
                              color: NColors.numBlockColor(_n.a))),
                      const _Sign('+'),
                      Expanded(
                          flex: 3,
                          child: _BlockPanel(
                              value: _n.b,
                              color: NColors.numBlockColor(_n.b))),
                      const _Sign('='),
                      Expanded(
                          flex: 4,
                          child: _BlockPanel(
                              value: _n.sum,
                              color: NColors.numBlockColor(_n.sum),
                              big: true)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Gap.sm),
              // ── Stepper rows (big +/- buttons) ───────────────────────
              _StepperRow(
                value: _n.a,
                color: NColors.numBlockColor(_n.a),
                onStep: (d) => _changeA(_n.a + d),
              ),
              const SizedBox(height: Gap.sm),
              _StepperRow(
                value: _n.b,
                color: NColors.numBlockColor(_n.b),
                onStep: (d) => _changeB(_n.b + d),
              ),
              const SizedBox(height: Gap.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EquationRow extends StatelessWidget {
  final AddUpNotifier notifier;
  const _EquationRow({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          _Num('${notifier.a}', NColors.numBlockColor(notifier.a)),
          const _OpText('+'),
          _Num('${notifier.b}', NColors.numBlockColor(notifier.b)),
          const _OpText('='),
          _Num('${notifier.sum}', NColors.ink),
        ],
      ),
    );
  }
}

class _Num extends StatelessWidget {
  final String text;
  final Color color;
  const _Num(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: Text(text,
          key: ValueKey('$text$color'),
          style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -1,
              height: 1)),
    );
  }
}

class _OpText extends StatelessWidget {
  final String text;
  const _OpText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      child: Text(text,
          style: const TextStyle(
              fontSize: 36, fontWeight: FontWeight.w400, color: NColors.inkSoft)),
    );
  }
}

class _Sign extends StatelessWidget {
  final String text;
  const _Sign(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
      child: Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w300,
                color: NColors.inkSoft)),
      ),
    );
  }
}

class _BlockPanel extends StatelessWidget {
  final int value;
  final Color color;
  final bool big;
  const _BlockPanel({required this.value, required this.color, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: big ? 24 : 18,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: Gap.xs),
        Expanded(child: NumBlockView(value: value)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// One addend's controls: big −100 −10 −1 [value] +1 +10 +100 chunky buttons.
class _StepperRow extends StatelessWidget {
  final int value;
  final Color color;
  final void Function(int) onStep;

  const _StepperRow({
    required this.value,
    required this.color,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        children: [
          _Step(label: '−100', color: color, onTap: () => onStep(-100)),
          const SizedBox(width: Gap.xs),
          _Step(label: '−10', color: color, onTap: () => onStep(-10)),
          const SizedBox(width: Gap.xs),
          _Step(label: '−1', color: color, onTap: () => onStep(-1), big: true),
          // Current value in the centre
          Container(
            width: 96,
            alignment: Alignment.center,
            child: Text('$value',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -1)),
          ),
          _Step(label: '+1', color: color, onTap: () => onStep(1), big: true),
          const SizedBox(width: Gap.xs),
          _Step(label: '+10', color: color, onTap: () => onStep(10)),
          const SizedBox(width: Gap.xs),
          _Step(label: '+100', color: color, onTap: () => onStep(100)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool big;

  const _Step({
    required this.label,
    required this.color,
    required this.onTap,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: big ? 3 : 2,
      child: ChunkyButton(
        color: color,
        onTap: onTap,
        height: big ? 72 : 60,
        radius: Radii.md,
        child: Text(label,
            style: TextStyle(fontSize: big ? 28 : 20)),
      ),
    );
  }
}
