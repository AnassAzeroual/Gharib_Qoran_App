import 'package:flutter/material.dart';

import '../models/hizb_menu.dart';
import '../utils/arabic_digits.dart';
import 'quiz_screen.dart';
import 'thumun_words_screen.dart';

/// Second-level menu: lists the 8 thumuns of a chosen hizb (only those that
/// contain unfamiliar words).
///
/// - Reading mode (quizMode == false): tapping a thumun opens its word list.
/// - Quiz mode (quizMode == true): a "كل الحزب" tile at the top quizzes the
///   whole hizb; tapping a thumun quizzes just that thumun.
class HizbThumunsScreen extends StatelessWidget {
  final HizbEntry hizb;
  final bool quizMode;

  const HizbThumunsScreen({
    super.key,
    required this.hizb,
    this.quizMode = false,
  });

  void _openThumun(BuildContext context, ThumunEntry t) {
    if (quizMode) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            thumun: t.thumun,
            thumunLabel:
                'الحزب ${toArabicDigits(hizb.hizb)} · الثمن ${toArabicDigits(t.thumunInHizb)}',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThumunWordsScreen(
          hizb: hizb.hizb,
          thumunInHizb: t.thumunInHizb,
          thumunGlobal: t.thumun,
        ),
      ),
    );
  }

  void _quizWholeHizb(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizScreen(hizb: hizb.hizb)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final int extra = quizMode ? 1 : 0; // "whole hizb" tile
    return Scaffold(
      appBar: AppBar(
        title: Text(
          quizMode
              ? 'اختبر نفسك — الحزب ${toArabicDigits(hizb.hizb)}'
              : 'الحزب ${toArabicDigits(hizb.hizb)}',
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
      ),
      body: hizb.thumuns.isEmpty
          ? Center(
              child: Text('لا توجد أثمان متاحة',
                  style: TextStyle(
                      fontSize: 16, color: scheme.onSurfaceVariant)),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + bottomInset),
                  itemCount: hizb.thumuns.length + extra,
                  itemBuilder: (context, index) {
                    if (quizMode && index == 0) {
                      return _WholeHizbTile(
                        hizb: hizb,
                        onTap: () => _quizWholeHizb(context),
                      );
                    }
                    final t = hizb.thumuns[index - extra];
                    return _ThumunTile(
                      hizb: hizb.hizb,
                      thumun: t,
                      quizMode: quizMode,
                      onTap: () => _openThumun(context, t),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _WholeHizbTile extends StatelessWidget {
  final HizbEntry hizb;
  final VoidCallback onTap;

  const _WholeHizbTile({required this.hizb, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.quiz, color: Color(0xFFFCD34D), size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'كل الحزب',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اختبار على ${toArabicDigits(hizb.totalEntries)} كلمة من كامل الحزب',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumunTile extends StatelessWidget {
  final int hizb;
  final ThumunEntry thumun;
  final bool quizMode;
  final VoidCallback onTap;

  const _ThumunTile({
    required this.hizb,
    required this.thumun,
    required this.quizMode,
    required this.onTap,
  });

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      toArabicDigits(thumun.thumunInHizb),
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الثمن ${toArabicDigits(thumun.thumunInHizb)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${toArabicDigits(thumun.entryCount)} كلمة · صفحة ${toArabicDigits(thumun.firstPage)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  quizMode ? Icons.quiz_outlined : Icons.chevron_left,
                  color: quizMode ? accent : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
