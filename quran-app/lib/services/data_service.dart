import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/page_data.dart';
import '../models/quiz_word.dart';
import '../models/hizb_menu.dart';
import 'arabic_normalizer.dart';

/// One searchable glossary entry found in a page.
class SearchHit {
  final int page;
  final int surahOrder;
  final String surahName;
  final int? ayahNumber;
  final String word;
  final String meaning;
  final String searchable;

  SearchHit({
    required this.page,
    required this.surahOrder,
    required this.surahName,
    this.ayahNumber,
    required this.word,
    required this.meaning,
    required this.searchable,
  });
}

/// One glossary word belonging to a thumun (for the Hizb -> Thumun -> words view).
class ThumunWord {
  final int page;
  final int? ayahNumber;
  final int surahOrder;
  final String surahName;
  final String word;
  final String meaning;

  ThumunWord({
    required this.page,
    this.ayahNumber,
    required this.surahOrder,
    required this.surahName,
    required this.word,
    required this.meaning,
  });
}

class SurahIndexEntry {
  final int order;
  final String nameNormalized;
  final String shortNormalized;
  final String classification;
  final int unfamiliarWordsCount;
  final int startPage;
  final List<int> pages;

  SurahIndexEntry({
    required this.order,
    required this.nameNormalized,
    required this.shortNormalized,
    this.classification = '',
    this.unfamiliarWordsCount = 0,
    required this.startPage,
    required this.pages,
  });

  factory SurahIndexEntry.fromJson(Map<String, dynamic> json) =>
      SurahIndexEntry(
        order: json['order'] as int? ?? 0,
        nameNormalized: json['name_normalized'] as String? ?? '',
        shortNormalized: json['short_normalized'] as String? ?? '',
        classification: json['classification'] as String? ?? '',
        unfamiliarWordsCount: json['unfamiliar_words_count'] as int? ?? 0,
        startPage: json['start_page'] as int? ?? 0,
        pages: (json['pages'] as List<dynamic>? ?? []).cast<int>(),
      );
}

/// Loads the bundled resources (index + page JSONs) and provides search.
class DataService {
  DataService._();
  static final DataService instance = DataService._();

  static String pageImagePath(int page) =>
      'assets/images/page_${page.toString().padLeft(4, '0')}.png';

  static String pageJsonPath(int page) =>
      'assets/json/page_${page.toString().padLeft(4, '0')}.json';

  int totalImages = 0;
  List<int> _availablePages = const [];
  Map<int, SurahIndexEntry> _surahIndex = {};
  bool _searchBuilt = false;
  final List<SearchHit> _searchIndex = [];
  final List<QuizWord> _allQuizWords = [];
  // Thumun (global 1..480) -> its glossary words, collected during the same
  // page scan that builds the search index. Ordered by page then ayah.
  final Map<int, List<ThumunWord>> _wordsByThumun = {};
  HizbMenu? _hizbMenu;

  /// Pages that have a JSON file available.
  List<int> get availablePages => _availablePages;

  /// The largest page number (usually matches the last image page).
  int get maxPage => _availablePages.isEmpty
      ? 0
      : _availablePages.reduce((a, b) => a > b ? a : b);

  SurahIndexEntry? surahByOrder(int order) => _surahIndex[order];

  bool hasSurah(int order) => _surahIndex.containsKey(order);

  /// All unique glossary words collected from surah sections.
  List<QuizWord> get allQuizWords => _allQuizWords;

