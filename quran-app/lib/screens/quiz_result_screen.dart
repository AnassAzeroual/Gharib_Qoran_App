import 'package:flutter/material.dart';

import '../models/quiz_word.dart';
import '../theme.dart';
import '../utils/arabic_digits.dart';
import '../widgets/numeral_toggle_button.dart';
import 'quiz_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizSession session;
  final int? surahOrder;
  final int? hizb;
  final int? thumun;
  final String? thumunLabel;
  final String surahName;

  const QuizResultScreen({
    super.key,
    required this.session,
    required this.surahName,
    this.surahOrder,
    this.hizb,
    this.thumun,
    this.thumunLabel,
  });

  int get _total => session.correctCount + session.wrongCount;

  String get _message {
    final pct = session.percentage;
    if (_total == 0) {
      return 'لم تجب عن أي سؤال، حاول مرة أخرى.';
    }
    if (pct >= 80) {
      return 'ممتاز! إتقان رائع للكلمات الغريبة في هذا النطاق، أحسنت.';
    }
    if (pct >= 50) {
      return 'جيد، واصل التدريب لتحسين الإلمام بالكلمات.';
    }
    return 'لا بأس، راجع معاني الكلمات ثم أعد المحاولة.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<NumeralSystem>(
      valueListenable: numeralNotifier,
      builder: (context, numeral, _) => Scaffold(
        appBar: AppBar(
          title: const Text('نتيجة الاختبار'),
          actions: const [NumeralToggleButton()],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.4),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${displayNumber(session.percentage.round())}%',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                            Text(
                              'نسبة الدقة',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'مبارك عليك إتمام الاختبار: $surahName',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            scheme: scheme,
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF16A34A),
                            label: 'إجابات صحيحة',
                            count: session.correctCount,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            scheme: scheme,
                            icon: Icons.cancel_outlined,
                            color: const Color(0xFFDC2626),
                            label: 'إجابات خاطئة',
                            count: session.wrongCount,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة الاختبار'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                surahOrder: surahOrder,
                                hizb: hizb,
                                thumun: thumun,
                                thumunLabel: thumunLabel,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('العودة إلى الرئيسية'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required ColorScheme scheme,
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              displayNumber(count),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
