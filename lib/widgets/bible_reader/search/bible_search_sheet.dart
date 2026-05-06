import 'package:flutter/material.dart';

import '../../../database/ko_bible_database.dart';
import '../../../theme/app_colors.dart';
import '../picker/bible_picker_result.dart';
import 'highlighted_verse_text.dart';

enum _BibleSearchScope { all, oldTestament, newTestament }

class BibleSearchSheet extends StatefulWidget {
  final Color backgroundColor;

  const BibleSearchSheet({super.key, required this.backgroundColor});

  @override
  State<BibleSearchSheet> createState() => _BibleSearchSheetState();
}

class _BibleSearchSheetState extends State<BibleSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _resultScrollController = ScrollController();

  Future<List<Map<String, dynamic>>>? _searchFuture;
  String _lastKeyword = '';
  _BibleSearchScope _selectedScope = _BibleSearchScope.all;

  @override
  void dispose() {
    _searchController.dispose();
    _resultScrollController.dispose();
    super.dispose();
  }

  int get _currentLimit {
    switch (_selectedScope) {
      case _BibleSearchScope.all:
        return 200;
      case _BibleSearchScope.oldTestament:
      case _BibleSearchScope.newTestament:
        return 100;
    }
  }

  String? get _currentTestament {
    switch (_selectedScope) {
      case _BibleSearchScope.all:
        return null;
      case _BibleSearchScope.oldTestament:
        return 'OLD';
      case _BibleSearchScope.newTestament:
        return 'NEW';
    }
  }

  String get _scopeLabel {
    switch (_selectedScope) {
      case _BibleSearchScope.all:
        return '전체';
      case _BibleSearchScope.oldTestament:
        return '구약';
      case _BibleSearchScope.newTestament:
        return '신약';
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _search() {
    final keyword = _searchController.text.trim();

    if (keyword.isEmpty) {
      _showMessage('검색어를 입력하세요.');
      return;
    }

    setState(() {
      _lastKeyword = keyword;
      _searchFuture = KoBibleDatabase.instance.searchVerses(
        keyword,
        testament: _currentTestament,
        limit: _currentLimit,
      );
    });

    if (_resultScrollController.hasClients) {
      _resultScrollController.jumpTo(0);
    }
  }

  void _changeScope(_BibleSearchScope scope) {
    if (_selectedScope == scope) {
      return;
    }

    setState(() {
      _selectedScope = scope;
    });

    if (_searchController.text.trim().isNotEmpty) {
      _search();
    }
  }

  Future<void> _openResult(Map<String, dynamic> row) async {
    final bookId = row['book_id'] as int;
    final chapter = row['chapter'] as int;
    final verse = row['verse'] as int;

    final book = await KoBibleDatabase.instance.getBookById(bookId);

    if (!mounted || book == null) {
      return;
    }

    Navigator.pop(
      context,
      BiblePickerResult(book: book, chapter: chapter, verse: verse),
    );
  }

  Widget _buildScopeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          side: BorderSide(
            color: isSelected ? AppColors.textPrimary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          backgroundColor: isSelected
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> row) {
    final bookName = row['name_ko'] as String;
    final chapter = row['chapter'] as int;
    final verse = row['verse'] as int;
    final verseText = row['verse_text'] as String;

    return InkWell(
      onTap: () {
        _openResult(row);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$bookName $chapter:$verse',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            HighlightedVerseText(text: verseText, keyword: _lastKeyword),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return ColoredBox(
      color: widget.backgroundColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 4, 18, bottomSafePadding + 18),
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
                Row(
                  children: [
                    Expanded(
                      child: _buildScopeButton(
                        label: '전체',
                        isSelected: _selectedScope == _BibleSearchScope.all,
                        onTap: () {
                          _changeScope(_BibleSearchScope.all);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildScopeButton(
                        label: '구약',
                        isSelected:
                            _selectedScope == _BibleSearchScope.oldTestament,
                        onTap: () {
                          _changeScope(_BibleSearchScope.oldTestament);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildScopeButton(
                        label: '신약',
                        isSelected:
                            _selectedScope == _BibleSearchScope.newTestament,
                        onTap: () {
                          _changeScope(_BibleSearchScope.newTestament);
                        },
                      ),
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
                      ? Center(
                          child: Text(
                            '검색어를 입력하면 $_scopeLabel 범위에서 찾습니다.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
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
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    0,
                                    4,
                                    10,
                                  ),
                                  child: Text(
                                    '"$_lastKeyword" $_scopeLabel 검색 결과 ${results.length}개 (최대 $_currentLimit개)',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    controller: _resultScrollController,
                                    itemCount: results.length,
                                    padding: EdgeInsets.only(
                                      bottom: bottomSafePadding + 12,
                                    ),
                                    separatorBuilder: (context, index) {
                                      return const Divider(height: 1);
                                    },
                                    itemBuilder: (context, index) {
                                      final row = results[index];
                                      return _buildResultItem(row);
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
      ),
    );
  }
}
