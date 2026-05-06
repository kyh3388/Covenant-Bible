import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../database/kjv_bible_database.dart';
import '../../../database/ko_bible_database.dart';
import '../../../models/bible_book.dart';
import '../../../models/bible_display_mode.dart';
import '../../../models/bible_note.dart';
import '../../../models/bible_section_title.dart';
import '../../../models/bible_verse.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../bookmark/bookmark_save_sheet.dart';
import 'displayed_verse_data.dart';
import 'note_block.dart';
import 'section_title_block.dart';

class ChapterReaderPage extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final int activeChapter;
  final int initialVerse;
  final bool shouldScrollToInitialVerse;
  final bool selectInitialVerse;
  final double fontSize;
  final Color bodyBackgroundColor;
  final BibleDisplayMode displayMode;
  final String? kjvBookNameEn;
  final String? kjvBookShortName;
  final void Function({required int chapter, required int verse})
  onVerseSelected;

  const ChapterReaderPage({
    super.key,
    required this.book,
    required this.chapter,
    required this.activeChapter,
    required this.initialVerse,
    required this.selectInitialVerse,
    required this.shouldScrollToInitialVerse,
    required this.fontSize,
    required this.bodyBackgroundColor,
    required this.displayMode,
    required this.kjvBookNameEn,
    required this.kjvBookShortName,
    required this.onVerseSelected,
  });

  @override
  State<ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<ChapterReaderPage> {
  late Future<_ChapterRenderData> _chapterContentFuture;

  final Map<int, GlobalKey> _verseKeys = {};
  bool _hasScrolledToInitialVerse = false;

  final Set<int> _selectedVerses = {};

  @override
  void initState() {
    super.initState();

    if (widget.selectInitialVerse) {
      _selectedVerses.add(widget.initialVerse);
    }

    _chapterContentFuture = _loadChapterContent();
  }

  @override
  void didUpdateWidget(covariant ChapterReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final movedAwayFromThisChapter =
        oldWidget.activeChapter != widget.activeChapter &&
        widget.activeChapter != widget.chapter;

    if (movedAwayFromThisChapter && _selectedVerses.isNotEmpty) {
      setState(() {
        _selectedVerses.clear();
      });
    }

    final contentChanged =
        oldWidget.book.bookId != widget.book.bookId ||
        oldWidget.chapter != widget.chapter ||
        oldWidget.displayMode != widget.displayMode;

    if (contentChanged) {
      _hasScrolledToInitialVerse = false;
      _verseKeys.clear();
      _chapterContentFuture = _loadChapterContent();
    }
  }

  Future<_ChapterRenderData> _loadChapterContent() async {
    List<BibleVerse> koVerses = [];
    List<KjvBibleVerse> kjvVerses = [];
    Map<int, List<BibleNote>> notesByVerse = {};
    Map<int, List<BibleSectionTitle>> sectionTitlesByVerse = {};

    if (!widget.displayMode.isEnglishOnly) {
      koVerses = await KoBibleDatabase.instance.getVerses(
        bookId: widget.book.bookId,
        chapter: widget.chapter,
      );

      notesByVerse = await KoBibleDatabase.instance.getNotesGroupedByVerse(
        bookId: widget.book.bookId,
        chapter: widget.chapter,
      );

      sectionTitlesByVerse = await KoBibleDatabase.instance
          .getSectionTitlesGroupedByVerse(
            bookId: widget.book.bookId,
            chapter: widget.chapter,
          );
    }

    if (!widget.displayMode.isKoreanOnly) {
      kjvVerses = await KjvBibleDatabase.instance.getVerses(
        bookId: widget.book.bookId,
        chapter: widget.chapter,
      );
    }

    final verseNumbers = widget.displayMode.isEnglishOnly
        ? kjvVerses.map((verse) => verse.verse).toList()
        : koVerses.map((verse) => verse.verse).toList();

    return _ChapterRenderData(
      verseNumbers: verseNumbers,
      koVersesByNumber: {for (final verse in koVerses) verse.verse: verse},
      kjvVersesByNumber: {for (final verse in kjvVerses) verse.verse: verse},
      notesByVerse: notesByVerse,
      sectionTitlesByVerse: sectionTitlesByVerse,
    );
  }

  void _scrollToInitialVerse(List<int> verseNumbers) {
    if (!widget.shouldScrollToInitialVerse) {
      return;
    }

    if (_hasScrolledToInitialVerse) {
      return;
    }

    final exists = verseNumbers.contains(widget.initialVerse);

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

  void _toggleVerse(int verseNumber) {
    setState(() {
      if (_selectedVerses.contains(verseNumber)) {
        _selectedVerses.remove(verseNumber);
      } else {
        _selectedVerses.add(verseNumber);
      }
    });

    widget.onVerseSelected(chapter: widget.chapter, verse: verseNumber);
  }

  void _selectVerseForAction(int verseNumber) {
    if (!_selectedVerses.contains(verseNumber)) {
      setState(() {
        _selectedVerses.add(verseNumber);
      });
    }

    widget.onVerseSelected(chapter: widget.chapter, verse: verseNumber);
  }

  String _buildVerseCopyText({
    required int verseNumber,
    required _ChapterRenderData data,
  }) {
    final buffer = StringBuffer();

    final koVerse = data.koVersesByNumber[verseNumber];
    final kjvVerse = data.kjvVersesByNumber[verseNumber];

    switch (widget.displayMode) {
      case BibleDisplayMode.krv:
        if (koVerse != null) {
          buffer.write(
            '${widget.book.nameKo} ${widget.chapter}:$verseNumber ${koVerse.verseText}',
          );
        }
        break;

      case BibleDisplayMode.kjv:
        if (kjvVerse != null) {
          final kjvLabel =
              widget.kjvBookShortName ??
              widget.kjvBookNameEn ??
              widget.book.nameKo;

          buffer.write(
            '$kjvLabel ${widget.chapter}:$verseNumber ${kjvVerse.verseText}',
          );
        }
        break;

      case BibleDisplayMode.krvKjv:
        if (koVerse != null) {
          buffer.write(
            '${widget.book.nameKo} ${widget.chapter}:$verseNumber ${koVerse.verseText}',
          );
        }

        if (kjvVerse != null) {
          final kjvLabel =
              widget.kjvBookShortName ??
              widget.kjvBookNameEn ??
              widget.book.nameKo;

          if (buffer.isNotEmpty) {
            buffer.write('\n');
          }

          buffer.write(
            '$kjvLabel ${widget.chapter}:$verseNumber ${kjvVerse.verseText}',
          );
        }
        break;
    }

    if (!widget.displayMode.isEnglishOnly) {
      final notes = data.notesByVerse[verseNumber] ?? [];

      for (final note in notes) {
        final marker = note.marker.trim();
        final noteText = note.noteText.trim();

        if (marker.isEmpty && noteText.isEmpty) {
          continue;
        }

        if (marker.isNotEmpty && noteText.isNotEmpty) {
          buffer.write('\n  $marker $noteText');
          continue;
        }

        if (marker.isNotEmpty) {
          buffer.write('\n  $marker');
          continue;
        }

        buffer.write('\n  $noteText');
      }
    }

    return buffer.toString();
  }

  List<int> _getSelectedVerseNumbers(_ChapterRenderData data) {
    final selected = data.verseNumbers
        .where((verseNumber) => _selectedVerses.contains(verseNumber))
        .toList();

    selected.sort();
    return selected;
  }

  Future<void> _copySelectedVerses({required _ChapterRenderData data}) async {
    final selectedVerseNumbers = _getSelectedVerseNumbers(data);

    if (selectedVerseNumbers.isEmpty) {
      return;
    }

    final copyText = selectedVerseNumbers
        .map(
          (verseNumber) =>
              _buildVerseCopyText(verseNumber: verseNumber, data: data),
        )
        .join('\n\n');

    await Clipboard.setData(ClipboardData(text: copyText));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedVerseNumbers.length}개 절을 복사했습니다.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  RelativeRect _getMenuPosition(Offset globalPosition) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final localPosition = overlay.globalToLocal(globalPosition);

    return RelativeRect.fromLTRB(
      localPosition.dx,
      localPosition.dy,
      overlay.size.width - localPosition.dx,
      overlay.size.height - localPosition.dy,
    );
  }

  Future<void> _openBookmarkSaveSheet({
    required _ChapterRenderData data,
  }) async {
    final selectedVerseNumbers = _getSelectedVerseNumbers(data).toSet();

    if (selectedVerseNumbers.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('북마크에 추가할 성구를 선택해주세요.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<BookmarkSaveResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: widget.bodyBackgroundColor,
      builder: (context) {
        return BookmarkSaveSheet(
          backgroundColor: widget.bodyBackgroundColor,
          bookId: widget.book.bookId,
          chapter: widget.chapter,
          selectedVerses: selectedVerseNumbers,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${result.groupName}" 북마크에 ${result.selectedVerseCount}개 성구를 추가했습니다.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _showVerseActionMenu({
    required Offset globalPosition,
    required int verseNumber,
    required _ChapterRenderData data,
  }) async {
    _selectVerseForAction(verseNumber);

    final selectedCount = _selectedVerses.length;

    final action = await showMenu<_VerseAction>(
      context: context,
      position: _getMenuPosition(globalPosition),
      color: widget.bodyBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem<_VerseAction>(
          value: _VerseAction.copy,
          child: Row(
            children: [
              const Icon(Icons.copy_rounded, size: 20),
              const SizedBox(width: 10),
              Text('복사 ($selectedCount개)'),
            ],
          ),
        ),
        const PopupMenuItem<_VerseAction>(
          value: _VerseAction.bookmark,
          child: Row(
            children: [
              Icon(Icons.bookmark_add_rounded, size: 20),
              SizedBox(width: 10),
              Text('북마크'),
            ],
          ),
        ),
      ],
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _VerseAction.copy) {
      await _copySelectedVerses(data: data);
      return;
    }

    if (action == _VerseAction.bookmark) {
      await _openBookmarkSaveSheet(data: data);
    }
  }

  double _verseNumberWidth(int verseNumber) {
    final digits = verseNumber.toString().length;

    if (digits <= 1) {
      return 22;
    }

    if (digits == 2) {
      return 30;
    }

    return 38;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ChapterRenderData>(
      future: _chapterContentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ColoredBox(
            color: widget.bodyBackgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return ColoredBox(
            color: widget.bodyBackgroundColor,
            child: Center(child: Text('오류 발생: ${snapshot.error}')),
          );
        }

        final data = snapshot.data;

        if (data == null || data.verseNumbers.isEmpty) {
          return ColoredBox(
            color: widget.bodyBackgroundColor,
            child: Center(
              child: Text(
                '${widget.book.nameKo} ${widget.chapter}장 본문 데이터가 없습니다.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        _scrollToInitialVerse(data.verseNumbers);

        return ColoredBox(
          color: widget.bodyBackgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...data.verseNumbers.map((verseNumber) {
                  final isSelected = _selectedVerses.contains(verseNumber);

                  final key = _verseKeys.putIfAbsent(
                    verseNumber,
                    () => GlobalKey(),
                  );

                  final koVerse = data.koVersesByNumber[verseNumber];
                  final kjvVerse = data.kjvVersesByNumber[verseNumber];

                  final rawSectionTitles =
                      data.sectionTitlesByVerse[verseNumber] ??
                      const <BibleSectionTitle>[];

                  final rawNotes =
                      data.notesByVerse[verseNumber] ?? const <BibleNote>[];

                  DisplayedVerseData? displayedVerse;
                  if (koVerse != null) {
                    displayedVerse = DisplayedVerseData.from(
                      verse: koVerse,
                      sectionTitles: rawSectionTitles,
                      notes: rawNotes,
                    );
                  }

                  final mainVerseText = switch (widget.displayMode) {
                    BibleDisplayMode.krv => displayedVerse?.verseText ?? '',
                    BibleDisplayMode.kjv => kjvVerse?.verseText ?? '',
                    BibleDisplayMode.krvKjv => displayedVerse?.verseText ?? '',
                  };

                  final sectionTitles = displayedVerse?.sectionTitles ?? [];
                  final notes = displayedVerse?.notes ?? [];
                  final englishText = widget.displayMode.isBilingual
                      ? (kjvVerse?.verseText ?? '')
                      : '';

                  final numberWidth = _verseNumberWidth(verseNumber);
                  final textLeftPadding = numberWidth + 1;

                  final verseNumberStyle = AppTextStyles.verseNumber(
                    widget.fontSize,
                  ).copyWith(height: 1.45);

                  final verseTextStyle = AppTextStyles.verseText(
                    widget.fontSize,
                  ).copyWith(height: 1.45);

                  final englishTextStyle = AppTextStyles.verseText(
                    (widget.fontSize - 2).clamp(10.0, 22.0).toDouble(),
                  ).copyWith(height: 1.45, color: AppColors.textSecondary);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.displayMode.isEnglishOnly &&
                          sectionTitles.isNotEmpty)
                        SectionTitleBlock(sectionTitles: sectionTitles),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _toggleVerse(verseNumber);
                        },
                        onLongPressStart: (details) {
                          _showVerseActionMenu(
                            globalPosition: details.globalPosition,
                            verseNumber: verseNumber,
                            data: data,
                          );
                        },
                        child: AnimatedContainer(
                          key: key,
                          duration: const Duration(milliseconds: 160),
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
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.verseHighlightBorder
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: numberWidth,
                                    child: Text(
                                      '$verseNumber',
                                      style: verseNumberStyle,
                                    ),
                                  ),
                                  const SizedBox(width: 1),
                                  Expanded(
                                    child: Text(
                                      mainVerseText,
                                      style: verseTextStyle,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.displayMode.isBilingual &&
                                  englishText.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: textLeftPadding,
                                    top: 2,
                                  ),
                                  child: Text(
                                    englishText,
                                    style: englishTextStyle,
                                  ),
                                ),
                              if (!widget.displayMode.isEnglishOnly &&
                                  notes.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: textLeftPadding,
                                    top: 2,
                                  ),
                                  child: NoteBlock(
                                    notes: notes,
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
          ),
        );
      },
    );
  }
}

enum _VerseAction { copy, bookmark }

class _ChapterRenderData {
  final List<int> verseNumbers;
  final Map<int, BibleVerse> koVersesByNumber;
  final Map<int, KjvBibleVerse> kjvVersesByNumber;
  final Map<int, List<BibleNote>> notesByVerse;
  final Map<int, List<BibleSectionTitle>> sectionTitlesByVerse;

  const _ChapterRenderData({
    required this.verseNumbers,
    required this.koVersesByNumber,
    required this.kjvVersesByNumber,
    required this.notesByVerse,
    required this.sectionTitlesByVerse,
  });
}
