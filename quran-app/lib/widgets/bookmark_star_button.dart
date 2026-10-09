import 'package:flutter/material.dart';

import '../services/bookmarks_store.dart';
import '../theme.dart';

/// Star toggle for a glossary word card. Shows the live saved state and
/// persists on tap, with a snackbar + undo. Identity comes from
/// [BookmarksStore.keyFor] so every card showing the same word agrees.
class BookmarkStarButton extends StatelessWidget {
  final Bookmark bookmark;
  final double size;

  const BookmarkStarButton({super.key, required this.bookmark, this.size = 22});

  /// Builds the snapshot identity for a word shown on a card.
  static String keyOf({
    required String word,
    required int surahOrder,
    required int? ayahNumber,
  }) => BookmarksStore.keyFor(
    word: word,
    surahOrder: surahOrder,
    ayahNumber: ayahNumber,
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Bookmark>>(
      valueListenable: BookmarksStore.bookmarksNotifier,
      builder: (context, bookmarks, _) {
        final saved = bookmarks.any((b) => b.key == bookmark.key);
        return IconButton(
          tooltip: saved ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
          iconSize: size,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            saved ? Icons.star_rounded : Icons.star_outline_rounded,
            color: saved
                ? paletteNotifier.value.favoriteStar
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: () async {
            final nowSaved = await BookmarksStore.toggle(bookmark);
            // Silent on add (the filled star is feedback enough); only
            // removals notify so an accidental un-star can be undone.
            if (nowSaved || !context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: const Text('أزيلت من المفضلة'),
                  duration: const Duration(seconds: 1),
                  action: SnackBarAction(
                    label: 'تراجع',
                    onPressed: () => BookmarksStore.toggle(bookmark),
                  ),
                ),
              );
          },
        );
      },
    );
  }
}
