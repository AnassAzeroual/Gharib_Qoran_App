// Models for the Hizb -> Thumun navigation index (assets/thumun-menu.json).
//
// Structure:
//   { "meta": {...}, "hizbs": [ { hizb, first_page, thumun_count,
//       thumuns: [ { thumun, thumun_in_hizb, entry_count, first_page,
//                    pages: [int...] } ] } ] }
//
// Only hizbs/thumuns that actually contain unfamiliar-word glossary entries
// are present. `thumun` is the global 1..480 key; `thumun_in_hizb` is 1..8.

class ThumunEntry {
  final int thumun; // global 1..480
  final int thumunInHizb; // 1..8
  final int entryCount; // number of glossary words in this thumun
  final int firstPage; // first page in this book containing them
  final List<int> pages;

  ThumunEntry({
    required this.thumun,
    required this.thumunInHizb,
    required this.entryCount,
    required this.firstPage,
    required this.pages,
  });

  factory ThumunEntry.fromJson(Map<String, dynamic> json) => ThumunEntry(
        thumun: json['thumun'] as int? ?? 0,
        thumunInHizb: json['thumun_in_hizb'] as int? ?? 0,
        entryCount: json['entry_count'] as int? ?? 0,
        firstPage: json['first_page'] as int? ?? 0,
        pages: (json['pages'] as List<dynamic>? ?? []).cast<int>(),
      );
}

class HizbEntry {
  final int hizb; // 1..60
  final int firstPage;
  final int thumunCount;
  final List<ThumunEntry> thumuns;

  HizbEntry({
    required this.hizb,
    required this.firstPage,
    required this.thumunCount,
    required this.thumuns,
  });

  factory HizbEntry.fromJson(Map<String, dynamic> json) => HizbEntry(
        hizb: json['hizb'] as int? ?? 0,
        firstPage: json['first_page'] as int? ?? 0,
        thumunCount: json['thumun_count'] as int? ?? 0,
        thumuns: (json['thumuns'] as List<dynamic>? ?? [])
            .map((e) => ThumunEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Total glossary words across all thumuns of this hizb.
  int get totalEntries =>
      thumuns.fold(0, (sum, t) => sum + t.entryCount);
}

class HizbMenu {
  final List<HizbEntry> hizbs;

  HizbMenu({required this.hizbs});

  factory HizbMenu.fromJson(Map<String, dynamic> json) => HizbMenu(
        hizbs: (json['hizbs'] as List<dynamic>? ?? [])
            .map((e) => HizbEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  HizbEntry? byHizb(int hizb) {
    for (final h in hizbs) {
      if (h.hizb == hizb) return h;
    }
    return null;
  }
}
