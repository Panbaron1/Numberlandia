import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import 'number_machine_notifier.dart';

class NumberMachineScreen extends StatefulWidget {
  const NumberMachineScreen({super.key});

  @override
  State<NumberMachineScreen> createState() => _NumberMachineScreenState();
}

class _NumberMachineScreenState extends State<NumberMachineScreen> {
  final _calc = CalculatorNotifier();

  @override
  void dispose() {
    _calc.dispose();
    super.dispose();
  }

  Future<void> _digit(int d) async {
    _calc.digit(d);
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
  }

  Future<void> _op(String op) async {
    _calc.setOp(op);
    await HapticsService.instance.selection();
    await AudioService.instance.playPop();
  }

  Future<void> _equals() async {
    _calc.equals();
    await HapticsService.instance.medium();
    await AudioService.instance.playChime();
  }

  Future<void> _clear() async {
    _calc.clear();
    await HapticsService.instance.medium();
    await AudioService.instance.playPop();
  }

  Future<void> _back() async {
    _calc.backspace();
    await HapticsService.instance.light();
    await AudioService.instance.playPop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RoomHeader(
        title: 'Calculator',
        color: NColors.machine,
        assetImage: 'assets/cards/machine.png',
      ),
      body: AnimatedBuilder(
        animation: _calc,
        builder: (context, _) => SafeArea(
          child: Row(
            children: [
              // ── Left: numberblock result + display ───────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(Gap.md),
                  child: Column(
                    children: [
                      // Big display number
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _calc.display,
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w800,
                            color: NColors.ink,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: Gap.sm),
                      // Numberblock view of the current value
                      Expanded(
                        child: NumBlockView(value: _calc.value),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Right: round-button keypad ───────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, Gap.sm, Gap.md, Gap.sm),
                  child: _Keypad(
                    onDigit: _digit,
                    onOp: _op,
                    onEquals: _equals,
                    onClear: _clear,
                    onBack: _back,
                    activeOp: _calc.op,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Keypad extends StatelessWidget {
  final Future<void> Function(int) onDigit;
  final Future<void> Function(String) onOp;
  final VoidCallback onEquals;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final String? activeOp;

  const _Keypad({
    required this.onDigit,
    required this.onOp,
    required this.onEquals,
    required this.onClear,
    required this.onBack,
    required this.activeOp,
  });

  @override
  Widget build(BuildContext context) {
    // 4-column layout: digits + ops, then C / 0 / ⌫ / =
    return Column(
      children: [
        _row([
          _digit(7), _digit(8), _digit(9), _op('×'),
        ]),
        _row([
          _digit(4), _digit(5), _digit(6), _op('−'),
        ]),
        _row([
          _digit(1), _digit(2), _digit(3), _op('+'),
        ]),
        _row([
          _RoundButton(
              label: 'C', color: NColors.doubling, onTap: onClear),
          _digit(0),
          _RoundButton(
              icon: Icons.backspace_rounded,
              color: NColors.inkSoft,
              onTap: onBack),
          _RoundButton(
              label: '=', color: NColors.numberLine, onTap: onEquals),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) => Expanded(
        child: Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: Gap.sm),
              Expanded(child: children[i]),
            ],
          ],
        ),
      );

  Widget _digit(int d) => _RoundButton(
        label: '$d',
        color: NColors.million,
        onTap: () => onDigit(d),
      );

  Widget _op(String op) => _RoundButton(
        label: op,
        color: NColors.timesTables,
        highlighted: activeOp == op,
        onTap: () => onOp(op),
      );
}

/// A big round, tactile calculator key.
class _RoundButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;

  const _RoundButton({
    this.label,
    this.icon,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    // Flat soft-tinted surface with a dark ink glyph (unified look).
    final bg = widget.color.withAlpha(
        widget.highlighted ? 110 : (_down ? 90 : 48));
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: widget.highlighted
                  ? Border.all(color: widget.color, width: 2.5)
                  : null,
            ),
            child: Center(
              child: widget.icon != null
                  ? Icon(widget.icon, color: NColors.ink, size: 38)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          widget.label!,
                          style: const TextStyle(
                            color: NColors.ink,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