  Future<void> loadIndex() async {
    final raw = await rootBundle.loadString('assets/surah_index.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    totalImages = json['image_count'] as int? ?? 0;
    _availablePages = (json['pages'] as List<dynamic>? ?? []).cast<int>();
    _surahIndex = {
      for (final e in (json['surahs'] as List<dynamic>? ?? []))
        (e as Map<String, dynamic>)['order'] as int:
            SurahIndexEntry.fromJson(e),
    };
  }

  /// Builds the in-memory search index from all available page JSONs.
  Future<void> buildSearchIndex() async {
    if (_searchBuilt) return;
    for (final page in _availablePages) {
      try {
        final raw = await rootBundle.loadString(pageJsonPath(page));
        final data = PageData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _indexPage(data);
      } catch (_) {
        // Missing/corrupt JSON is skipped gracefully.
      }
    }
    _searchBuilt = true;
  }

  void _indexPage(PageData page) {
    final surahs = page.surahs;
    for (final section in page.sections) {
      if (section.type == 'surah_section') {
        final surah = section.surah;
        for (final entry in section.glossary) {
          _searchIndex.add(_toHit(page, surah, entry.ayahNumber, entry.word,
              entry.wordNormalized, entry.meaning, entry.meaningNormalized));
          _allQuizWords.add(QuizWord(
            surahOrder: surah?.order ?? 0,
            surahName: surah?.nameNormalized ?? page.headerRightNormalized,
            ayahNumber: entry.ayahNumber,
            ayah: entry.ayah,
            word: entry.word,
            wordNormalized: entry.wordNormalized,
            meaning: entry.meaning,
            meaningNormalized: entry.meaningNormalized,
          ));
          // Collect by thumun (additive; does not affect search).
          if (entry.thumun != null) {
            _wordsByThumun.putIfAbsent(entry.thumun!, () => []).add(ThumunWord(
                  page: page.pageNumber,
                  ayahNumber: entry.ayahNumber,
                  surahOrder: surah?.order ?? 0,
                  surahName:
                      surah?.nameNormalized ?? page.headerRightNormalized,
                  word: entry.word,
                  meaning: entry.meaning,
                ));
          }
        }
      } else if (section.type == 'preliminary_entries') {
        for (final entry in section.entries) {
          _searchIndex.add(_toHit(page, null, null, entry.term,
              entry.termNormalized, entry.meaning, entry.meaningNormalized));
        }
      }
    }
    if (surahs.isNotEmpty) {
      // Also allow searching for the surah name itself on this page.
      for (final s in surahs) {
        _searchIndex.add(SearchHit(
          page: page.pageNumber,
          surahOrder: s.order,
          surahName: s.nameNormalized,
          searchable: ArabicNormalizer.normalize(s.nameNormalized),
          word: '',
          meaning: '',
        ));
      }
    }
  }

  SearchHit _toHit(PageData page, SurahInfo? surah, int? ayah,
      String word, String wordNorm, String meaning, String meaningNorm) {
    final norm = ArabicNormalizer.normalize;
    final searchable = [
      norm(wordNorm),
      norm(meaningNorm),
      if (surah != null) norm(surah.nameNormalized),
    ].join(' ');
    return SearchHit(
      page: page.pageNumber,
      surahOrder: surah?.order ?? 0,
      surahName: surah?.nameNormalized ?? page.headerRightNormalized,
      ayahNumber: ayah,
      word: word,
      meaning: meaning,
      searchable: searchable,
    );
  }

  /// Returns hits whose normalized text contains all query tokens.
  List<SearchHit> search(String rawQuery) {
    final query = ArabicNormalizer.normalize(rawQuery);
    final tokens = query.split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return const [];

    final results = <SearchHit>[];
    for (final hit in _searchIndex) {
      if (tokens.every((t) => hit.searchable.contains(t))) {
        results.add(hit);
      }
    }

    // Simple relevance: exact/prefix matches on the word field rank higher.
    results.sort((a, b) {
      final scoreA = _score(a, tokens);
      final scoreB = _score(b, tokens);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      if (a.surahOrder != b.surahOrder) return a.surahOrder - b.surahOrder;
      if ((a.ayahNumber ?? 0) != (b.ayahNumber ?? 0)) {
        return (a.ayahNumber ?? 0) - (b.ayahNumber ?? 0);
      }
      return a.page - b.page;
    });

    return results;
  }

  int _score(SearchHit hit, List<String> tokens) {
    final norm = ArabicNormalizer.normalize(hit.word);
    for (final t in tokens) {
      if (norm == t) return 3;
      if (norm.startsWith(t)) return 2;
    }
    return 1;
  }

  /// Loads one page's JSON (for header/surah info in the page viewer).
  Future<PageData?> loadPage(int page) async {
    try {
      final raw = await rootBundle.loadString(pageJsonPath(page));
      return PageData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------- Hizb / Thumun
  /// The Hizb -> Thumun navigation index (loaded from assets/thumun-menu.json).
  HizbMenu? get hizbMenu => _hizbMenu;

  /// Loads the Hizb/Thumun menu. Safe to call multiple times (cached).
  Future<HizbMenu?> loadHizbMenu() async {
    if (_hizbMenu != null) return _hizbMenu;
    try {
      final raw = await rootBundle.loadString('assets/thumun-menu.json');
      _hizbMenu =
          HizbMenu.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _hizbMenu = null;
    }
    return _hizbMenu;
  }

  /// Glossary words in a given thumun (global 1..480), ordered by page then
  /// ayah. Requires buildSearchIndex() to have run. Returns [] if none.
  List<ThumunWord> glossaryByThumun(int thumun) {
    final list = _wordsByThumun[thumun];
    if (list == null) return const [];
    final sorted = [...list];
    sorted.sort((a, b) {
      if (a.page != b.page) return a.page - b.page;
      return (a.ayahNumber ?? 0) - (b.ayahNumber ?? 0);
    });
    return sorted;
  }
}