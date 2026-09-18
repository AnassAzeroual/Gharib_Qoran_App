import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/models/quiz_word.dart';
import 'package:quran_app/services/quiz_service.dart';

void main() {
  QuizWord w(String word, String meaning, {int surah = 1, int? ayah}) =>
      QuizWord(
        surahOrder: surah,
        ayahNumber: ayah,
        word: word,
        wordNormalized: word,
        meaning: meaning,
        meaningNormalized: meaning,
      );

  final words = [
    w('السراج', 'المصباح'),
    w('غريب', 'الوحيد'),
    w('بيان', 'الإيضاح'),
    w('القرآن', 'كتاب الله'),
    w('آية', 'علامة'),
    w('سورة', 'فصل من القرآن'),
  ];

  group('QuizService', () {
    test('buildQuestion returns 3 options with exactly one correct', () {
      final service = QuizService();
      service.prime(words);

      final q = service.buildQuestion(words.first);
      expect(q.options, hasLength(3));
      expect(q.options.where((o) => o.isCorrect), hasLength(1));
      expect(q.correctIndex, isNot(-1));
      expect(
        q.options.map((o) => o.label).toSet(),
        contains(words.first.meaning),
      );
    });

    test('options are shuffled and include two distinct distractors', () {
      final service = QuizService();
      service.prime(words);

      final q = service.buildQuestion(words.first);
      final correct = q.options[q.correctIndex];
      expect(correct.label, words.first.meaning);

      final labels = q.options.map((o) => o.label).toList();
      final distinct = labels.toSet();
      expect(distinct.length, labels.length);
      expect(labels.where((l) => l == words.first.meaning), hasLength(1));
    });

    test('prime deduplicates repeated words', () {
      final service = QuizService();
      service.prime([...words, w(words.first.word, words.first.meaning)]);

      expect(service.wordsForSurah(1), hasLength(6));
    });

    test('wordsForSurah filters by surah order', () {
      final service = QuizService();
      service.prime([
        w('كلمة', 'معنى', surah: 1),
        w('أخرى', 'معنى آخر', surah: 2),
      ]);

      final list = service.wordsForSurah(2);
      expect(list, hasLength(1));
      expect(list.single.word, 'أخرى');
    });

    test('nextAllWord never returns the same word twice in a cycle', () {
      final service = QuizService();
      service.prime([...words, ...words, ...words]);

      final seen = <String>{};
      for (var i = 0; i < words.length; i++) {
        final picked = service.nextAllWord().wordNormalized;
        expect(seen.add(picked), isTrue, reason: 'word repeated: $picked');
      }
    });
  });

  group('QuizSession', () {
    test('wrong answer increments wrongCount only', () {
      final s = QuizSession();
      s.onWrong(w('السراج', 'المصباح'));
      s.onWrong(w('السراج', 'المصباح'));
      expect(s.wrongCount, 2);
      expect(s.correctCount, 0);
    });

    test('correct answer increments correctCount and advances', () {
      final s = QuizSession();
      s.onWrong(w('السراج', 'المصباح'));
      s.onWrong(w('السراج', 'المصباح'));
      s.onCorrect(w('السراج', 'المصباح'));
      expect(s.wrongCount, 2);
      expect(s.correctCount, 1);
    });

    test('percentage = correct / (correct + wrong) * 100', () {
      final s = QuizSession();
      s.onWrong(w('السراج', 'المصباح'));
      s.onWrong(w('السراج', 'المصباح'));
      s.onCorrect(w('السراج', 'المصباح'));
      expect(s.percentage, closeTo(33.333, 0.01));
    });

    test('percentage is zero when nothing answered', () {
      expect(QuizSession().percentage, 0);
    });
  });
}