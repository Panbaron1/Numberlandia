import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/scene_background.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';

/// A live 24-hour clock with each digit drawn as a numberblock character.
/// HH : MM : SS, centred on the screen, ticking once a second.
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Tick on the second boundary, then every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hh = _two(_now.hour);
    final mm = _two(_now.minute);
    final ss = _two(_now.second);

    return Scaffold(
      appBar: const RoomHeader(
        title: 'Clock',
        color: NColors.clock,
        assetImage: 'assets/cards/clock.png',
      ),
      body: SceneBackground(
        color: NColors.clock,
        child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Digital readout above the blocks — each digit tinted with
                // its numberblock colour, colons in soft ink.
                Text.rich(
                  TextSpan(
                    children: [
                      for (final ch in '$hh:$mm:$ss'.split(''))
                        TextSpan(
                          text: ch,
                          style: TextStyle(
                            color: ch == ':'
                                ? NColors.inkSoft
                                : NColors.numBlockColor(int.parse(ch)),
                          ),
                        ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    height: 1,
                  ),
                ),
                const SizedBox(height: Gap.xl),
                // Numberblock clock
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ..._group(hh),
                    const _Colon(),
                    ..._group(mm),
                    const _Colon(),
                    ..._group(ss),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      )),
    );
  }

  // Two digit-blocks for one HH/MM/SS group.
  List<Widget> _group(String two) {
    return [
      _Digit(int.parse(two[0])),
      const SizedBox(width: Gap.sm),
      _Digit(int.parse(two[1])),
    ];
  }
}

class _Digit extends StatelessWidget {
  final int value;
  const _Digit(this.value);

  @override
  Widget build(BuildContext context) {
    // Fixed-ish slot so the clock doesn't jump as digits change shape.
    return SizedBox(
      width: 90,
      child: AspectRatio(
        aspectRatio: 0.62,
        child: NumBlockView(value: value),
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(),
          const SizedBox(height: 26),
          _dot(),
        ],
      ),
    );
  }

  Widget _dot() => Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: NColors.inkSoft,
          shape: BoxShape.circle,
        ),
      );
}
