import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/scene_background.dart';
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
      body: SceneBackground(
        color: NColors.addUp,
        child: AnimatedBuilder(
        animation: _n,
        builder: (context, _) => SafeArea(
          child: LayoutBuilder(
            builder: (context, cons) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: cons.maxHeight),
                child: Column(
            children: [
              const SizedBox(height: Gap.sm),
              _EquationRow(notifier: _n),
              const SizedBox(height: Gap.sm),
              // ── Three blocks: A + B = C ──────────────────────────────
              SizedBox(
                height: (cons.maxHeight * 0.6).clamp(200.0, 620.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          flex: 3,
                          child: _BlockPanel(
                              value: _n.a,
                              color: NColors.numBlockColor(_n.a),
                              onStep: (d) => _changeA(_n.a + d))),
                      const _Sign('+'),
                      Expanded(
                          flex: 3,
                          child: _BlockPanel(
                              value: _n.b,
                              color: NColors.numBlockColor(_n.b),
                              onStep: (d) => _changeB(_n.b + d))),
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
              const SizedBox(height: Gap.md),
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
  final void Function(int)? onStep; // null = no controls (the sum)
  const _BlockPanel({
    required this.value,
    required this.color,
    this.big = false,
    this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: big ? 28 : 22,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: Gap.xs),
        Expanded(child: NumBlockView(value: value)),
        // − / + directly under the block (step of 1)
        if (onStep != null) ...[
          const SizedBox(height: Gap.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              SoftButton(
                color: color,
                onTap: () => onStep!(-1),
                width: 58,
                height: 58,
                radius: Radii.md,
                child: const Icon(Icons.remove, size: 32),
              ),
              SoftButton(
                color: color,
                onTap: () => onStep!(1),
                width: 58,
                height: 58,
                radius: Radii.md,
                child: const Icon(Icons.add, size: 32),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

