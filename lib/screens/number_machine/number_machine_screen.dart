import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/num_block.dart';
import 'number_machine_notifier.dart';

class NumberMachineScreen extends StatefulWidget {
  const NumberMachineScreen({super.key});

  @override
  State<NumberMachineScreen> createState() => _NumberMachineScreenState();
}

class _NumberMachineScreenState extends State<NumberMachineScreen>
    with SingleTickerProviderStateMixin {
  final _n = NumberMachineNotifier();
  late final AnimationController _runAnim;

  @override
  void initState() {
    super.initState();
    _runAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _n.dispose();
    _runAnim.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    _n.run();
    _runAnim.forward(from: 0);
    await HapticsService.instance.medium();
    await AudioService.instance.playChime();
  }

  Future<void> _feedBack() async {
    _n.feedBack();
    await HapticsService.instance.selection();
    await AudioService.instance.playPop();
  }

  Future<void> _step(int d) async {
    _n.stepInput(d);
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: NColors.bg,
        leading: IconButton(
          iconSize: 28,
          icon: const Icon(Icons.arrow_back_rounded, color: NColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Number Machine',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_n, _runAnim]),
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.lg, vertical: Gap.md),
            child: Column(
              children: [
                // ── Input ────────────────────────────────────────────
                _Section(
                  label: 'Put in',
                  color: NColors.million,
                  child: _InputPanel(notifier: _n, onStep: _step),
                ),
                const SizedBox(height: Gap.md),
                // ── Machine / operation ───────────────────────────────
                _MachinePanel(notifier: _n, anim: _runAnim),
                const SizedBox(height: Gap.md),
                // ── Run button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton(
                    onPressed: _run,
                    style: FilledButton.styleFrom(
                      backgroundColor: NColors.machine,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.lg),
                      ),
                    ),
                    child: const Text('RUN ▶'),
                  ),
                ),
                const SizedBox(height: Gap.md),
                // ── Output ───────────────────────────────────────────
                _OutputPanel(
                    notifier: _n, anim: _runAnim, onFeedBack: _feedBack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final Color color;
  final Widget child;

  const _Section(
      {required this.label, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: color.withAlpha(50), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.4)),
          const SizedBox(height: Gap.xs),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InputPanel extends StatelessWidget {
  final NumberMachineNotifier notifier;
  final Future<void> Function(int) onStep;

  const _InputPanel({required this.notifier, required this.onStep});

  @override
  Widget build(BuildContext context) {
    final n = notifier.input;
    final abs = n.abs();
    final showBlock = abs <= 9 && abs > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IBtn(label: '−10', onTap: () => onStep(-10)),
        const SizedBox(width: Gap.sm),
        _IBtn(label: '−1', onTap: () => onStep(-1), big: true),
        const SizedBox(width: Gap.md),
        Column(
          children: [
            if (showBlock) BouncyNumBlock(value: n, unit: 20),
            if (showBlock) const SizedBox(height: 4),
            Text(
              '$n',
              style: TextStyle(
                fontSize: showBlock ? 40 : 56,
                fontWeight: FontWeight.w900,
                color: NColors.million,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
        const SizedBox(width: Gap.md),
        _IBtn(label: '+1', onTap: () => onStep(1), big: true),
        const SizedBox(width: Gap.sm),
        _IBtn(label: '+10', onTap: () => onStep(10)),
      ],
    );
  }
}

class _IBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool big;

  const _IBtn({required this.label, required this.onTap, this.big = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: big ? 60 : 52,
      height: big ? 60 : 52,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: NColors.million,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          textStyle: TextStyle(
              fontSize: big ? 18 : 13, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md)),
        ),
        child: Text(label),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MachinePanel extends StatelessWidget {
  final NumberMachineNotifier notifier;
  final AnimationController anim;

  const _MachinePanel({required this.notifier, required this.anim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NColors.machine.withAlpha(30),
            NColors.machine.withAlpha(14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: NColors.machine.withAlpha(60), width: 1.5),
      ),
      child: Column(
        children: [
          // Spinning gear during animation
          RotationTransition(
            turns: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: const Text('⚙️', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: Gap.sm),
          // Operation selector
          Wrap(
            spacing: Gap.xs,
            runSpacing: Gap.xs,
            alignment: WrapAlignment.center,
            children: MachineOp.values.map((op) {
              final sel = op == notifier.op;
              return GestureDetector(
                onTap: () => notifier.setOp(op),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: Gap.sm, vertical: Gap.xs),
                  decoration: BoxDecoration(
                    color: sel ? NColors.machine : NColors.machine.withAlpha(20),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    op.label,
                    style: TextStyle(
                      color: sel ? Colors.white : NColors.machine,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OutputPanel extends StatelessWidget {
  final NumberMachineNotifier notifier;
  final AnimationController anim;
  final VoidCallback onFeedBack;

  const _OutputPanel({
    required this.notifier,
    required this.anim,
    required this.onFeedBack,
  });

  @override
  Widget build(BuildContext context) {
    final out = notifier.output;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: out != null ? NColors.numberLine.withAlpha(18) : NColors.bg,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: out != null
              ? NColors.numberLine.withAlpha(80)
              : NColors.inkMuted.withAlpha(40),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text('Out comes',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: out != null ? NColors.numberLine : NColors.inkMuted,
                  letterSpacing: 0.4)),
          const SizedBox(height: Gap.sm),
          if (out == null)
            const Text('?',
                style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: NColors.inkMuted))
          else ...[
            ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
              child: Text(
                '$out',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: NColors.numberLine,
                  letterSpacing: -2,
                ),
              ),
            ),
            const SizedBox(height: Gap.sm),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onFeedBack,
                icon: const Icon(Icons.redo_rounded),
                label: const Text('Feed back in',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NColors.numberLine,
                  side: const BorderSide(color: NColors.numberLine, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
