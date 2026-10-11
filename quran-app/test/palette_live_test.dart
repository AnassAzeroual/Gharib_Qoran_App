import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/main.dart';
import 'package:quran_app/services/data_service.dart';

/// Palette changes must repaint live — including routes covered by other
/// routes (ancestor rebuilds from main.dart stop at Navigator entries, so
/// every screen subscribes directly via PaletteLive).
void main() {
  testWidgets('covered home header follows palette without navigating', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      final data = DataService.instance;
      await data.loadIndex();
      await data.buildSearchIndex();
      await data.loadHizbMenu();
    });
    await tester.pumpWidget(const QuranApp());
    await tester.pumpAndSettle();

    bool headerHas(int argb) {
      for (final e in find.byType(Container).evaluate()) {
        final d = (e.widget as Container).decoration;
        if (d is BoxDecoration && d.gradient is LinearGradient) {
          if ((d.gradient as LinearGradient).colors.any(
            (x) => x.toARGB32() == argb,
          )) {
            return true;
          }
        }
      }
      return false;
    }

    // Cover home with settings + the color editor, change the color there.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    // Individual rows live under the collapsed advanced editor.
    await tester.ensureVisible(find.text('تخصيص متقدم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تخصيص متقدم'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('الرئيسية (بداية)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الرئيسية (بداية)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('swatch_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();

    // Back home WITHOUT any palette change in between: it must be fresh.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(headerHas(0xFFFCD34D), isTrue);
  });
}
