import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/main.dart';

void main() {
  testWidgets('App builds and shows the search field', (WidgetTester tester) async {
    await tester.pumpWidget(const QuranApp());
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
}