import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryIndigo = Color(0xFF2B1B4B);
  static const Color gold = Color(0xFFEFB810);
  static const Color primaryColor = Color(0xFFEFB810);
  static const Color cream = Color(0xFFF7F4EA);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: const ColorScheme.light(
      primary: primaryIndigo,
      secondary: gold,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: gold,
      foregroundColor: primaryIndigo,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: primaryIndigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // Adaptive colors
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? gold
        : primaryIndigo;
  }
}
