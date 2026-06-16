import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/scene_background.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import 'number_machine_notifier.dart';

/// Numberblocks — tap digits 0–9 to write a number and see it as numberblocks.
class NumberMachineScreen extends StatefulWidget {
  const NumberMachineScreen({super.key});

  @override
  State<NumberMachineScreen> createState() => _NumberMachineScreenState();
}

class _NumberMachineScreenState extends State<NumberMachineScreen> {
  final _n = NumberInputNotifier();

  @override
  void dispose() {
    _n.dispose();
    super.dispose();
  }

  Future<void> _digit(int d) async {
    _n.digit(d);
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
  }

  Future<void> _back() async {
    _n.backspace();
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
  }

  Future<void> _clear() async {
    _n.clear();
    await HapticsService.instance.medium();
    await AudioService.instance.playPop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RoomHeader(
        title: 'Numberblocks',
        color: NColors.machine,
        assetImage: 'assets/cards/numberblocks.png',
      ),
      body: SceneBackground(
        color: NColors.machine,
        child: AnimatedBuilder(
        animation: _n,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              // ── One numberblock character per digit, in a row ───────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < _n.text.length; i++) ...[
                        if (i > 0) const SizedBox(width: Gap.xs),
                        Expanded(
                          child: NumBlockView(
                              value: int.parse(_n.text[i])),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // ── The number being written ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Gap.md, vertical: Gap.sm),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _n.text,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: NColors.ink,
                      letterSpacing: 2,
                      height: 1,
                    ),
                  ),
                ),
              ),
              // ── Keypad: 0 1 2 3 4 5 6 7 8 9 (+ backspace, clear) ────
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.sm, 0, Gap.sm, Gap.md),
                child: Row(
                  children: [
                    _Key(
                      color: NColors.inkSoft,
                      onTap: _back,
                      child: const Icon(Icons.backspace_rounded, size: 28),
                    ),
                    for (int d = 0; d <= 9; d++) ...[
                      const SizedBox(width: Gap.xs),
                      _Key(
                        color: NColors.numBlockColor(d),
                        onTap: () => _digit(d),
                        child: Text('$d',
                            style: const TextStyle(fontSize: 30)),
                      ),
                    ],
                    const SizedBox(width: Gap.xs),
                    _Key(
                      color: NColors.doubling,
                      onTap: _clear,
                      child: const Text('C', style: TextStyle(fontSize: 26)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}

class _Key extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback onTap;

  const _Key({required this.child, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoftButton(
        color: color,
        onTap: onTap,
        height: 76,
        radius: Radii.md,
        child: child,
      ),
    );
  }
}
