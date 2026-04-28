import 'package:flutter/material.dart';

import '../../../database/bible_database.dart';
import '../../../theme/app_colors.dart';
import '../picker/bible_picker_result.dart';
import 'highlighted_verse_text.dart';

class BibleSearchSheet extends StatefulWidget {
  final Color backgroundColor;

  const BibleSearchSheet({super.key, required this.backgroundColor});

  @override
  State<BibleSearchSheet> createState() => _BibleSearchSheetState();
}

class _BibleSearchSheetState extends State<BibleSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  Future<List<Map<String, dynamic>>>? _searchFuture;
  String _lastKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final keyword = _searchController.text.trim();

    if (keyword.isEmpty) {
      return;
    }

    setState(() {
      _lastKeyword = keyword;
      _searchFuture = BibleDatabase.instance.searchVerses(keyword);
    });
  }

  Future<void> _openResult(Map<String, dynamic> row) async {
    final bookId = row['book_id'] as int;
    final chapter = row['chapter'] as int;
    final verse = row['verse'] as int;

    final book = await BibleDatabase.instance.getBookById(bookId);

    if (!mounted || book == null) {
      return;
    }

    Navigator.pop(
      context,
      BiblePickerResult(book: book, chapter: chapter, verse: verse),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      '성경 검색',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _search();
                },
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.82),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _searchFuture == null
                    ? const Center(
                        child: Text(
                          '검색어를 입력하면 본문에서 찾습니다.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _searchFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('오류 발생: ${snapshot.error}'),
                            );
                          }

                          final results = snapshot.data ?? [];

                          if (results.isEmpty) {
                            return Center(
                              child: Text(
                                '"$_lastKeyword" 검색 결과가 없습니다.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                                child: Text(
                                  '"$_lastKeyword" 검색 결과 ${results.length}개',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: results.length,
                                  separatorBuilder: (context, index) {
                                    return const Divider(height: 1);
                                  },
                                  itemBuilder: (context, index) {
                                    final row = results[index];

                                    final bookName = row['name_ko'] as String;
                                    final chapter = row['chapter'] as int;
                                    final verse = row['verse'] as int;
                                    final verseText =
                                        row['verse_text'] as String;

                                    return ListTile(
                                      title: Text(
                                        '$bookName $chapter:$verse',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      subtitle: HighlightedVerseText(
                                        text: verseText,
                                        keyword: _lastKeyword,
                                      ),
                                      onTap: () {
                                        _openResult(row);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
