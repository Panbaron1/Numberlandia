import 'package:flutter/material.dart';
import '../theme.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;
  final bool live;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.live,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: live ? 1.0 : 0.6,
      child: Material(
        color: NColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: live ? onTap : null, // silently no-op for coming-soon
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: color.withAlpha(40), width: 1.5),
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Coloured header ──────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withAlpha(220),
                          color,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
                // ── White label area ─────────────────────────────────
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.sm, vertical: Gap.xs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: live ? NColors.ink : NColors.inkSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        if (!live) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Text(
                              'Coming soon',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
