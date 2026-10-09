import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/models/quiz_word.dart';
import 'package:quran_app/services/data_service.dart';
import 'package:quran_app/services/quiz_service.dart';

/// Guards the book order: word lists must follow the original page-JSON
/// glossary order (pages ascending, surah sections grouped as in the book),
/// never a re-sorted (page, ayah) order that interleaves same-page surahs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('thumun word order matches the original page JSON order', () async {
    final data = DataService.instance;
    await data.loadIndex();
    await data.buildSearchIndex();

    // Independent oracle straight from the raw page JSONs (DataService is
    // not involved in building this map).
    final expected = <int, List<String>>{};
    for (final page in data.availablePages) {
      final raw = await rootBundle.loadString(DataService.pageJsonPath(page));
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final sections =
          (decoded['page'] as Map<String, dynamic>)['sections'] as List;
      for (final section in sections) {
        if ((section as Map)['type'] != 'surah_section') continue;
        for (final entry in (section['glossary'] as List)) {
          final thumun = (entry as Map)['thumun'];
          if (thumun == null) continue;
          expected
              .putIfAbsent(thumun as int, () => [])
              .add(entry['word'] as String? ?? '');
        }
      }
    }

    expect(expected.length, greaterThan(400));
    for (final entry in expected.entries) {
      final actual =
          data.glossaryByThumun(entry.key).map((w) => w.word).toList();
      expect(actual, entry.value, reason: 'thumun ${entry.key} order');
    }
  });

  test('scoped quiz lists preserve primed book order', () {
    QuizWord qw(String word, {int surah = 105, int? ayah, int? thumun}) =>
        QuizWord(
          surahOrder: surah,
          ayahNumber: ayah,
          word: word,
          wordNormalized: word,
          meaning: 'meaning of $word',
          meaningNormalized: 'meaning of $word',
          thumun: thumun,
        );

    // Book order on one page: all of Al-Fil (ayahs 1,1,2) then Quraysh
    // (ayahs 1,2). An ayah-based sort would wrongly interleave them.
    final quiz = QuizService();
    quiz.prime([
      qw('a', ayah: 1, thumun: 479),
      qw('b', ayah: 1, thumun: 479),
      qw('c', ayah: 2, thumun: 479),
      qw('d', surah: 106, ayah: 1, thumun: 479),
      qw('e', surah: 106, ayah: 2, thumun: 479),
    ]);

    expect(
      quiz.wordsForThumun(479).map((w) => w.word).toList(),
      ['a', 'b', 'c', 'd', 'e'],
    );
    expect(
      quiz.wordsForSurah(105).map((w) => w.word).toList(),
      ['a', 'b', 'c'],
    );
  });
}
