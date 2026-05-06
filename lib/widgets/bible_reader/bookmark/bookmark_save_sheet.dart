import 'package:flutter/material.dart';

import '../../../database/ko_bible_database.dart';
import '../../../models/bible_bookmark_group.dart';
import '../../../theme/app_colors.dart';

class BookmarkSaveResult {
  final String groupName;
  final int selectedVerseCount;
  final bool createdNewGroup;

  const BookmarkSaveResult({
    required this.groupName,
    required this.selectedVerseCount,
    required this.createdNewGroup,
  });
}

class BookmarkSaveSheet extends StatefulWidget {
  final Color backgroundColor;
  final int bookId;
  final int chapter;
  final Set<int> selectedVerses;

  const BookmarkSaveSheet({
    super.key,
    required this.backgroundColor,
    required this.bookId,
    required this.chapter,
    required this.selectedVerses,
  });

  @override
  State<BookmarkSaveSheet> createState() => _BookmarkSaveSheetState();
}

class _BookmarkSaveSheetState extends State<BookmarkSaveSheet> {
  final TextEditingController _nameController = TextEditingController();

  late Future<List<BibleBookmarkGroup>> _bookmarkGroupsFuture;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bookmarkGroupsFuture = KoBibleDatabase.instance.getBookmarkGroups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _createGroupAndSave() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('북마크 이름을 입력해주세요.');
      return;
    }

    if (widget.selectedVerses.isEmpty) {
      _showMessage('선택된 성구가 없습니다.');
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bookmarkGroupId = await KoBibleDatabase.instance
          .createBookmarkGroup(name);

      await KoBibleDatabase.instance.addBookmarkVersesToGroup(
        bookmarkGroupId: bookmarkGroupId,
        bookId: widget.bookId,
        chapter: widget.chapter,
        verses: widget.selectedVerses,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        BookmarkSaveResult(
          groupName: name,
          selectedVerseCount: widget.selectedVerses.length,
          createdNewGroup: true,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('북마크 저장 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveToExistingGroup(BibleBookmarkGroup group) async {
    if (widget.selectedVerses.isEmpty) {
      _showMessage('선택된 성구가 없습니다.');
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await KoBibleDatabase.instance.addBookmarkVersesToGroup(
        bookmarkGroupId: group.bookmarkGroupId,
        bookId: widget.bookId,
        chapter: widget.chapter,
        verses: widget.selectedVerses,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        BookmarkSaveResult(
          groupName: group.name,
          selectedVerseCount: widget.selectedVerses.length,
          createdNewGroup: false,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('북마크 저장 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildCreateSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 북마크 만들기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _createGroupAndSave();
                  },
                  decoration: InputDecoration(
                    hintText: '예: 믿음, 기도, 회개',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSaving ? null : _createGroupAndSave,
                child: const Text('저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExistingGroupsSection() {
    return Expanded(
      child: FutureBuilder<List<BibleBookmarkGroup>>(
        future: _bookmarkGroupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const Center(
              child: Text(
                '아직 생성된 북마크가 없습니다.\n위에서 새 북마크를 만들어주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 4),
            itemCount: groups.length,
            separatorBuilder: (context, index) {
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              final group = groups[index];

              return ListTile(
                enabled: !_isSaving,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                leading: const Icon(Icons.bookmark_rounded),
                title: Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${group.verseCount}개 성구',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.add_rounded),
                onTap: () {
                  _saveToExistingGroup(group);
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return ColoredBox(
      color: widget.backgroundColor,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, bottomSafePadding + 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '북마크에 추가',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '${widget.selectedVerses.length}개 성구를 추가합니다.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCreateSection(),
              const SizedBox(height: 18),
              const Text(
                '기존 북마크에 추가',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildExistingGroupsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
