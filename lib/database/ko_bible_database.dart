import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bible_book.dart';
import '../models/bible_bookmark_group.dart';
import '../models/bible_bookmark_verse.dart';
import '../models/bible_note.dart';
import '../models/bible_section_title.dart';
import '../models/bible_verse.dart';

class KoBibleDatabase {
  static final KoBibleDatabase instance = KoBibleDatabase._init();

  static Database? _database;

  KoBibleDatabase._init();

  static const String _assetDbPath = 'assets/db/bible_ko.db';
  static const String _localDbName = 'covenant_bible_ko_asset_v1.db';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final localDbPath = join(databasePath, _localDbName);

    final exists = await databaseExists(localDbPath);

    if (!exists) {
      await _copyDatabaseFromAssets(localDbPath);
    }

    final db = await openDatabase(localDbPath, readOnly: false);

    await _ensureUserTables(db);

    return db;
  }

  Future<void> _copyDatabaseFromAssets(String localDbPath) async {
    final dbDirectory = Directory(dirname(localDbPath));

    if (!await dbDirectory.exists()) {
      await dbDirectory.create(recursive: true);
    }

    final byteData = await rootBundle.load(_assetDbPath);

    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    await File(localDbPath).writeAsBytes(bytes, flush: true);
  }

  Future<void> _ensureUserTables(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bible_bookmark_group (
        bookmark_group_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bible_bookmark_verse (
        bookmark_verse_id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookmark_group_id INTEGER NOT NULL,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (bookmark_group_id)
          REFERENCES bible_bookmark_group (bookmark_group_id)
          ON DELETE CASCADE,
        UNIQUE (bookmark_group_id, book_id, chapter, verse)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_bible_bookmark_verse_group_id
      ON bible_bookmark_verse (bookmark_group_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_bible_bookmark_verse_reference
      ON bible_bookmark_verse (book_id, chapter, verse)
    ''');
  }

  Future<List<BibleBook>> getBooks() async {
    final db = await database;

    final result = await db.query(
      'bible_book',
      columns: [
        'book_id',
        'testament',
        'name_ko',
        'short_name',
        'chapter_count',
        'sort_order',
      ],
      orderBy: 'sort_order ASC',
    );

    return result.map((row) => BibleBook.fromMap(row)).toList();
  }

  Future<BibleBook?> getBookById(int bookId) async {
    final db = await database;

    final result = await db.query(
      'bible_book',
      columns: [
        'book_id',
        'testament',
        'name_ko',
        'short_name',
        'chapter_count',
        'sort_order',
      ],
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return BibleBook.fromMap(result.first);
  }

  Future<List<BibleVerse>> getVerses({
    required int bookId,
    required int chapter,
  }) async {
    final db = await database;

    final result = await db.query(
      'bible_verse',
      columns: ['verse_id', 'book_id', 'chapter', 'verse', 'verse_text'],
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse ASC, verse_id ASC',
    );

    return result.map((row) => BibleVerse.fromMap(row)).toList();
  }

  Future<List<BibleNote>> getNotes({
    required int bookId,
    required int chapter,
  }) async {
    final db = await database;

    final result = await db.query(
      'bible_note',
      columns: [
        'note_id',
        'book_id',
        'chapter',
        'verse',
        'marker',
        'note_text',
      ],
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse ASC, note_id ASC',
    );

    return result.map((row) => BibleNote.fromMap(row)).toList();
  }

  Future<List<BibleSectionTitle>> getSectionTitles({
    required int bookId,
    required int chapter,
  }) async {
    final db = await database;

    final result = await db.query(
      'bible_section_title',
      columns: ['title_id', 'book_id', 'chapter', 'verse', 'title_text'],
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse ASC, title_id ASC',
    );

    return result.map((row) => BibleSectionTitle.fromMap(row)).toList();
  }

  Future<Map<int, List<BibleNote>>> getNotesGroupedByVerse({
    required int bookId,
    required int chapter,
  }) async {
    final notes = await getNotes(bookId: bookId, chapter: chapter);

    final Map<int, List<BibleNote>> groupedNotes = {};

    for (final note in notes) {
      groupedNotes.putIfAbsent(note.verse, () => []);
      groupedNotes[note.verse]!.add(note);
    }

    return groupedNotes;
  }

  Future<Map<int, List<BibleSectionTitle>>> getSectionTitlesGroupedByVerse({
    required int bookId,
    required int chapter,
  }) async {
    final titles = await getSectionTitles(bookId: bookId, chapter: chapter);

    final Map<int, List<BibleSectionTitle>> groupedTitles = {};

    for (final title in titles) {
      groupedTitles.putIfAbsent(title.verse, () => []);
      groupedTitles[title.verse]!.add(title);
    }

    return groupedTitles;
  }

  Future<List<Map<String, dynamic>>> searchVerses(
    String keyword, {
    String? testament,
    int? limit,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return [];
    }

    final db = await database;

    final whereConditions = <String>['v.verse_text LIKE ?'];
    final whereArgs = <Object>['%$trimmedKeyword%'];

    if (testament != null && testament.isNotEmpty) {
      whereConditions.add('b.testament = ?');
      whereArgs.add(testament);
    }

    final normalizedLimit = (limit != null && limit > 0) ? limit : null;
    final limitClause = normalizedLimit != null ? 'LIMIT $normalizedLimit' : '';

    final result = await db.rawQuery('''
      SELECT
        v.book_id,
        b.name_ko,
        b.testament,
        v.chapter,
        v.verse,
        v.verse_text
      FROM bible_verse v
      INNER JOIN bible_book b
        ON v.book_id = b.book_id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY v.book_id ASC, v.chapter ASC, v.verse ASC
      $limitClause
      ''', whereArgs);

    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<BibleBookmarkGroup>> getBookmarkGroups() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        g.bookmark_group_id,
        g.name,
        g.created_at,
        g.updated_at,
        COUNT(v.bookmark_verse_id) AS verse_count
      FROM bible_bookmark_group g
      LEFT JOIN bible_bookmark_verse v
        ON g.bookmark_group_id = v.bookmark_group_id
      GROUP BY
        g.bookmark_group_id,
        g.name,
        g.created_at,
        g.updated_at
      ORDER BY g.updated_at DESC, g.bookmark_group_id DESC
    ''');

    return result.map((row) => BibleBookmarkGroup.fromMap(row)).toList();
  }

  Future<BibleBookmarkGroup?> getBookmarkGroupById(int bookmarkGroupId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        g.bookmark_group_id,
        g.name,
        g.created_at,
        g.updated_at,
        COUNT(v.bookmark_verse_id) AS verse_count
      FROM bible_bookmark_group g
      LEFT JOIN bible_bookmark_verse v
        ON g.bookmark_group_id = v.bookmark_group_id
      WHERE g.bookmark_group_id = ?
      GROUP BY
        g.bookmark_group_id,
        g.name,
        g.created_at,
        g.updated_at
      LIMIT 1
      ''',
      [bookmarkGroupId],
    );

    if (result.isEmpty) {
      return null;
    }

    return BibleBookmarkGroup.fromMap(result.first);
  }

  Future<int> createBookmarkGroup(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('북마크 이름은 비어 있을 수 없습니다.');
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('bible_bookmark_group', {
      'name': trimmedName,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateBookmarkGroupName({
    required int bookmarkGroupId,
    required String name,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('북마크 이름은 비어 있을 수 없습니다.');
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'bible_bookmark_group',
      {'name': trimmedName, 'updated_at': now},
      where: 'bookmark_group_id = ?',
      whereArgs: [bookmarkGroupId],
    );
  }

  Future<void> deleteBookmarkGroup(int bookmarkGroupId) async {
    final db = await database;

    await db.delete(
      'bible_bookmark_group',
      where: 'bookmark_group_id = ?',
      whereArgs: [bookmarkGroupId],
    );
  }

  Future<List<BibleBookmarkVerse>> getBookmarkVerses({
    required int bookmarkGroupId,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        bv.bookmark_verse_id,
        bv.bookmark_group_id,
        bv.book_id,
        bv.chapter,
        bv.verse,
        bv.created_at,
        b.name_ko,
        b.short_name,
        v.verse_text
      FROM bible_bookmark_verse bv
      INNER JOIN bible_book b
        ON bv.book_id = b.book_id
      INNER JOIN bible_verse v
        ON bv.book_id = v.book_id
       AND bv.chapter = v.chapter
       AND bv.verse = v.verse
      WHERE bv.bookmark_group_id = ?
      ORDER BY
        bv.book_id ASC,
        bv.chapter ASC,
        bv.verse ASC,
        bv.bookmark_verse_id ASC
      ''',
      [bookmarkGroupId],
    );

    return result.map((row) => BibleBookmarkVerse.fromMap(row)).toList();
  }

  Future<void> addBookmarkVersesToGroup({
    required int bookmarkGroupId,
    required int bookId,
    required int chapter,
    required Iterable<int> verses,
  }) async {
    final normalizedVerses = verses.toSet().toList()..sort();

    if (normalizedVerses.isEmpty) {
      return;
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final verse in normalizedVerses) {
        await txn.insert('bible_bookmark_verse', {
          'bookmark_group_id': bookmarkGroupId,
          'book_id': bookId,
          'chapter': chapter,
          'verse': verse,
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await txn.update(
        'bible_bookmark_group',
        {'updated_at': now},
        where: 'bookmark_group_id = ?',
        whereArgs: [bookmarkGroupId],
      );
    });
  }

  Future<void> removeBookmarkVerse({required int bookmarkVerseId}) async {
    final db = await database;

    final target = await db.query(
      'bible_bookmark_verse',
      columns: ['bookmark_group_id'],
      where: 'bookmark_verse_id = ?',
      whereArgs: [bookmarkVerseId],
      limit: 1,
    );

    if (target.isEmpty) {
      return;
    }

    final bookmarkGroupId = target.first['bookmark_group_id'] as int;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'bible_bookmark_verse',
        where: 'bookmark_verse_id = ?',
        whereArgs: [bookmarkVerseId],
      );

      await txn.update(
        'bible_bookmark_group',
        {'updated_at': now},
        where: 'bookmark_group_id = ?',
        whereArgs: [bookmarkGroupId],
      );
    });
  }

  Future<void> removeBookmarkVerseByReference({
    required int bookmarkGroupId,
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'bible_bookmark_verse',
        where:
            'bookmark_group_id = ? AND book_id = ? AND chapter = ? AND verse = ?',
        whereArgs: [bookmarkGroupId, bookId, chapter, verse],
      );

      await txn.update(
        'bible_bookmark_group',
        {'updated_at': now},
        where: 'bookmark_group_id = ?',
        whereArgs: [bookmarkGroupId],
      );
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
