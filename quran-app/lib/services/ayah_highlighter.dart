/// The three raw-text parts of an ayah around a matched word.
class AyahMatch {
  final String before;
  final String match;
  final String after;
  const AyahMatch(
      {required this.before, required this.match, required this.after});
}

/// Locates a glossary word inside a raw (fully vocalized) ayah so it can be
/// highlighted without altering the Quran text.
///
/// The matching is diacritic-insensitive and mirrors the app's ArabicNormalizer
/// (same tashkeel set + letter unification), but instead of throwing the
/// original indices away it keeps a per-character position map from the
/// normalized string back to the raw ayah. Because normalization here only
/// *drops* characters or does 1:1 letter swaps (never merges or reorders),
/// the map is exact.
///
/// Arabic text lives entirely in the Unicode BMP, so each relevant character is
/// a single UTF-16 code unit — we can index the raw string directly.
class AyahHighlighter {
  AyahHighlighter._();

  // Same combining marks / tatweel that ArabicNormalizer strips.
  static final RegExp _tashkeel = RegExp(
      r'[\u064B-\u065F\u0670\u0653-\u0656\u0640\u06D6-\u06ED]');

  // Same 1:1 letter unification map. Entries mapping to '' are dropped.
  static const Map<String, String> _letterMap = {
    '\u0622': '\u0627', '\u0623': '\u0627', '\u0625': '\u0627',
    '\u0671': '\u0627', '\u0624': '\u0623', '\u0626': '\u0623',
    '\u0629': '\u0647', '\u0649': '\u064A', '\u06D2': '\u064A',
    '\u0655': '', '\u0656': '',
  };

  /// Normalizes a single character (returns '' if it should be dropped).
  static String _mapChar(String ch) {
    if (_tashkeel.hasMatch(ch)) return '';
    return _letterMap[ch] ?? ch;
  }

  /// True if a normalized character is an Arabic letter (for word boundaries).
  static bool _isLetter(String ch) {
    if (ch.isEmpty) return false;
    final code = ch.codeUnitAt(0);
    return (code >= 0x0621 && code <= 0x064A) ||
        (code >= 0x0671 && code <= 0x06D3);
  }

  /// Splits [ayah] into (before, match, after) where `match` is the raw text of
  /// [word] inside the ayah (diacritics preserved). Returns null when there is
  /// no clean match, so callers can render the ayah without a highlight.
  static AyahMatch? split(String ayah, String word) {
    if (ayah.isEmpty || word.isEmpty) return null;

    // Normalized ayah + map from each normalized index to the raw code-unit
    // index it came from.
    final normBuf = StringBuffer();
    final map = <int>[]; // map[i] = code-unit index in `ayah` of norm char i
    for (var i = 0; i < ayah.length; i++) {
      final mapped = _mapChar(ayah[i]);
      if (mapped.isEmpty) continue; // dropped (tashkeel / hamza below)
      normBuf.write(mapped);
      map.add(i);
    }
    final normAyah = normBuf.toString();
    if (normAyah.isEmpty) return null;

    // Normalize the target word.
    final wb = StringBuffer();
    for (var i = 0; i < word.length; i++) {
      wb.write(_mapChar(word[i]));
    }
    final normWord = wb.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normWord.isEmpty) return null;

    // Prefer a whole-word (boundary-aligned) match; fall back to any match.
    final start = _search(normAyah, normWord, boundary: true) ??
        _search(normAyah, normWord);
    if (start == null) return null;

    final endNorm = start + normWord.length; // exclusive (normalized)
    final rawStart = map[start];
    var rawEnd = map[endNorm - 1] + 1; // exclusive (raw code-unit index)
    // Absorb trailing dropped marks (tashkeel) on the last matched letter.
    while (rawEnd < ayah.length && _mapChar(ayah[rawEnd]).isEmpty) {
      rawEnd++;
    }

    return AyahMatch(
      before: ayah.substring(0, rawStart),
      match: ayah.substring(rawStart, rawEnd),
      after: ayah.substring(rawEnd),
    );
  }

  /// Returns the normalized start index of [needle] in [haystack]. When
  /// [boundary] is true, both sides of the match must be non-letters (or the
  /// string edge) so we match a whole word, not a fragment.
  static int? _search(String haystack, String needle, {bool boundary = false}) {
    var from = 0;
    while (true) {
      final idx = haystack.indexOf(needle, from);
      if (idx < 0) return null;
      if (!boundary) return idx;
      final beforeOk = idx == 0 || !_isLetter(haystack[idx - 1]);
      final afterIdx = idx + needle.length;
      final afterOk =
          afterIdx >= haystack.length || !_isLetter(haystack[afterIdx]);
      if (beforeOk && afterOk) return idx;
      from = idx + 1;
    }
  }
}
