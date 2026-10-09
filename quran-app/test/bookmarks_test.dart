import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/services/bookmarks_store.dart';

void main() {
  test('bookmark keys are stable across text variants', () {
    final a = BookmarksStore.keyFor(
      word: 'أَلَمْ تَرَ',
      surahOrder: 105,
      ayahNumber: 1,
    );
    final b = BookmarksStore.keyFor(
      word: 'الم تر',
      surahOrder: 105,
      ayahNumber: 1,
    );
    expect(a, b);

    final otherAyah = BookmarksStore.keyFor(
      word: 'أَلَمْ تَرَ',
      surahOrder: 105,
      ayahNumber: 2,
    );
    expect(otherAyah, isNot(a));

    final otherSurah = BookmarksStore.keyFor(
      word: 'أَلَمْ تَرَ',
      surahOrder: 106,
      ayahNumber: 1,
    );
    expect(otherSurah, isNot(a));
  });

  test('toggle adds then removes, snapshot round-trips', () async {
    BookmarksStore.bookmarksNotifier.value = const [];
    const bookmark = Bookmark(
      key: '105|1|test',
      word: 'كلمة',
      meaning: 'معنى',
      surahOrder: 105,
      surahName: 'سورة الفيل',
      ayahNumber: 1,
      page: 339,
    );

    expect(await BookmarksStore.toggle(bookmark), isTrue);
    expect(BookmarksStore.isSaved(bookmark.key), isTrue);

    final restored = Bookmark.fromJson(bookmark.toJson());
    expect(restored.key, bookmark.key);
    expect(restored.page, 339);

    expect(await BookmarksStore.toggle(bookmark), isFalse);
    expect(BookmarksStore.isSaved(bookmark.key), isFalse);
    BookmarksStore.bookmarksNotifier.value = const [];
  });
}
