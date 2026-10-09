import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/theme.dart';

void main() {
  test('palette defaults match entry fallbacks and survive a round-trip', () {
    final palette = AppPalette.defaults();
    for (final entry in kPaletteEntries) {
      expect(
        palette.valueOf(entry.key).toARGB32(),
        entry.fallback.toARGB32(),
        reason: entry.key,
      );
    }

    final restored = AppPalette.fromJson(palette.toJson());
    for (final entry in kPaletteEntries) {
      expect(
        restored.valueOf(entry.key).toARGB32(),
        entry.fallback.toARGB32(),
        reason: entry.key,
      );
    }

    // Unknown/missing keys must fall back to defaults instead of throwing.
    final partial = AppPalette.fromJson(const {'seed': 0xFF000000});
    expect(partial.seed.toARGB32(), 0xFF000000);
    expect(
      partial.gold.toARGB32(),
      AppPalette.defaults().gold.toARGB32(),
    );
  });
}
