import '../../../models/bible_note.dart';
import '../../../models/bible_section_title.dart';
import '../../../models/bible_verse.dart';

class ChapterContentData {
  final List<BibleVerse> verses;
  final Map<int, List<BibleNote>> notesByVerse;
  final Map<int, List<BibleSectionTitle>> sectionTitlesByVerse;

  const ChapterContentData({
    required this.verses,
    required this.notesByVerse,
    required this.sectionTitlesByVerse,
  });
}
