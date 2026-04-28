import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../database/bible_database.dart';
import '../../../models/bible_book.dart';
import '../../../models/bible_note.dart';
import '../../../models/bible_verse.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../bookmark/bookmark_save_sheet.dart';
import 'chapter_content_data.dart';
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
    required this.onVerseSelected,
  });

  @override
  State<ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<ChapterReaderPage> {
  late Future<ChapterContentData> _chapterContentFuture;

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

    if (movedAwayFromThisChapter) {
      if (_selectedVerses.isNotEmpty) {
        setState(() {
          _selectedVerses.clear();
        });
      }
    }
  }

  Future<ChapterContentData> _loadChapterContent() async {
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

    return ChapterContentData(
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

  void _selectVerseForAction(BibleVerse verse) {
    if (!_selectedVerses.contains(verse.verse)) {
      setState(() {
        _selectedVerses.add(verse.verse);
      });
    }

    widget.onVerseSelected(chapter: widget.chapter, verse: verse.verse);
  }

  String _buildVerseCopyText({
    required BibleVerse verse,
    required Map<int, List<BibleNote>> notesByVerse,
  }) {
    final buffer = StringBuffer();

    buffer.write(
      '${widget.book.nameKo} ${widget.chapter}:${verse.verse} ${verse.verseText}',
    );

    final notes = notesByVerse[verse.verse] ?? [];

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

    return buffer.toString();
  }

  List<BibleVerse> _getSelectedVerseObjects(List<BibleVerse> allVerses) {
    final selected = allVerses
        .where((verse) => _selectedVerses.contains(verse.verse))
        .toList();

    selected.sort((a, b) => a.verse.compareTo(b.verse));

    return selected;
  }

  Future<void> _copySelectedVerses({
    required List<BibleVerse> allVerses,
    required Map<int, List<BibleNote>> notesByVerse,
  }) async {
    final selectedVerseObjects = _getSelectedVerseObjects(allVerses);

    if (selectedVerseObjects.isEmpty) {
      return;
    }

    final copyText = selectedVerseObjects
        .map(
          (verse) =>
              _buildVerseCopyText(verse: verse, notesByVerse: notesByVerse),
        )
        .join('\n\n');

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
    required List<BibleVerse> allVerses,
  }) async {
    final selectedVerseObjects = _getSelectedVerseObjects(allVerses);

    if (selectedVerseObjects.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('북마크에 추가할 성구를 선택해주세요.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final selectedVerseNumbers = selectedVerseObjects
        .map((verse) => verse.verse)
        .toSet();

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
    required BibleVerse verse,
    required List<BibleVerse> allVerses,
    required Map<int, List<BibleNote>> notesByVerse,
  }) async {
    _selectVerseForAction(verse);

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
      await _copySelectedVerses(
        allVerses: allVerses,
        notesByVerse: notesByVerse,
      );
      return;
    }

    if (action == _VerseAction.bookmark) {
      await _openBookmarkSaveSheet(allVerses: allVerses);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChapterContentData>(
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

        if (data == null || data.verses.isEmpty) {
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

        _scrollToInitialVerse(data.verses);

        return ColoredBox(
          color: widget.bodyBackgroundColor,
          child: SingleChildScrollView(
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

                  final displayedVerse = DisplayedVerseData.from(
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
                        SectionTitleBlock(
                          sectionTitles: displayedVerse.sectionTitles,
                        ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _toggleVerse(verse);
                        },
                        onLongPressStart: (details) {
                          _showVerseActionMenu(
                            globalPosition: details.globalPosition,
                            verse: verse,
                            allVerses: data.verses,
                            notesByVerse: data.notesByVerse,
                          );
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
                                  child: NoteBlock(
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
          ),
        );
      },
    );
  }
}

enum _VerseAction { copy, bookmark }
