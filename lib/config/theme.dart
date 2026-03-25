import 'package:flutter/material.dart';

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
    final textTheme = _createManropeTextTheme(colorScheme);

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

  static TextTheme _createManropeTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: Colors.black,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: Colors.black,
      ),
      displaySmall: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: Colors.black,
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: Colors.black,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: Colors.black,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: Colors.black,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: Colors.black,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: Colors.black,
      ),
      titleSmall: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: Colors.black,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: Colors.black,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Colors.black,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Colors.black,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: Colors.black,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: Colors.black,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: Colors.black,
      ),
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }
}
