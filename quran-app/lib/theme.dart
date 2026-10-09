import 'package:flutter/material.dart';

/// A single customizable brand color: its storage key, settings section,
/// Arabic label, usage description, and default value. Rendered as one row
/// in the settings page, grouped by section.
class PaletteEntry {
  final String key;
  final String section;
  final String label;
  final String usage;
  final Color fallback;

  const PaletteEntry({
    required this.key,
    required this.section,
    required this.label,
    required this.usage,
    required this.fallback,
  });
}

/// All customizable colors of the app, in settings-page order. The map keys
/// are the persistence keys (stable — never rename) and match [AppPalette]
/// fields one to one. Headers are per page so recoloring one page never
/// affects the others; the "general" colors stay shared by design.
const List<PaletteEntry> kPaletteEntries = [
  // ---- Page headers (one per page) ----
  PaletteEntry(
    key: 'homeHeaderStart',
    section: 'ترويسات الصفحات',
    label: 'الرئيسية (بداية)',
    usage: 'بداية تدرج الترويسة العلوية وبلاطة «كل القرآن»',
    fallback: Color(0xFF0F766E),
  ),
  PaletteEntry(
    key: 'homeHeaderEnd',
    section: 'ترويسات الصفحات',
    label: 'الرئيسية (نهاية)',
    usage: 'نهاية تدرج الترويسة العلوية وبلاطة «كل القرآن»',
    fallback: Color(0xFF134E4A),
  ),
  PaletteEntry(
    key: 'quizHeader',
    section: 'ترويسات الصفحات',
    label: 'الاختبار',
    usage: 'الشريط العلوي لشاشة الاختبار',
    fallback: Color(0xFFA12FCD),
  ),
  PaletteEntry(
    key: 'quizResultHeader',
    section: 'ترويسات الصفحات',
    label: 'نتيجة الاختبار',
    usage: 'الشريط العلوي لشاشة نتيجة الاختبار',
    fallback: Color(0xFF0F766E),
  ),
  PaletteEntry(
    key: 'quizWordsHeader',
    section: 'ترويسات الصفحات',
    label: 'مراجعة الإجابات',
    usage: 'الشريط العلوي لقائمة الإجابات الصحيحة والخاطئة',
    fallback: Color(0xFF0F766E),
  ),
  PaletteEntry(
    key: 'searchHeader',
    section: 'ترويسات الصفحات',
    label: 'نتائج البحث',
    usage: 'الشريط العلوي لشاشة نتائج البحث',
    fallback: Color(0xFF0F766E),
  ),
  PaletteEntry(
    key: 'thumunWordsHeader',
    section: 'ترويسات الصفحات',
    label: 'كلمات الثمن',
    usage: 'الشريط العلوي لقائمة كلمات الثمن',
    fallback: Color(0xFF0F766E),
  ),
  PaletteEntry(
    key: 'hizbHeader',
    section: 'ترويسات الصفحات',
    label: 'الحزب',
    usage: 'الشريط العلوي لقائمة الأثمان وبلاطة «كل الحزب»',
    fallback: Color(0xFF0F766E),
  ),
  PaletteEntry(
    key: 'settingsHeader',
    section: 'ترويسات الصفحات',
    label: 'الإعدادات',
    usage: 'الشريط العلوي لصفحة إعدادات الألوان',
    fallback: Color(0xFF0F766E),
  ),
  // ---- Verification & viewer (one accent + bottom bar per page) ----
  PaletteEntry(
    key: 'pageViewerNav',
    section: 'التحقق والعارض',
    label: 'عارض الصفحات (الشريط)',
    usage: 'الشريط السفلي لأزرار التنقل في عارض الصفحات',
    fallback: Color(0xFF16191F),
  ),
  PaletteEntry(
    key: 'surahVerifyAccent',
    section: 'التحقق والعارض',
    label: 'تحقق السور (العنوان)',
    usage: 'شريط عنوان السورة في قائمة التحقق',
    fallback: Color(0xFFE15725),
  ),
  PaletteEntry(
    key: 'surahVerifyNav',
    section: 'التحقق والعارض',
    label: 'تحقق السور (الشريط)',
    usage: 'الشريط السفلي لأزرار التنقل في تحقق السور',
    fallback: Color(0xFF16191F),
  ),
  PaletteEntry(
    key: 'thumunVerifyAccent',
    section: 'التحقق والعارض',
    label: 'تحقق الثمن (التمييز)',
    usage: 'تمييز الكلمة النشطة وشارة الصفحة في تحقق الثمن',
    fallback: Color(0xFF0F766E),
  ),
  PaletteEntry(
    key: 'thumunVerifyNav',
    section: 'التحقق والعارض',
    label: 'تحقق الثمن (الشريط)',
    usage: 'الشريط السفلي لأزرار التنقل في تحقق الثمن',
    fallback: Color(0xFF16191F),
  ),
  // ---- General (shared accents) ----
  PaletteEntry(
    key: 'seed',
    section: 'ألوان عامة',
    label: 'الأساسي',
    usage: 'اللون الرئيسي: الأزرار النشطة والشارات والأيقونات',
    fallback: Color(0xFF0F766E),
  ),
  PaletteEntry(
    key: 'gold',
    section: 'ألوان عامة',
    label: 'الذهبي',
    usage: 'أيقونات مميزة وأزرار التنقل بين الصفحات',
    fallback: Color(0xFFFCD34D),
  ),
  // ---- Light mode ----
  PaletteEntry(
    key: 'lightScaffold',
    section: 'الوضع النهاري',
    label: 'الخلفية',
    usage: 'خلفية الشاشات في الوضع النهاري',
    fallback: Color(0xFFF6F3EC),
  ),
  PaletteEntry(
    key: 'lightSurface',
    section: 'الوضع النهاري',
    label: 'السطح',
    usage: 'خلفية البطاقات في الوضع النهاري',
    fallback: Color(0xFFFFFFFF),
  ),
  PaletteEntry(
    key: 'lightText',
    section: 'الوضع النهاري',
    label: 'النص',
    usage: 'لون النصوص في الوضع النهاري',
    fallback: Color(0xFF1E293B),
  ),
  // ---- Dark mode ----
  PaletteEntry(
    key: 'darkScaffold',
    section: 'الوضع الليلي',
    label: 'الخلفية',
    usage: 'خلفية الشاشات في الوضع الليلي',
    fallback: Color(0xFF0D0B08),
  ),
  PaletteEntry(
    key: 'darkSurface',
    section: 'الوضع الليلي',
    label: 'السطح',
    usage: 'خلفية البطاقات وشاشة الاختبار في الوضع الليلي',
    fallback: Color(0xFF101418),
  ),
  PaletteEntry(
    key: 'darkPrimary',
    section: 'الوضع الليلي',
    label: 'الإبراز',
    usage: 'اللون الرئيسي في الوضع الليلي',
    fallback: Color(0xFF2DD4BF),
  ),
  PaletteEntry(
    key: 'darkText',
    section: 'الوضع الليلي',
    label: 'النص',
    usage: 'لون النصوص في الوضع الليلي',
    fallback: Color(0xFFEDE9E2),
  ),
  // ---- Quiz ----
  PaletteEntry(
    key: 'quizCanvas',
    section: 'الاختبار',
    label: 'الخلفية',
    usage: 'أرضية شاشة الاختبار في الوضع النهاري',
    fallback: Color(0xFFFBFBFB),
  ),
  PaletteEntry(
    key: 'quizWord',
    section: 'الاختبار',
    label: 'الكلمة',
    usage: 'لون الكلمة المسؤول عن معناها',
    fallback: Color(0xFF4A4A4A),
  ),
  PaletteEntry(
    key: 'quizVerse',
    section: 'الاختبار',
    label: 'الآية',
    usage: 'تمييز الكلمة داخل نص الآية',
    fallback: Color(0xFF2FA885),
  ),
  PaletteEntry(
    key: 'quizRef',
    section: 'الاختبار',
    label: 'المرجع',
    usage: 'النصوص الثانوية في شاشة الاختبار',
    fallback: Color(0xFF9AA0A6),
  ),
  PaletteEntry(
    key: 'quizGoldTop',
    section: 'الاختبار',
    label: 'ذهبي علوي',
    usage: 'أعلى زر الكشف عن الآية',
    fallback: Color(0xFFE5C158),
  ),
  PaletteEntry(
    key: 'quizGoldBottom',
    section: 'الاختبار',
    label: 'ذهبي سفلي',
    usage: 'أسفل زر الكشف عن الآية',
    fallback: Color(0xFFC89B27),
  ),
  PaletteEntry(
    key: 'quizCorrect',
    section: 'الاختبار',
    label: 'الصحيح',
    usage: 'لون الإجابة الصحيحة',
    fallback: Color(0xFF16A34A),
  ),
  PaletteEntry(
    key: 'quizWrong',
    section: 'الاختبار',
    label: 'الخطأ',
    usage: 'لون الإجابة الخاطئة',
    fallback: Color(0xFFDC2626),
  ),
  // ---- Badges & viewer ----
  PaletteEntry(
    key: 'makki',
    section: 'الشارات والعارض',
    label: 'المكي',
    usage: 'شارة السور المكية وعناوين المقدمة',
    fallback: Color(0xFFE6A15C),
  ),
  PaletteEntry(
    key: 'favoriteStar',
    section: 'الشارات والعارض',
    label: 'نجمة المفضلة',
    usage: 'نجمة الحفظ وبلاطة قائمة المفضلة',
    fallback: Color(0xFFE5A81C),
  ),
  PaletteEntry(
    key: 'hizbSpineEnd',
    section: 'الشارات والعارض',
    label: 'كعب الحزب',
    usage: 'الطرف الداكن للشريط الجانبي في بطاقة الحزب',
    fallback: Color(0xFF0B5B54),
  ),
  PaletteEntry(
    key: 'viewerBg',
    section: 'الشارات والعارض',
    label: 'العارض',
    usage: 'خلفية صورة الصفحة والأشرطة السفلية في العارض والتحقق',
    fallback: Color(0xFF16191F),
  ),
];

