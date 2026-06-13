import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/num_block.dart';
import 'number_line_notifier.dart';
import 'number_line_painter.dart';

class NumberLineScreen extends StatefulWidget {
  const NumberLineScreen({super.key});

  @override
  State<NumberLineScreen> createState() => _NumberLineScreenState();
}

class _NumberLineScreenState extends State<NumberLineScreen> {
  final _notifier = NumberLineNotifier();
  static const double _pixelsPerUnit = 80.0;
  int _lastFeedback = 0;

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _step(int delta) async {
    _notifier.step(delta);
    await HapticsService.instance.selection();
    await AudioService.instance.playPop();
  }

  Future<void> _jumpToZero() async {
    _notifier.jumpTo(0);
    await HapticsService.instance.medium();
    await AudioService.instance.playPop();
  }

  Future<void> _onPanUpdate(DragUpdateDetails d) async {
    final prev = _notifier.current;
    _notifier.pan(-d.delta.dx / _pixelsPerUnit);
    if (_notifier.current != prev && _notifier.current != _lastFeedback) {
      _lastFeedback = _notifier.current;
      await HapticsService.instance.light();
    }
  }

  void _onPanEnd(DragEndDetails _) => _notifier.snapToCurrent();

  void _onTapDown(TapDownDetails d, double canvasWidth) {
    final dx = d.localPosition.dx - canvasWidth / 2;
    final tapped = (_notifier.viewOffset + dx / _pixelsPerUnit)
        .round()
        .clamp(NumberLineNotifier.minValue, NumberLineNotifier.maxValue);
    _notifier.jumpTo(tapped);
    HapticsService.instance.medium();
    AudioService.instance.playPop();
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
        title: const Text('Number Line',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: TextButton(
              onPressed: _jumpToZero,
              child: const Text('Go to 0',
                  style: TextStyle(
                      color: NColors.zero,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _notifier,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              _FactsPanel(notifier: _notifier),
              // ── Number line canvas ─────────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) => GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTapDown: (d) => _onTapDown(d, constraints.maxWidth),
                    child: CustomPaint(
                      painter: NumberLinePainter(
                        viewOffset: _notifier.viewOffset,
                        current: _notifier.current,
                        pixelsPerUnit: _pixelsPerUnit,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  ),
                ),
              ),
              // ── Step controls ──────────────────────────────────────
              _StepControls(onStep: _step),
              const SizedBox(height: Gap.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FactsPanel extends StatelessWidget {
  final NumberLineNotifier notifier;
  const _FactsPanel({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final n = notifier.current;
    final abs = n.abs();
    final showBlock = abs <= 9; // NumBlock for single-digit range

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 0),
      child: Column(
        children: [
          // ── Big number + optional NumBlock ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showBlock) ...[
                NumBlock(value: n, unit: 22, showSign: false),
                const SizedBox(width: Gap.sm),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 110),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  n.toString(),
                  key: ValueKey(n),
                  style: TextStyle(
                    fontSize: showBlock ? 64 : 80,
                    fontWeight: FontWeight.w900,
                    color: n == 0
                        ? NColors.zero
                        : (n < 0 ? NColors.numberLine : NColors.ink),
                    letterSpacing: -3,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          // ── Fact chips ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(
                  label: 'One less',
                  value: notifier.prevNum.toString(),
                  color: NColors.numberLine),
              const SizedBox(width: Gap.sm),
              _Chip(
                  label: notifier.isEven ? 'Even' : 'Odd',
                  value: notifier.isEven ? 'Even' : 'Odd',
                  color: NColors.machine),
              const SizedBox(width: Gap.sm),
              _Chip(
                  label: 'One more',
                  value: notifier.nextNum.toString(),
                  color: NColors.million),
            ],
          ),
          const SizedBox(height: Gap.sm),
          // ── Drag hint ────────────────────────────────────────────────
          const Text(
            'Drag • Tap a number • Use buttons below',
            style: TextStyle(
                fontSize: 11, color: NColors.inkSoft, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: NColors.inkSoft, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StepControls extends StatelessWidget {
  final Future<void> Function(int) onStep;
  const _StepControls({required this.onStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, 0),
      child: Row(
        children: [
          _Btn(label: '−100', delta: -100, color: NColors.numberLine.withAlpha(180), onTap: onStep),
          const SizedBox(width: Gap.xs),
          _Btn(label: '−10', delta: -10, color: NColors.numberLine.withAlpha(210), onTap: onStep),
          const SizedBox(width: Gap.xs),
          _Btn(label: '−1', delta: -1, color: NColors.numberLine, onTap: onStep, big: true),
          const SizedBox(width: Gap.xs),
          _Btn(label: '+1', delta: 1, color: NColors.million, onTap: onStep, big: true),
          const SizedBox(width: Gap.xs),
          _Btn(label: '+10', delta: 10, color: NColors.million.withAlpha(210), onTap: onStep),
          const SizedBox(width: Gap.xs),
          _Btn(label: '+100', delta: 100, color: NColors.million.withAlpha(180), onTap: onStep),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final int delta;
  final Color color;
  final Future<void> Function(int) onTap;
  final bool big;

  const _Btn({
    required this.label,
    required this.delta,
    required this.color,
    required this.onTap,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: big ? 2 : 1,
      child: SizedBox(
        height: big ? 68 : 52,
        child: FilledButton(
          onPressed: () => onTap(delta),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            textStyle: TextStyle(
              fontSize: big ? 20 : 13,
              fontWeight: FontWeight.w800,
            ),
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
