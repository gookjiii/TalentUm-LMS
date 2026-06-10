import 'package:flutter/material.dart';

class SwTheme {
  SwTheme._();

  // Premium, desaturated palette
  static const Color primary = Color(0xFF09090B); // Zinc 950
  static const Color primaryForeground = Color(0xFFFAFAFA); // Zinc 50
  
  static const Color secondary = Color(0xFFF4F4F5); // Zinc 100
  static const Color secondaryForeground = Color(0xFF18181B); // Zinc 900
  
  static const Color accent = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color success = Color(0xFF10B981); // Emerald 500

  static const Color background = Color(0xFFF9FAFB); // Gray 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E4E7); // Zinc 200

  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF71717A); // Zinc 500

  // Diffusion shadow for Bento cards
  static const List<BoxShadow> diffusionShadow = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      offset: Offset(0, 20),
      blurRadius: 40,
      spreadRadius: -15,
    ),
  ];

  static ThemeData lightTheme() => ThemeData(
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: primaryForeground,
      secondary: secondary,
      onSecondary: secondaryForeground,
      surface: surface,
      background: background,
      error: error,
      outline: border,
    ),
    scaffoldBackgroundColor: background,
    useMaterial3: true,
    dividerTheme: const DividerThemeData(
      color: border,
      space: 1,
      thickness: 1,
    ),
  );
}