/// The live color palette. Immutable — change it by assigning a modified
/// copy to [paletteNotifier], which rebuilds the app with the new colors.
class AppPalette {
  final Color homeHeaderStart;
  final Color homeHeaderEnd;
  final Color quizHeader;
  final Color quizResultHeader;
  final Color quizWordsHeader;
  final Color searchHeader;
  final Color thumunWordsHeader;
  final Color hizbHeader;
  final Color settingsHeader;
  final Color pageViewerNav;
  final Color surahVerifyAccent;
  final Color surahVerifyNav;
  final Color thumunVerifyAccent;
  final Color thumunVerifyNav;
  final Color seed;
  final Color gold;
  final Color lightScaffold;
  final Color lightSurface;
  final Color lightText;
  final Color darkScaffold;
  final Color darkSurface;
  final Color darkPrimary;
  final Color darkText;
  final Color quizCanvas;
  final Color quizWord;
  final Color quizVerse;
  final Color quizRef;
  final Color quizGoldTop;
  final Color quizGoldBottom;
  final Color quizCorrect;
  final Color quizWrong;
  final Color makki;
  final Color favoriteStar;
  final Color hizbSpineEnd;
  final Color viewerBg;

  const AppPalette({
    required this.homeHeaderStart,
    required this.homeHeaderEnd,
    required this.quizHeader,
    required this.quizResultHeader,
    required this.quizWordsHeader,
    required this.searchHeader,
    required this.thumunWordsHeader,
    required this.hizbHeader,
    required this.settingsHeader,
    required this.pageViewerNav,
    required this.surahVerifyAccent,
    required this.surahVerifyNav,
    required this.thumunVerifyAccent,
    required this.thumunVerifyNav,
    required this.seed,
    required this.gold,
    required this.lightScaffold,
    required this.lightSurface,
    required this.lightText,
    required this.darkScaffold,
    required this.darkSurface,
    required this.darkPrimary,
    required this.darkText,
    required this.quizCanvas,
    required this.quizWord,
    required this.quizVerse,
    required this.quizRef,
    required this.quizGoldTop,
    required this.quizGoldBottom,
    required this.quizCorrect,
    required this.quizWrong,
    required this.makki,
    required this.favoriteStar,
    required this.hizbSpineEnd,
    required this.viewerBg,
  });

