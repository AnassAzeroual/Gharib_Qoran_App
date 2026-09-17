import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../utils/arabic_digits.dart';
import '../screens/page_viewer_screen.dart';

/// A single search result card. Shared by the live search panel and the
/// dedicated search results screen.
class SearchResultCard extends StatelessWidget {
  final SearchHit hit;

  const SearchResultCard({super.key, required this.hit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PageViewerScreen(
              initialPage: hit.page,
              surahName: hit.surahName,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Right page badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      toArabicDigits(hit.page),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'صفحة',
                      style: TextStyle(color: scheme.primary, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (hit.word.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              hit.surahName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (hit.ayahNumber != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              'آية ${toArabicDigits(hit.ayahNumber!)}',
                              style: TextStyle(
                                  color: scheme.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hit.word,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface),
                        textDirection: TextDirection.rtl,
                      ),
                      if (hit.meaning.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          hit.meaning,
                          style: TextStyle(
                              fontSize: 14, color: scheme.onSurfaceVariant),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ],
                  ),
                )
              else
                Expanded(
                  child: Text(
                    hit.surahName,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}