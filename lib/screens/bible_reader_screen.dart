import 'package:flutter/material.dart';

import '../database/kjv_bible_database.dart';
import '../database/ko_bible_database.dart';
import '../models/bible_book.dart';
import '../models/bible_display_mode.dart';
import '../services/reader_theme_service.dart';
import '../services/recent_read_service.dart';
import '../widgets/bible_reader/bookmark/bookmark_list_sheet.dart';
import '../widgets/bible_reader/layout/bible_reader_app_bar.dart';
import '../widgets/bible_reader/layout/floating_reader_menu.dart';
import '../widgets/bible_reader/layout/reader_bottom_bar.dart';
import '../widgets/bible_reader/picker/bible_picker_result.dart';
import '../widgets/bible_reader/picker/bible_picker_sheet.dart';
import '../widgets/bible_reader/reader/chapter_reader_page.dart';
import '../widgets/bible_reader/search/bible_search_sheet.dart';
import '../widgets/bible_reader/themes/font_size_sheet.dart';
import '../widgets/bible_reader/themes/reader_theme_option.dart';
import '../widgets/bible_reader/themes/reader_theme_sheet.dart';

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
  final ReaderThemeService _readerThemeService = ReaderThemeService();

  double _fontSize = RecentReadService.defaultFontSize;
  bool _isReaderMenuOpen = false;

  String _selectedThemeId = ReaderThemeService.defaultThemeId;
  String _bodyBackgroundMode = ReaderThemeService.defaultBodyBackgroundMode;

  double _horizontalDragDistance = 0;

  BibleDisplayMode _displayMode = BibleDisplayMode.krv;

  Map<int, KjvBibleBook> _kjvBooksById = {};

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
    _loadThemeColor();
    _loadBodyBackgroundMode();
    _loadKjvBooks();

    _saveRecentLocation(chapter: widget.chapter, verse: widget.initialVerse);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadKjvBooks() async {
    final books = await KjvBibleDatabase.instance.getBooks();

    if (!mounted) {
      return;
    }

    setState(() {
      _kjvBooksById = {for (final book in books) book.bookId: book};
    });
  }

  KjvBibleBook? get _currentKjvBook => _kjvBooksById[_currentBook.bookId];

  String get _titleText {
    final kjvBook = _currentKjvBook;

    switch (_displayMode) {
      case BibleDisplayMode.krv:
        return '${_currentBook.nameKo} $_currentChapter장';
      case BibleDisplayMode.kjv:
        return '${kjvBook?.shortName ?? _currentBook.nameKo} $_currentChapter';
      case BibleDisplayMode.krvKjv:
        if (kjvBook == null) {
          return '${_currentBook.nameKo} $_currentChapter장';
        }
        return '${_currentBook.nameKo}(${kjvBook.shortName}) $_currentChapter장';
    }
  }

  bool get _canGoPrevious {
    return _currentChapter > 1 || _currentBook.bookId > 1;
  }

  bool get _canGoNext {
    return _currentChapter < _currentBook.chapterCount ||
        _currentBook.bookId < 66;
  }

  ReaderThemeOption get _selectedTheme {
    return ReaderThemeOption.findById(_selectedThemeId);
  }

  Color get _barColor {
    return _selectedTheme.color;
  }

  Color get _barSoftColor {
    return _selectedTheme.softColor;
  }

  Color get _barTextColor {
    return _selectedTheme.foregroundColor;
  }

  Color get _bodyBackgroundColor {
    if (_bodyBackgroundMode == ReaderThemeService.bodyBackgroundTinted) {
      return Color.lerp(Colors.white, _barColor, 0.10)!;
    }

    return Colors.white;
  }

  Future<void> _loadThemeColor() async {
    final savedThemeId = await _readerThemeService.getThemeId();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedThemeId = savedThemeId;
    });
  }

  Future<void> _saveThemeColor(String themeId) async {
    await _readerThemeService.saveThemeId(themeId);
  }

  Future<void> _loadBodyBackgroundMode() async {
    final savedMode = await _readerThemeService.getBodyBackgroundMode();

    if (!mounted) {
      return;
    }

    setState(() {
      _bodyBackgroundMode = savedMode;
    });
  }

  Future<void> _saveBodyBackgroundMode(String mode) async {
    await _readerThemeService.saveBodyBackgroundMode(mode);
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

  Future<void> _saveFontSize(double fontSize) async {
    final normalizedFontSize = fontSize
        .clamp(_minFontSize, _maxFontSize)
        .toDouble();

    await _recentReadService.saveFontSize(normalizedFontSize);
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

    final previousBook = await KoBibleDatabase.instance.getBookById(
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

    final nextBook = await KoBibleDatabase.instance.getBookById(
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

  Future<void> _openReaderFromResult(
    BiblePickerResult result, {
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

    final sheetBackgroundColor = _bodyBackgroundColor;

    final result = await showModalBottomSheet<BiblePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: sheetBackgroundColor,
      showDragHandle: true,
      builder: (context) {
        return BiblePickerSheet(
          currentBook: _currentBook,
          currentChapter: _currentChapter,
          backgroundColor: sheetBackgroundColor,
          displayMode: _displayMode,
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

    final sheetBackgroundColor = _bodyBackgroundColor;

    final result = await showModalBottomSheet<BiblePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: sheetBackgroundColor,
      showDragHandle: true,
      builder: (context) {
        return BibleSearchSheet(backgroundColor: sheetBackgroundColor);
      },
    );

    if (result == null) {
      return;
    }

    await _openReaderFromResult(result, selectVerse: true);
  }

  Future<void> _showBookmarkBottomSheet() async {
    setState(() {
      _isReaderMenuOpen = false;
    });

    final sheetBackgroundColor = _bodyBackgroundColor;

    final result = await showModalBottomSheet<BiblePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: sheetBackgroundColor,
      showDragHandle: true,
      builder: (context) {
        return BookmarkListSheet(
          backgroundColor: sheetBackgroundColor,
          currentBook: _currentBook,
          currentChapter: _currentChapter,
          displayMode: _displayMode,
        );
      },
    );

    if (result == null) {
      return;
    }

    await _openReaderFromResult(result, selectVerse: true);
  }

  Future<void> _showDisplayModeBottomSheet() async {
    final selectedMode = await showModalBottomSheet<BibleDisplayMode>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: _bodyBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDisplayModeTile(
                context: context,
                mode: BibleDisplayMode.krv,
                subtitle: '한글 책 목록 + 한글 본문',
              ),
              _buildDisplayModeTile(
                context: context,
                mode: BibleDisplayMode.kjv,
                subtitle: '영어 책 목록 + 영어 본문',
              ),
              _buildDisplayModeTile(
                context: context,
                mode: BibleDisplayMode.krvKjv,
                subtitle: '한글(영어) 책 목록 + 한/영 병기',
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selectedMode == null || selectedMode == _displayMode) {
      return;
    }

    setState(() {
      _displayMode = selectedMode;
      _isReaderMenuOpen = false;
    });
  }

  Widget _buildDisplayModeTile({
    required BuildContext context,
    required BibleDisplayMode mode,
    required String subtitle,
  }) {
    final isSelected = _displayMode == mode;

    return ListTile(
      title: Text(mode.label),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check_rounded, color: _barColor) : null,
      onTap: () {
        Navigator.pop(context, mode);
      },
    );
  }

  void _showThemeColorBottomSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ReaderThemeSheet(
          initialThemeId: _selectedThemeId,
          initialBodyBackgroundMode: _bodyBackgroundMode,
          onThemeSelected: (themeId) {
            setState(() {
              _selectedThemeId = themeId;
            });

            _saveThemeColor(themeId);
          },
          onBodyBackgroundModeSelected: (mode) {
            setState(() {
              _bodyBackgroundMode = mode;
            });

            _saveBodyBackgroundMode(mode);
          },
        );
      },
    );
  }

  void _showFontSizeBottomSheet() {
    final sheetBackgroundColor = _bodyBackgroundColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: sheetBackgroundColor,
      builder: (context) {
        return FontSizeSheet(
          backgroundColor: sheetBackgroundColor,
          initialFontSize: _fontSize,
          minFontSize: _minFontSize,
          maxFontSize: _maxFontSize,
          onFontSizeChanged: (fontSize) {
            setState(() {
              _fontSize = fontSize;
            });

            _saveFontSize(fontSize);
          },
        );
      },
    );
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

  void _openThemeColorFromMenu() {
    setState(() {
      _isReaderMenuOpen = false;
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _showThemeColorBottomSheet();
      }
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

  void _openBookmarkFromMenu() {
    setState(() {
      _isReaderMenuOpen = false;
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _showBookmarkBottomSheet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _barColor;
    final barSoftColor = _barSoftColor;
    final barTextColor = _barTextColor;
    final bodyBackgroundColor = _bodyBackgroundColor;

    return Scaffold(
      backgroundColor: bodyBackgroundColor,
      appBar: BibleReaderAppBar(
        titleText: _titleText,
        versionText: _displayMode.label,
        barColor: barColor,
        barSoftColor: barSoftColor,
        barTextColor: barTextColor,
        onTitlePressed: _openBiblePicker,
        onVersionPressed: _showDisplayModeBottomSheet,
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _handleHorizontalDragStart,
            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            child: PageView.builder(
              key: ValueKey(
                'pageview-${_currentBook.bookId}-${_displayMode.name}',
              ),
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentBook.chapterCount,
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, index) {
                final chapter = index + 1;

                return ChapterReaderPage(
                  key: ValueKey(
                    'chapter-${_currentBook.bookId}-$chapter-$_targetChapter-$_targetVerse-$_locationVersion-${_displayMode.name}',
                  ),
                  book: _currentBook,
                  chapter: chapter,
                  activeChapter: _currentChapter,
                  initialVerse: _targetVerse,
                  shouldScrollToInitialVerse: chapter == _targetChapter,
                  selectInitialVerse:
                      _selectTargetVerse && chapter == _targetChapter,
                  fontSize: _fontSize,
                  bodyBackgroundColor: bodyBackgroundColor,
                  displayMode: _displayMode,
                  kjvBookNameEn: _currentKjvBook?.nameEn,
                  kjvBookShortName: _currentKjvBook?.shortName,
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
              child: FloatingReaderMenu(
                barColor: barSoftColor,
                iconColor: barTextColor,
                onThemeColorPressed: _openThemeColorFromMenu,
                onFontSizePressed: _openFontSizeFromMenu,
                onSearchPressed: _openSearchFromMenu,
                onBookmarkPressed: _openBookmarkFromMenu,
              ),
            ),
        ],
      ),
      bottomNavigationBar: ReaderBottomBar(
        canGoPrevious: _canGoPrevious,
        canGoNext: _canGoNext,
        barColor: barColor,
        barTextColor: barTextColor,
        onPreviousPressed: _goToPreviousChapter,
        onNextPressed: _goToNextChapter,
        onMenuPressed: _toggleReaderMenu,
      ),
    );
  }
}
