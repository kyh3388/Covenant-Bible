import 'package:shared_preferences/shared_preferences.dart';

class RecentReadLocation {
  final int bookId;
  final int chapter;
  final int verse;

  const RecentReadLocation({
    required this.bookId,
    required this.chapter,
    required this.verse,
  });
}

class RecentReadService {
  static const String _bookIdKey = 'recent_book_id';
  static const String _chapterKey = 'recent_chapter';
  static const String _verseKey = 'recent_verse';

  static const String _fontSizeKey = 'reader_font_size';

  static const int defaultBookId = 1;
  static const int defaultChapter = 1;
  static const int defaultVerse = 1;
  static const double defaultFontSize = 20.0;

  Future<void> saveRecentLocation({
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_bookIdKey, bookId);
    await prefs.setInt(_chapterKey, chapter);
    await prefs.setInt(_verseKey, verse);
  }

  Future<RecentReadLocation> getRecentLocation() async {
    final prefs = await SharedPreferences.getInstance();

    final bookId = prefs.getInt(_bookIdKey) ?? defaultBookId;
    final chapter = prefs.getInt(_chapterKey) ?? defaultChapter;
    final verse = prefs.getInt(_verseKey) ?? defaultVerse;

    return RecentReadLocation(bookId: bookId, chapter: chapter, verse: verse);
  }

  Future<void> clearRecentLocation() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_bookIdKey);
    await prefs.remove(_chapterKey);
    await prefs.remove(_verseKey);
  }

  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_fontSizeKey, fontSize);
  }

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getDouble(_fontSizeKey) ?? defaultFontSize;
  }
}
