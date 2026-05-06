import 'package:flutter/foundation.dart';

import '../database/ko_bible_database.dart';
import '../database/kjv_bible_database.dart';

Future<void> runDbSmokeTest() async {
  debugPrint('===== DB SMOKE TEST START =====');

  try {
    final koBooks = await KoBibleDatabase.instance.getBooks();
    debugPrint('[KO] book count = ${koBooks.length}');

    final kjvBooks = await KjvBibleDatabase.instance.getBooks();
    debugPrint('[KJV] book count = ${kjvBooks.length}');

    final koGenesis = await KoBibleDatabase.instance.getVerses(
      bookId: 1,
      chapter: 1,
    );

    if (koGenesis.isNotEmpty) {
      debugPrint('[KO] Genesis 1:1 = ${koGenesis.first.verseText}');
    } else {
      debugPrint('[KO] Genesis 1장은 비어 있습니다.');
    }

    final kjvGenesis = await KjvBibleDatabase.instance.getVerses(
      bookId: 1,
      chapter: 1,
    );

    if (kjvGenesis.isNotEmpty) {
      debugPrint('[KJV] Genesis 1:1 = ${kjvGenesis.first.verseText}');
    } else {
      debugPrint('[KJV] Genesis 1장은 비어 있습니다.');
    }

    debugPrint('===== DB SMOKE TEST END =====');
  } catch (e, st) {
    debugPrint('===== DB SMOKE TEST ERROR =====');
    debugPrint(e.toString());
    debugPrint(st.toString());
  }
}
