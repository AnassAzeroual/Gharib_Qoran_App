import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/page_data.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../utils/arabic_digits.dart';
import '../widgets/numeral_toggle_button.dart';

class PageViewerScreen extends StatefulWidget {
  final int initialPage;
  final String? surahName;

  const PageViewerScreen({
    super.key,
    required this.initialPage,
    this.surahName,
  });

  @override
  State<PageViewerScreen> createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  final DataService _data = DataService.instance;
  late final PageController _pageController;
  final LinkedHashMap<int, TransformationController> _controllers =
      LinkedHashMap();

  late int _minPage;
  late int _maxPage;
  late int _currentIndex;

  PageData? _pageMeta;
  final Set<int> _zoomedPages = {};

  /// Number of pointers currently touching the page image.
  int _activePointers = 0;

  /// True while a two-finger (pinch) gesture is in progress.
  bool _pinching = false;

  /// PageView should not swipe while pinching or while the page is zoomed.
  bool get _scrollLocked => _pinching || _zoomedPages.contains(_currentIndex);

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers >= 2 && !_pinching) {
      setState(() => _pinching = true);
    }
  }

  void _onPointerEnd() {
    _activePointers = _activePointers > 0 ? _activePointers - 1 : 0;
    if (_activePointers < 2 && _pinching) {
      setState(() => _pinching = false);
    }
  }

  int get _currentPage => _currentIndex + _minPage;

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
    _currentIndex = (widget.initialPage - _minPage).clamp(
      0,
      _maxPage - _minPage,
    );
    _pageController = PageController(initialPage: _currentIndex);
    _loadMeta();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMeta() async {
    final meta = await _data.loadPage(_currentPage);
    if (mounted) setState(() => _pageMeta = meta);
  }

  TransformationController _getController(int index) =>
      _controllers.putIfAbsent(index, TransformationController.new);

  void _pruneControllers() {
    final keep = {_currentIndex - 1, _currentIndex, _currentIndex + 1};
    final toRemove = _controllers.keys.where((k) => !keep.contains(k)).toList();
    for (final k in toRemove) {
      _controllers.remove(k)?.dispose();
      _zoomedPages.remove(k);
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      final old = _controllers[_currentIndex];
      old?.value = Matrix4.identity();
      _zoomedPages.remove(_currentIndex);
    }
    _currentIndex = index;
    _pruneControllers();
    setState(() {
      _pageMeta = null;
    });
    _loadMeta();
  }

  void _toggleZoom(int index) {
    final controller = _getController(index);
    if (controller.value.getMaxScaleOnAxis() > 1.01) {
      controller.value = Matrix4.identity();
    } else {
      controller.value = Matrix4.identity()..scaleByDouble(2.5, 2.5, 1, 1);
    }
  }

  void _attachZoomListener(int index) {
    final controller = _getController(index);
    controller.addListener(() {
      final zoomed = controller.value.getMaxScaleOnAxis() > 1.01;
      final isZoomed = _zoomedPages.contains(index);
      if (zoomed != isZoomed) {
        if (zoomed) {
          _zoomedPages.add(index);
        } else {
          _zoomedPages.remove(index);
        }
        if (mounted) setState(() {});
      }
    });
  }

  String _subtitle() {
    if (_pageMeta != null) {
      final header = _pageMeta!.headerRightNormalized.isNotEmpty
          ? _pageMeta!.headerRightNormalized
          : _pageMeta!.headerLeftNormalized;
      if (header.isNotEmpty) return header;
    }
    return widget.surahName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NumeralSystem>(
      valueListenable: numeralNotifier,
      builder: (context, numeral, _) => Scaffold(
        backgroundColor: const Color(0xFF16191F),
        appBar: AppBar(
          title: Text(
            'الصفحة ${displayNumber(_currentPage)} من ${displayNumber(_maxPage)}',
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          backgroundColor: const Color(0xFF16191F),
          elevation: 0,
          actions: const [NumeralToggleButton()],
        ),
        body: Column(
          children: [
            if (_subtitle().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _subtitle(),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFFCD34D),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: _scrollLocked
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: _maxPage - _minPage + 1,
                itemBuilder: (context, index) {
                  return _buildPage(index);
                },
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    final controller = _getController(index);
    _attachZoomListener(index);
    final zoomed = _zoomedPages.contains(index);

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: (_) => _onPointerEnd(),
      onPointerCancel: (_) => _onPointerEnd(),
      child: InteractiveViewer(
        transformationController: controller,
        minScale: 1,
        maxScale: 5,
        panEnabled: zoomed,
        clipBehavior: Clip.hardEdge,
        child: GestureDetector(
          onDoubleTap: () => _toggleZoom(index),
          child: Center(
            child: Image.asset(
              DataService.pageImagePath(index + _minPage),
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

  void _goTo(int index) {
    final clamped = index.clamp(0, _maxPage - _minPage);
    if (clamped == _currentIndex) return;
    _pageController.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
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
                  color: _currentIndex < _maxPage - _minPage
                      ? const Color(0xFFFCD34D)
                      : Colors.grey,
                  size: 34,
                ),
                tooltip: 'الصفحة التالية',
                onPressed: _currentIndex < _maxPage - _minPage
                    ? () => _goTo(_currentIndex + 1)
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
                  color: _currentIndex > 0
                      ? const Color(0xFFFCD34D)
                      : Colors.grey,
                  size: 34,
                ),
                tooltip: 'الصفحة السابقة',
                onPressed: _currentIndex > 0
                    ? () => _goTo(_currentIndex - 1)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
