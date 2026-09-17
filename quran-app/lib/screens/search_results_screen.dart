import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../utils/arabic_digits.dart';
import '../widgets/search_result_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final DataService _data = DataService.instance;
  late List<SearchHit> _results;

  @override
  void initState() {
    super.initState();
    _results = _data.search(widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EC),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          'نتائج البحث: «${widget.query}»',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17),
        ),
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('لا توجد نتائج',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '${toArabicDigits(_results.length)} نتيجة',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final hit = _results[index];
                        return SearchResultCard(hit: hit);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}