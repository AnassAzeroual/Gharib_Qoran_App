import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/data_service.dart';
import '../theme.dart';
import '../utils/arabic_digits.dart';
import '../widgets/numeral_toggle_button.dart';

/// Thumun verification screen: the thumun's glossary words on one side and
/// the real book page image on the other — the Hizb-menu counterpart of
/// VerificationScreen. The word list covers the whole thumun (which may span
/// several pages); tapping a word jumps the image to that word's page, and
/// the bottom bar steps through the thumun's pages.
class ThumunVerificationScreen extends StatefulWidget {
  final int hizb; // 1..60
  final int thumunInHizb; // 1..8
  final int thumunGlobal; // 1..480
  final List<int> pages; // thumun pages from the hizb menu

  const ThumunVerificationScreen({
    super.key,
    required this.hizb,
    required this.thumunInHizb,
    required this.thumunGlobal,
    this.pages = const [],
  });

  @override
  State<ThumunVerificationScreen> createState() =>
      _ThumunVerificationScreenState();
}

class _ThumunVerificationScreenState extends State<ThumunVerificationScreen> {
  late final List<ThumunWord> _words;
  late final List<int> _pages;
  late int _currentPage;

  final TransformationController _imageController = TransformationController();
  final ScrollController _listScroll = ScrollController();
  bool _zoomed = false;
  bool _landscape = false;

  /// Base font size for the word list (adjustable with + / -).
  double _listFontSize = 22;
  static const double _minFontSize = 14;
  static const double _maxFontSize = 44;

  /// Fraction of the available space given to the page image (right / top).
  /// The word list gets the remaining (1 - _imageFraction). Adjustable by
  /// dragging the divider between the two panes.
  double _imageFraction = 0.6;
  static const double _minImageFraction = 0.25;
  static const double _maxImageFraction = 0.85;
  static const double _dividerThickness = 14;

  @override
  void initState() {
    super.initState();
    _words = DataService.instance.glossaryByThumun(widget.thumunGlobal);
    // Union of menu pages and word pages (sorted); either source alone can
    // lag behind the other after a data resync.
    final all = <int>{...widget.pages};
    for (final w in _words) {
      all.add(w.page);
    }
    final sorted = all.toList()..sort();
    _pages = sorted;
    _currentPage = sorted.isNotEmpty ? sorted.first : 0;
    _imageController.addListener(_onZoomChanged);
  }

  @override
  void dispose() {
    _imageController.removeListener(_onZoomChanged);
    _imageController.dispose();
    _listScroll.dispose();
    // Release any orientation we forced while open.
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  void _onZoomChanged() {
    final zoomed = _imageController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      if (mounted) setState(() {});
    }
  }

  void _toggleZoom() {
    if (_zoomed) {
      _imageController.value = Matrix4.identity();
    } else {
      _imageController.value = Matrix4.identity()
        ..scaleByDouble(2.5, 2.5, 1, 1);
    }
  }

  void _goToPage(int page) {
    if (!_pages.contains(page) || page == _currentPage) return;
    setState(() {
      _currentPage = page;
      _imageController.value = Matrix4.identity();
    });
  }

  void _step(int delta) {
    if (_pages.isEmpty) return;
    final next = _pages.indexOf(_currentPage) + delta;
    if (next >= 0 && next < _pages.length) _goToPage(_pages[next]);
  }

