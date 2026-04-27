import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/bible_database.dart';
import '../models/bible_book.dart';
import '../models/bible_note.dart';
import '../models/bible_section_title.dart';
import '../models/bible_verse.dart';
import '../services/recent_read_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class BibleReaderScreen extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final int initialVerse;
  final bool selectInitialVerse;

  const BibleReaderScreen({
    super.key,
    required this.book,
    required this.chapter,
    required this.initialVerse,
    this.selectInitialVerse = false,
  });

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  static const double _minFontSize = 10.0;
  static const double _maxFontSize = 25.0;

  late BibleBook _currentBook;
  late PageController _pageController;
  late int _currentChapter;

  late int _targetChapter;
  late int _targetVerse;
  late bool _selectTargetVerse;

  int _locationVersion = 0;

  final RecentReadService _recentReadService = RecentReadService();

  double _fontSize = RecentReadService.defaultFontSize;
  bool _isReaderMenuOpen = false;

  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();

    _currentBook = widget.book;
    _currentChapter = widget.chapter;
    _targetChapter = widget.chapter;
    _targetVerse = widget.initialVerse;
    _selectTargetVerse = widget.selectInitialVerse;

    _pageController = PageController(initialPage: widget.chapter - 1);

    _loadFontSize();

    _saveRecentLocation(chapter: widget.chapter, verse: widget.initialVerse);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _titleText {
    return '${_currentBook.nameKo} $_currentChapter장';
  }

  bool get _canGoPrevious {
    return _currentChapter > 1 || _currentBook.bookId > 1;
  }

  bool get _canGoNext {
    return _currentChapter < _currentBook.chapterCount ||
        _currentBook.bookId < 66;
  }

  Future<void> _loadFontSize() async {
    final savedFontSize = await _recentReadService.getFontSize();

    final normalizedFontSize = savedFontSize
        .clamp(_minFontSize, _maxFontSize)
        .toDouble();

    if (!mounted) {
      return;
    }

    setState(() {
      _fontSize = normalizedFontSize;
    });
  }

  Future<void> _saveRecentLocation({
    required int chapter,
    required int verse,
  }) async {
    await _recentReadService.saveRecentLocation(
      bookId: _currentBook.bookId,
      chapter: chapter,
      verse: verse,
    );
  }

  Future<void> _saveFontSize(double fontSize) async {
    final normalizedFontSize = fontSize
        .clamp(_minFontSize, _maxFontSize)
        .toDouble();

    await _recentReadService.saveFontSize(normalizedFontSize);
  }

  void _handlePageChanged(int index) {
    final changedChapter = index + 1;

    setState(() {
      _currentChapter = changedChapter;
      _targetChapter = changedChapter;
      _targetVerse = 1;
      _selectTargetVerse = false;
      _isReaderMenuOpen = false;
      _locationVersion++;
    });

    _saveRecentLocation(chapter: changedChapter, verse: 1);
  }

  void _handleVerseSelected({required int chapter, required int verse}) {
    _saveRecentLocation(chapter: chapter, verse: verse);
  }

  void _replaceCurrentLocation({
    required BibleBook book,
    required int chapter,
    required int verse,
    required bool selectVerse,
  }) {
    final bookChanged = _currentBook.bookId != book.bookId;
    final oldController = _pageController;
    final nextController = bookChanged
        ? PageController(initialPage: chapter - 1)
        : _pageController;

    setState(() {
      _currentBook = book;
      _currentChapter = chapter;
      _targetChapter = chapter;
      _targetVerse = verse;
      _selectTargetVerse = selectVerse;
      _isReaderMenuOpen = false;
      _locationVersion++;

      if (bookChanged) {
        _pageController = nextController;
      }
    });

    if (bookChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    } else {
      _pageController.jumpToPage(chapter - 1);
    }

    _saveRecentLocation(chapter: chapter, verse: verse);
  }

  void _goToPreviousChapter() {
    if (_currentChapter > 1) {
      setState(() {
        _isReaderMenuOpen = false;
      });

      _pageController.jumpToPage(_currentChapter - 2);
      return;
    }

    _moveToPreviousBook();
  }

  Future<void> _moveToPreviousBook() async {
    if (_currentBook.bookId <= 1) {
      return;
    }

    final previousBook = await BibleDatabase.instance.getBookById(
      _currentBook.bookId - 1,
    );

    if (!mounted || previousBook == null) {
      return;
    }

    _replaceCurrentLocation(
      book: previousBook,
      chapter: previousBook.chapterCount,
      verse: 1,
      selectVerse: false,
    );
  }

  void _goToNextChapter() {
    if (_currentChapter < _currentBook.chapterCount) {
      setState(() {
        _isReaderMenuOpen = false;
      });

      _pageController.jumpToPage(_currentChapter);
      return;
    }

    _moveToNextBook();
  }

  Future<void> _moveToNextBook() async {
    if (_currentBook.bookId >= 66) {
      return;
    }

    final nextBook = await BibleDatabase.instance.getBookById(
      _currentBook.bookId + 1,
    );

    if (!mounted || nextBook == null) {
      return;
    }

    _replaceCurrentLocation(
      book: nextBook,
      chapter: 1,
      verse: 1,
      selectVerse: false,
    );
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _horizontalDragDistance = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDistance += details.primaryDelta ?? 0;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    const threshold = 48.0;

    if (_horizontalDragDistance <= -threshold) {
      _goToNextChapter();
      return;
    }

    if (_horizontalDragDistance >= threshold) {
      _goToPreviousChapter();
      return;
    }

    final velocity = details.primaryVelocity ?? 0;

    if (velocity <= -500) {
      _goToNextChapter();
      return;
    }

    if (velocity >= 500) {
      _goToPreviousChapter();
    }
  }

  void _increaseFontSize() {
    if (_fontSize >= _maxFontSize) {
      return;
    }

    final nextFontSize = (_fontSize + 1)
        .clamp(_minFontSize, _maxFontSize)
        .toDouble();

    setState(() {
      _fontSize = nextFontSize;
    });

    _saveFontSize(nextFontSize);
  }

  void _decreaseFontSize() {
    if (_fontSize <= _minFontSize) {
      return;
    }

    final nextFontSize = (_fontSize - 1)
        .clamp(_minFontSize, _maxFontSize)
        .toDouble();

    setState(() {
      _fontSize = nextFontSize;
    });

    _saveFontSize(nextFontSize);
  }

  Future<void> _openReaderFromResult(
    _BiblePickerResult result, {
    required bool selectVerse,
  }) async {
    _replaceCurrentLocation(
      book: result.book,
      chapter: result.chapter,
      verse: result.verse,
      selectVerse: selectVerse,
    );
  }

  Future<void> _openBiblePicker() async {
    setState(() {
      _isReaderMenuOpen = false;
    });

    final result = await showModalBottomSheet<_BiblePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (context) {
        return _BiblePickerSheet(
          currentBook: _currentBook,
          currentChapter: _currentChapter,
        );
      },
    );

    if (result == null) {
      return;
    }

    await _openReaderFromResult(result, selectVerse: true);
  }

  Future<void> _showSearchBottomSheet() async {
    setState(() {
      _isReaderMenuOpen = false;
    });

    final result = await showModalBottomSheet<_BiblePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (context) {
        return const _BibleSearchSheet();
      },
    );

    if (result == null) {
      return;
    }

    await _openReaderFromResult(result, selectVerse: true);
  }

  void _toggleReaderMenu() {
    setState(() {
      _isReaderMenuOpen = !_isReaderMenuOpen;
    });
  }

  void _closeReaderMenu() {
    if (!_isReaderMenuOpen) {
      return;
    }

    setState(() {
      _isReaderMenuOpen = false;
    });
  }

  void _openFontSizeFromMenu() {
    setState(() {
      _isReaderMenuOpen = false;
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _showFontSizeBottomSheet();
      }
    });
  }

  void _openSearchFromMenu() {
    setState(() {
      _isReaderMenuOpen = false;
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _showSearchBottomSheet();
      }
    });
  }

  void _showFontSizeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void decrease() {
              _decreaseFontSize();
              setModalState(() {});
            }

            void increase() {
              _increaseFontSize();
              setModalState(() {});
            }

            final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 8, 22, bottomSafePadding + 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.lightBrown,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        '태초에 하나님이 천지를 창조하시니라',
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 1.65,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: _fontSize <= _minFontSize
                              ? null
                              : decrease,
                          icon: const Icon(Icons.remove),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${_fontSize.toInt()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _fontSize >= _maxFontSize
                              ? null
                              : increase,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _BibleReaderAppBar(
        titleText: _titleText,
        onTitlePressed: _openBiblePicker,
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _handleHorizontalDragStart,
            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            child: PageView.builder(
              key: ValueKey('pageview-${_currentBook.bookId}'),
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentBook.chapterCount,
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, index) {
                final chapter = index + 1;

                return _ChapterReaderPage(
                  key: ValueKey(
                    'chapter-${_currentBook.bookId}-$chapter-$_targetChapter-$_targetVerse-$_locationVersion',
                  ),
                  book: _currentBook,
                  chapter: chapter,
                  activeChapter: _currentChapter,
                  initialVerse: _targetVerse,
                  shouldScrollToInitialVerse: chapter == _targetChapter,
                  selectInitialVerse:
                      _selectTargetVerse && chapter == _targetChapter,
                  fontSize: _fontSize,
                  onVerseSelected: _handleVerseSelected,
                );
              },
            ),
          ),
          if (_isReaderMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeReaderMenu,
                child: const SizedBox.expand(),
              ),
            ),
          if (_isReaderMenuOpen)
            Positioned(
              right: 14,
              bottom: 10,
              child: _FloatingReaderMenu(
                onFontSizePressed: _openFontSizeFromMenu,
                onSearchPressed: _openSearchFromMenu,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _ReaderBottomBar(
        canGoPrevious: _canGoPrevious,
        canGoNext: _canGoNext,
        isMenuOpen: _isReaderMenuOpen,
        onPreviousPressed: _goToPreviousChapter,
        onNextPressed: _goToNextChapter,
        onMenuPressed: _toggleReaderMenu,
      ),
    );
  }
}

