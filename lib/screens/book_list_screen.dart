import 'package:flutter/material.dart';

import '../database/bible_database.dart';
import '../models/bible_book.dart';
import 'chapter_list_screen.dart';

class BookListScreen extends StatefulWidget {
  final bool openAsPicker;

  const BookListScreen({super.key, this.openAsPicker = false});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  late Future<List<BibleBook>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = BibleDatabase.instance.getBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.openAsPicker ? '책 선택' : '약속의 책 성경'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<BibleBook>>(
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
            itemCount: books.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final book = books[index];

              return ListTile(
                title: Text(
                  book.nameKo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${book.testament == 'OLD' ? '구약' : '신약'} · ${book.chapterCount}장',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChapterListScreen(
                        book: book,
                        openAsPicker: widget.openAsPicker,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
