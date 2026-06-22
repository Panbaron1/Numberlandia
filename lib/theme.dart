import 'package:flutter/material.dart';

class NColors {
  static const bg = Color(0xFFF5F7FF);
  static const surface = Colors.white;
  static const ink = Color(0xFF1A1F36);
  static const inkSoft = Color(0xFF6B7280);
  static const inkMuted = Color(0xFFB0B8C4);

  // Activity accent colors
  static const million    = Color(0xFF4F8EF7); // blue
  static const numberLine = Color(0xFF2DC9A0); // teal
  static const timesTables = Color(0xFFFF8C42);
  static const machine    = Color(0xFFA78BFA);
  static const doubling   = Color(0xFFFF6B9D);
  static const addUp      = Color(0xFF34C759); // green
  static const clock      = Color(0xFF5C6BC0); // indigo
  static const takeAway   = Color(0xFFFF6B6B); // coral red
  static const pop        = Color(0xFF12C2E9); // cyan

  static const primary = million;
  static const zero    = Color(0xFFFFCC00); // gold

  // ── Original NumBlock palette ────────────────────────────────────────────
  // Pastel-soft spectrum — NOT the Numberblocks saturated palette.
  // Each number 0–10 gets its own character colour.
  static const List<Color> numBlock = [
    Color(0xFFB0BEC5), // 0 — cloud grey
    Color(0xFFFF8A80), // 1 — coral
    Color(0xFFFFAB40), // 2 — amber
    Color(0xFFFFD740), // 3 — lemon
    Color(0xFF69F0AE), // 4 — spring green
    Color(0xFF40C4FF), // 5 — sky blue
    Color(0xFF1DE9B6), // 6 — aqua
    Color(0xFFB388FF), // 7 — lavender
    Color(0xFFF48FB1), // 8 — rose
    Color(0xFF7986CB), // 9 — periwinkle
    Color(0xFFFFD600), // 10 — sunflower
  ];

  /// Returns the block colour for any integer n.
  /// 0 → grey, 1–10 → unique, > 10 → cycles through 1–10.
  static Color numBlockColor(int n) {
    if (n == 0) return numBlock[0];
    return numBlock[(n.abs() - 1) % 10 + 1];
  }

  // Gradient stops used for the home-screen wordmark
  static const List<Color> brandGradient = [
    Color(0xFF4F8EF7),
    Color(0xFF2DC9A0),
    Color(0xFFA78BFA),
    Color(0xFFFF6B9D),
  ];
}

class Gap {
  static const xs  = 6.0;
  static const sm  = 10.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 36.0;
  static const xxl = 56.0;
}

class Radii {
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 40.0;
}

ThemeData buildNumberlandiaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NColors.primary,
      surface: NColors.surface,
    ),
    scaffoldBackgroundColor: NColors.bg,
    fontFamily: 'Fredoka',
    cardTheme: const CardThemeData(
      color: NColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Radii.lg)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: NColors.ink,
      titleTextStyle: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: NColors.ink,
      ),
    ),
  );
  // Apply Fredoka across the text theme.
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Fredoka'),
  );
}

int gridColumns(double width) {
  if (width >= 1100) return 4; // wide tablet landscape: 7 cards → 4 + 3
  if (width >= 600) return 3;
  return 2;
}

/// Soft diagonal gradient from an accent colour — used on cards and panels.
LinearGradient softGradient(Color c, {double topAlpha = 0.20, double botAlpha = 0.06}) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      c.withAlpha((topAlpha * 255).round()),
      c.withAlpha((botAlpha * 255).round()),
    ],
  );
}

/// Soft spectrum gradient (blue→teal→lavender→pink) blended toward [tint] and
/// lifted toward white — the same calm backdrop used behind the rooms, so a
/// card's surface matches its room. Characters float on top of this.
LinearGradient spectrumGradient(Color tint) {
  Color soft(Color c) =>
      Color.lerp(Color.lerp(c, Colors.white, 0.66)!, tint, 0.11)!;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: const [
      Color(0xFF4F8EF7),
      Color(0xFF2DC9A0),
      Color(0xFFA78BFA),
      Color(0xFFFF6B9D),
    ].map(soft).toList(),
  );
}

/// Vivid gradient (for solid buttons / headers).
LinearGradient vividGradient(Color c) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.lerp(c, Colors.white, 0.22)!, c],
  );
}
