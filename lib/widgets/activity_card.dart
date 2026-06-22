import 'package:flutter/material.dart';
import '../theme.dart';

class ActivityCard extends StatefulWidget {
  final String title;
  final String assetImage;
  final Color color;
  final bool live;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.title,
    required this.assetImage,
    required this.color,
    required this.live,
    this.onTap,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.live ? (_) => setState(() => _down = true) : null,
      onTapUp: widget.live ? (_) => setState(() => _down = false) : null,
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.live ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: widget.live ? 1.0 : 0.6,
          child: Container(
            decoration: BoxDecoration(
              color: NColors.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: widget.color.withAlpha(70), width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Spectrum surface with the characters floating on it ──
                Expanded(
                  flex: 7,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: spectrumGradient(widget.color),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Gap.md),
                      child: Image.asset(widget.assetImage, fit: BoxFit.contain),
                    ),
                  ),
                ),
                // ── Title strip ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: widget.color,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Gap.sm, vertical: Gap.sm),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      if (!widget.live)
                        const Text(
                          'Coming soon',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
