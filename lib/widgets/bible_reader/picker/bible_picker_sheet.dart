import 'package:flutter/material.dart';

import '../../../database/bible_database.dart';
import '../../../models/bible_book.dart';
import '../../../models/bible_verse.dart';
import '../../../theme/app_colors.dart';
import 'bible_picker_header.dart';
import 'bible_picker_result.dart';
import 'picker_number_button.dart';
import 'testament_tab_button.dart';

enum BibleTestamentGroup { oldTestament, newTestament }

class BiblePickerSheet extends StatefulWidget {
  final BibleBook currentBook;
  final int currentChapter;
  final Color backgroundColor;

  const BiblePickerSheet({
    super.key,
    required this.currentBook,
    required this.currentChapter,
    required this.backgroundColor,
  });

  @override
  State<BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends State<BiblePickerSheet> {
  late Future<List<BibleBook>> _booksFuture;
  late BibleTestamentGroup _selectedTestamentGroup;

  BibleBook? _selectedBook;
  int? _selectedChapter;
  Future<List<BibleVerse>>? _versesFuture;

  @override
  void initState() {
    super.initState();

    _booksFuture = BibleDatabase.instance.getBooks();

    _selectedTestamentGroup = widget.currentBook.bookId <= 39
        ? BibleTestamentGroup.oldTestament
        : BibleTestamentGroup.newTestament;
  }

  void _selectBook(BibleBook book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = null;
      _versesFuture = null;
    });
  }

  void _selectChapter(int chapter) {
    final book = _selectedBook;

    if (book == null) {
      return;
    }

    setState(() {
      _selectedChapter = chapter;
      _versesFuture = BibleDatabase.instance.getVerses(
        bookId: book.bookId,
        chapter: chapter,
      );
    });
  }

  void _backStep() {
    if (_selectedChapter != null) {
      setState(() {
        _selectedChapter = null;
        _versesFuture = null;
      });
      return;
    }

    if (_selectedBook != null) {
      setState(() {
        _selectedBook = null;
        _selectedChapter = null;
        _versesFuture = null;
      });
    }
  }

  void _completeSelection(BibleVerse verse) {
    final book = _selectedBook;
    final chapter = _selectedChapter;

    if (book == null || chapter == null) {
      return;
    }

    Navigator.pop(
      context,
      BiblePickerResult(book: book, chapter: chapter, verse: verse.verse),
    );
  }

  String get _stepTitle {
    if (_selectedBook == null) {
      return '';
    }

    if (_selectedChapter == null) {
      return '${_selectedBook!.nameKo} 장 선택';
    }

    return '${_selectedBook!.nameKo} $_selectedChapter장 절 선택';
  }

  @override
  Widget build(BuildContext context) {
    final isBookStep = _selectedBook == null;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return ColoredBox(
      color: widget.backgroundColor,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            isBookStep ? 0 : 4,
            18,
            bottomSafePadding + 18,
          ),
          child: Column(
            children: [
              if (!isBookStep) ...[
                BiblePickerHeader(
                  title: _stepTitle,
                  canGoBack: _selectedBook != null,
                  onBackPressed: _backStep,
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _buildCurrentStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_selectedBook == null) {
      return _buildBookStep();
    }

    if (_selectedChapter == null) {
      return _buildChapterStep(_selectedBook!);
    }

    return _buildVerseStep();
  }

  Widget _buildBookStep() {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return FutureBuilder<List<BibleBook>>(
      future: _booksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }

        final books = snapshot.data ?? [];

        if (books.isEmpty) {
          return const Center(child: Text('성경 책 데이터가 없습니다.'));
        }

        final visibleBooks = books.where((book) {
          if (_selectedTestamentGroup == BibleTestamentGroup.oldTestament) {
            return book.bookId <= 39;
          }

          return book.bookId >= 40;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TestamentTabButton(
                      label: '구약',
                      isSelected:
                          _selectedTestamentGroup ==
                          BibleTestamentGroup.oldTestament,
                      onTap: () {
                        setState(() {
                          _selectedTestamentGroup =
                              BibleTestamentGroup.oldTestament;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TestamentTabButton(
                      label: '신약',
                      isSelected:
                          _selectedTestamentGroup ==
                          BibleTestamentGroup.newTestament,
                      onTap: () {
                        setState(() {
                          _selectedTestamentGroup =
                              BibleTestamentGroup.newTestament;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                key: ValueKey('book_step_${_selectedTestamentGroup.index}'),
                padding: EdgeInsets.only(bottom: bottomSafePadding + 16),
                itemCount: visibleBooks.length,
                separatorBuilder: (context, index) {
                  return const SizedBox.shrink();
                },
                itemBuilder: (context, index) {
                  final book = visibleBooks[index];
                  final isCurrent = book.bookId == widget.currentBook.bookId;

                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      splashColor: AppColors.primaryBrown.withValues(
                        alpha: 0.20,
                      ),
                      highlightColor: AppColors.primaryBrown.withValues(
                        alpha: 0.10,
                      ),
                      onTap: () {
                        _selectBook(book);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Text(
                          '${book.nameKo}(${book.shortName})',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isCurrent
                                ? AppColors.primaryBrown
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChapterStep(BibleBook book) {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    final chapters = List.generate(book.chapterCount, (index) => index + 1);

    return GridView.builder(
      key: const ValueKey('chapter_step'),
      padding: EdgeInsets.only(top: 4, bottom: bottomSafePadding + 24),
      itemCount: chapters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isCurrent =
            book.bookId == widget.currentBook.bookId &&
            chapter == widget.currentChapter;

        return PickerNumberButton(
          label: '$chapter',
          isSelected: isCurrent,
          onTap: () {
            _selectChapter(chapter);
          },
        );
      },
    );
  }

  Widget _buildVerseStep() {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    final versesFuture = _versesFuture;

    if (versesFuture == null) {
      return const Center(child: Text('절 데이터를 불러오지 못했습니다.'));
    }

    return FutureBuilder<List<BibleVerse>>(
      future: versesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }

        final verses = snapshot.data ?? [];

        if (verses.isEmpty) {
          return const Center(child: Text('절 데이터가 없습니다.'));
        }

        return GridView.builder(
          key: const ValueKey('verse_step'),
          padding: EdgeInsets.only(top: 4, bottom: bottomSafePadding + 24),
          itemCount: verses.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final verse = verses[index];

            return PickerNumberButton(
              label: '${verse.verse}',
              isSelected: false,
              onTap: () {
                _completeSelection(verse);
              },
            );
          },
        );
      },
    );
  }
}
