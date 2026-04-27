import 'package:flutter/material.dart';

import 'database/bible_database.dart';
import 'models/bible_book.dart';
import 'screens/bible_reader_screen.dart';
import 'services/recent_read_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CovenantBibleApp());
}

class CovenantBibleApp extends StatelessWidget {
  const CovenantBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '약속의 책 성경',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppStartScreen(),
    );
  }
}

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  late Future<_InitialReaderData> _initialReaderFuture;

  @override
  void initState() {
    super.initState();
    _initialReaderFuture = _loadInitialReaderData();
  }

  Future<_InitialReaderData> _loadInitialReaderData() async {
    final recentReadService = RecentReadService();

    final recentLocation = await recentReadService.getRecentLocation();

    BibleBook? book = await BibleDatabase.instance.getBookById(
      recentLocation.bookId,
    );

    int chapter = recentLocation.chapter;
    int verse = recentLocation.verse;

    if (book == null) {
      book = await BibleDatabase.instance.getBookById(
        RecentReadService.defaultBookId,
      );

      chapter = RecentReadService.defaultChapter;
      verse = RecentReadService.defaultVerse;
    }

    if (book == null) {
      throw Exception('기본 성경 책 정보를 찾을 수 없습니다.');
    }

    if (chapter < 1 || chapter > book.chapterCount) {
      chapter = RecentReadService.defaultChapter;
    }

    if (verse < 1) {
      verse = RecentReadService.defaultVerse;
    }

    return _InitialReaderData(book: book, chapter: chapter, verse: verse);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InitialReaderData>(
      future: _initialReaderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('앱 시작 중 오류가 발생했습니다.', textAlign: TextAlign.center),
              ),
            ),
          );
        }

        final data = snapshot.data;

        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('성경 데이터를 불러오지 못했습니다.')),
          );
        }

        return BibleReaderScreen(
          book: data.book,
          chapter: data.chapter,
          initialVerse: data.verse,
        );
      },
    );
  }
}

class _InitialReaderData {
  final BibleBook book;
  final int chapter;
  final int verse;

  const _InitialReaderData({
    required this.book,
    required this.chapter,
    required this.verse,
  });
}
