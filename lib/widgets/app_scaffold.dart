import 'package:flutter/material.dart';
import '../theme.dart';

/// A large, obvious circular back button for child users (64dp target).
class BigBackButton extends StatelessWidget {
  final Color color;
  const BigBackButton({super.key, this.color = NColors.ink});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Gap.sm),
      child: Material(
        color: NColors.surface,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: color.withAlpha(60),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.arrow_back_rounded, color: color, size: 30),
          ),
        ),
      ),
    );
  }
}

/// A coloured room header bar: big back button, title, and a hero image badge.
/// Replaces the plain AppBar to fill the top of each room with spectrum colour.
class RoomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color color;
  final String? assetImage; // optional hero icon on the right
  final List<Widget> actions;

  const RoomHeader({
    super.key,
    required this.title,
    required this.color,
    this.assetImage,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
        child: Row(
          children: [
            const BigBackButton(),
            const SizedBox(width: Gap.sm),
            if (assetImage != null) ...[
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: softGradient(color, topAlpha: 0.28, botAlpha: 0.12),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Image.asset(assetImage!),
              ),
              const SizedBox(width: Gap.sm),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// The app's unified button — a flat, soft-tinted rounded rectangle with an
/// accent-coloured glyph (the Times Tables look). Calm, high-contrast, and
/// dims briefly on press. Disabled state uses a muted grey.
class SoftButton extends StatefulWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final double height;
  final double? width;
  final double radius;

  const SoftButton({
    super.key,
    required this.child,
    required this.color,
    required this.onTap,
    this.height = 64,
    this.width,
    this.radius = Radii.md,
  });

  @override
  State<SoftButton> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<SoftButton> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final bg = enabled
        ? widget.color.withAlpha(_down ? 90 : 48)
        : NColors.inkMuted.withAlpha(26);
    // Dark ink glyphs for legibility on the soft tint (Spectroom-style).
    final fg = enabled ? NColors.ink : NColors.inkMuted;

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontFamily: 'Fredoka',
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: fg),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
