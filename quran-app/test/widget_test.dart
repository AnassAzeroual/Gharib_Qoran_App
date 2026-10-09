import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/main.dart';
import 'package:quran_app/services/data_service.dart';

void main() {
  testWidgets('App builds and shows the search field', (
    WidgetTester tester,
  ) async {
    // Widget tests run inside FakeAsync, where loading the multi-MB
    // search_index.json via rootBundle never resolves. Preload everything
    // in real async instead; the (now idempotent) loaders make the app's
    // own startup load return immediately.
    await tester.runAsync(() async {
      final data = DataService.instance;
      await data.loadIndex();
      await data.buildSearchIndex();
      await data.loadHizbMenu();
    });
    await tester.pumpWidget(const QuranApp());
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
}
