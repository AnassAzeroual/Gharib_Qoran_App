import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../utils/arabic_digits.dart';
import 'page_viewer_screen.dart';

/// Shows the unfamiliar words (glossary entries) that belong to a single
/// thumun, and lets the user jump to the page each word appears on.
class ThumunWordsScreen extends StatelessWidget {
  final int hizb; // 1..60
  final int thumunInHizb; // 1..8
  final int thumunGlobal; // 1..480

  const ThumunWordsScreen({
    super.key,
    required this.hizb,
    required this.thumunInHizb,
    required this.thumunGlobal,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final words = DataService.instance.glossaryByThumun(thumunGlobal);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الحزب ${toArabicDigits(hizb)} · الثمن ${toArabicDigits(thumunInHizb)}',
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
      ),
      body: words.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('لا توجد كلمات غريبة في هذا الثمن',
                      style: TextStyle(
                          fontSize: 16, color: scheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final w = words[index];
                return _WordCard(word: w);
              },
            ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final ThumunWord word;
  const _WordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const accent = Color(0xFF0F766E);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PageViewerScreen(
                  initialPage: word.page,
                  surahName: word.surahName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Page badge (jump target).
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded,
                              size: 14, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            'صفحة ${toArabicDigits(word.page)}',
                            style: const TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (word.surahName.isNotEmpty)
                      Flexible(
                        child: Text(
                          word.ayahNumber != null
                              ? '${word.surahName} · آية ${toArabicDigits(word.ayahNumber!)}'
                              : word.surahName,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  word.word,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
                if (word.meaning.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    word.meaning,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: scheme.onSurface,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
