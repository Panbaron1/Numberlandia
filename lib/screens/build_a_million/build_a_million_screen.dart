import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import 'million_notifier.dart';

class BuildAMillionScreen extends StatefulWidget {
  const BuildAMillionScreen({super.key});

  @override
  State<BuildAMillionScreen> createState() => _BuildAMillionScreenState();
}

class _BuildAMillionScreenState extends State<BuildAMillionScreen> {
  final _notifier = MillionNotifier();

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _tap(int amount) async {
    _notifier.add(amount);
    await HapticsService.instance.light();
    if (_notifier.atMax) {
      await AudioService.instance.playChime();
    } else {
      await AudioService.instance.playPop();
    }
  }

  Future<void> _reset() async {
    _notifier.reset();
    await HapticsService.instance.medium();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const _BackButton(),
        title: const Text('Build a Million'),
      ),
      body: AnimatedBuilder(
        animation: _notifier,
        builder: (context, _) => _Body(
          notifier: _notifier,
          onTap: _tap,
          onReset: _reset,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final MillionNotifier notifier;
  final Future<void> Function(int) onTap;
  final Future<void> Function() onReset;

  const _Body({
    required this.notifier,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: Gap.lg),
          // Big number display
          _NumberDisplay(value: notifier.value),
          const SizedBox(height: Gap.lg),
          // Place value blocks
          _PlaceValueRow(notifier: notifier),
          const Spacer(),
          // Add buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            child: Column(
              children: [
                Row(
                  children: [
                    _AddButton(label: '+1', amount: 1, onTap: onTap),
                    const SizedBox(width: Gap.sm),
                    _AddButton(label: '+10', amount: 10, onTap: onTap),
                    const SizedBox(width: Gap.sm),
                    _AddButton(label: '+100', amount: 100, onTap: onTap),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                Row(
                  children: [
                    _AddButton(label: '+1,000', amount: 1000, onTap: onTap),
                    const SizedBox(width: Gap.sm),
                    _AddButton(
                        label: '+10,000', amount: 10000, onTap: onTap),
                    const SizedBox(width: Gap.sm),
                    _AddButton(
                        label: '+100,000', amount: 100000, onTap: onTap),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          // Reset
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset to zero'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NColors.inkSoft,
                  side: const BorderSide(color: NColors.inkSoft, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }
}

class _NumberDisplay extends StatelessWidget {
  final int value;
  const _NumberDisplay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _format(value),
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w800,
            color: NColors.ink,
            letterSpacing: -2,
            height: 1,
          ),
        ),
        if (value == 1000000)
          const Padding(
            padding: EdgeInsets.only(top: Gap.sm),
            child: Text(
              'ONE MILLION! 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NColors.million,
              ),
            ),
          ),
      ],
    );
  }

  String _format(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _PlaceValueRow extends StatelessWidget {
  final MillionNotifier notifier;
  const _PlaceValueRow({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        children: [
          if (notifier.millions > 0)
            _PlaceBlock(
                count: notifier.millions, label: 'M', color: NColors.million),
          _PlaceBlock(
              count: notifier.hundredThousands,
              label: '100K',
              color: NColors.million.withAlpha(200)),
          _PlaceBlock(
              count: notifier.tenThousands,
              label: '10K',
              color: NColors.numberLine),
          _PlaceBlock(
              count: notifier.thousands,
              label: '1K',
              color: NColors.numberLine.withAlpha(200)),
          _PlaceBlock(
              count: notifier.hundreds,
              label: '100',
              color: NColors.timesTables),
          _PlaceBlock(
              count: notifier.tens, label: '10', color: NColors.machine),
          _PlaceBlock(count: notifier.ones, label: '1', color: NColors.doubling),
        ],
      ),
    );
  }
}

class _PlaceBlock extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _PlaceBlock(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Gap.xs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 58,
        height: 72,
        decoration: BoxDecoration(
          color: count > 0 ? color.withAlpha(36) : NColors.bg,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: count > 0 ? color : NColors.inkSoft.withAlpha(40),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: count > 0 ? color : NColors.inkSoft.withAlpha(80),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: count > 0 ? color : NColors.inkSoft.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final int amount;
  final Future<void> Function(int) onTap;

  const _AddButton(
      {required this.label, required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 64,
        child: FilledButton(
          onPressed: () => onTap(amount),
          style: FilledButton.styleFrom(
            backgroundColor: NColors.million,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 28,
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}
