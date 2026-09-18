import 'dart:async';

import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../models/quiz_word.dart';
import '../services/data_service.dart';
import '../services/quiz_service.dart';
import '../services/ayah_highlighter.dart';
import '../services/sound_service.dart';
import '../theme.dart';
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

  // Palette from the minimalist target design.
  static const Color _canvas = Color(0xFFFBFBFB);
  static const Color _promptOrange = Color(0xFFE07A5F);
  static const Color _wordDark = Color(0xFF4A4A4A);
  static const Color _verseGreen = Color(0xFF2FA885);
  static const Color _refGrey = Color(0xFF9AA0A6);
  static const Color _goldTop = Color(0xFFE5C158);
  static const Color _goldBottom = Color(0xFFC89B27);

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

  // Whether the ayah (verse context) panel is revealed. Hidden by default so
  // the rare word/meaning comes first; the gold toggle expands it.
  bool _ayahExpanded = false;

  bool get _isThumunMode => widget.thumun != null;
  bool get _isHizbMode => widget.hizb != null && widget.thumun == null;
  bool get _isAllMode =>
      widget.surahOrder == null && widget.hizb == null && widget.thumun == null;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _toggleAyah() {
    setState(() => _ayahExpanded = !_ayahExpanded);
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
      // Keep the user's ayah open/closed choice across questions; it only
      // resets when they leave the quiz page (this state is recreated).
    });
    final QuizWord target = _isAllMode ? _quiz.nextAllWord() : _queue[_index++];
    setState(() {
      _question = _quiz.buildQuestion(target);
    });
  }

  void _increaseFont() {
    quizFontScaleNotifier.value = (quizFontScaleNotifier.value + kQuizScaleStep)
        .clamp(kQuizScaleMin, kQuizScaleMax);
  }

  void _decreaseFont() {
    quizFontScaleNotifier.value = (quizFontScaleNotifier.value - kQuizScaleStep)
        .clamp(kQuizScaleMin, kQuizScaleMax);
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
        backgroundColor: _canvas,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ValueListenableBuilder<double>(
                      valueListenable: quizFontScaleNotifier,
                      builder: (context, scale, _) => _quizBody(scale),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Minimalist layout: clean canvas with the prompt top-right and a collapsible
  // verse in the middle; the gold toggle reveals/hides the ayah. The answer
  // choices are always on screen at the bottom.
  Widget _quizBody(double scale) {
    final scheme = Theme.of(context).colorScheme;
    final q = _question;
    if (q == null) return const SizedBox.shrink();

    final progress = _isAllMode
        ? _quiz.allModeProgress
        : (_queue.isEmpty ? 0.0 : (_index / _queue.length).clamp(0.0, 1.0));

    // Single scroll flow: expanding a long ayah naturally pushes the answer
    // choices down (they never float under/behind it), and the gold toggle
    // always sits right beneath the verse.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Row(
          children: [
            // Compact live score: ✓ correct  ✗ wrong.
            _miniScore(Icons.check_circle, _session.correctCount,
                const Color(0xFF16A34A)),
            const SizedBox(width: 8),
            _miniScore(Icons.cancel, _session.wrongCount,
                const Color(0xFFDC2626)),
            const SizedBox(width: 12),
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
            const SizedBox(width: 10),
            Text(
              _isAllMode
                  ? 'جميع السور'
                  : '${toArabicDigits(_index)} / ${toArabicDigits(_queue.length)}',
              style: const TextStyle(color: _refGrey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _fontSizeControl(scheme),
        const SizedBox(height: 6),
        // Prompt, aligned to the top-right.
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ما معنى كلمة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15 * scale,
                  color: _promptOrange,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${q.word.word}؟',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 32 * scale,
                    fontWeight: FontWeight.bold,
                    color: _wordDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Collapsible verse: hidden by default, the gold toggle reveals it.
        // Growing the verse pushes the answers down instead of overlaying them.
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _ayahExpanded
              ? _verseBlock(q, scheme, scale)
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 12),
        Center(child: _ayahToggle()),
        const SizedBox(height: 20),
        // Answer choices, always on screen.
        Column(
          children: [
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _optionCard(context, i, q, scale),
              ),
          ],
        ),
      ],
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

  // Centered verse block: "قال تعالى" + the verse (with brackets ﴿ ﴾ and the
  // active word highlighted green) + the reference, all on the clean canvas.
  Widget _verseBlock(QuizQuestion q, ColorScheme scheme, double scale) {
    if (q.word.ayah.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'قَالَ تَعَالَىٰ:',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 15 * scale,
            color: _refGrey,
          ),
        ),
        SizedBox(height: 14 * scale),
        _ayahText(q, scale),
        if (q.word.surahName.isNotEmpty || q.word.ayahNumber != null) ...[
          SizedBox(height: 12 * scale),
          Text(
            _ayahReference(q),
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13 * scale,
              color: _refGrey,
            ),
          ),
        ],
      ],
    );
  }

  // ⊕  حجم الخط  ⊖  control that scales all text on the quiz page.
  Widget _fontSizeControl(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _roundIconButton(
          icon: Icons.add,
          tooltip: 'تكبير حجم الخط',
          onTap: _increaseFont,
          scheme: scheme,
        ),
        const SizedBox(width: 12),
        Text(
          'حجم الخط',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 15,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        _roundIconButton(
          icon: Icons.remove,
          tooltip: 'تصغير حجم الخط',
          onTap: _decreaseFont,
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
        ),
      ),
    );
  }

  // Renders the verse wrapped in ornate brackets ﴿ ﴾ with the glossary word
  // highlighted green. Falls back to plain (bracketed) text when the word
  // can't be located cleanly — the Quran text is never altered, only colored.
  Widget _ayahText(QuizQuestion q, double scale) {
    final baseStyle = TextStyle(
      fontFamily: 'Amiri',
      fontSize: 24 * scale,
      height: 1.8,
      color: _wordDark,
    );
    const bracketStyle = TextStyle(color: _refGrey);

    final match = AyahHighlighter.split(q.word.ayah, q.word.word);

    final List<InlineSpan> verseSpans;
    if (match == null) {
      verseSpans = [TextSpan(text: q.word.ayah)];
    } else {
      verseSpans = [
        TextSpan(text: match.before),
        TextSpan(
          text: match.match,
          style: const TextStyle(
            color: _verseGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: match.after),
      ];
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: '﴿ ', style: bracketStyle),
          ...verseSpans,
          const TextSpan(text: ' ﴾', style: bracketStyle),
        ],
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );
  }

  // Reference line shown under the ayah, e.g. "[الفاتحة : ١]".
  String _ayahReference(QuizQuestion q) {
    final name = q.word.surahName;
    final ayah = q.word.ayahNumber;
    if (name.isNotEmpty && ayah != null) {
      return '[$name : ${toArabicDigits(ayah)}]';
    }
    if (name.isNotEmpty) return '[$name]';
    if (ayah != null) return '[آية ${toArabicDigits(ayah)}]';
    return '';
  }

  // Circular gold gradient button that reveals/hides the ayah verse. The
  // chevron flips as the panel expands/collapses.
  Widget _ayahToggle() {
    return GestureDetector(
      onTap: _toggleAyah,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_goldTop, _goldBottom],
          ),
          boxShadow: [
            BoxShadow(
              color: _goldBottom.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedRotation(
          turns: _ayahExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _optionCard(BuildContext context, int i, QuizQuestion q, double scale) {
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
                        fontSize: 15 * scale,
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
                      fontSize: 18 * scale,
                      height: 1.4,
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

  // Compact live score chip: icon + count.
  Widget _miniScore(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            toArabicDigits(count),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