  /// Factory defaults. They must stay identical to the [kPaletteEntries]
  /// fallbacks above (the settings reset button relies on both).
  factory AppPalette.defaults() {
    Color fb(String key) =>
        kPaletteEntries.firstWhere((e) => e.key == key).fallback;
    return AppPalette(
      homeHeaderStart: fb('homeHeaderStart'),
      homeHeaderEnd: fb('homeHeaderEnd'),
      quizHeader: fb('quizHeader'),
      quizResultHeader: fb('quizResultHeader'),
      quizWordsHeader: fb('quizWordsHeader'),
      searchHeader: fb('searchHeader'),
      thumunWordsHeader: fb('thumunWordsHeader'),
      hizbHeader: fb('hizbHeader'),
      settingsHeader: fb('settingsHeader'),
      pageViewerNav: fb('pageViewerNav'),
      surahVerifyAccent: fb('surahVerifyAccent'),
      surahVerifyNav: fb('surahVerifyNav'),
      thumunVerifyAccent: fb('thumunVerifyAccent'),
      thumunVerifyNav: fb('thumunVerifyNav'),
      seed: fb('seed'),
      gold: fb('gold'),
      lightScaffold: fb('lightScaffold'),
      lightSurface: fb('lightSurface'),
      lightText: fb('lightText'),
      darkScaffold: fb('darkScaffold'),
      darkSurface: fb('darkSurface'),
      darkPrimary: fb('darkPrimary'),
      darkText: fb('darkText'),
      quizCanvas: fb('quizCanvas'),
      quizWord: fb('quizWord'),
      quizVerse: fb('quizVerse'),
      quizRef: fb('quizRef'),
      quizGoldTop: fb('quizGoldTop'),
      quizGoldBottom: fb('quizGoldBottom'),
      quizCorrect: fb('quizCorrect'),
      quizWrong: fb('quizWrong'),
      makki: fb('makki'),
      favoriteStar: fb('favoriteStar'),
      hizbSpineEnd: fb('hizbSpineEnd'),
      viewerBg: fb('viewerBg'),
    );
  }

