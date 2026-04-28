import '../../../models/bible_note.dart';
import '../../../models/bible_section_title.dart';
import '../../../models/bible_verse.dart';

class DisplayedVerseData {
  final String verseText;
  final List<String> sectionTitles;
  final List<BibleNote> notes;

  const DisplayedVerseData({
    required this.verseText,
    required this.sectionTitles,
    required this.notes,
  });

  factory DisplayedVerseData.from({
    required BibleVerse verse,
    required List<BibleSectionTitle> sectionTitles,
    required List<BibleNote> notes,
  }) {
    var verseText = verse.verseText.trimLeft();

    final titles = <String>[];

    for (final title in sectionTitles) {
      final normalized = _normalizeTitle(title.titleText);

      if (normalized.isNotEmpty && !titles.contains(normalized)) {
        titles.add(normalized);
      }
    }

    final parsed = _extractLeadingTitlesAndBody(verseText);

    for (final title in parsed.titles) {
      final normalized = _normalizeTitle(title);

      if (normalized.isNotEmpty && !titles.contains(normalized)) {
        titles.add(normalized);
      }
    }

    verseText = _cleanVerseBody(parsed.body);

    return DisplayedVerseData(
      verseText: verseText,
      sectionTitles: titles,
      notes: notes,
    );
  }

  static _ParsedTitleBody _extractLeadingTitlesAndBody(String rawText) {
    var text = rawText.trimLeft();
    final titles = <String>[];

    while (text.startsWith('〔')) {
      final fullWidthCloseIndex = text.indexOf('〕');

      if (fullWidthCloseIndex >= 0) {
        final title = text.substring(1, fullWidthCloseIndex).trim();

        if (title.isNotEmpty) {
          titles.add(title);
        }

        text = text.substring(fullWidthCloseIndex + 1).trimLeft();
        continue;
      }

      final asciiReferenceEndIndex = text.indexOf(']');

      if (asciiReferenceEndIndex >= 0 && asciiReferenceEndIndex <= 80) {
        final title = text.substring(1, asciiReferenceEndIndex + 1).trim();

        if (title.isNotEmpty) {
          titles.add(title);
        }

        text = text.substring(asciiReferenceEndIndex + 1).trimLeft();
        continue;
      }

      break;
    }

    return _ParsedTitleBody(titles: titles, body: text);
  }

  static String _normalizeTitle(String rawTitle) {
    var title = rawTitle.trim();

    if (title.isEmpty) {
      return '';
    }

    title = title.replaceFirst(RegExp(r'^〔\s*'), '');
    title = title.replaceFirst(RegExp(r'\s*〕$'), '');

    final openSquareCount = RegExp(r'\[').allMatches(title).length;
    final closeSquareCount = RegExp(r'\]').allMatches(title).length;

    if (openSquareCount > closeSquareCount) {
      final missingCloseCount = openSquareCount - closeSquareCount;
      title = '$title${List.filled(missingCloseCount, ']').join()}';
    }

    return title.trim();
  }

  static String _cleanVerseBody(String rawBody) {
    var body = rawBody.trimLeft();

    while (body.startsWith('〕') ||
        body.startsWith(']') ||
        body.startsWith('〔') ||
        body.startsWith('[')) {
      body = body.substring(1).trimLeft();
    }

    return body;
  }
}

class _ParsedTitleBody {
  final List<String> titles;
  final String body;

  const _ParsedTitleBody({required this.titles, required this.body});
}
