class BibleBookmarkGroup {
  final int bookmarkGroupId;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int verseCount;

  const BibleBookmarkGroup({
    required this.bookmarkGroupId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.verseCount = 0,
  });

  factory BibleBookmarkGroup.fromMap(Map<String, dynamic> map) {
    return BibleBookmarkGroup(
      bookmarkGroupId: map['bookmark_group_id'] as int,
      name: map['name'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      verseCount: (map['verse_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookmark_group_id': bookmarkGroupId,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'verse_count': verseCount,
    };
  }
}
