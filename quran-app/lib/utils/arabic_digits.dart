// Convert western digits to Arabic-Indic numerals.

const String _east = '٠١٢٣٤٥٦٧٨٩';

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