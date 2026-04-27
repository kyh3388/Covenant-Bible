class BibleVerse {
  final int verseId;
  final int bookId;
  final int chapter;
  final int verse;
  final String verseText;

  BibleVerse({
    required this.verseId, //절 고유번호
    required this.bookId, //책 번호
    required this.chapter, //장 번호
    required this.verse, //절 번호
    required this.verseText, //본문 내용
  });

  factory BibleVerse.fromMap(Map<String, dynamic> map) {
    return BibleVerse(
      verseId: map['verse_id'] as int,
      bookId: map['book_id'] as int,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      verseText: map['verse_text'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verse_id': verseId,
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'verse_text': verseText,
    };
  }
}
