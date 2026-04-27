class BibleNote {
  final int noteId;
  final int bookId;
  final int chapter;
  final int verse;
  final String marker;
  final String noteText;

  BibleNote({
    required this.noteId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.marker,
    required this.noteText,
  });

  factory BibleNote.fromMap(Map<String, dynamic> map) {
    return BibleNote(
      noteId: map['note_id'] as int,
      bookId: map['book_id'] as int,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      marker: (map['marker'] ?? '') as String,
      noteText: map['note_text'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'marker': marker,
      'note_text': noteText,
    };
  }
}