  void _changeFontSize(double delta) {
    setState(() {
      _listFontSize = (_listFontSize + delta).clamp(_minFontSize, _maxFontSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<NumeralSystem>(
      valueListenable: numeralNotifier,
      builder: (context, numeral, _) => Scaffold(
        backgroundColor: scheme.surface,
        // Immersive: no AppBar, the panes fill the whole screen. A floating
        // mini header (back + reference, rotate on phones) and the bottom
        // bar overlay the content.
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool wide = constraints.maxWidth >= 600;
                        // Keep the top of the list clear of the floating header
                        // in wide/landscape mode, where they overlap.
                        final double listTopInset = wide ? 64 : 0;
                        // Available space for the two panes (minus the divider).
                        final double total =
                            (wide
                                ? constraints.maxWidth
                                : constraints.maxHeight) -
                            _dividerThickness;
                        final double imageExtent = (total * _imageFraction)
                            .clamp(0.0, total);
                        final double listExtent = total - imageExtent;

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Right side (RTL start): page image
                              SizedBox(
                                width: imageExtent,
                                child: _imagePane(),
                              ),
                              _dividerHandle(wide: true, total: total),
                              // Left side (RTL end): thumun word list
                              SizedBox(
                                width: listExtent,
                                child: _listPane(topInset: listTopInset),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            SizedBox(
                              height: imageExtent,
                              child: _imagePane(),
                            ),
                            _dividerHandle(wide: false, total: total),
                            SizedBox(
                              height: listExtent,
                              child: _listPane(topInset: listTopInset),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  _bottomBar(context),
                ],
              ),
            ),
            // Floating mini header.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _floatingRoundIcon(
                        Icons.arrow_back_rounded,
                        'رجوع',
                        () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(child: Center(child: _referenceChip())),
                      _isMobile
                          ? _floatingRoundIcon(
                              Icons.screen_rotation_rounded,
                              _landscape ? 'دوران عمودي' : 'دوران أفقي',
                              _toggleOrientation,
                            )
                          : const SizedBox(width: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Whether this platform can rotate (phones/tablets). Desktops/web resize
  // their window instead, so no orientation button is offered there.
  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _toggleOrientation() {
    setState(() => _landscape = !_landscape);
    if (_landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  Widget _floatingRoundIcon(IconData icon, String tooltip, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }

  // Reference chip: hizb / thumun / current page, so it stays out of the way.
  Widget _referenceChip() {
    final scheme = Theme.of(context).colorScheme;
    final label = _pages.isEmpty
        ? 'الحزب ${displayNumber(widget.hizb)} · الثمن ${displayNumber(widget.thumunInHizb)}'
        : 'الحزب ${displayNumber(widget.hizb)} · الثمن ${displayNumber(widget.thumunInHizb)} · صفحة ${displayNumber(_currentPage)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          color: scheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Draggable divider between the page image and the word list.
  /// Drag it to give the page image more or less space.
  Widget _dividerHandle({required bool wide, required double total}) {
    final scheme = Theme.of(context).colorScheme;

    void applyDelta(double delta) {
      if (total <= 0) return;
      setState(() {
        _imageFraction = (_imageFraction + delta / total).clamp(
          _minImageFraction,
          _maxImageFraction,
        );
      });
    }

    final Widget grip = Container(
      color: scheme.surface,
      alignment: Alignment.center,
      child: Container(
        width: wide ? 4 : 44,
        height: wide ? 44 : 4,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );

    return MouseRegion(
      cursor: wide
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: wide ? null : (d) => applyDelta(d.delta.dy),
        // In wide mode the layout is RTL: the image pane sits on the RIGHT, so
        // growing its fraction must correspond to dragging the handle LEFT.
        // Physical dx is negative when dragging left, hence invert it.
        onHorizontalDragUpdate: wide ? (d) => applyDelta(-d.delta.dx) : null,
        // Double-tap the handle to reset to the default split.
        onDoubleTap: () => setState(() => _imageFraction = 0.6),
        child: SizedBox(
          width: wide ? _dividerThickness : double.infinity,
          height: wide ? double.infinity : _dividerThickness,
          child: grip,
        ),
      ),
    );
  }

  Widget _imagePane() {
    if (_pages.isEmpty) {
      return Container(
        color: paletteNotifier.value.viewerBg,
        alignment: Alignment.center,
        child: const Text(
          'لا توجد صفحات لهذا الثمن',
          style: TextStyle(color: Colors.white70, fontFamily: 'Amiri'),
        ),
      );
    }
    return Container(
      color: paletteNotifier.value.viewerBg,
      child: InteractiveViewer(
        transformationController: _imageController,
        minScale: 1,
        maxScale: 6,
        panEnabled: _zoomed,
        clipBehavior: Clip.hardEdge,
        child: GestureDetector(
          onDoubleTap: _toggleZoom,
          child: Center(
            child: Image.asset(
              DataService.pageImagePath(_currentPage),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stack) => const Center(
                child: Text(
                  'تعذر تحميل الصفحة',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _listPane({double topInset = 0}) {
    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: Column(
        children: [
          _fontControls(),
          Expanded(child: _listContent()),
        ],
      ),
    );
  }

  Widget _fontControls() {
    final canDecrease = _listFontSize > _minFontSize;
    final canIncrease = _listFontSize < _maxFontSize;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: 'تصغير الخط',
            icon: Icon(
              Icons.remove_circle_outline,
              color: canDecrease
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            onPressed: canDecrease ? () => _changeFontSize(-2) : null,
          ),
          const SizedBox(width: 4),
          Text(
            'حجم الخط',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: 'تكبير الخط',
            icon: Icon(
              Icons.add_circle_outline,
              color: canIncrease
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            onPressed: canIncrease ? () => _changeFontSize(2) : null,
          ),
        ],
      ),
    );
  }

  Widget _listContent() {
    final scheme = Theme.of(context).colorScheme;
    if (_words.isEmpty) {
      return Center(
        child: Text(
          'لا توجد كلمات غريبة في هذا الثمن',
          style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      controller: _listScroll,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      itemCount: _words.length,
      itemBuilder: (context, index) {
        final w = _words[index];
        return _wordTile(w, current: w.page == _currentPage);
      },
    );
  }

  Widget _wordTile(ThumunWord w, {required bool current}) {
    final scheme = Theme.of(context).colorScheme;
    final accent = paletteNotifier.value.thumunVerifyAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: current ? accent : scheme.outlineVariant,
          width: current ? 1.6 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          // Jump the page image to this word's page.
          onTap: () => _goToPage(w.page),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'صفحة ${displayNumber(w.page)}',
                        style: TextStyle(
                          color: accent,
                          fontSize: _listFontSize * 0.6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (w.surahName.isNotEmpty)
                      Flexible(
                        child: Text(
                          w.ayahNumber != null
                              ? '${w.surahName} · آية ${displayNumber(w.ayahNumber!)}'
                              : w.surahName,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: _listFontSize * 0.6,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  w.word,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: _listFontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
                if (w.meaning.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    w.meaning,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: _listFontSize * 0.75,
                      height: 1.5,
                      color: scheme.onSurface,
                      fontFamily: 'Amiri',
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

  Widget _bottomBar(BuildContext context) {
    final int index = _pages.indexOf(_currentPage);
    final bool hasPrev = index > 0;
    final bool hasNext = index >= 0 && index < _pages.length - 1;
    return Container(
      color: paletteNotifier.value.thumunVerifyNav,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: hasNext ? paletteNotifier.value.gold : Colors.grey,
                  size: 34,
                ),
                tooltip: 'الصفحة التالية',
                onPressed: hasNext ? () => _step(1) : null,
              ),
              Text(
                _pages.isEmpty
                    ? '—'
                    : 'صفحة ${displayNumber(_currentPage)} · ${displayNumber(index + 1)} / ${displayNumber(_pages.length)}',
                // LTR base direction so the "1 / 5" position fraction is not
                // bidi-reordered into "5 / 1" by the surrounding RTL text.
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: hasPrev ? paletteNotifier.value.gold : Colors.grey,
                  size: 34,
                ),
                tooltip: 'الصفحة السابقة',
                onPressed: hasPrev ? () => _step(-1) : null,
              ),
              const SizedBox(width: 12),
              const NumeralToggleButton(),
            ],
          ),
        ),
      ),
    );
  }
}
