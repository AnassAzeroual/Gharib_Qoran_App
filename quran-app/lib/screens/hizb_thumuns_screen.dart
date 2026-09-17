import 'package:flutter/material.dart';

import '../models/hizb_menu.dart';
import '../utils/arabic_digits.dart';
import 'thumun_words_screen.dart';

/// Second-level menu: lists the 8 thumuns of a chosen hizb (only those that
/// contain unfamiliar words). Tapping a thumun opens its word list.
class HizbThumunsScreen extends StatelessWidget {
  final HizbEntry hizb;

  const HizbThumunsScreen({super.key, required this.hizb});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الحزب ${toArabicDigits(hizb.hizb)}',
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
      ),
      body: hizb.thumuns.isEmpty
          ? Center(
              child: Text('لا توجد أثمان متاحة',
                  style: TextStyle(
                      fontSize: 16, color: scheme.onSurfaceVariant)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: hizb.thumuns.length,
              itemBuilder: (context, index) {
                final t = hizb.thumuns[index];
                return _ThumunTile(hizb: hizb.hizb, thumun: t);
              },
            ),
    );
  }
}

class _ThumunTile extends StatelessWidget {
  final int hizb;
  final ThumunEntry thumun;

  const _ThumunTile({required this.hizb, required this.thumun});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const accent = Color(0xFF0F766E);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ThumunWordsScreen(
                  hizb: hizb,
                  thumunInHizb: thumun.thumunInHizb,
                  thumunGlobal: thumun.thumun,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      toArabicDigits(thumun.thumunInHizb),
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الثمن ${toArabicDigits(thumun.thumunInHizb)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${toArabicDigits(thumun.entryCount)} كلمة · صفحة ${toArabicDigits(thumun.firstPage)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
