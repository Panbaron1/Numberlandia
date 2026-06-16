import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/scene_background.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import 'take_away_notifier.dart';

/// Take Away — A − B = C, shown live as three numberblocks. Result clamps at 0.
class TakeAwayScreen extends StatefulWidget {
  const TakeAwayScreen({super.key});

  @override
  State<TakeAwayScreen> createState() => _TakeAwayScreenState();
}

class _TakeAwayScreenState extends State<TakeAwayScreen> {
  final _n = TakeAwayNotifier();

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
        title: 'Take Away',
        color: NColors.takeAway,
        assetImage: 'assets/cards/takeaway.png',
      ),
      body: SceneBackground(
        color: NColors.takeAway,
        child: AnimatedBuilder(
        animation: _n,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: Gap.sm),
              _EquationRow(notifier: _n),
              const SizedBox(height: Gap.sm),
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
                              color: NColors.numBlockColor(_n.a),
                              onStep: (d) => _changeA(_n.a + d))),
                      const _Sign('−'),
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
                              value: _n.diff,
                              color: NColors.numBlockColor(_n.diff),
                              big: true)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Gap.md),
            ],
          ),
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EquationRow extends StatelessWidget {
  final TakeAwayNotifier notifier;
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
          const _OpText('−'),
          _Num('${notifier.b}', NColors.numBlockColor(notifier.b)),
          const _OpText('='),
          _Num('${notifier.diff}', NColors.ink),
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
  final void Function(int)? onStep; // null = no controls (the result)
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
        if (onStep != null) ...[
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              Expanded(
                child: SoftButton(
                  color: color,
                  onTap: () => onStep!(-1),
                  height: 64,
                  radius: Radii.md,
                  child: const Icon(Icons.remove, size: 36),
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: SoftButton(
                  color: color,
                  onTap: () => onStep!(1),
                  height: 64,
                  radius: Radii.md,
                  child: const Icon(Icons.add, size: 36),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
