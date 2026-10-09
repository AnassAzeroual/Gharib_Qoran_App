import 'package:flutter/material.dart';

import '../services/bookmarks_store.dart';
import '../theme.dart';
import '../utils/arabic_digits.dart';
import '../widgets/bookmark_star_button.dart';
import '../widgets/numeral_toggle_button.dart';
import '../widgets/palette_live.dart';
import 'page_viewer_screen.dart';
import 'verification_screen.dart';

/// Saved favorite words (المفضلة). Tapping a row jumps to its page — the
/// page viewer normally, or the verification screen in verification mode.
/// Un-starring removes the row live.
class BookmarksScreen extends StatelessWidget {
  final bool verifyMode;

  const BookmarksScreen({super.key, this.verifyMode = false});

  void _openBookmark(BuildContext context, Bookmark bookmark) {
    final page = bookmark.page;
    if (page == null || page <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد صفحة محفوظة لهذه الكلمة'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => verifyMode
            ? VerificationScreen(
                initialPage: page,
                surahName: bookmark.surahName,
              )
            : PageViewerScreen(
                initialPage: page,
                surahName: bookmark.surahName,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<NumeralSystem>(
      valueListenable: numeralNotifier,
      builder: (context, numeral, _) => ValueListenableBuilder<List<Bookmark>>(
        valueListenable: BookmarksStore.bookmarksNotifier,
        builder: (context, bookmarks, _) => PaletteLive(child: Scaffold(
          appBar: AppBar(
            title: Text(
              'المفضلة · ${displayNumber(bookmarks.length)}',
              style: TextStyle(fontFamily: fontFamilyNotifier.value),
            ),
            actions: const [
              Padding(
                padding: EdgeInsetsDirectional.only(start: 12),
                child: NumeralToggleButton(),
              ),
            ],
          ),
          body: bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline_rounded,
                        size: 64,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد كلمات محفوظة بعد',
                        style: TextStyle(
                          fontSize: 18,
                          color: scheme.onSurfaceVariant,
                          fontFamily: fontFamilyNotifier.value,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اضغط النجمة على أي كلمة لحفظها هنا',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                          fontFamily: fontFamilyNotifier.value,
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        24 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: bookmarks.length,
                      itemBuilder: (context, index) {
                        final b = bookmarks[index];
                        return _BookmarkCard(
                          bookmark: b,
                          onTap: () => _openBookmark(context, b),
                        );
                      },
                    ),
                  ),
                ),
        )),
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;

  const _BookmarkCard({required this.bookmark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = paletteNotifier.value.seed;
    final b = bookmark;
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    if (b.page != null && b.page! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'صفحة ${displayNumber(b.page!)}',
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: b.surahName.isNotEmpty
                          ? Text(
                              b.ayahNumber != null
                                  ? '${b.surahName} · آية ${displayNumber(b.ayahNumber!)}'
                                  : b.surahName,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                                fontFamily: fontFamilyNotifier.value,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    BookmarkStarButton(bookmark: b),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  b.word,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamilyNotifier.value,
                  ),
                ),
                if (b.meaning.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    b.meaning,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: scheme.onSurface,
                      fontFamily: fontFamilyNotifier.value,
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
