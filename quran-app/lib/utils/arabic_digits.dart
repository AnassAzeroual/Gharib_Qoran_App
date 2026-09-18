// Convert western digits to Arabic-Indic numerals.

import '../theme.dart';

const String _east = '٠١٢٣٤٥٦٧٨٩';

/// Formats [value] for display using the app-wide numeral system selected in
/// [numeralNotifier]: Arabic-Indic (١٢٣, default) or Western (123).
String displayNumber(int value) =>
    numeralNotifier.value == NumeralSystem.western
        ? value.toString()
        : toArabicDigits(value);

String toArabicDigits(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (final ch in s.split('')) {
    if (ch == '-') {
      buffer.write('-');
    } else {
      buffer.write(_east[ch.codeUnitAt(0) - 0x30]);
    }
  }
  return buffer.toString();
}