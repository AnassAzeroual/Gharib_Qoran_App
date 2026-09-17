import 'package:flutter/material.dart';

const Color appSeed = Color(0xFF0F766E);

/// Global theme-mode notifier so any screen can switch light/dark.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

/// How the main menu is organized: by Surah (default) or by Hizb (60 -> thumun).
enum MenuMode { surah, hizb }

/// Global menu-mode notifier so the header toggle can switch the home menu
/// between the Surah grid and the Hizb list. Not persisted across restarts
/// (mirrors themeModeNotifier).
final ValueNotifier<MenuMode> menuModeNotifier =
    ValueNotifier(MenuMode.surah);

ThemeData _baseTheme(
    Brightness brightness, ColorScheme colorScheme, Color scaffoldColor) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: 'Amiri',
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontFamily: 'Amiri',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

final ThemeData lightTheme = _baseTheme(
  Brightness.light,
  ColorScheme.fromSeed(
    seedColor: appSeed,
    primary: appSeed,
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF1E293B),
  ),
  const Color(0xFFF6F3EC),
);

final ThemeData darkTheme = _baseTheme(
  Brightness.dark,
  ColorScheme.fromSeed(
    seedColor: appSeed,
    brightness: Brightness.dark,
    primary: const Color(0xFF2DD4BF),
    surface: const Color(0xFF101418),
    onSurface: const Color(0xFFEDE9E2),
  ),
  const Color(0xFF0D0B08),
);