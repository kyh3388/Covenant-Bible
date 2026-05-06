import 'package:flutter/material.dart';

import '../../../database/kjv_bible_database.dart';
import '../../../database/ko_bible_database.dart';
import '../../../models/bible_book.dart';
import '../../../models/bible_display_mode.dart';
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
  final BibleDisplayMode displayMode;

  const BiblePickerSheet({
    super.key,
    required this.currentBook,
    required this.currentChapter,
    required this.backgroundColor,
    required this.displayMode,
  });

  @override
  State<BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends State<BiblePickerSheet> {
  static const double _bookRowHeight = 56.0;

  late Future<List<BibleBook>> _koBooksFuture;
  late Future<Map<int, KjvBibleBook>> _kjvBooksByIdFuture;
  late BibleTestamentGroup _selectedTestamentGroup;

  final ScrollController _bookListScrollController = ScrollController();

  BibleBook? _selectedBook;
  int? _selectedChapter;
  Future<List<int>>? _verseNumbersFuture;

  bool _didInitialJump = false;
  bool _ignoreNextScrollSync = false;

  @override
  void initState() {
    super.initState();

    _koBooksFuture = KoBibleDatabase.instance.getBooks();
    _kjvBooksByIdFuture = KjvBibleDatabase.instance.getBooks().then((books) {
      return {for (final book in books) book.bookId: book};
    });

    _selectedTestamentGroup = widget.currentBook.bookId <= 39
        ? BibleTestamentGroup.oldTestament
        : BibleTestamentGroup.newTestament;

    _bookListScrollController.addListener(_handleBookListScroll);
  }

  @override
  void dispose() {
    _bookListScrollController.removeListener(_handleBookListScroll);
    _bookListScrollController.dispose();
    super.dispose();
  }

  void _handleBookListScroll() {
    if (_ignoreNextScrollSync) {
      return;
    }

    if (!_bookListScrollController.hasClients) {
      return;
    }

    final offset = _bookListScrollController.offset;
    final firstVisibleIndex = (offset / _bookRowHeight).floor();

    final nextGroup = firstVisibleIndex >= 39
        ? BibleTestamentGroup.newTestament
        : BibleTestamentGroup.oldTestament;

    if (nextGroup != _selectedTestamentGroup && mounted) {
      setState(() {
        _selectedTestamentGroup = nextGroup;
      });
    }
  }

  void _selectBook(BibleBook book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = null;
      _verseNumbersFuture = null;
      _selectedTestamentGroup = book.bookId <= 39
          ? BibleTestamentGroup.oldTestament
          : BibleTestamentGroup.newTestament;
    });
  }

  void _selectChapter(int chapter) {
    final book = _selectedBook;

    if (book == null) {
      return;
    }

    setState(() {
      _selectedChapter = chapter;
      _verseNumbersFuture = _loadVerseNumbers(book.bookId, chapter);
    });
  }

  Future<List<int>> _loadVerseNumbers(int bookId, int chapter) async {
    if (widget.displayMode.isEnglishOnly) {
      final verses = await KjvBibleDatabase.instance.getVerses(
        bookId: bookId,
        chapter: chapter,
      );
      return verses.map((verse) => verse.verse).toList();
    }

    final verses = await KoBibleDatabase.instance.getVerses(
      bookId: bookId,
      chapter: chapter,
    );
    return verses.map((verse) => verse.verse).toList();
  }

  void _backStep() {
    if (_selectedChapter != null) {
      setState(() {
        _selectedChapter = null;
        _verseNumbersFuture = null;
      });
      return;
    }

    if (_selectedBook != null) {
      setState(() {
        _selectedBook = null;
        _selectedChapter = null;
        _verseNumbersFuture = null;
      });
    }
  }

  void _completeSelection(int verseNumber) {
    final book = _selectedBook;
    final chapter = _selectedChapter;

    if (book == null || chapter == null) {
      return;
    }

    Navigator.pop(
      context,
      BiblePickerResult(book: book, chapter: chapter, verse: verseNumber),
    );
  }

  String _buildBookLabel(BibleBook koBook, KjvBibleBook? kjvBook) {
    switch (widget.displayMode) {
      case BibleDisplayMode.krv:
        return '${koBook.nameKo}(${koBook.shortName})';
      case BibleDisplayMode.kjv:
        if (kjvBook == null) {
          return koBook.nameKo;
        }
        return '${kjvBook.nameEn}(${kjvBook.shortName})';
      case BibleDisplayMode.krvKjv:
        if (kjvBook == null) {
          return koBook.nameKo;
        }
        return '${koBook.nameKo}(${kjvBook.nameEn})';
    }
  }

  String _buildStepBookLabel(BibleBook koBook, KjvBibleBook? kjvBook) {
    switch (widget.displayMode) {
      case BibleDisplayMode.krv:
        return koBook.nameKo;
      case BibleDisplayMode.kjv:
        return kjvBook?.nameEn ?? koBook.nameKo;
      case BibleDisplayMode.krvKjv:
        return kjvBook == null
            ? koBook.nameKo
            : '${koBook.nameKo}(${kjvBook.shortName})';
    }
  }

  String _stepTitle(Map<int, KjvBibleBook> kjvBooksById) {
    if (_selectedBook == null) {
      return '';
    }

    final kjvBook = kjvBooksById[_selectedBook!.bookId];
    final bookLabel = _buildStepBookLabel(_selectedBook!, kjvBook);

    if (_selectedChapter == null) {
      return '$bookLabel 장 선택';
    }

    return '$bookLabel ${_selectedChapter!}장 절 선택';
  }

  void _jumpToBookIndex(int index) {
    if (!_bookListScrollController.hasClients) {
      return;
    }

    final maxScroll = _bookListScrollController.position.maxScrollExtent;
    final targetOffset = (index * _bookRowHeight).clamp(0.0, maxScroll);

    _ignoreNextScrollSync = true;
    _bookListScrollController.jumpTo(targetOffset);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ignoreNextScrollSync = false;
      _handleBookListScroll();
    });
  }

  void _jumpToOldTestament() {
    setState(() {
      _selectedTestamentGroup = BibleTestamentGroup.oldTestament;
    });

    _jumpToBookIndex(0);
  }

  void _jumpToNewTestament() {
    setState(() {
      _selectedTestamentGroup = BibleTestamentGroup.newTestament;
    });

    _jumpToBookIndex(39);
  }

  void _jumpToCurrentBookInitially() {
    if (_didInitialJump) {
      return;
    }

    _didInitialJump = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_bookListScrollController.hasClients) {
        return;
      }

      final currentIndex = widget.currentBook.bookId - 1;
      _jumpToBookIndex(currentIndex);
    });
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
          child: FutureBuilder<Map<int, KjvBibleBook>>(
            future: _kjvBooksByIdFuture,
            builder: (context, kjvSnapshot) {
              final kjvBooksById = kjvSnapshot.data ?? <int, KjvBibleBook>{};

              return Column(
                children: [
                  if (!isBookStep) ...[
                    BiblePickerHeader(
                      title: _stepTitle(kjvBooksById),
                      canGoBack: _selectedBook != null,
                      onBackPressed: _backStep,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _buildCurrentStep(kjvBooksById),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(Map<int, KjvBibleBook> kjvBooksById) {
    if (_selectedBook == null) {
      return _buildBookStep(kjvBooksById);
    }

    if (_selectedChapter == null) {
      return _buildChapterStep(_selectedBook!);
    }

    return _buildVerseStep();
  }

  Widget _buildBookStep(Map<int, KjvBibleBook> kjvBooksById) {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return FutureBuilder<List<BibleBook>>(
      future: _koBooksFuture,
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

        _jumpToCurrentBookInitially();

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
                      onTap: _jumpToOldTestament,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TestamentTabButton(
                      label: '신약',
                      isSelected:
                          _selectedTestamentGroup ==
                          BibleTestamentGroup.newTestament,
                      onTap: _jumpToNewTestament,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: ValueKey('book_step_${widget.displayMode.name}'),
                controller: _bookListScrollController,
                padding: EdgeInsets.only(bottom: bottomSafePadding + 16),
                itemCount: books.length,
                itemExtent: _bookRowHeight,
                itemBuilder: (context, index) {
                  final koBook = books[index];
                  final kjvBook = kjvBooksById[koBook.bookId];
                  final isCurrent = koBook.bookId == widget.currentBook.bookId;

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
                        _selectBook(koBook);
                      },
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _buildBookLabel(koBook, kjvBook),
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
    final verseNumbersFuture = _verseNumbersFuture;

    if (verseNumbersFuture == null) {
      return const Center(child: Text('절 데이터를 불러오지 못했습니다.'));
    }

    return FutureBuilder<List<int>>(
      future: verseNumbersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }

        final verseNumbers = snapshot.data ?? [];

        if (verseNumbers.isEmpty) {
          return const Center(child: Text('절 데이터가 없습니다.'));
        }

        return GridView.builder(
          key: const ValueKey('verse_step'),
          padding: EdgeInsets.only(top: 4, bottom: bottomSafePadding + 24),
          itemCount: verseNumbers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final verseNumber = verseNumbers[index];

            return PickerNumberButton(
              label: '$verseNumber',
              isSelected: false,
              onTap: () {
                _completeSelection(verseNumber);
              },
            );
          },
        );
      },
    );
  }
}