  AppPalette copyWith({
    Color? homeHeaderStart,
    Color? homeHeaderEnd,
    Color? quizHeader,
    Color? quizResultHeader,
    Color? quizWordsHeader,
    Color? searchHeader,
    Color? thumunWordsHeader,
    Color? hizbHeader,
    Color? settingsHeader,
    Color? pageViewerNav,
    Color? surahVerifyAccent,
    Color? surahVerifyNav,
    Color? thumunVerifyAccent,
    Color? thumunVerifyNav,
    Color? seed,
    Color? gold,
    Color? lightScaffold,
    Color? lightSurface,
    Color? lightText,
    Color? darkScaffold,
    Color? darkSurface,
    Color? darkPrimary,
    Color? darkText,
    Color? quizCanvas,
    Color? quizWord,
    Color? quizVerse,
    Color? quizRef,
    Color? quizGoldTop,
    Color? quizGoldBottom,
    Color? quizCorrect,
    Color? quizWrong,
    Color? makki,
    Color? favoriteStar,
    Color? hizbSpineEnd,
    Color? viewerBg,
  }) {
    return AppPalette(
      homeHeaderStart: homeHeaderStart ?? this.homeHeaderStart,
      homeHeaderEnd: homeHeaderEnd ?? this.homeHeaderEnd,
      quizHeader: quizHeader ?? this.quizHeader,
      quizResultHeader: quizResultHeader ?? this.quizResultHeader,
      quizWordsHeader: quizWordsHeader ?? this.quizWordsHeader,
      searchHeader: searchHeader ?? this.searchHeader,
      thumunWordsHeader: thumunWordsHeader ?? this.thumunWordsHeader,
      hizbHeader: hizbHeader ?? this.hizbHeader,
      settingsHeader: settingsHeader ?? this.settingsHeader,
      pageViewerNav: pageViewerNav ?? this.pageViewerNav,
      surahVerifyAccent: surahVerifyAccent ?? this.surahVerifyAccent,
      surahVerifyNav: surahVerifyNav ?? this.surahVerifyNav,
      thumunVerifyAccent: thumunVerifyAccent ?? this.thumunVerifyAccent,
      thumunVerifyNav: thumunVerifyNav ?? this.thumunVerifyNav,
      seed: seed ?? this.seed,
      gold: gold ?? this.gold,
      lightScaffold: lightScaffold ?? this.lightScaffold,
      lightSurface: lightSurface ?? this.lightSurface,
      lightText: lightText ?? this.lightText,
      darkScaffold: darkScaffold ?? this.darkScaffold,
      darkSurface: darkSurface ?? this.darkSurface,
      darkPrimary: darkPrimary ?? this.darkPrimary,
      darkText: darkText ?? this.darkText,
      quizCanvas: quizCanvas ?? this.quizCanvas,
      quizWord: quizWord ?? this.quizWord,
      quizVerse: quizVerse ?? this.quizVerse,
      quizRef: quizRef ?? this.quizRef,
      quizGoldTop: quizGoldTop ?? this.quizGoldTop,
      quizGoldBottom: quizGoldBottom ?? this.quizGoldBottom,
      quizCorrect: quizCorrect ?? this.quizCorrect,
      quizWrong: quizWrong ?? this.quizWrong,
      makki: makki ?? this.makki,
      favoriteStar: favoriteStar ?? this.favoriteStar,
      hizbSpineEnd: hizbSpineEnd ?? this.hizbSpineEnd,
      viewerBg: viewerBg ?? this.viewerBg,
    );
  }

