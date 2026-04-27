import 'package:flutter/material.dart';

import '../models/bible_book.dart';
import 'verse_list_screen.dart';

class ChapterListScreen extends StatelessWidget {
  final BibleBook book;
  final bool openAsPicker;

  const ChapterListScreen({
    super.key,
    required this.book,
    this.openAsPicker = false,
  });

  @override
  Widget build(BuildContext context) {
    final chapters = List.generate(book.chapterCount, (index) => index + 1);

    return Scaffold(
      appBar: AppBar(title: Text('${book.nameKo} 장 선택'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chapters.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final chapter = chapters[index];

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerseListScreen(
                    book: book,
                    chapter: chapter,
                    openAsPicker: openAsPicker,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                border: Border.all(color: Colors.brown.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$chapter',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
