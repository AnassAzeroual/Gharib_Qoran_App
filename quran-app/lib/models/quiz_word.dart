class QuizWord {
  final int surahOrder;
  final String surahName;
  final int? ayahNumber;
  final String ayah;
  final String word;
  final String wordNormalized;
  final String meaning;
  final String meaningNormalized;
  final int? hizb; // 1..60, for per-hizb quiz filtering
  final int? thumun; // 1..480 (global), for per-thumun quiz filtering

  const QuizWord({
    this.surahOrder = 0,
    this.surahName = '',
    this.ayahNumber,
    this.ayah = '',
    required this.word,
    required this.wordNormalized,
    required this.meaning,
    required this.meaningNormalized,
    this.hizb,
    this.thumun,
  });
}

class QuizOption {
  final String label;
  final bool isCorrect;

  const QuizOption({required this.label, required this.isCorrect});
}

class QuizQuestion {
  final QuizWord word;
  final List<QuizOption> options;

  const QuizQuestion({required this.word, required this.options});

  int get correctIndex => options.indexWhere((o) => o.isCorrect);
}

class QuizSession {
  int correctCount = 0;
  int wrongCount = 0;

  /// Every word answered correctly, in answer order (for review lists).
  final List<QuizWord> correctWords = [];

  /// Every word answered wrong, in answer order (for review lists).
  final List<QuizWord> wrongWords = [];

  void onWrong(QuizWord word) {
    wrongCount++;
    wrongWords.add(word);
  }

  void onCorrect(QuizWord word) {
    correctCount++;
    correctWords.add(word);
  }

  double get percentage {
    final total = correctCount + wrongCount;
    return total == 0 ? 0 : correctCount / total * 100;
  }
}
