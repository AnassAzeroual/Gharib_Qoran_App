import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/page_data.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/arabic_digits.dart';
import '../widgets/numeral_toggle_button.dart';

/// Side-by-side verification screen: the scanned page image on one side and
/// the OCR glossary list for that same page on the other, with prev/next
/// navigation to step through pages and compare them by eye.
class VerificationScreen extends StatefulWidget {
  final int initialPage;
  final String? surahName;

  const VerificationScreen({
    super.key,
    required this.initialPage,
    this.surahName,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final DataService _data = DataService.instance;

  late int _currentPage;
  late int _minPage;
  late int _maxPage;
  PageData? _pageData;
  bool _loading = false;

  final TransformationController _imageController = TransformationController();
  final ScrollController _listScroll = ScrollController();
  bool _zoomed = false;
  bool _landscape = false;
  bool _fullscreen = false;

  /// Base font size for the glossary list (adjustable with + / -).
  double _listFontSize = 22;
  static const double _minFontSize = 14;
  static const double _maxFontSize = 44;

  /// Fraction of the available space given to the page image (top / right).
  /// The glossary list gets the remaining (1 - _imageFraction). Adjustable by
  /// dragging the divider between the two panes.
  double _imageFraction = 0.6; // was flex 3:2 => 0.6
  static const double _minImageFraction = 0.25;
  static const double _maxImageFraction = 0.85;
  static const double _dividerThickness = 14;

  void _changeFontSize(double delta) {
    setState(() {
      _listFontSize = (_listFontSize + delta).clamp(_minFontSize, _maxFontSize);
    });
  }

  @override
  void initState() {
    super.initState();
    final pages = _data.availablePages;
    if (pages.isNotEmpty) {
      _minPage = pages.first;
      _maxPage = pages.last;
    } else {
      _minPage = 1;
      _maxPage = _data.totalImages > 0 ? _data.totalImages : 350;
    }
    _currentPage = widget.initialPage.clamp(_minPage, _maxPage);
    _imageController.addListener(_onZoomChanged);
    _load();
  }

  @override
  void dispose() {
    _imageController.removeListener(_onZoomChanged);
    _imageController.dispose();
    _listScroll.dispose();
    // Release any orientation and system-UI mode we forced while open.
    SystemChrome.setPreferredOrientations([]);
    if (_isMobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _onZoomChanged() {
    final zoomed = _imageController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _data.loadPage(_currentPage);
    if (mounted) {
      setState(() {
        _pageData = data;
        _loading = false;
        _imageController.value = Matrix4.identity();
      });
    }
    if (_listScroll.hasClients) {
      _listScroll.jumpTo(0);
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

  void _goTo(int page) {
    final clamped = page.clamp(_minPage, _maxPage);
    if (clamped == _currentPage) return;
    setState(() => _currentPage = clamped);
    _load();
  }

  String _subtitle() {
    if (_pageData != null) {
      final header = _pageData!.headerRightNormalized.isNotEmpty
          ? _pageData!.headerRightNormalized
          : _pageData!.headerLeftNormalized;
      if (header.isNotEmpty) return header;
    }
    return widget.surahName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<NumeralSystem>(
      valueListenable: numeralNotifier,
      builder: (context, numeral, _) => Scaffold(
        backgroundColor: scheme.surface,
        // Immersive: no AppBar, the panes fill the whole screen. A floating mini
        // header (back + reference, rotate on phones) and the bottom bar overlay
        // the content. Tapping anywhere toggles a pure fullscreen mode where all
        // of these (plus the Android system bars) are hidden.
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleFullscreen,
          child: Stack(
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
                          final double listTopInset = (!_fullscreen && wide)
                              ? 64
                              : 0;
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
                                // Left side (RTL end): glossary list
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
                    if (!_fullscreen) _bottomBar(context),
                  ],
                ),
              ),
              // Floating mini header (hidden in fullscreen).
              if (!_fullscreen)
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
      ),
    );
  }

  /// True fullscreen: hides every control AND the Android system bars so only
  /// the page content is visible. Tapping again restores everything.
  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    if (!_isMobile) return;
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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

  // Small floating reference chip showing only the surah/page header text
  // (no page counter) so it stays out of the way.
  Widget _referenceChip() {
    final subtitle = _subtitle();
    if (subtitle.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
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
        subtitle,
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

  /// Draggable divider between the page image and the glossary list.
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
    return Container(
      color: const Color(0xFF16191F),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = _pageData;
    if (data == null) {
      return Center(
        child: Text(
          'لا توجد بيانات JSON لهذه الصفحة',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final sections = data.sections;
    if (sections.isEmpty) {
      return Center(
        child: Text(
          'لا توجد كلمات غريبة في هذه الصفحة',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      );
    }

    return ListView(
      controller: _listScroll,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      children: [for (final section in sections) ..._sectionWidgets(section)],
    );
  }

  List<Widget> _sectionWidgets(PageSection section) {
    final widgets = <Widget>[];

    if (section.type == 'surah_section' && section.surah != null) {
      final surah = section.surah!;
      widgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${surah.name} — كلمة ${displayNumber(section.glossary.length)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: _listFontSize * 0.77,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      for (final entry in section.glossary) {
        widgets.add(
          _entryTile(
            number: entry.ayahNumber,
            word: entry.word,
            meaning: entry.meaning,
          ),
        );
      }
    } else if (section.type == 'preliminary_entries') {
      if (section.entries.isNotEmpty) {
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE6A15C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'مقدمة الكتاب',
              style: TextStyle(
                color: Colors.white,
                fontSize: _listFontSize * 0.77,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        );
        for (final entry in section.entries) {
          widgets.add(
            _entryTile(number: null, word: entry.term, meaning: entry.meaning),
          );
        }
      }
    }

    return widgets;
  }

  Widget _entryTile({
    int? number,
    required String word,
    required String meaning,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              if (number != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'آية ${displayNumber(number)}',
                    style: TextStyle(
                      fontSize: _listFontSize * 0.68,
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: _listFontSize,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                    fontFamily: 'Amiri',
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'المعنى: ${meaning.isEmpty ? '—' : meaning}',
            style: TextStyle(
              fontSize: _listFontSize * 0.82,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      color: const Color(0xFF16191F),
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
                  color: _currentPage < _maxPage
                      ? const Color(0xFFFCD34D)
                      : Colors.grey,
                  size: 34,
                ),
                tooltip: 'الصفحة التالية',
                onPressed: _currentPage < _maxPage
                    ? () => _goTo(_currentPage + 1)
                    : null,
              ),
              Text(
                '${displayNumber(_currentPage)} / ${displayNumber(_maxPage)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _currentPage > _minPage
                      ? const Color(0xFFFCD34D)
                      : Colors.grey,
                  size: 34,
                ),
                tooltip: 'الصفحة السابقة',
                onPressed: _currentPage > _minPage
                    ? () => _goTo(_currentPage - 1)
                    : null,
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
