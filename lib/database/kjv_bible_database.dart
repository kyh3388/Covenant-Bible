import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class KjvBibleBook {
  final int bookId;
  final String testament;
  final String nameEn;
  final String shortName;
  final int chapterCount;
  final int sortOrder;

  const KjvBibleBook({
    required this.bookId,
    required this.testament,
    required this.nameEn,
    required this.shortName,
    required this.chapterCount,
    required this.sortOrder,
  });

  factory KjvBibleBook.fromMap(Map<String, dynamic> map) {
    return KjvBibleBook(
      bookId: map['book_id'] as int,
      testament: map['testament'] as String,
      nameEn: map['name_en'] as String,
      shortName: map['short_name'] as String,
      chapterCount: map['chapter_count'] as int,
      sortOrder: map['sort_order'] as int,
    );
  }
}

class KjvBibleVerse {
  final int verseId;
  final int bookId;
  final int chapter;
  final int verse;
  final String verseText;

  const KjvBibleVerse({
    required this.verseId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.verseText,
  });

  factory KjvBibleVerse.fromMap(Map<String, dynamic> map) {
    return KjvBibleVerse(
      verseId: map['verse_id'] as int,
      bookId: map['book_id'] as int,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      verseText: map['verse_text'] as String,
    );
  }
}

class KjvBibleDatabase {
  static final KjvBibleDatabase instance = KjvBibleDatabase._init();

  static Database? _database;

  KjvBibleDatabase._init();

  // 수정: 영어 KJV DB 파일 분리
  static const String _assetDbPath = 'assets/db/bible_kjv.db';
  static const String _localDbName = 'covenant_bible_kjv_asset.db';

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

    return await openDatabase(localDbPath, readOnly: true);
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

  Future<List<KjvBibleBook>> getBooks() async {
    final db = await database;

    final result = await db.query(
      'bible_book',
      columns: [
        'book_id',
        'testament',
        'name_en',
        'short_name',
        'chapter_count',
        'sort_order',
      ],
      orderBy: 'sort_order ASC',
    );

    return result.map((row) => KjvBibleBook.fromMap(row)).toList();
  }

  Future<KjvBibleBook?> getBookById(int bookId) async {
    final db = await database;

    final result = await db.query(
      'bible_book',
      columns: [
        'book_id',
        'testament',
        'name_en',
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

    return KjvBibleBook.fromMap(result.first);
  }

  Future<List<KjvBibleVerse>> getVerses({
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

    return result.map((row) => KjvBibleVerse.fromMap(row)).toList();
  }

  Future<List<Map<String, dynamic>>> searchVerses(String keyword) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return [];
    }

    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        v.book_id,
        b.name_en,
        v.chapter,
        v.verse,
        v.verse_text
      FROM bible_verse v
      INNER JOIN bible_book b
        ON v.book_id = b.book_id
      WHERE v.verse_text LIKE ?
      ORDER BY v.book_id ASC, v.chapter ASC, v.verse ASC
      ''',
      ['%$trimmedKeyword%'],
    );

    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
