import 'package:flutter/material.dart';

class DesignSystem {
  // Colors
  static const Color primaryBlue = Color(0xFF1E5EFF); // #1E5EFF
  static const Color secondaryBlue = Color(0xFFE8F0FF);
  static const Color darkText = Color(0xFF1F2937);
  static const Color lightText = Color(0xFF6B7280);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color background = Color(0xFFFFFFFF);

  // Spacing
  static const double spacing = 16.0;

  // Corner radius
  static const double cardRadius = 14.0;
  static const double buttonRadius = 12.0;

  // Color helpers
  static Color alpha(Color c, double opacity) {
    final a = (opacity * 255).round() & 0xFF;
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return Color.fromARGB(a, r, g, b);
  }

  // Typography
  static final TextTheme textTheme = const TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
    bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: darkText),
    bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: lightText),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
  );

  static final ThemeData theme = ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    primaryColor: primaryBlue,
    colorScheme: ColorScheme.light(primary: primaryBlue, surface: background, secondary: secondaryBlue),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      elevation: 1,
      backgroundColor: background,
      foregroundColor: darkText,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        elevation: 3,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius))),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
