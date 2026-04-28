import '../../../models/bible_book.dart';

class BiblePickerResult {
  final BibleBook book;
  final int chapter;
  final int verse;

  const BiblePickerResult({
    required this.book,
    required this.chapter,
    required this.verse,
  });
}
