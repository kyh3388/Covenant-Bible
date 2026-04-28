class BibleBookmarkVerse {
  final int bookmarkVerseId;
  final int bookmarkGroupId;
  final int bookId;
  final int chapter;
  final int verse;
  final String createdAt;

  final String bookNameKo;
  final String bookShortName;
  final String verseText;

  const BibleBookmarkVerse({
    required this.bookmarkVerseId,
    required this.bookmarkGroupId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.createdAt,
    required this.bookNameKo,
    required this.bookShortName,
    required this.verseText,
  });

  factory BibleBookmarkVerse.fromMap(Map<String, dynamic> map) {
    return BibleBookmarkVerse(
      bookmarkVerseId: map['bookmark_verse_id'] as int,
      bookmarkGroupId: map['bookmark_group_id'] as int,
      bookId: map['book_id'] as int,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      createdAt: map['created_at'] as String,
      bookNameKo: (map['name_ko'] ?? '') as String,
      bookShortName: (map['short_name'] ?? '') as String,
      verseText: (map['verse_text'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookmark_verse_id': bookmarkVerseId,
      'bookmark_group_id': bookmarkGroupId,
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'created_at': createdAt,
      'name_ko': bookNameKo,
      'short_name': bookShortName,
      'verse_text': verseText,
    };
  }

  String get referenceText {
    return '$bookNameKo $chapter:$verse';
  }

  String get shortReferenceText {
    if (bookShortName.trim().isEmpty) {
      return referenceText;
    }

    return '$bookShortName $chapter:$verse';
  }
}
