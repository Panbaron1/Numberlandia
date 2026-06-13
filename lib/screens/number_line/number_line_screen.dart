import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
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
      appBar: RoomHeader(
        title: 'Number Line',
        color: NColors.numberLine,
        assetImage: 'assets/cards/numberline.png',
        actions: [
          ChunkyButton(
            color: NColors.zero,
            onTap: _jumpToZero,
            height: 48,
            width: 92,
            child: const Text('Go to 0', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: Gap.sm),
        ],
      ),
      body: AnimatedBuilder(
        animation: _notifier,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              _FactsPanel(notifier: _notifier),
              // ── Numberblock view (scales to 100×100 = 10,000) ──────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Gap.lg, vertical: Gap.sm),
                  child: NumBlockView(value: _notifier.current),
                ),
              ),
              // ── Thick colourful slider ─────────────────────────────
              SizedBox(
                height: 120,
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
              const SizedBox(height: Gap.lg),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.md, 0),
      child: Column(
        children: [
          // ── Big current number ──────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 110),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              n.toString(),
              key: ValueKey(n),
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w800,
                color: n == 0
                    ? NColors.zero
                    : (n < 0 ? NColors.numberLine : NColors.ink),
                letterSpacing: -2,
                height: 1,
              ),
            ),
          ),
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
      child: ChunkyButton(
        color: color,
        onTap: () => onTap(delta),
        height: big ? 76 : 60,
        radius: Radii.md,
        child: Text(label,
            style: TextStyle(fontSize: big ? 24 : 15)),
      ),
    );
  }
}
