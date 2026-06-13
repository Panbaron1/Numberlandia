import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import 'times_tables_notifier.dart';

class TimesTablesScreen extends StatefulWidget {
  const TimesTablesScreen({super.key});

  @override
  State<TimesTablesScreen> createState() => _TimesTablesScreenState();
}

class _TimesTablesScreenState extends State<TimesTablesScreen> {
  final _n = TimesTablesNotifier();

  Future<void> _tap() async {
    await HapticsService.instance.light();
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
      appBar: AppBar(
        backgroundColor: NColors.bg,
        leading: IconButton(
          iconSize: 28,
          icon: const Icon(Icons.arrow_back_rounded, color: NColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Times Tables',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: AnimatedBuilder(
        animation: _n,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: Gap.md),
              // ── Equation display ─────────────────────────────────────
              _EquationRow(notifier: _n),
              const SizedBox(height: Gap.lg),
              // ── Block grid ───────────────────────────────────────────
              Expanded(
                child: _BlockGrid(a: _n.a, b: _n.b, onTap: _tap),
              ),
              const SizedBox(height: Gap.md),
              // ── Pickers ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NumberPicker(
                      value: _n.a,
                      label: 'Rows',
                      color: NColors.numBlockColor(_n.a),
                      onStep: _n.stepA,
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: _NumberPicker(
                      value: _n.b,
                      label: 'Columns',
                      color: NColors.timesTables,
                      onStep: _n.stepB,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EquationRow extends StatelessWidget {
  final TimesTablesNotifier notifier;
  const _EquationRow({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final aColor = NColors.numBlockColor(notifier.a);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        _BigNum('${notifier.a}', aColor),
        const _Op('×'),
        _BigNum('${notifier.b}', NColors.timesTables),
        const _Op('='),
        _BigNum('${notifier.product}', NColors.ink),
      ],
    );
  }
}

class _BigNum extends StatelessWidget {
  final String text;
  final Color color;
  const _BigNum(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: Text(
        text,
        key: ValueKey(text + color.toString()),
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: -2,
          height: 1,
        ),
      ),
    );
  }
}

class _Op extends StatelessWidget {
  final String text;
  const _Op(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w300,
          color: NColors.inkSoft,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// A × B grid of coloured squares — each tap plays a pop.
/// Virtualization not needed: max 144 cells (12×12).
class _BlockGrid extends StatelessWidget {
  final int a; // rows
  final int b; // columns
  final VoidCallback onTap;

  const _BlockGrid({required this.a, required this.b, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = NColors.numBlockColor(a);
    final cellSize = _cellSize(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int row = 0; row < a; row++) ...[
              if (row > 0) const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int col = 0; col < b; col++) ...[
                    if (col > 0) const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(cellSize * 0.2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(70),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _cellSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width - Gap.lg * 2;
    final maxByWidth = (w - (b - 1) * 4) / b;
    return maxByWidth.clamp(14.0, 36.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NumberPicker extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final void Function(int) onStep;

  const _NumberPicker({
    required this.value,
    required this.label,
    required this.color,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: NColors.inkSoft,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: Gap.xs),
          Row(
            children: [
              _PBtn(
                  icon: Icons.remove,
                  color: color,
                  onTap: () => onStep(-1),
                  enabled: value > TimesTablesNotifier.min),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Center(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gap.sm),
              _PBtn(
                  icon: Icons.add,
                  color: color,
                  onTap: () => onStep(1),
                  enabled: value < TimesTablesNotifier.max),
            ],
          ),
        ],
      ),
    );
  }
}

class _PBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _PBtn(
      {required this.icon,
      required this.color,
      required this.onTap,
      required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: NColors.inkMuted.withAlpha(40),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
