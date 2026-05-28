import 'package:flutter/material.dart';

class SwTheme {
  SwTheme._();

  static const Color primary = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF7B1FA2);
  static const Color accent = Color(0xFFFFC107);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF212121);
  static const Color onSurface = Color(0xFF212121);

  static ThemeData lightTheme() => ThemeData(
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      error: error,
    ),
    useMaterial3: true,
  );
}
