/// Arabic text normalization for search.
///
/// The JSON already ships `*_normalized` fields, but we apply the same
/// normalization to the user's query so a search with or without
/// tashkeel/diacritics finds the same results.
class ArabicNormalizer {
  ArabicNormalizer._();

  static final RegExp _tashkeel = RegExp(
      r'[\u064B-\u065F\u0670\u0653-\u0656\u0640\u06D6-\u06ED]');

  static final Map<String, String> _letterMap = {
    '\u0622': '\u0627', '\u0623': '\u0627', '\u0625': '\u0627',
    '\u0671': '\u0627', '\u0624': '\u0623', '\u0626': '\u0623',
    '\u0629': '\u0647', '\u0649': '\u064A', '\u06D2': '\u064A',
    '\u0655': '', '\u0656': '',
  };

  /// Strips tashkeel, unifies alef variants, ta marbuta -> ha, alef maqsura -> ya.
  static String normalize(String input) {
    if (input.isEmpty) return input;
    var out = input.replaceAll(_tashkeel, '');
    final buffer = StringBuffer();
    for (final rune in out.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_letterMap[ch] ?? ch);
    }
    out = buffer.toString();
    // Collapse repeated whitespace and trim
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    return out;
  }
}