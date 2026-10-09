import 'package:flutter/material.dart';

import '../services/bookmarks_store.dart';
import '../theme.dart';

/// Star toggle for a glossary word card. Shows the live saved state and
/// persists on tap — silently, with a spring pop as the only feedback.
/// Identity comes from [BookmarksStore.keyFor] so every card showing the
/// same word agrees.
class BookmarkStarButton extends StatefulWidget {
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
  State<BookmarkStarButton> createState() => _BookmarkStarButtonState();
}

class _BookmarkStarButtonState extends State<BookmarkStarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Bookmark>>(
      valueListenable: BookmarksStore.bookmarksNotifier,
      builder: (context, bookmarks, _) {
        final saved = bookmarks.any((b) => b.key == widget.bookmark.key);
        return ScaleTransition(
          scale: _scale,
          child: IconButton(
            tooltip: saved ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
            iconSize: widget.size,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              saved ? Icons.star_rounded : Icons.star_outline_rounded,
              color: saved
                  ? paletteNotifier.value.favoriteStar
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              BookmarksStore.toggle(widget.bookmark);
              _pop.forward(from: 0.0);
            },
          ),
        );
      },
    );
  }
}
