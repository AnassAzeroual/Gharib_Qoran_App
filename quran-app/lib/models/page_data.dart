// Model classes for the page JSON structure produced by the OCR pipeline.

class SurahInfo {
  final String name;
  final String nameNormalized;
  final int order;
  final int ayatCount;
  final String classification;

  SurahInfo({
    required this.name,
    required this.nameNormalized,
    required this.order,
    this.ayatCount = 0,
    this.classification = '',
  });

  factory SurahInfo.fromJson(Map<String, dynamic> json) => SurahInfo(
        name: json['name'] as String? ?? '',
        nameNormalized: json['name_normalized'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        ayatCount: json['ayat_count'] as int? ?? 0,
        classification: json['classification'] as String? ?? '',
      );
}

class GlossaryEntry {
  final int? ayahNumber;
  final String ayah;
  final String word;
  final String wordNormalized;
  final String meaning;
  final String meaningNormalized;
  // Thumun tagging (added by the data pipeline). Nullable for backward compat.
  final int? thumun; // global 1..480
  final int? hizb; // 1..60
  final int? thumunInHizb; // 1..8

  GlossaryEntry({
    this.ayahNumber,
    this.ayah = '',
    required this.word,
    required this.wordNormalized,
    required this.meaning,
    required this.meaningNormalized,
    this.thumun,
    this.hizb,
    this.thumunInHizb,
  });

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) => GlossaryEntry(
        ayahNumber: json['ayah_number'] as int?,
        ayah: json['ayah'] as String? ?? '',
        word: json['word'] as String? ?? '',
        wordNormalized: json['word_normalized'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
        meaningNormalized: json['meaning_normalized'] as String? ?? '',
        thumun: json['thumun'] as int?,
        hizb: json['hizb'] as int?,
        thumunInHizb: json['thumun_in_hizb'] as int?,
      );
}

class PreliminaryEntry {
  final String term;
  final String termNormalized;
  final String meaning;
  final String meaningNormalized;

  PreliminaryEntry({
    required this.term,
    required this.termNormalized,
    required this.meaning,
    required this.meaningNormalized,
  });

  factory PreliminaryEntry.fromJson(Map<String, dynamic> json) =>
      PreliminaryEntry(
        term: (json['word'] as String? ?? json['term'] as String?) ?? '',
        termNormalized:
            (json['word_normalized'] as String? ?? json['term_normalized'] as String?) ??
                '',
        meaning: json['meaning'] as String? ?? '',
        meaningNormalized: json['meaning_normalized'] as String? ?? '',
      );
}

class PageSection {
  final String type;
  final SurahInfo? surah;
  final List<GlossaryEntry> glossary;
  final List<PreliminaryEntry> entries;

  PageSection({
    required this.type,
    this.surah,
    this.glossary = const [],
    this.entries = const [],
  });

  factory PageSection.fromJson(Map<String, dynamic> json) => PageSection(
        type: json['type'] as String? ?? '',
        surah: json['surah'] != null
            ? SurahInfo.fromJson(json['surah'] as Map<String, dynamic>)
            : null,
        glossary: (json['glossary'] as List<dynamic>? ?? [])
            .map((e) => GlossaryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => PreliminaryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PageData {
  final int pageNumber;
  final String headerRight;
  final String headerRightNormalized;
  final String headerLeft;
  final String headerLeftNormalized;
  final List<PageSection> sections;

  PageData({
    required this.pageNumber,
    this.headerRight = '',
    this.headerRightNormalized = '',
    this.headerLeft = '',
    this.headerLeftNormalized = '',
    this.sections = const [],
  });

  factory PageData.fromJson(Map<String, dynamic> json) {
    final page = json['page'] as Map<String, dynamic>? ?? json;
    final header = page['header'] as Map<String, dynamic>? ?? {};
    return PageData(
      pageNumber: page['page_number'] as int? ?? 0,
      headerRight: header['right'] as String? ?? '',
      headerRightNormalized: header['right_normalized'] as String? ?? '',
      headerLeft: header['left'] as String? ?? '',
      headerLeftNormalized: header['left_normalized'] as String? ?? '',
      sections: (page['sections'] as List<dynamic>? ?? [])
          .map((e) => PageSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<SurahInfo> get surahs =>
      sections.where((s) => s.surah != null).map((s) => s.surah!).toList();
}