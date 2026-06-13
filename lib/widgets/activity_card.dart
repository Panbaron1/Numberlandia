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
      opacity: live ? 1.0 : 0.55,
      child: Material(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(Radii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: live ? onTap : _handleComingSoon,
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withAlpha(48),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: Gap.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: live ? NColors.ink : NColors.inkSoft,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (!live) ...[
                  const SizedBox(height: Gap.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: NColors.inkSoft.withAlpha(24),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: const Text(
                      'Coming soon',
                      style: TextStyle(
                        color: NColors.inkSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Silently absorb tap — no error, no scary feedback
  void _handleComingSoon() {}
}
