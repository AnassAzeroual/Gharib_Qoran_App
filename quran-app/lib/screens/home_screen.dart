import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../models/hizb_menu.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/arabic_digits.dart';
import '../widgets/search_result_card.dart';
import 'hizb_thumuns_screen.dart';
import 'page_viewer_screen.dart';
import 'quiz_screen.dart';
import 'search_results_screen.dart';
import 'verification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final DataService _data = DataService.instance;
  bool _ready = false;
  bool _verifyMode = false;
  bool _quizMode = false;

  bool _hasLiveQuery = false;
  List<SearchHit> _liveResults = const [];

  // ---- Collapsible floating controls -------------------------------------
  // Scroll observation for the surah grid.
  final ScrollController _scrollController = ScrollController();

  // Drives the bar sliding up/out (0 = fully shown, 1 = fully hidden).
  // ~450ms easeInOutCubic in BOTH directions so the reveal is animated too.
  late final AnimationController _barController;
  late final Animation<double> _barSlide; // curved 0..1

  // Drives the 3-button mode row collapse when typing (0 = expanded, 1 = collapsed).
  late final AnimationController _collapseController;
  late final Animation<double> _collapseAnim; // curved 0..1

  // Drives the التحقق chip show/hide when switching Surah<->Hizb menu.
  // value 1 = verify chip fully shown (Surah), 0 = fully hidden (Hizb).
  late final AnimationController _verifyController;
  late final Animation<double> _verifyAnim; // curved 0..1

  // Measured heights (via GlobalKey + postFrame, never context.size in build).
  final GlobalKey _barKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _toggleKey = GlobalKey();
  double _barHeight = 0; // full expanded height (search + toggle + paddings)
  double _searchHeight = 0; // search-bar-only height (used when collapsed)
  double _toggleHeight = 0; // 3-button row height (the collapsible part)

  // Threshold under which the bar is always visible.
  static const double _topRevealThreshold = 40;
  double _lastScrollOffset = 0;

  void _onSearchChanged(String value) {
    final q = value.trim();
    setState(() {
      _hasLiveQuery = q.isNotEmpty;
      _liveResults = q.isEmpty ? const [] : _data.search(q);
    });
    // Collapse the 3-button row away while there is a live query; restore it
    // (animated) when the field is cleared.
    if (q.isNotEmpty) {
      _collapseController.forward();
      // Ensure the search field is visible over the results even if the grid
      // had been scrolled down (bar hidden) before typing.
      if (_barController.value != 0) _barController.reverse();
    } else {
      _collapseController.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 450),
    );
    _barSlide = CurvedAnimation(
      parent: _barController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _collapseAnim = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _verifyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 250),
      // Start shown (Surah is the default menu mode).
      value: menuModeNotifier.value == MenuMode.surah ? 1.0 : 0.0,
    );
    _verifyAnim = CurvedAnimation(
      parent: _verifyController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
    _scrollController.addListener(_onScroll);
    menuModeNotifier.addListener(_onMenuModeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBar());
    _load();
  }

  // التحقق is hidden in Hizb mode; animate it out and, if it was the active
  // mode, fall back to المطالعة so a valid chip stays selected.
  void _onMenuModeChanged() {
    if (menuModeNotifier.value == MenuMode.hizb) {
      _verifyController.reverse(); // animate verify chip away
      if (_verifyMode) setState(() => _verifyMode = false);
    } else {
      _verifyController.forward(); // animate verify chip back in
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    menuModeNotifier.removeListener(_onMenuModeChanged);
    _scrollController.dispose();
    _barController.dispose();
    _collapseController.dispose();
    _verifyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Measure the floating bar + search-only heights after layout so the grid
  // padding and slide distance are exact.
  void _measureBar() {
    if (!mounted) return;
    final barBox = _barKey.currentContext?.findRenderObject() as RenderBox?;
    final searchBox =
        _searchKey.currentContext?.findRenderObject() as RenderBox?;
    final toggleBox =
        _toggleKey.currentContext?.findRenderObject() as RenderBox?;
    final nextSearch = searchBox?.size.height ?? _searchHeight;
    final nextToggle = toggleBox?.size.height ?? _toggleHeight;
    // Only trust the outer bar height while the toggle is fully expanded, so
    // the expanded height stays stable and isn't corrupted mid-collapse.
    final bool expanded = _collapseController.value == 0;
    final nextBar =
        expanded ? (barBox?.size.height ?? _barHeight) : _barHeight;
    if (nextBar != _barHeight ||
        nextSearch != _searchHeight ||
        nextToggle != _toggleHeight) {
      setState(() {
        _barHeight = nextBar;
        _searchHeight = nextSearch;
        _toggleHeight = nextToggle;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;

    // Near the top: always reveal (animated back into place).
    if (offset <= _topRevealThreshold) {
      if (_barController.value != 0) _barController.reverse();
      _lastScrollOffset = offset;
      return;
    }

    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    // Ignore micro jitters.
    if (delta.abs() < 1) return;

    if (delta > 0) {
      // Scrolling down -> hide (slide up & out).
      if (_barController.status != AnimationStatus.forward &&
          _barController.value != 1) {
        _barController.forward();
      }
    } else {
      // Scrolling up -> show (slide back down), no matter how far scrolled.
      if (_barController.status != AnimationStatus.reverse &&
          _barController.value != 0) {
        _barController.reverse();
      }
    }
  }

  Future<void> _load() async {
    await _data.loadIndex();
    await _data.buildSearchIndex();
    await _data.loadHizbMenu();
    if (mounted) setState(() => _ready = true);
  }

  void _onSearchSubmitted(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(query: q),
      ),
    );
  }

  void _openSurah(Surah surah) {
    final entry = _data.surahByOrder(surah.order);
    if (_quizMode) {
      final count = entry?.unfamiliarWordsCount ?? 0;
      if (count <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد كلمات غريبة في هذه السورة للاختبار'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizScreen(surahOrder: surah.order)),
      );
      return;
    }
    if (entry == null || entry.startPage <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد صفحات لهذه السورة بعد'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _verifyMode
            ? VerificationScreen(
                initialPage: entry.startPage,
                surahName: surah.name,
              )
            : PageViewerScreen(
                initialPage: entry.startPage,
                surahName: surah.name,
              ),
      ),
    );
  }

  void _startAllQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-measure each frame the layout might have changed (mode changes, etc.).
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBar());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: _ready
                  ? _floatingBody(context)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------ floating-overlay body
  // The grid is full-bleed; the controls bar floats above it. The grid's top
  // padding is derived from the SAME curved slide value as the bar offset so
  // content tracks the bar's bottom edge frame-by-frame (no gaps/overlaps).
  Widget _floatingBody(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_barSlide, _collapseAnim]),
      builder: (context, _) {
        // Effective expanded bar height shrinks as the button row collapses.
        final double collapsedBy = _toggleHeight * _collapseAnim.value;
        final double effectiveBarHeight =
            (_barHeight - collapsedBy).clamp(0.0, double.infinity);

        // slide.dy goes 0 (shown) -> -1 (fully hidden, moved up by its height).
        final double slideDy = -_barSlide.value;
        // Content top edge tracks the bar bottom: barHeight * (1 + slide.dy).
        final double contentTop = effectiveBarHeight * (1 + slideDy);

        // ClipRect keeps everything within the body bounds: the bar slides up
        // UNDER the global "السِّراج" header (which is a sibling above this
        // body in the Column) and is clipped at the top edge, never painting
        // over the header. Think of it as the header having a higher z-index.
        return ClipRect(
          child: Stack(
            children: [
              // Full-bleed content underneath.
              Positioned.fill(
                child: _hasLiveQuery
                    ? _resultsPanel(topPadding: _searchHeight)
                    : ValueListenableBuilder<MenuMode>(
                        valueListenable: menuModeNotifier,
                        builder: (context, mode, _) => mode == MenuMode.hizb
                            ? _hizbList(topPadding: contentTop)
                            : _surahGrid(topPadding: contentTop),
                      ),
              ),

              // Floating controls bar on top (opaque background covers grid).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FractionalTranslation(
                  translation: Offset(0, slideDy),
                  child: Opacity(
                    // Soft fade tied to the same curve.
                    opacity: (1 - _barSlide.value).clamp(0.0, 1.0),
                    child: _controlsBar(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // The opaque floating bar: search field + collapsible 3-button mode row.
  Widget _controlsBar(BuildContext context) {
    return Container(
      key: _barKey,
      // Match the Scaffold background so the bar looks the same as before
      // (the original search field sat directly on the scaffold surface).
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _searchBar(),
          // Collapse the button row (height + fade) as _collapseAnim goes 0->1.
          ClipRect(
            child: Align(
              heightFactor: (1 - _collapseAnim.value).clamp(0.0, 1.0),
              child: Opacity(
                opacity: (1 - _collapseAnim.value).clamp(0.0, 1.0),
                child: _modeToggle(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _header(BuildContext context) {
    final available = _data.availablePages.length;
    final total = _data.totalImages;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book, color: Color(0xFFFCD34D), size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'السِّراج',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'في بيان غريب القرآن',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<MenuMode>(
                valueListenable: menuModeNotifier,
                builder: (context, mode, _) => IconButton(
                  tooltip: mode == MenuMode.surah
                      ? 'التصفح حسب الحزب'
                      : 'التصفح حسب السورة',
                  icon: Icon(
                    mode == MenuMode.surah
                        ? Icons.auto_stories_outlined
                        : Icons.grid_view_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => menuModeNotifier.value =
                      mode == MenuMode.surah ? MenuMode.hizb : MenuMode.surah,
                ),
              ),
              IconButton(
                tooltip: 'الوضع الليلي / النهاري',
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => themeModeNotifier.value =
                    Theme.of(context).brightness == Brightness.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statChip(context, Icons.image_outlined, '$total صفحة', Colors.teal.shade100),
              const SizedBox(width: 8),
              _statChip(context, Icons.check_circle_outline,
                  '$available متاحة', const Color(0xFFFCD34D)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- search bar
  Widget _searchBar() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: _searchKey,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث عن كلمة أو معنى...',
          hintStyle: TextStyle(
              color: scheme.onSurfaceVariant, fontFamily: 'Amiri'),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.search, color: Color(0xFF0F766E)),
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
          ),
          filled: true,
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
      ),
    );
  }

  // ------------------------------------------------------------- mode toggle
  // In Surah mode: المطالعة / التحقق / اختبر نفسك (3 chips).
  // In Hizb mode:  المطالعة / اختبر نفسك (التحقق is animated-hidden — it is
  // page/surah oriented and has no meaning for hizb navigation).
  Widget _modeToggle() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: _toggleKey,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        // Drive the التحقق chip's width from a real AnimationController so the
        // value genuinely interpolates (t: 1 shown -> 0 hidden). The three
        // chips ALWAYS stay in the widget tree (no if-removal -> no render-tree
        // jump). المطالعة and اختبر نفسك keep equal flex; التحقق's flex animates
        // 1000 -> 0 while fading and clipping, so it collapses smoothly and the
        // two side chips stretch evenly. Fixed row height avoids vertical jump.
        child: SizedBox(
          height: 34,
          child: AnimatedBuilder(
            animation: _verifyAnim,
            builder: (context, _) {
              final double t = _verifyAnim.value.clamp(0.0, 1.0);
              // Keep a minimum flex of 1 so Flexible never fully degenerates
              // mid-frame; visual width still reaches ~0 via the tiny flex.
              final int verifyFlex = (t * 1000).round();
              return Row(
                children: [
                  Expanded(
                    flex: 1000,
                    child: _modeChip(
                      label: 'المطالعة',
                      active: !_verifyMode && !_quizMode,
                      onTap: () => setState(() {
                        _verifyMode = false;
                        _quizMode = false;
                      }),
                    ),
                  ),
                  Flexible(
                    flex: verifyFlex < 1 ? 1 : verifyFlex,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        widthFactor: t, // shrink horizontally to 0
                        child: Opacity(
                          opacity: t,
                          child: IgnorePointer(
                            ignoring: t < 0.5,
                            child: _modeChip(
                              label: 'التحقق',
                              active: _verifyMode,
                              onTap: () => setState(() {
                                _verifyMode = true;
                                _quizMode = false;
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1000,
                    child: _modeChip(
                      label: 'اختبر نفسك',
                      active: _quizMode,
                      onTap: () => setState(() {
                        _quizMode = true;
                        _verifyMode = false;
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F766E) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        // Guard against reflow/wrap glitches while the chip width animates.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: 'Amiri',
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- live search
  Widget _resultsPanel({double topPadding = 0}) {
    final scheme = Theme.of(context).colorScheme;
    if (_liveResults.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('لا توجد نتائج',
                style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant)),
          ],
        ),
        ),
      );
    }
    return Column(
      children: [
        // Spacer so the results start below the floating search field.
        SizedBox(height: topPadding),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 4),
          child: Row(
            children: [
              Text(
                'نتيجة ${toArabicDigits(_liveResults.length)}',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontFamily: 'Amiri',
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'مسح البحث',
                icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: _liveResults.length,
            itemBuilder: (context, index) {
              return SearchResultCard(hit: _liveResults[index]);
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- surah grid
  Widget _surahGrid({double topPadding = 0}) {
    final quizMode = _quizMode;
    return GridView.builder(
      controller: _scrollController,
      // Top padding tracks the floating bar's bottom edge (curved), so at rest
      // Fatihah/Bakarah sit flush below the buttons and flow up as it hides.
      padding: EdgeInsets.only(top: topPadding, left: 16, right: 16, bottom: 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisExtent: 132,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: kQuranSurahs.length + (quizMode ? 1 : 0),
      itemBuilder: (context, index) {
        if (quizMode && index == 0) return _allQuranTile();
        final surah = kQuranSurahs[index - (quizMode ? 1 : 0)];
        final entry = _data.surahByOrder(surah.order);
        final enabled = quizMode
            ? (entry?.unfamiliarWordsCount ?? 0) > 0
            : entry != null && entry.startPage > 0 && entry.pages.isNotEmpty;
        return _SurahCard(
          surah: surah,
          entry: entry,
          enabled: enabled,
          onTap: enabled ? () => _openSurah(surah) : null,
        );
      },
    );
  }

  // -------------------------------------------------------------- hizb list
  void _openHizb(HizbEntry hizb) {
    // In both reading and quiz mode we drill into the thumun list; quizMode
    // makes that screen offer "whole hizb" + per-thumun quizzes.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HizbThumunsScreen(hizb: hizb, quizMode: _quizMode),
      ),
    );
  }

  Widget _hizbList({double topPadding = 0}) {
    final menu = _data.hizbMenu;
    final scheme = Theme.of(context).colorScheme;
    if (menu == null || menu.hizbs.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Center(
          child: Text('قائمة الأحزاب غير متوفرة',
              style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant)),
        ),
      );
    }
    final bool quizMode = _quizMode;
    return GridView.builder(
      controller: _scrollController,
      padding:
          EdgeInsets.only(top: topPadding, left: 16, right: 16, bottom: 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        mainAxisExtent: 176,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      // In quiz mode, prepend the "all-Quran" quiz tile (same as surah grid).
      itemCount: menu.hizbs.length + (quizMode ? 1 : 0),
      itemBuilder: (context, index) {
        if (quizMode && index == 0) return _allQuranTile();
        final h = menu.hizbs[index - (quizMode ? 1 : 0)];
        return _HizbCard(hizb: h, onTap: () => _openHizb(h));
      },
    );
  }

  Widget _allQuranTile() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startAllQuiz,
          borderRadius: BorderRadius.circular(18),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, color: Color(0xFFFCD34D), size: 30),
              SizedBox(height: 6),
              Text(
                'كل القرآن',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'أسئلة مستمرة من جميع السور',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ card
class _SurahCard extends StatelessWidget {
  final Surah surah;
  final SurahIndexEntry? entry;
  final bool enabled;
  final VoidCallback? onTap;

  const _SurahCard({
    required this.surah,
    required this.entry,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool isMakki = entry?.classification.contains('مك') ?? false;
    final Color badgeColor = !enabled
        ? Colors.grey.shade400
        : (isMakki ? const Color(0xFFE6A15C) : const Color(0xFF0F766E));
    final String type = entry?.classification ?? '';
    final int startPage = entry?.startPage ?? 0;
    final int unfamiliarWordsCount = entry?.unfamiliarWordsCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: enabled ? scheme.surface : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          splashColor: badgeColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              // Subtle Accent Strip on the Side
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 4,
                child: Container(color: badgeColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row: Number Circle Badge + Type Chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              toArabicDigits(surah.order),
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (enabled && type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (!enabled)
                          Text(
                            'غير متاحة',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
const SizedBox(height: 8),

                    // Middle: Surah Name (vertically centered in card)
                    const Spacer(),
                    Center(
                      child: Text(
                        surah.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: enabled
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Stats Row: Page badge (right) + Word count badge (left)
                    Row(
                      children: [
                        Expanded(
                          child: _statBadge(
                            icon: Icons.menu_book_rounded,
                            label: 'صفحة ${toArabicDigits(startPage)}',
                            color: badgeColor,
                            enabled: enabled,
                            alignStart: true,
                            scheme: scheme,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _statBadge(
                            icon: Icons.text_snippet_outlined,
                            label:
                                'كلمة ${toArabicDigits(unfamiliarWordsCount)}',
                            color: badgeColor,
                            enabled: enabled,
                            alignStart: false,
                            scheme: scheme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _statBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required bool alignStart,
    required ColorScheme scheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (enabled ? color : Colors.grey.shade400).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignStart
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: enabled
                  ? color.withValues(alpha: 0.85)
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ hizb card
// Grid tile styled like _SurahCard: side accent strip, number badge + juz chip
// on top, "الحزب N" centered, and stats badges (thumun count + word count).
class _HizbCard extends StatelessWidget {
  final HizbEntry hizb;
  final VoidCallback onTap;

  const _HizbCard({required this.hizb, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const Color badgeColor = Color(0xFF0F766E);
    final int juz = ((hizb.hizb + 1) ~/ 2); // hizb 1-2 -> juz 1, etc.

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          splashColor: badgeColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              // Accent strip on the side (matches surah cards).
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 4,
                child: Container(color: badgeColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top row: number badge + juz chip.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              toArabicDigits(hizb.hizb),
                              style: const TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'جزء ${toArabicDigits(juz)}',
                            style: const TextStyle(
                              color: badgeColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Middle: "الحزب N" centered (dominant element).
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'الحزب ${toArabicDigits(hizb.hizb)}',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Stats row: thumun count (right) + word count (left).
                    Row(
                      children: [
                        Expanded(
                          child: _hizbStatBadge(
                            icon: Icons.bookmark_border_rounded,
                            label: 'ثمن ${toArabicDigits(hizb.thumunCount)}',
                            color: badgeColor,
                            alignStart: true,
                            scheme: scheme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _hizbStatBadge(
                            icon: Icons.menu_book_rounded,
                            label:
                                'كلمة ${toArabicDigits(hizb.totalEntries)}',
                            color: badgeColor,
                            alignStart: false,
                            scheme: scheme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hizbStatBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool alignStart,
    required ColorScheme scheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignStart
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color.withValues(alpha: 0.85)),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
