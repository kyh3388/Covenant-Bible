import 'package:flutter/material.dart';

import '../database/ko_bible_database.dart';
import '../models/bible_book.dart';
import '../models/bible_verse.dart';
import 'bible_reader_screen.dart';

class VerseListScreen extends StatefulWidget {
  final BibleBook book;
  final int chapter;
  final bool openAsPicker;

  const VerseListScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.openAsPicker = false,
  });

  @override
  State<VerseListScreen> createState() => _VerseListScreenState();
}

class _VerseListScreenState extends State<VerseListScreen> {
  late Future<List<BibleVerse>> _versesFuture;

  @override
  void initState() {
    super.initState();

    _versesFuture = KoBibleDatabase.instance.getVerses(
      bookId: widget.book.bookId,
      chapter: widget.chapter,
    );
  }

  void _openReader(BibleVerse verse) {
    final readerScreen = BibleReaderScreen(
      book: widget.book,
      chapter: widget.chapter,
      initialVerse: verse.verse,
    );

    if (widget.openAsPicker) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => readerScreen),
        (route) => false,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => readerScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.book.nameKo} ${widget.chapter}장 절 선택'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<BibleVerse>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          final verses = snapshot.data ?? [];

          if (verses.isEmpty) {
            return Center(
              child: Text(
                '${widget.book.nameKo} ${widget.chapter}장 절 데이터가 없습니다.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: verses.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final verse = verses[index];

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _openReader(verse);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    border: Border.all(color: Colors.blueGrey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${verse.verse}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
