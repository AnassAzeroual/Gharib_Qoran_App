import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Persisted UI settings (theme mode, numerals, quiz font scale, menu mode,
/// app font, active preset). Loaded once at startup into the global
/// notifiers; every later change is saved back automatically via listeners,
/// so all existing call sites keep working untouched.
class UiSettings {
  final ThemeMode theme;
  final NumeralSystem numeral;
  final double quizScale;
  final MenuMode menu;
  final String font;
  final String preset;

  const UiSettings({
    required this.theme,
    required this.numeral,
    required this.quizScale,
    required this.menu,
    required this.font,
    required this.preset,
  });

  factory UiSettings.defaults() => const UiSettings(
    theme: ThemeMode.light,
    numeral: NumeralSystem.arabicIndic,
    quizScale: 1.0,
    menu: MenuMode.surah,
    font: kAppDefaultFont,
    preset: 'default',
  );

  static UiSettings snapshot() => UiSettings(
    theme: themeModeNotifier.value,
    numeral: numeralNotifier.value,
    quizScale: quizFontScaleNotifier.value,
    menu: menuModeNotifier.value,
    font: fontFamilyNotifier.value,
    preset: activePresetIdNotifier.value,
  );

  Map<String, dynamic> toJson() => {
    'theme': theme == ThemeMode.dark ? 'dark' : 'light',
    'numeral': numeral == NumeralSystem.western ? 'western' : 'arabicIndic',
    'quizScale': quizScale,
    'menu': menu == MenuMode.hizb ? 'hizb' : 'surah',
    'font': font,
    'preset': preset,
  };

  factory UiSettings.fromJson(Map<String, dynamic> json) {
    double scale = (json['quizScale'] as num?)?.toDouble() ?? 1.0;
    scale = scale.clamp(kQuizScaleMin, kQuizScaleMax);
    final font = json['font'] as String?;
    final preset = json['preset'] as String?;
    return UiSettings(
      theme: json['theme'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
      numeral: json['numeral'] == 'western'
          ? NumeralSystem.western
          : NumeralSystem.arabicIndic,
      quizScale: scale,
      menu: json['menu'] == 'hizb' ? MenuMode.hizb : MenuMode.surah,
      font:
          (font != null && kAppFonts.any((f) => f.family == font))
              ? font
              : kAppDefaultFont,
      preset:
          (preset != null &&
              (preset == 'custom' ||
                  kPalettePresets.any((p) => p.id == preset)))
          ? preset
          : 'default',
    );
  }
}

class UiSettingsStore {
  UiSettingsStore._();

  static const String storageKey = 'ui_settings_v1';
  static bool _listening = false;

  /// Loads stored settings into the global notifiers, then attaches
  /// persistence listeners. Safe to call once at startup.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final settings =
            UiSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        themeModeNotifier.value = settings.theme;
        numeralNotifier.value = settings.numeral;
        quizFontScaleNotifier.value = settings.quizScale;
        menuModeNotifier.value = settings.menu;
        fontFamilyNotifier.value = settings.font;
        activePresetIdNotifier.value = settings.preset;
      }
    } catch (_) {
      // Corrupt storage is ignored — the app keeps working with defaults.
    }
    if (_listening) return;
    _listening = true;
    void persist() {
      SharedPreferences.getInstance().then(
        (prefs) =>
            prefs.setString(storageKey, jsonEncode(UiSettings.snapshot().toJson())),
      );
    }

    themeModeNotifier.addListener(persist);
    numeralNotifier.addListener(persist);
    quizFontScaleNotifier.addListener(persist);
    menuModeNotifier.addListener(persist);
    fontFamilyNotifier.addListener(persist);
    activePresetIdNotifier.addListener(persist);
  }
}
