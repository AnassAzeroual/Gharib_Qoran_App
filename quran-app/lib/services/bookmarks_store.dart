import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_word.dart';
import 'arabic_normalizer.dart';
import 'data_service.dart';

/// A saved favorite word snapshot. The [key] is stable across data resyncs
/// (surah + ayah + normalized word); the remaining fields are a display
/// snapshot taken at save time so the favorites list never needs a lookup.
class Bookmark {
  final String key;
  final String word;
  final String meaning;
  final int surahOrder;
  final String surahName;
  final int? ayahNumber;
  final int? page;

  const Bookmark({
    required this.key,
    required this.word,
    required this.meaning,
    required this.surahOrder,
    required this.surahName,
    required this.ayahNumber,
    required this.page,
  });

  Map<String, dynamic> toJson() => {
    'k': key,
    'w': word,
    'm': meaning,
    's': surahOrder,
    'sn': surahName,
    'a': ayahNumber,
    'p': page,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    key: json['k'] as String? ?? '',
    word: json['w'] as String? ?? '',
    meaning: json['m'] as String? ?? '',
    surahOrder: json['s'] as int? ?? 0,
    surahName: json['sn'] as String? ?? '',
    ayahNumber: json['a'] as int?,
    page: json['p'] as int?,
  );

  /// Snapshot from a thumun word card (page is always known there).
  factory Bookmark.fromThumun(ThumunWord w) => Bookmark(
    key: BookmarksStore.keyFor(
      word: w.word,
      surahOrder: w.surahOrder,
      ayahNumber: w.ayahNumber,
    ),
    word: w.word,
    meaning: w.meaning,
    surahOrder: w.surahOrder,
    surahName: w.surahName,
    ayahNumber: w.ayahNumber,
    page: w.page,
  );

  /// Snapshot from a quiz word (page resolved separately, may be null).
  factory Bookmark.fromQuiz(QuizWord w, int? page) => Bookmark(
    key: BookmarksStore.keyFor(
      word: w.word,
      surahOrder: w.surahOrder,
      ayahNumber: w.ayahNumber,
    ),
    word: w.word,
    meaning: w.meaning,
    surahOrder: w.surahOrder,
    surahName: w.surahName,
    ayahNumber: w.ayahNumber,
    page: page,
  );
}

/// Saved favorite words (المفضلة), persisted in local storage. The live list
/// notifier makes every star icon and the home counter update instantly.
class BookmarksStore {
  BookmarksStore._();

  static const String storageKey = 'bookmarks_v1';

  static final ValueNotifier<List<Bookmark>> bookmarksNotifier =
      ValueNotifier(const []);

  /// Stable identity across resyncs: surah + ayah + normalized word.
  static String keyFor({
    required String word,
    required int surahOrder,
    required int? ayahNumber,
  }) {
    final normalized = ArabicNormalizer.normalize(word);
    return '$surahOrder|${ayahNumber ?? 0}|$normalized';
  }

  static bool isSaved(String key) =>
      bookmarksNotifier.value.any((b) => b.key == key);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      bookmarksNotifier.value = [
        for (final e in decoded)
          Bookmark.fromJson(e as Map<String, dynamic>),
      ].where((b) => b.key.isNotEmpty && b.word.isNotEmpty).toList();
    } catch (_) {
      // Corrupt storage is ignored — favorites simply start empty.
    }
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        jsonEncode(bookmarksNotifier.value.map((b) => b.toJson()).toList()),
      );
    } catch (_) {
      // Storage failures must never break starring.
    }
  }

  /// Toggles the bookmark. Returns true when the word ends up saved.
  static Future<bool> toggle(Bookmark bookmark) async {
    final current = [...bookmarksNotifier.value];
    final index = current.indexWhere((b) => b.key == bookmark.key);
    final bool saved;
    if (index >= 0) {
      current.removeAt(index);
      saved = false;
    } else {
      current.add(bookmark);
      saved = true;
    }
    bookmarksNotifier.value = current;
    await _save();
    return saved;
  }

  static Future<void> remove(String key) async {
    final current = [...bookmarksNotifier.value];
    current.removeWhere((b) => b.key == key);
    if (current.length != bookmarksNotifier.value.length) {
      bookmarksNotifier.value = current;
      await _save();
    }
  }
}
