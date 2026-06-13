import 'package:flutter/material.dart';

class NColors {
  static const bg = Color(0xFFF5F7FF);
  static const surface = Colors.white;
  static const ink = Color(0xFF1A1F36);
  static const inkSoft = Color(0xFF6B7280);

  // Activity card accent colors
  static const million = Color(0xFF4F8EF7);    // blue
  static const numberLine = Color(0xFF2DC9A0); // teal
  static const timesTables = Color(0xFFFF8C42);
  static const machine = Color(0xFFA78BFA);
  static const doubling = Color(0xFFFF6B9D);

  static const primary = million;
  static const zero = Color(0xFFFFCC00);       // gold for zero on number line
}

class Gap {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 36.0;
  static const xxl = 56.0;
}

class Radii {
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 40.0;
}

ThemeData buildNumberlandiaTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NColors.primary,
      surface: NColors.surface,
    ),
    scaffoldBackgroundColor: NColors.bg,
    fontFamily: 'sans-serif',
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
    ),
  );
}

// Responsive grid columns
int gridColumns(double width) {
  if (width >= 900) return 3;
  if (width >= 600) return 3;
  return 2;
}