  Color valueOf(String key) {
    switch (key) {
      case 'homeHeaderStart':
        return homeHeaderStart;
      case 'homeHeaderEnd':
        return homeHeaderEnd;
      case 'quizHeader':
        return quizHeader;
      case 'quizResultHeader':
        return quizResultHeader;
      case 'quizWordsHeader':
        return quizWordsHeader;
      case 'searchHeader':
        return searchHeader;
      case 'thumunWordsHeader':
        return thumunWordsHeader;
      case 'hizbHeader':
        return hizbHeader;
      case 'settingsHeader':
        return settingsHeader;
      case 'pageViewerNav':
        return pageViewerNav;
      case 'surahVerifyAccent':
        return surahVerifyAccent;
      case 'surahVerifyNav':
        return surahVerifyNav;
      case 'thumunVerifyAccent':
        return thumunVerifyAccent;
      case 'thumunVerifyNav':
        return thumunVerifyNav;
      case 'seed':
        return seed;
      case 'gold':
        return gold;
      case 'lightScaffold':
        return lightScaffold;
      case 'lightSurface':
        return lightSurface;
      case 'lightText':
        return lightText;
      case 'darkScaffold':
        return darkScaffold;
      case 'darkSurface':
        return darkSurface;
      case 'darkPrimary':
        return darkPrimary;
      case 'darkText':
        return darkText;
      case 'quizCanvas':
        return quizCanvas;
      case 'quizWord':
        return quizWord;
      case 'quizVerse':
        return quizVerse;
      case 'quizRef':
        return quizRef;
      case 'quizGoldTop':
        return quizGoldTop;
      case 'quizGoldBottom':
        return quizGoldBottom;
      case 'quizCorrect':
        return quizCorrect;
      case 'quizWrong':
        return quizWrong;
      case 'makki':
        return makki;
      case 'favoriteStar':
        return favoriteStar;
      case 'hizbSpineEnd':
        return hizbSpineEnd;
      case 'viewerBg':
        return viewerBg;
    }
    throw ArgumentError('Unknown palette key: $key');
  }

