import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bible_book.dart';
import '../models/bible_note.dart';
import '../models/bible_section_title.dart';
import '../models/bible_verse.dart';

class BibleDatabase {
  static final BibleDatabase instance = BibleDatabase._init();

  static Database? _database;

  BibleDatabase._init();

  static const String _assetDbPath = 'assets/db/bible.db';
  static const String _localDbName = 'covenant_bible_asset_v1.db';

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

    return await openDatabase(localDbPath, readOnly: false);
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
    int limit = 100,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return [];
    }

    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        v.book_id,
        b.name_ko,
        v.chapter,
        v.verse,
        v.verse_text
      FROM bible_verse v
      INNER JOIN bible_book b
        ON v.book_id = b.book_id
      WHERE v.verse_text LIKE ?
      ORDER BY v.book_id ASC, v.chapter ASC, v.verse ASC
      LIMIT ?
      ''',
      ['%$trimmedKeyword%', limit],
    );

    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
