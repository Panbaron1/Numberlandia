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
              // ── Sliders ──────────────────────────────────────────────
              _AddSlider(
                label: 'First',
                value: _n.a,
                color: NColors.numBlockColor(_n.a),
                onChanged: _changeA,
                onStep: (d) => _changeA(_n.a + d),
              ),
              _AddSlider(
                label: 'Second',
                value: _n.b,
                color: NColors.numBlockColor(_n.b),
                onChanged: _changeB,
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

class _AddSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;
  final void Function(int) onStep;

  const _AddSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    // Square curve: easy on the low (single-digit) end, still reaches 5000.
    const maxV = AddUpNotifier.max;
    final norm = (value / maxV).clamp(0.0, 1.0);
    final thumb = norm <= 0 ? 0.0 : _sqrt(norm);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text('$value',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: NColors.inkSoft,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _StepDot(icon: Icons.remove, color: color, onTap: () => onStep(-1)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withAlpha(40),
                overlayColor: color.withAlpha(30),
                trackHeight: 6,
              ),
              child: Slider(
                value: thumb,
                onChanged: (v) => onChanged((v * v * maxV).round()),
              ),
            ),
          ),
          _StepDot(icon: Icons.add, color: color, onTap: () => onStep(1)),
        ],
      ),
    );
  }

  // Local sqrt to avoid importing dart:math for one call.
  static double _sqrt(double x) {
    double g = x;
    for (int i = 0; i < 20; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }
}

class _StepDot extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StepDot(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