  AppPalette withValue(String key, Color value) {
    switch (key) {
      case 'homeHeaderStart':
        return copyWith(homeHeaderStart: value);
      case 'homeHeaderEnd':
        return copyWith(homeHeaderEnd: value);
      case 'quizHeader':
        return copyWith(quizHeader: value);
      case 'quizResultHeader':
        return copyWith(quizResultHeader: value);
      case 'quizWordsHeader':
        return copyWith(quizWordsHeader: value);
      case 'searchHeader':
        return copyWith(searchHeader: value);
      case 'thumunWordsHeader':
        return copyWith(thumunWordsHeader: value);
      case 'hizbHeader':
        return copyWith(hizbHeader: value);
      case 'settingsHeader':
        return copyWith(settingsHeader: value);
      case 'pageViewerNav':
        return copyWith(pageViewerNav: value);
      case 'surahVerifyAccent':
        return copyWith(surahVerifyAccent: value);
      case 'surahVerifyNav':
        return copyWith(surahVerifyNav: value);
      case 'thumunVerifyAccent':
        return copyWith(thumunVerifyAccent: value);
      case 'thumunVerifyNav':
        return copyWith(thumunVerifyNav: value);
      case 'seed':
        return copyWith(seed: value);
      case 'gold':
        return copyWith(gold: value);
      case 'lightScaffold':
        return copyWith(lightScaffold: value);
      case 'lightSurface':
        return copyWith(lightSurface: value);
      case 'lightText':
        return copyWith(lightText: value);
      case 'darkScaffold':
        return copyWith(darkScaffold: value);
      case 'darkSurface':
        return copyWith(darkSurface: value);
      case 'darkPrimary':
        return copyWith(darkPrimary: value);
      case 'darkText':
        return copyWith(darkText: value);
      case 'quizCanvas':
        return copyWith(quizCanvas: value);
      case 'quizWord':
        return copyWith(quizWord: value);
      case 'quizVerse':
        return copyWith(quizVerse: value);
      case 'quizRef':
        return copyWith(quizRef: value);
      case 'quizGoldTop':
        return copyWith(quizGoldTop: value);
      case 'quizGoldBottom':
        return copyWith(quizGoldBottom: value);
      case 'quizCorrect':
        return copyWith(quizCorrect: value);
      case 'quizWrong':
        return copyWith(quizWrong: value);
      case 'makki':
        return copyWith(makki: value);
      case 'favoriteStar':
        return copyWith(favoriteStar: value);
      case 'hizbSpineEnd':
        return copyWith(hizbSpineEnd: value);
      case 'viewerBg':
        return copyWith(viewerBg: value);
    }
    throw ArgumentError('Unknown palette key: $key');
  }

  Map<String, int> toJson() => {
    for (final e in kPaletteEntries) e.key: valueOf(e.key).toARGB32(),
  };

  factory AppPalette.fromJson(Map<String, dynamic> json) {
    var palette = AppPalette.defaults();
    for (final e in kPaletteEntries) {
      final raw = json[e.key];
      if (raw is int) {
        palette = palette.withValue(e.key, Color(raw));
      }
    }
    return palette;
  }
}

/// The live palette. Assign a modified copy to apply new colors instantly
/// across the whole app (MaterialApp rebuilds from this notifier).
final ValueNotifier<AppPalette> paletteNotifier = ValueNotifier(
  AppPalette.defaults(),
);

/// Global theme-mode notifier so any screen can switch light/dark.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

/// How the main menu is organized: by Surah (default) or by Hizb (60 -> thumun).
enum MenuMode { surah, hizb }

/// Global menu-mode notifier so the header toggle can switch the home menu
/// between the Surah grid and the Hizb list. Not persisted across restarts
/// (mirrors themeModeNotifier).
final ValueNotifier<MenuMode> menuModeNotifier =
    ValueNotifier(MenuMode.surah);

/// User-adjustable font-size multiplier for the quiz page. The ⊕ / ⊖ buttons
/// scale ALL text on the quiz screen (word, ayah, chips, options). 1.0 is the
/// design default; clamped to [kQuizScaleMin, kQuizScaleMax]. Not persisted
/// across restarts (mirrors the notifiers above).
const double kQuizScaleMin = 0.8;
const double kQuizScaleMax = 1.8;
const double kQuizScaleStep = 0.1;
final ValueNotifier<double> quizFontScaleNotifier = ValueNotifier(1.0);

/// App-wide numeral system: Arabic-Indic (١٢٣, default) or Western (123).
/// Not persisted across restarts (mirrors the notifiers above).
enum NumeralSystem { arabicIndic, western }

/// Global numeral-format notifier so any screen can switch the digit style.
final ValueNotifier<NumeralSystem> numeralNotifier =
    ValueNotifier(NumeralSystem.arabicIndic);

ThemeData _baseTheme(
  Brightness brightness,
  ColorScheme colorScheme,
  Color scaffoldColor,
) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: 'Amiri',
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontFamily: 'Amiri',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

ThemeData buildLightTheme(AppPalette p) => _baseTheme(
  Brightness.light,
  ColorScheme.fromSeed(
    seedColor: p.seed,
    primary: p.seed,
    surface: p.lightSurface,
    onSurface: p.lightText,
  ),
  p.lightScaffold,
);

ThemeData buildDarkTheme(AppPalette p) => _baseTheme(
  Brightness.dark,
  ColorScheme.fromSeed(
    seedColor: p.seed,
    brightness: Brightness.dark,
    primary: p.darkPrimary,
    surface: p.darkSurface,
    onSurface: p.darkText,
  ),
  p.darkScaffold,
);
