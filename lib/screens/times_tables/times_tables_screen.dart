import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import 'times_tables_notifier.dart';

class TimesTablesScreen extends StatefulWidget {
  const TimesTablesScreen({super.key});

  @override
  State<TimesTablesScreen> createState() => _TimesTablesScreenState();
}

class _TimesTablesScreenState extends State<TimesTablesScreen> {
  final _n = TimesTablesNotifier();

  Future<void> _feedback() async {
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
      appBar: const RoomHeader(
        title: 'Times Tables',
        color: NColors.timesTables,
        assetImage: 'assets/cards/timestables.png',
      ),
      body: AnimatedBuilder(
        animation: _n,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: Gap.sm),
              _EquationRow(notifier: _n),
              const SizedBox(height: Gap.sm),
              // ── Array (painter — scales to 100×100 = 10,000) ─────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  child: GestureDetector(
                    onTapDown: (_) => _feedback(),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: TimesArrayPainter(
                        rows: _n.a,
                        cols: _n.b,
                        color: NColors.numBlockColor(_n.a),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Gap.sm),
              // ── Sliders ──────────────────────────────────────────────
              _AxisSlider(
                label: 'Rows (down)',
                value: _n.a,
                color: NColors.numBlockColor(_n.a),
                onChanged: _n.setA,
                onStep: _n.stepA,
              ),
              _AxisSlider(
                label: 'Columns (across)',
                value: _n.b,
                color: NColors.timesTables,
                onChanged: _n.setB,
                onStep: _n.stepB,
              ),
              const SizedBox(height: Gap.md),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          _BigNum('${notifier.a}', aColor),
          const _Op('×'),
          _BigNum('${notifier.b}', NColors.timesTables),
          const _Op('='),
          _BigNum('${notifier.product}', NColors.ink),
        ],
      ),
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
        key: ValueKey('$text$color'),
        style: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -1,
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
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: NColors.inkSoft,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Draws an A×B array of squares, fit to the available box and centred.
/// Pure canvas — renders 10,000 cells (100×100) with no widget overhead.
class TimesArrayPainter extends CustomPainter {
  final int rows;
  final int cols;
  final Color color;

  const TimesArrayPainter({
    required this.rows,
    required this.cols,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || cols <= 0) return;

    // Gap shrinks as the grid grows so dense arrays stay readable.
    final density = rows * cols;
    final gap = density > 400 ? 1.0 : (density > 100 ? 2.0 : 4.0);

    final cell = _cellSize(size, gap);
    final gridW = cols * cell + (cols - 1) * gap;
    final gridH = rows * cell + (rows - 1) * gap;
    final ox = (size.width - gridW) / 2;
    final oy = (size.height - gridH) / 2;

    final radius = Radius.circular(cell * 0.2);
    final fill = Paint()..color = color;
    final rounded = cell > 5;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = ox + c * (cell + gap);
        final y = oy + r * (cell + gap);
        final rect = Rect.fromLTWH(x, y, cell, cell);
        if (rounded) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), fill);
        } else {
          canvas.drawRect(rect, fill);
        }
      }
    }

    // Friendly face on the top-left cell when it's big enough to read.
    if (cell >= 22) {
      paintNumberFace(canvas, Offset(ox, oy), cell);
    }
  }

  double _cellSize(Size size, double gap) {
    final byW = (size.width - (cols - 1) * gap) / cols;
    final byH = (size.height - (rows - 1) * gap) / rows;
    return byW < byH ? byW : byH;
  }

  @override
  bool shouldRepaint(TimesArrayPainter old) =>
      old.rows != rows || old.cols != cols || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────

class _AxisSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;
  final void Function(int) onStep;

  const _AxisSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        children: [
          // Label + current value
          SizedBox(
            width: 132,
            child: Row(
              children: [
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text('$value',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: NColors.inkSoft,
                          fontWeight: FontWeight.w500),
                      maxLines: 2),
                ),
              ],
            ),
          ),
          _StepIcon(icon: Icons.remove, color: color, onTap: () => onStep(-1)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withAlpha(40),
                overlayColor: color.withAlpha(30),
                trackHeight: 6,
              ),
              child: Slider(
                value: value.toDouble(),
                min: TimesTablesNotifier.min.toDouble(),
                max: TimesTablesNotifier.max.toDouble(),
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          _StepIcon(icon: Icons.add, color: color, onTap: () => onStep(1)),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StepIcon(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
