import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/services/ui_settings_store.dart';
import 'package:quran_app/theme.dart';

void main() {
  test('ui settings round-trip with validation', () {
    const settings = UiSettings(
      theme: ThemeMode.dark,
      numeral: NumeralSystem.western,
      quizScale: 1.2,
      menu: MenuMode.hizb,
      font: 'Rubik',
      preset: 'midnight',
    );
    final restored = UiSettings.fromJson(settings.toJson());
    expect(restored.theme, ThemeMode.dark);
    expect(restored.numeral, NumeralSystem.western);
    expect(restored.quizScale, 1.2);
    expect(restored.menu, MenuMode.hizb);
    expect(restored.font, 'Rubik');
    expect(restored.preset, 'midnight');

    // Garbage in -> safe defaults out (never throws, never out of range).
    final fallback = UiSettings.fromJson(const {
      'theme': 'nope',
      'numeral': 'nope',
      'quizScale': 99,
      'menu': 'nope',
      'font': 'No Such Font',
    });
    expect(fallback.theme, ThemeMode.light);
    expect(fallback.numeral, NumeralSystem.arabicIndic);
    expect(fallback.quizScale, lessThanOrEqualTo(kQuizScaleMax));
    expect(fallback.menu, MenuMode.surah);
    expect(fallback.font, kAppDefaultFont);
    expect(fallback.preset, 'default');
    expect(fallback.preset, 'default');
  });

  test('presets have unique ids and build complete palettes', () {
    final ids = kPalettePresets.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final preset in kPalettePresets) {
      final built = preset.build();
      expect(
        built.toJson().length,
        kPaletteEntries.length,
        reason: preset.id,
      );
    }
  });
}
