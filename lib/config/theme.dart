import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    return _buildTheme(Brightness.light);
  }

  static ThemeData dark() {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2F6F5E),
      brightness: brightness,
    );

    // Custom colors: redder red, orange instead of blue, greener green
    final colorScheme = baseScheme.copyWith(
      // Primary: greener green (more saturated, vibrant green)
      primary: brightness == Brightness.light
          ? const Color(0xFF1B9D5F)
          : const Color(0xFF2ECC71),
      onPrimary: brightness == Brightness.light ? Colors.white : Colors.black,
      // Tertiary: orange instead of blue (used for rating 2)
      tertiary: brightness == Brightness.light
          ? const Color(0xFFF5A623)
          : const Color(0xFFFFB74D),
      onTertiary: brightness == Brightness.light ? Colors.black : Colors.black,
      // Error: redder red (more vibrant, pure red)
      error: brightness == Brightness.light
          ? const Color(0xFFE53935)
          : const Color(0xFFEF5350),
      onError: Colors.white,
      errorContainer: brightness == Brightness.light
          ? const Color(0xFFFFEBEE)
          : const Color(0xFFB71C1C),
      onErrorContainer: brightness == Brightness.light
          ? const Color(0xFFB71C1C)
          : const Color(0xFFFFEBEE),
    );
    final baseTextTheme = GoogleFonts.manropeTextTheme();
    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
