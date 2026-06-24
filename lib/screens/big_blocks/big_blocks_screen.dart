import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/num_block.dart';
import '../../widgets/scene_background.dart';
import 'big_blocks_notifier.dart';

class BigBlocksScreen extends StatefulWidget {
  const BigBlocksScreen({super.key});

  @override
  State<BigBlocksScreen> createState() => _BigBlocksScreenState();
}

class _BigBlocksScreenState extends State<BigBlocksScreen> {
  final _n = BigBlocksNotifier();
  final _focus = FocusNode();
  Offset _drag = Offset.zero;

  @override
  void dispose() {
    _n.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _move(String dir) async {
    final scoreBefore = _n.score;
    final moved = _n.move(dir);
    if (!moved) return;
    await HapticsService.instance.selection();
    if (_n.score > scoreBefore) {
      await AudioService.instance.playChime(); // a merge happened
    } else {
      await AudioService.instance.playPop();
    }
  }

  void _onPanEnd(DragEndDetails _) {
    const threshold = 16.0;
    if (_drag.distance < threshold) return;
    final dir = _drag.dx.abs() > _drag.dy.abs()
        ? (_drag.dx > 0 ? 'right' : 'left')
        : (_drag.dy > 0 ? 'down' : 'up');
    _move(dir);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    String? dir;
    if (k == LogicalKeyboardKey.arrowUp) dir = 'up';
    if (k == LogicalKeyboardKey.arrowDown) dir = 'down';
    if (k == LogicalKeyboardKey.arrowLeft) dir = 'left';
    if (k == LogicalKeyboardKey.arrowRight) dir = 'right';
    if (dir == null) return KeyEventResult.ignored;
    _move(dir);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RoomHeader(title: 'Big Blocks', color: NColors.bigBlocks),
      body: SceneBackground(
        color: NColors.bigBlocks,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _n,
            builder: (context, _) => Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: Gap.sm),
                    _ScoreBar(notifier: _n),
                    const SizedBox(height: Gap.sm),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Gap.md),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final side =
                                  math.min(c.maxWidth, c.maxHeight).toDouble();
                              return Focus(
                                focusNode: _focus,
                                autofocus: true,
                                onKeyEvent: _onKey,
                                child: GestureDetector(
                                  onTap: () => _focus.requestFocus(),
                                  onPanStart: (_) => _drag = Offset.zero,
                                  onPanUpdate: (d) => _drag += d.delta,
                                  onPanEnd: _onPanEnd,
                                  child: SizedBox(
                                    width: side,
                                    height: side,
                                    child: _Board(notifier: _n),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
                      child: Text(
                        'Swipe to slide the blocks. Same blocks join and double — reach 2048!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: NColors.inkSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (_n.showWin)
                  _Overlay(
                    notifier: _n,
                    win: true,
                  ),
                if (_n.over)
                  _Overlay(
                    notifier: _n,
                    win: false,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ScoreBar extends StatelessWidget {
  final BigBlocksNotifier notifier;
  const _ScoreBar({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      child: Row(
        children: [
          _ScorePill(label: 'SCORE', value: notifier.score),
          const SizedBox(width: Gap.sm),
          _ScorePill(label: 'BEST', value: notifier.best),
          const Spacer(),
          SoftButton(
            color: NColors.bigBlocks,
            width: 56,
            height: 56,
            onTap: notifier.canUndo ? notifier.undo : null,
            child: const Icon(Icons.undo_rounded, size: 26),
          ),
          const SizedBox(width: Gap.sm),
          SoftButton(
            color: NColors.bigBlocks,
            width: 56,
            height: 56,
            onTap: notifier.newGame,
            child: const Icon(Icons.refresh_rounded, size: 28),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int value;
  const _ScorePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(210),
        borderRadius: BorderRadius.circular(Radii.md),
        boxShadow: [
          BoxShadow(
              color: NColors.bigBlocks.withAlpha(28),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: NColors.inkSoft,
                  fontWeight: FontWeight.w700)),
          Text('$value',
              style: const TextStyle(
                  fontSize: 20,
                  color: NColors.ink,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Board extends StatelessWidget {
  final BigBlocksNotifier notifier;
  const _Board({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const n = BigBlocksNotifier.size;
        final boardW = c.maxWidth;
        final gap = boardW * 0.03;
        final cell = (boardW - gap * (n + 1)) / n;
        double pos(int i) => gap + i * (cell + gap);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(235),
            borderRadius: BorderRadius.circular(Radii.md),
            boxShadow: [
              BoxShadow(
                  color: NColors.bigBlocks.withAlpha(45),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(
            children: [
              // Static background cells — their own layer, so the animated
              // layer below holds only keyed tiles (no mixed keyed/un-keyed
              // children, which is what left orphaned "ghost" tiles behind).
              Positioned.fill(
                child: Stack(
                  children: [
                    for (int x = 0; x < n; x++)
                      for (int y = 0; y < n; y++)
                        Positioned(
                          left: pos(x),
                          top: pos(y),
                          width: cell,
                          height: cell,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEEF7),
                              borderRadius: BorderRadius.circular(cell * 0.16),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              // Live tiles — isolated layer, only keyed AnimatedPositioned.
              // RepaintBoundary stops the GPU leaving trails on slower devices.
              Positioned.fill(
                child: RepaintBoundary(
                  child: Stack(
                    children: [
                      for (final t in notifier.tiles)
                        AnimatedPositioned(
                          key: ValueKey(t.id),
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeInOut,
                          left: pos(t.x),
                          top: pos(t.y),
                          width: cell,
                          height: cell,
                          child: _TileBlock(value: t.value, cell: cell),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One block: the app's signature gradient square + face + count, coloured per
/// power-of-two tier. Pops in when it first appears (spawn or merge survivor).
class _TileBlock extends StatefulWidget {
  final int value;
  final double cell;
  const _TileBlock({required this.value, required this.cell});

  @override
  State<_TileBlock> createState() => _TileBlockState();
}

class _TileBlockState extends State<_TileBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
      child: _face(),
    );
  }

  Widget _face() {
    final v = widget.value;
    final cell = widget.cell;
    final color = NColors.mergeBlockColor(v);
    final isWin = v >= BigBlocksNotifier.target;
    final digits = v.toString().length;
    final numSize = cell *
        (digits <= 2
            ? 0.40
            : digits == 3
                ? 0.30
                : digits == 4
                    ? 0.24
                    : 0.20);
    final pad = cell * 0.06;

    return Padding(
      padding: EdgeInsets.all(cell * 0.04),
      child: Container(
        decoration: BoxDecoration(
          gradient: isWin
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF8A80),
                    Color(0xFFFFD740),
                    Color(0xFF69F0AE),
                    Color(0xFF40C4FF),
                    Color(0xFFB388FF),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(color, Colors.white, 0.22)!, color],
                ),
          borderRadius: BorderRadius.circular(cell * 0.16),
          boxShadow: [
            BoxShadow(
              color: (isWin ? Colors.amber : color).withAlpha(isWin ? 150 : 95),
              blurRadius: isWin ? 16 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Signature face on the top-left (same painter as every block).
            Positioned(
              left: pad,
              top: pad,
              child: CustomPaint(
                size: Size(cell * 0.42, cell * 0.42),
                painter: _FaceP(),
              ),
            ),
            // Count on the bottom-right.
            Positioned(
              right: cell * 0.12,
              bottom: cell * 0.08,
              child: Text(
                '$v',
                style: TextStyle(
                  fontSize: numSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                  shadows: const [
                    Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      paintNumberFace(canvas, Offset.zero, size.width);
  @override
  bool shouldRepaint(_FaceP old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

class _Overlay extends StatelessWidget {
  final BigBlocksNotifier notifier;
  final bool win;
  const _Overlay({required this.notifier, required this.win});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(120),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: Container(
              padding: const EdgeInsets.all(Gap.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radii.lg),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 24,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    win ? '🎉 You made 2048!' : 'No more moves',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: NColors.ink),
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    win
                        ? 'You built the biggest block!'
                        : 'Score: ${notifier.score}',
                    style: const TextStyle(
                        fontSize: 15,
                        color: NColors.inkSoft,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: Gap.md),
                  // The crew bounces in to celebrate.
                  SizedBox(
                    height: 44,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          for (int i = 1; i <= 8; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: BouncyNumBlock(
                                  value: i, unit: 9, showSign: false),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (win)
                        SoftButton(
                          color: NColors.bigBlocks,
                          width: 140,
                          height: 56,
                          onTap: notifier.continuePlaying,
                          child: const Text('Keep Going',
                              style: TextStyle(fontSize: 16)),
                        ),
                      if (win) const SizedBox(width: Gap.sm),
                      SoftButton(
                        color: NColors.bigBlocks,
                        width: 140,
                        height: 56,
                        onTap: notifier.newGame,
                        child: const Text('New Game',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
