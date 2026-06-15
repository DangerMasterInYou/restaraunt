import 'package:flutter/material.dart';

const _accent = Color(0xFFFF6B2C);
const _accentDark = Color(0xFFFF7A3D);
const _gold = Color(0xFFF5A623);

const _lightBg = Color(0xFFF2F4F7);
const _lightSurface = Color(0xFFFFFFFF);
const _lightSurfaceAlt = Color(0xFFE9EDF3);
const _lightInk = Color(0xFF1A1D21);
const _lightOutline = Color(0xFFD3D9E0);

const _darkBg = Color(0xFF121417);
const _darkSurface = Color(0xFF1B1E24);
const _darkSurfaceAlt = Color(0xFF262A31);
const _darkInk = Color(0xFFECEEF1);
const _darkOutline = Color(0xFF3A3F47);

const _radiusCard = 20.0;
const _radiusField = 16.0;
const _radiusButton = 16.0;

class AppGradients {
  const AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A3D), Color(0xFFFF5722)],
  );

  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFB347), Color(0xFFFF7A1A)],
  );

  static const LinearGradient darkSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF23272F), Color(0xFF15171C)],
  );

  static const LinearGradient lightSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBFCFE), Color(0xFFEDF0F5)],
  );

  static LinearGradient glassDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.08),
      Colors.white.withValues(alpha: 0.02),
    ],
  );

  static LinearGradient glassLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.75),
      Colors.white.withValues(alpha: 0.45),
    ],
  );
}

TextTheme _buildTextTheme(Color ink, TextTheme base) {
  Color soft(double a) => ink.withValues(alpha: a);
  return base.copyWith(
    headlineMedium: TextStyle(
      color: ink,
      fontWeight: FontWeight.w800,
      fontSize: 24,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      color: ink,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      color: ink,
      fontWeight: FontWeight.w700,
      fontSize: 19,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      color: ink,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    ),
    titleSmall: TextStyle(
      color: ink,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    bodyLarge: TextStyle(color: ink, fontWeight: FontWeight.w500, fontSize: 16),
    bodyMedium: TextStyle(color: ink, fontWeight: FontWeight.w500, fontSize: 15),
    bodySmall: TextStyle(color: soft(0.7), fontWeight: FontWeight.w500, fontSize: 13),
    labelMedium: TextStyle(color: ink, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(color: soft(0.7), fontWeight: FontWeight.w600, fontSize: 12.5),
  );
}

ThemeData _build({
  required Brightness brightness,
  required ColorScheme scheme,
  required Color bg,
  required Color ink,
  required Color outline,
}) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,

    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: bg,
    primaryColor: scheme.primary,
    dividerColor: outline.withValues(alpha: 0.6),
    textTheme: _buildTextTheme(ink, ThemeData(brightness: brightness).textTheme),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      iconTheme: IconThemeData(color: ink),
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    listTileTheme: ListTileThemeData(iconColor: scheme.primary),
    iconTheme: IconThemeData(color: ink),
    cardTheme: CardThemeData(
      elevation: isDark ? 1 : 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusCard),
        side: BorderSide(color: outline.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,

      color: scheme.surface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? _darkSurfaceAlt.withValues(alpha: 0.6)
          : _lightSurfaceAlt.withValues(alpha: 0.6),
      labelStyle: TextStyle(color: ink.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: ink.withValues(alpha: 0.45)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusField),
        borderSide: BorderSide(color: outline),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusField),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusField),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusField),
        borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusField),
        borderSide: const BorderSide(color: Color(0xFFE5484D), width: 2),
      ),
      prefixIconColor: ink.withValues(alpha: 0.7),
      suffixIconColor: ink.withValues(alpha: 0.7),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shadowColor: scheme.primary.withValues(alpha: 0.4),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusButton),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusButton),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: outline),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusButton),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedColor: scheme.primary,
      side: BorderSide(color: outline),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusCard)),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
    ),
  );
}

final lightTheme = _build(
  brightness: Brightness.light,
  bg: _lightBg,
  ink: _lightInk,
  outline: _lightOutline,
  scheme: const ColorScheme.light(
    primary: _accent,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFE2D1),
    onPrimaryContainer: Color(0xFF5A2300),
    secondary: _gold,
    onSecondary: Color(0xFF3A2600),
    tertiary: _accent,
    surface: _lightSurface,
    onSurface: _lightInk,
    surfaceContainerHighest: _lightSurfaceAlt,
    outline: _lightOutline,
  ),
);

final darkTheme = _build(
  brightness: Brightness.dark,
  bg: _darkBg,
  ink: _darkInk,
  outline: _darkOutline,
  scheme: const ColorScheme.dark(
    primary: _accentDark,
    onPrimary: Color(0xFF1A0E06),
    primaryContainer: Color(0xFF5A2A12),
    onPrimaryContainer: Color(0xFFFFD9C4),
    secondary: Color(0xFFFFC04D),
    onSecondary: Color(0xFF3A2600),
    tertiary: _accentDark,
    surface: _darkSurface,
    onSurface: _darkInk,
    surfaceContainerHighest: _darkSurfaceAlt,
    outline: _darkOutline,
  ),
);
