import 'package:flutter/material.dart';

import '../models/quiz_word.dart';
import '../theme.dart';
import '../utils/arabic_digits.dart';
import '../widgets/numeral_toggle_button.dart';

/// Review list of all questions answered correctly or wrongly in a quiz.
/// Shows each word with its correct meaning and Quran reference, so the user
/// can revise the mistakes. Style follows the stat card the user tapped on.
class QuizWordsListScreen extends StatelessWidget {
  final List<QuizWord> words;
  final bool correct;

  const QuizWordsListScreen({
    super.key,
    required this.words,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = correct ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ValueListenableBuilder<NumeralSystem>(
      valueListenable: numeralNotifier,
      builder: (context, numeral, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            correct
                ? 'الإجابات الصحيحة ${displayNumber(words.length)}'
                : 'الإجابات الخاطئة ${displayNumber(words.length)}',
            style: const TextStyle(fontFamily: 'Amiri'),
          ),
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          actions: const [
            Padding(
              padding: EdgeInsetsDirectional.only(start: 12),
              child: NumeralToggleButton(),
            ),
          ],
        ),
        body: words.isEmpty
            ? Center(
                child: Text(
                  correct ? 'لا توجد إجابات صحيحة' : 'لا توجد إجابات خاطئة',
                  style: TextStyle(
                    fontSize: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 16 + bottomInset),
                itemCount: words.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _wordTile(context, words[index], accent, scheme);
                },
              ),
      ),
    );
  }

  Widget _wordTile(
    BuildContext context,
    QuizWord w,
    Color accent,
    ColorScheme scheme,
  ) {
    final String reference = w.ayahNumber != null && w.surahName.isNotEmpty
        ? '${w.surahName} · آية ${displayNumber(w.ayahNumber!)}'
        : w.surahName;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              correct ? Icons.check_circle : Icons.cancel,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        w.word,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (reference.isNotEmpty)
                      Text(
                        reference,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'المعنى: ',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: w.meaning),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