class _BibleReaderAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String titleText;
  final VoidCallback onTitlePressed;

  const _BibleReaderAppBar({
    required this.titleText,
    required this.onTitlePressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.topBar,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 10,
      title: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTitlePressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.topBarSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 22,
                      color: AppColors.topBarText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.48,
                    ),
                    child: Text(
                      titleText,
                      style: AppTextStyles.appTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.topBarSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text('개역한글', style: AppTextStyles.versionLabel),
          ),
        ],
      ),
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isMenuOpen;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final VoidCallback onMenuPressed;

  const _ReaderBottomBar({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isMenuOpen,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 58,
        decoration: const BoxDecoration(
          color: AppColors.topBar,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            IconButton(
              onPressed: canGoPrevious ? onPreviousPressed : null,
              icon: Icon(
                Icons.chevron_left_rounded,
                size: 34,
                color: canGoPrevious
                    ? AppColors.topBarText
                    : AppColors.textSecondary,
              ),
            ),
            IconButton(
              onPressed: canGoNext ? onNextPressed : null,
              icon: Icon(
                Icons.chevron_right_rounded,
                size: 34,
                color: canGoNext
                    ? AppColors.topBarText
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onMenuPressed,
              icon: Icon(
                isMenuOpen
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 34,
                color: AppColors.topBarText,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _FloatingReaderMenu extends StatelessWidget {
  final VoidCallback onFontSizePressed;
  final VoidCallback onSearchPressed;

  const _FloatingReaderMenu({
    required this.onFontSizePressed,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.topBarSoft,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FloatingReaderMenuIconButton(
              icon: Icons.text_fields_rounded,
              onPressed: onFontSizePressed,
            ),
            const SizedBox(width: 4),
            _FloatingReaderMenuIconButton(
              icon: Icons.search_rounded,
              onPressed: onSearchPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingReaderMenuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _FloatingReaderMenuIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: SizedBox(
        width: 46,
        height: 42,
        child: Icon(icon, color: AppColors.topBarText, size: 25),
      ),
    );
  }
}

class _ChapterReaderPage extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final int activeChapter;
  final int initialVerse;
  final bool shouldScrollToInitialVerse;
  final bool selectInitialVerse;
  final double fontSize;
  final void Function({required int chapter, required int verse})
  onVerseSelected;

  const _ChapterReaderPage({
    super.key,
    required this.book,
    required this.chapter,
    required this.activeChapter,
    required this.initialVerse,
    required this.shouldScrollToInitialVerse,
    required this.selectInitialVerse,
    required this.fontSize,
    required this.onVerseSelected,
  });

  @override
  State<_ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<_ChapterReaderPage> {
  late Future<_ChapterContentData> _chapterContentFuture;

  final Map<int, GlobalKey> _verseKeys = {};
  bool _hasScrolledToInitialVerse = false;

  final Set<int> _selectedVerses = {};

  Timer? _copyHoldTimer;
  bool _didCopyByHold = false;

  @override
  void initState() {
    super.initState();

    if (widget.selectInitialVerse) {
      _selectedVerses.add(widget.initialVerse);
    }

    _chapterContentFuture = _loadChapterContent();
  }

  @override
  void didUpdateWidget(covariant _ChapterReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final movedAwayFromThisChapter =
        oldWidget.activeChapter != widget.activeChapter &&
        widget.activeChapter != widget.chapter;

    if (movedAwayFromThisChapter) {
      _copyHoldTimer?.cancel();

      if (_selectedVerses.isNotEmpty) {
        setState(() {
          _selectedVerses.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _copyHoldTimer?.cancel();
    super.dispose();
  }

  Future<_ChapterContentData> _loadChapterContent() async {
    final verses = await BibleDatabase.instance.getVerses(
      bookId: widget.book.bookId,
      chapter: widget.chapter,
    );

    final notesByVerse = await BibleDatabase.instance.getNotesGroupedByVerse(
      bookId: widget.book.bookId,
      chapter: widget.chapter,
    );

    final sectionTitlesByVerse = await BibleDatabase.instance
        .getSectionTitlesGroupedByVerse(
          bookId: widget.book.bookId,
          chapter: widget.chapter,
        );

    return _ChapterContentData(
      verses: verses,
      notesByVerse: notesByVerse,
      sectionTitlesByVerse: sectionTitlesByVerse,
    );
  }

  void _scrollToInitialVerse(List<BibleVerse> verses) {
    if (!widget.shouldScrollToInitialVerse) {
      return;
    }

    if (_hasScrolledToInitialVerse) {
      return;
    }

    final exists = verses.any((verse) => verse.verse == widget.initialVerse);

    if (!exists) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetKey = _verseKeys[widget.initialVerse];

      if (targetKey?.currentContext != null) {
        Scrollable.ensureVisible(
          targetKey!.currentContext!,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.12,
        );

        _hasScrolledToInitialVerse = true;
      }
    });
  }

  void _toggleVerse(BibleVerse verse) {
    setState(() {
      if (_selectedVerses.contains(verse.verse)) {
        _selectedVerses.remove(verse.verse);
      } else {
        _selectedVerses.add(verse.verse);
      }
    });

    widget.onVerseSelected(chapter: widget.chapter, verse: verse.verse);
  }

  String _buildVerseCopyText(BibleVerse verse) {
    return '${widget.book.nameKo} ${widget.chapter}:${verse.verse} ${verse.verseText}';
  }

  List<BibleVerse> _getSelectedVerseObjects(List<BibleVerse> allVerses) {
    final selected = allVerses
        .where((verse) => _selectedVerses.contains(verse.verse))
        .toList();

    selected.sort((a, b) => a.verse.compareTo(b.verse));

    return selected;
  }

  Future<void> _copySelectedVerses(List<BibleVerse> allVerses) async {
    final selectedVerseObjects = _getSelectedVerseObjects(allVerses);

    if (selectedVerseObjects.isEmpty) {
      return;
    }

    final copyText = selectedVerseObjects.map(_buildVerseCopyText).join('\n');

    await Clipboard.setData(ClipboardData(text: copyText));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedVerseObjects.length}개 절을 복사했습니다.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _startCopyHoldTimer({
    required BibleVerse verse,
    required List<BibleVerse> allVerses,
  }) {
    _didCopyByHold = false;
    _copyHoldTimer?.cancel();

    _copyHoldTimer = Timer(const Duration(seconds: 1), () async {
      _copyHoldTimer = null;
      _didCopyByHold = true;

      if (!_selectedVerses.contains(verse.verse)) {
        setState(() {
          _selectedVerses.add(verse.verse);
        });
      }

      widget.onVerseSelected(chapter: widget.chapter, verse: verse.verse);

      await _copySelectedVerses(allVerses);

      Future.delayed(const Duration(milliseconds: 300), () {
        _didCopyByHold = false;
      });
    });
  }

  void _cancelCopyHoldTimer() {
    _copyHoldTimer?.cancel();
    _copyHoldTimer = null;
  }

  void _handleVerseTap(BibleVerse verse) {
    if (_didCopyByHold) {
      _didCopyByHold = false;
      return;
    }

    _toggleVerse(verse);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ChapterContentData>(
      future: _chapterContentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }

        final data = snapshot.data;

        if (data == null || data.verses.isEmpty) {
          return Center(
            child: Text(
              '${widget.book.nameKo} ${widget.chapter}장 본문 데이터가 없습니다.',
              textAlign: TextAlign.center,
            ),
          );
        }

        _scrollToInitialVerse(data.verses);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...data.verses.map((verse) {
                final isSelected = _selectedVerses.contains(verse.verse);

                final key = _verseKeys.putIfAbsent(
                  verse.verse,
                  () => GlobalKey(),
                );

                final rawSectionTitles =
                    data.sectionTitlesByVerse[verse.verse] ?? [];

                final rawNotes = data.notesByVerse[verse.verse] ?? [];

                final displayedVerse = _DisplayedVerseData.from(
                  verse: verse,
                  sectionTitles: rawSectionTitles,
                  notes: rawNotes,
                );

                final verseNumberStyle = AppTextStyles.verseNumber(
                  widget.fontSize,
                ).copyWith(height: 1.45);

                final verseTextStyle = AppTextStyles.verseText(
                  widget.fontSize,
                ).copyWith(height: 1.45);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayedVerse.sectionTitles.isNotEmpty)
                      _SectionTitleBlock(
                        sectionTitles: displayedVerse.sectionTitles,
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) {
                        _startCopyHoldTimer(
                          verse: verse,
                          allVerses: data.verses,
                        );
                      },
                      onTapUp: (_) {
                        _cancelCopyHoldTimer();
                      },
                      onTapCancel: _cancelCopyHoldTimer,
                      onTap: () {
                        _handleVerseTap(verse);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        key: key,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.verseHighlight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.verseHighlightBorder,
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 22,
                                  child: Text(
                                    '${verse.verse}',
                                    style: verseNumberStyle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    displayedVerse.verseText,
                                    style: verseTextStyle,
                                  ),
                                ),
                              ],
                            ),
                            if (displayedVerse.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 25),
                                child: _NoteBlock(
                                  notes: displayedVerse.notes,
                                  fontSize: widget.fontSize,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _DisplayedVerseData {
  final String verseText;
  final List<String> sectionTitles;
  final List<BibleNote> notes;

  const _DisplayedVerseData({
    required this.verseText,
    required this.sectionTitles,
    required this.notes,
  });

  factory _DisplayedVerseData.from({
    required BibleVerse verse,
    required List<BibleSectionTitle> sectionTitles,
    required List<BibleNote> notes,
  }) {
    var verseText = verse.verseText.trimLeft();

    final titles = <String>[];

    for (final title in sectionTitles) {
      final normalized = _normalizeTitle(title.titleText);

      if (normalized.isNotEmpty && !titles.contains(normalized)) {
        titles.add(normalized);
      }
    }

    final parsed = _extractLeadingTitlesAndBody(verseText);

    for (final title in parsed.titles) {
      final normalized = _normalizeTitle(title);

      if (normalized.isNotEmpty && !titles.contains(normalized)) {
        titles.add(normalized);
      }
    }

    verseText = _cleanVerseBody(parsed.body);

    return _DisplayedVerseData(
      verseText: verseText,
      sectionTitles: titles,
      notes: notes,
    );
  }

  static _ParsedTitleBody _extractLeadingTitlesAndBody(String rawText) {
    var text = rawText.trimLeft();
    final titles = <String>[];

    while (text.startsWith('〔')) {
      final fullWidthCloseIndex = text.indexOf('〕');

      if (fullWidthCloseIndex >= 0) {
        final title = text.substring(1, fullWidthCloseIndex).trim();

        if (title.isNotEmpty) {
          titles.add(title);
        }

        text = text.substring(fullWidthCloseIndex + 1).trimLeft();
        continue;
      }

      final asciiReferenceEndIndex = text.indexOf(']');

      if (asciiReferenceEndIndex >= 0 && asciiReferenceEndIndex <= 80) {
        final title = text.substring(1, asciiReferenceEndIndex + 1).trim();

        if (title.isNotEmpty) {
          titles.add(title);
        }

        text = text.substring(asciiReferenceEndIndex + 1).trimLeft();
        continue;
      }

      break;
    }

    return _ParsedTitleBody(titles: titles, body: text);
  }

  static String _normalizeTitle(String rawTitle) {
    var title = rawTitle.trim();

    if (title.isEmpty) {
      return '';
    }

    title = title.replaceFirst(RegExp(r'^〔\s*'), '');
    title = title.replaceFirst(RegExp(r'\s*〕$'), '');

    final openSquareCount = RegExp(r'\[').allMatches(title).length;
    final closeSquareCount = RegExp(r'\]').allMatches(title).length;

    if (openSquareCount > closeSquareCount) {
      title = '$title${']' * (openSquareCount - closeSquareCount)}';
    }

    title = title.trim();

    return title;
  }

  static String _cleanVerseBody(String rawBody) {
    var body = rawBody.trimLeft();

    while (body.startsWith('〕') ||
        body.startsWith(']') ||
        body.startsWith('〔') ||
        body.startsWith('[')) {
      body = body.substring(1).trimLeft();
    }

    return body;
  }
}

class _ParsedTitleBody {
  final List<String> titles;
  final String body;

  const _ParsedTitleBody({required this.titles, required this.body});
}

class _BibleSearchSheet extends StatefulWidget {
  const _BibleSearchSheet();

  @override
  State<_BibleSearchSheet> createState() => _BibleSearchSheetState();
}

class _BibleSearchSheetState extends State<_BibleSearchSheet> {
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
      _BiblePickerResult(book: book, chapter: chapter, verse: verse),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                                  final verseText = row['verse_text'] as String;

                                  return ListTile(
                                    title: Text(
                                      '$bookName $chapter:$verse',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: _HighlightedVerseText(
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
    );
  }
}

class _HighlightedVerseText extends StatelessWidget {
  final String text;
  final String keyword;

  const _HighlightedVerseText({required this.text, required this.keyword});

  @override
  Widget build(BuildContext context) {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = trimmedKeyword.toLowerCase();

    final spans = <TextSpan>[];
    int currentIndex = 0;

    while (true) {
      final matchIndex = lowerText.indexOf(lowerKeyword, currentIndex);

      if (matchIndex < 0) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
        break;
      }

      if (matchIndex > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, matchIndex),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

      final endIndex = matchIndex + trimmedKeyword.length;

      spans.add(
        TextSpan(
          text: text.substring(matchIndex, endIndex),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            backgroundColor: Colors.amber.withValues(alpha: 0.45),
          ),
        ),
      );

      currentIndex = endIndex;
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }
}

class _BiblePickerSheet extends StatefulWidget {
  final BibleBook currentBook;
  final int currentChapter;

  const _BiblePickerSheet({
    required this.currentBook,
    required this.currentChapter,
  });

  @override
  State<_BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends State<_BiblePickerSheet> {
  late Future<List<BibleBook>> _booksFuture;

  BibleBook? _selectedBook;
  int? _selectedChapter;
  Future<List<BibleVerse>>? _versesFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = BibleDatabase.instance.getBooks();
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
      _BiblePickerResult(book: book, chapter: chapter, verse: verse.verse),
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

    return SizedBox(
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
              _BiblePickerHeader(
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

        return ListView.separated(
          key: const ValueKey('book_step'),
          padding: EdgeInsets.only(bottom: bottomSafePadding + 24),
          itemCount: books.length,
          separatorBuilder: (context, index) {
            return const Divider(height: 1);
          },
          itemBuilder: (context, index) {
            final book = books[index];
            final isCurrent = book.bookId == widget.currentBook.bookId;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              title: Text(
                book.nameKo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                  color: isCurrent
                      ? AppColors.primaryBrown
                      : AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _selectBook(book);
              },
            );
          },
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

        return _PickerNumberButton(
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

            return _PickerNumberButton(
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

class _BiblePickerHeader extends StatelessWidget {
  final String title;
  final bool canGoBack;
  final VoidCallback onBackPressed;

  const _BiblePickerHeader({
    required this.title,
    required this.canGoBack,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack)
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
    );
  }
}

class _PickerNumberButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerNumberButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryBrown : AppColors.lightBrown,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? AppColors.primaryBrown : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BiblePickerResult {
  final BibleBook book;
  final int chapter;
  final int verse;

  const _BiblePickerResult({
    required this.book,
    required this.chapter,
    required this.verse,
  });
}

class _SectionTitleBlock extends StatelessWidget {
  final List<String> sectionTitles;

  const _SectionTitleBlock({required this.sectionTitles});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 7, bottom: 2),
      padding: const EdgeInsets.only(left: 2, right: 0, bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionTitles.map((title) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(top: 1, right: 6),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: Text(
                  '〔$title〕',
                  textAlign: TextAlign.left,
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  final List<BibleNote> notes;
  final double fontSize;

  const _NoteBlock({required this.notes, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final noteFontSize = (fontSize - 3).clamp(10.0, 19.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notes.map((note) {
          final marker = note.marker.trim();
          final noteText = note.noteText.trim();

          return Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (marker.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Text(
                      marker,
                      style: TextStyle(
                        fontSize: noteFontSize,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.noteText,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    noteText,
                    style: TextStyle(
                      fontSize: noteFontSize,
                      height: 1.25,
                      color: AppColors.noteText,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChapterContentData {
  final List<BibleVerse> verses;
  final Map<int, List<BibleNote>> notesByVerse;
  final Map<int, List<BibleSectionTitle>> sectionTitlesByVerse;

  const _ChapterContentData({
    required this.verses,
    required this.notesByVerse,
    required this.sectionTitlesByVerse,
  });
}
