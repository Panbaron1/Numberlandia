import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import 'number_line_notifier.dart';
import 'number_line_painter.dart';

class NumberLineScreen extends StatefulWidget {
  const NumberLineScreen({super.key});

  @override
  State<NumberLineScreen> createState() => _NumberLineScreenState();
}

class _NumberLineScreenState extends State<NumberLineScreen> {
  final _notifier = NumberLineNotifier();

  // px per integer unit — determines zoom level
  static const double _pixelsPerUnit = 80.0;

  int _lastFeedbackNumber = 0;

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

  Future<void> _onPanUpdate(DragUpdateDetails details) async {
    // Convert pixel delta to number-space delta (inverted: drag right = lower numbers)
    final numberDelta = -details.delta.dx / _pixelsPerUnit;
    final prevNumber = _notifier.current;
    _notifier.pan(numberDelta);

    // Haptic tick each time the current number changes while dragging
    if (_notifier.current != prevNumber &&
        _notifier.current != _lastFeedbackNumber) {
      _lastFeedbackNumber = _notifier.current;
      await HapticsService.instance.light();
    }
  }

  void _onPanEnd(DragEndDetails _) => _notifier.snapToCurrent();

  // Compute which integer the user tapped on the painter canvas
  void _onTapDown(TapDownDetails details, double canvasWidth) {
    final centerX = canvasWidth / 2;
    final dx = details.localPosition.dx - centerX;
    final tapped = (_notifier.viewOffset + dx / _pixelsPerUnit).round();
    final clamped =
        tapped.clamp(NumberLineNotifier.minValue, NumberLineNotifier.maxValue);
    _notifier.jumpTo(clamped);
    HapticsService.instance.medium();
    AudioService.instance.playPop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          iconSize: 28,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Number Line'),
      ),
      body: AnimatedBuilder(
        animation: _notifier,
        builder: (context, _) {
          return SafeArea(
            child: Column(
              children: [
                // ── Facts panel ─────────────────────────────────────
                _FactsPanel(notifier: _notifier),
                const SizedBox(height: Gap.md),

                // ── Number line canvas ───────────────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTapDown: (d) =>
                            _onTapDown(d, constraints.maxWidth),
                        child: CustomPaint(
                          painter: NumberLinePainter(
                            viewOffset: _notifier.viewOffset,
                            current: _notifier.current,
                            pixelsPerUnit: _pixelsPerUnit,
                          ),
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      );
                    },
                  ),
                ),

                // ── Step controls ────────────────────────────────────
                _StepControls(onStep: _step),
                const SizedBox(height: Gap.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _FactsPanel extends StatelessWidget {
  final NumberLineNotifier notifier;
  const _FactsPanel({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final n = notifier.current;
    final isZero = n == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, 0),
      child: Column(
        children: [
          // Current number — large
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Text(
              n.toString(),
              key: ValueKey(n),
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w800,
                color: isZero ? NColors.zero : NColors.ink,
                letterSpacing: -3,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: Gap.md),
          // Fact row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Fact(
                  label: 'One less',
                  value: notifier.prevNum.toString(),
                  color: NColors.numberLine),
              const SizedBox(width: Gap.md),
              _Fact(
                  label: notifier.isEven ? 'Even' : 'Odd',
                  value: notifier.isEven ? '2️⃣' : '1️⃣',
                  color: NColors.machine),
              const SizedBox(width: Gap.md),
              _Fact(
                  label: 'One more',
                  value: notifier.nextNum.toString(),
                  color: NColors.million),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Fact(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(
          horizontal: Gap.md, vertical: Gap.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: NColors.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _StepControls extends StatelessWidget {
  final Future<void> Function(int) onStep;
  const _StepControls({required this.onStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        children: [
          _StepBtn(label: '−10', delta: -10, onTap: onStep),
          const SizedBox(width: Gap.sm),
          _StepBtn(label: '−1', delta: -1, onTap: onStep, big: true),
          const SizedBox(width: Gap.sm),
          _StepBtn(label: '+1', delta: 1, onTap: onStep, big: true),
          const SizedBox(width: Gap.sm),
          _StepBtn(label: '+10', delta: 10, onTap: onStep),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final String label;
  final int delta;
  final Future<void> Function(int) onTap;
  final bool big;

  const _StepBtn({
    required this.label,
    required this.delta,
    required this.onTap,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = big ? 72.0 : 56.0;
    final color = delta < 0 ? NColors.numberLine : NColors.million;

    return Expanded(
      flex: big ? 2 : 1,
      child: SizedBox(
        height: h,
        child: FilledButton(
          onPressed: () => onTap(delta),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            textStyle: TextStyle(
              fontSize: big ? 22 : 16,
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
