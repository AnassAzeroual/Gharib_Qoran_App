import 'dart:async';

import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../models/quiz_word.dart';
import '../services/data_service.dart';
import '../services/quiz_service.dart';
import '../services/sound_service.dart';
import '../utils/arabic_digits.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final int? surahOrder;
  final int? hizb;
  final int? thumun; // global 1..480
  final String? thumunLabel; // e.g. "الحزب ٥١ · الثمن ٨" for the title

  const QuizScreen(
      {super.key, this.surahOrder, this.hizb, this.thumun, this.thumunLabel});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const List<String> _letters = ['أ', 'ب', 'ج'];

  final QuizService _quiz = QuizService.instance;
  final DataService _data = DataService.instance;
  final QuizSession _session = QuizSession();
  final SoundService _sound = SoundService.instance;

  List<QuizWord> _queue = const [];
  int _index = 0;
  bool _loading = true;
  bool _finished = false;
  QuizQuestion? _question;
  Set<int> _wrongPicks = {};
  int? _correctPick;
  int? _answered;

  bool get _isThumunMode => widget.thumun != null;
  bool get _isHizbMode => widget.hizb != null && widget.thumun == null;
  bool get _isAllMode =>
      widget.surahOrder == null && widget.hizb == null && widget.thumun == null;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    _quiz.prime(_data.allQuizWords);
    final List<QuizWord> words = _isAllMode
        ? const []
        : _isThumunMode
            ? _quiz.wordsForThumun(widget.thumun!)
            : _isHizbMode
                ? _quiz.wordsForHizb(widget.hizb!)
                : _quiz.wordsForSurah(widget.surahOrder!);
    if (!_isAllMode && words.isEmpty) {
      if (!mounted) return;
      _showEmptyAndPop();
      return;
    }
    setState(() {
      _queue = words;
      _index = 0;
      _loading = false;
    });
    _next();
  }

  void _showEmptyAndPop() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isThumunMode
            ? 'لا توجد كلمات غريبة في هذا الثمن'
            : _isHizbMode
                ? 'لا توجد كلمات غريبة في هذا الحزب'
                : 'لا توجد كلمات غريبة في هذه السورة'),
      ),
    );
    Navigator.of(context).maybePop();
  }

  void _next() {
    setState(() {
      _wrongPicks = {};
      _correctPick = null;
      _answered = null;
    });
    final QuizWord target = _isAllMode ? _quiz.nextAllWord() : _queue[_index++];
    setState(() {
      _question = _quiz.buildQuestion(target);
    });
  }

  void _onOptionTap(int i) {
    final q = _question;
    if (q == null || _finished || _answered != null) return;
    final option = q.options[i];
    if (option.isCorrect) {
      _session.onCorrect();
      _sound.playCorrect();
      setState(() {
        _correctPick = i;
        _answered = i;
      });
      Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        if (_isAllMode) {
          _next();
        } else if (_index >= _queue.length) {
          _finish();
        } else {
          _next();
        }
      });
    } else {
      _session.onWrong();
      _sound.playWrong();
      setState(() {
        _wrongPicks.add(i);
      });
    }
  }

  String _scopeLabel() {
    if (_isThumunMode) {
      return widget.thumunLabel ?? 'الثمن';
    }
    if (_isHizbMode) return 'الحزب ${toArabicDigits(widget.hizb!)}';
    if (_isAllMode) return 'كل القرآن';
    return kQuranSurahs
        .firstWhere((s) => s.order == widget.surahOrder,
            orElse: () => kQuranSurahs.first)
        .name;
  }

  void _finish() {
    _sound.playFinish();
    setState(() => _finished = true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          session: _session,
          surahOrder: widget.surahOrder,
          hizb: widget.hizb,
          thumun: widget.thumun,
          thumunLabel: widget.thumunLabel,
          surahName: _scopeLabel(),
        ),
      ),
    );
  }

  String _title() => 'اختبر نفسك — ${_scopeLabel()}';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title()),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _sound.soundEnabled,
              builder: (context, on, _) => IconButton(
                tooltip: on ? 'إيقاف الصوت' : 'تشغيل الصوت',
                icon: Icon(
                  on ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
                onPressed: () =>
                    _sound.soundEnabled.value = !_sound.soundEnabled.value,
              ),
            ),
            IconButton(
              tooltip: 'إنهاء الاختبار',
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              onPressed: _confirmFinish,
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              // Center the content and cap its width so it doesn't stretch
              // edge-to-edge on wide screens (web / large monitors).
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        Expanded(child: _contentList()),
                        _bottomBar(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _confirmFinish() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الاختبار؟'),
        content: const Text('ستظهر النتيجة النهائية للأسئلة التي أجبت عنها.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('متابعة'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    ).then((value) {
      if (value == true && mounted) {
        if (_session.correctCount == 0 && _session.wrongCount == 0) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        } else {
          _finish();
        }
      }
    });
  }

  void _confirmQuit() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الخروج من الاختبار؟'),
        content: const Text('سيتم فقدان التقدم الحالي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('البقاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    ).then((value) {
      if (value == true && mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });
  }

  Widget _contentList() {
    final scheme = Theme.of(context).colorScheme;
    final q = _question;
    if (q == null) return const SizedBox.shrink();

    final progress = _isAllMode
        ? _quiz.allModeProgress
        : (_queue.isEmpty ? 0.0 : (_index / _queue.length).clamp(0.0, 1.0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      children: [
        Row(
          children: [
            Text(
              _isAllMode
                  ? 'جميع السور'
                  : '${toArabicDigits(_index)} / ${toArabicDigits(_queue.length)}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: scheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (q.word.surahName.isNotEmpty)
                    _contextChip(Icons.menu_book, q.word.surahName, scheme),
                  if (q.word.ayahNumber != null)
                    _contextChip(
                        Icons.format_list_numbered,
                        'آية ${toArabicDigits(q.word.ayahNumber!)}',
                        scheme),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  q.word.word,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (q.word.ayah.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    q.word.ayah,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 19,
                      height: 1.7,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _optionCard(context, i, q),
          ),
      ],
    );
  }

  Widget _contextChip(IconData icon, String label, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: scheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(BuildContext context, int i, QuizQuestion q) {
    final scheme = Theme.of(context).colorScheme;
    final option = q.options[i];

    final bool isCorrectPick = _correctPick == i;
    final bool isWrongPick = _wrongPicks.contains(i);

    final Color bg;
    final Color fg;
    Color border = scheme.outlineVariant;
    if (isCorrectPick) {
      bg = const Color(0xFF16A34A);
      fg = Colors.white;
      border = Colors.transparent;
    } else if (isWrongPick) {
      bg = const Color(0xFFDC2626);
      fg = Colors.white;
      border = Colors.transparent;
    } else {
      bg = scheme.surface;
      fg = scheme.onSurface;
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: isCorrectPick || isWrongPick
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: InkWell(
          onTap: () => _onOptionTap(i),
          borderRadius: BorderRadius.circular(16),
          highlightColor: scheme.primary.withValues(alpha: 0.08),
          splashColor: scheme.primary.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isCorrectPick || isWrongPick
                        ? Colors.white.withValues(alpha: 0.22)
                        : scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _letters[i],
                      style: TextStyle(
                        color: isCorrectPick || isWrongPick
                            ? Colors.white
                            : scheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.label,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      color: fg,
                    ),
                  ),
                ),
                if (isCorrectPick)
                  const Icon(Icons.check_circle, color: Colors.white, size: 22)
                else if (isWrongPick)
                  const Icon(Icons.cancel, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _scoreCard(
              label: 'إجابات صحيحة',
              count: _session.correctCount,
              color: const Color(0xFF16A34A),
              icon: Icons.check_circle_outline,
              scheme: scheme,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _scoreCard(
              label: 'إجابات خاطئة',
              count: _session.wrongCount,
              color: const Color(0xFFDC2626),
              icon: Icons.cancel_outlined,
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required ColorScheme scheme,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$label ${toArabicDigits(count)}',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}