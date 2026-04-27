class BibleBook {
  final int bookId; //책 번호 ex.창세기 = 1, 출애굽기 = 2
  final String testament; //구약(OLD), 신약(NEW)
  final String nameKo; //책 한글 이름
  final String shortName; //책 약어
  final int chapterCount; //해당 책이 몇장까지 있는지.
  final int sortOrder;

  BibleBook({
    required this.bookId,
    required this.testament,
    required this.nameKo,
    required this.shortName,
    required this.chapterCount,
    required this.sortOrder,
  });

  factory BibleBook.fromMap(Map<String, dynamic> map) {
    return BibleBook(
      bookId: map['book_id'] as int,
      testament: map['testament'] as String,
      nameKo: map['name_ko'] as String,
      shortName: map['short_name'] as String,
      chapterCount: map['chapter_count'] as int,
      sortOrder: map['sort_order'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'book_id': bookId,
      'testament': testament,
      'name_ko': nameKo,
      'short_name': shortName,
      'chapter_count': chapterCount,
      'sort_order': sortOrder,
    };
  }
}
