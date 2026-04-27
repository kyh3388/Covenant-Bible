class BibleSectionTitle {
  final int titleId;
  final int bookId;
  final int chapter;
  final int verse;
  final String titleText;

  BibleSectionTitle({
    required this.titleId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.titleText,
  });

  factory BibleSectionTitle.fromMap(Map<String, dynamic> map) {
    return BibleSectionTitle(
      titleId: map['title_id'] as int,
      bookId: map['book_id'] as int,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      titleText: map['title_text'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title_id': titleId,
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'title_text': titleText,
    };
  }
}
