import 'dart:math';

import '../models/quiz_word.dart';

class QuizService {
  final Random _rng = Random();

  /// Shared instance used by the UI screens.
  static final QuizService instance = QuizService();

  List<QuizWord> _allWords = const [];
  List<QuizWord> _shuffledQueue = const [];
  int _queueIndex = 0;

  void _dedupe(Iterable<QuizWord> source) {
    final seen = <String>{};
    _allWords = [];
    for (final w in source) {
      final key = w.wordNormalized.isEmpty ? w.word : w.wordNormalized;
      if (key.isEmpty) continue;
      if (seen.add(key)) _allWords.add(w);
    }
    _allWords.sort((a, b) {
      if (a.surahOrder != b.surahOrder) return a.surahOrder - b.surahOrder;
      return (a.ayahNumber ?? 0) - (b.ayahNumber ?? 0);
    });
  }

  void prime(List<QuizWord> words) {
    _dedupe(words);
    _shuffledQueue = List.of(_allWords)..shuffle(_rng);
    _queueIndex = 0;
  }

  List<QuizWord> wordsForSurah(int surahOrder) =>
      _allWords.where((w) => w.surahOrder == surahOrder).toList();

  List<QuizWord> wordsForHizb(int hizb) =>
      _allWords.where((w) => w.hizb == hizb).toList();

  List<QuizWord> wordsForThumun(int thumun) =>
      _allWords.where((w) => w.thumun == thumun).toList();

  QuizWord nextAllWord() {
    if (_shuffledQueue.isEmpty) _shuffledQueue = List.of(_allWords)..shuffle(_rng);
    if (_queueIndex >= _shuffledQueue.length) {
      _shuffledQueue = List.of(_allWords)..shuffle(_rng);
      _queueIndex = 0;
    }
    return _shuffledQueue[_queueIndex++];
  }

  double get allModeProgress {
    if (_shuffledQueue.isEmpty) return 0;
    return (_queueIndex / _shuffledQueue.length).clamp(0.0, 1.0);
  }

  QuizQuestion buildQuestion(QuizWord target) {
    final distractors = <String>[];
    final seen = <String>{target.meaningNormalized};

    final shuffled = List.of(_allWords)..shuffle(_rng);
    for (final w in shuffled) {
      if (distractors.length >= 2) break;
      if (w.meaningNormalized.isEmpty) continue;
      if (seen.add(w.meaningNormalized)) distractors.add(w.meaning);
    }

    final options = <QuizOption>[
      QuizOption(label: target.meaning, isCorrect: true),
      for (final d in distractors) QuizOption(label: d, isCorrect: false),
    ];
    while (options.length < 3) {
      options.add(QuizOption(label: 'معنى آخر', isCorrect: false));
    }
    options.shuffle(_rng);
    return QuizQuestion(word: target, options: options);
  }
}