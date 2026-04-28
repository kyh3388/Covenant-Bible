import 'package:flutter/material.dart';

import '../../../database/bible_database.dart';
import '../../../models/bible_book.dart';
import '../../../models/bible_bookmark_group.dart';
import '../../../models/bible_bookmark_verse.dart';
import '../../../theme/app_colors.dart';
import '../picker/bible_picker_result.dart';
import '../picker/bible_picker_sheet.dart';

class BookmarkListSheet extends StatefulWidget {
  final Color backgroundColor;
  final BibleBook currentBook;
  final int currentChapter;

  const BookmarkListSheet({
    super.key,
    required this.backgroundColor,
    required this.currentBook,
    required this.currentChapter,
  });

  @override
  State<BookmarkListSheet> createState() => _BookmarkListSheetState();
}

class _BookmarkListSheetState extends State<BookmarkListSheet> {
  late Future<List<BibleBookmarkGroup>> _bookmarkGroupsFuture;

  BibleBookmarkGroup? _selectedGroup;
  Future<List<BibleBookmarkVerse>>? _bookmarkVersesFuture;

  final TextEditingController _createController = TextEditingController();
  final FocusNode _createFocusNode = FocusNode();

  final TextEditingController _renameController = TextEditingController();
  final FocusNode _renameFocusNode = FocusNode();

  BibleBookmarkGroup? _editingGroup;

  bool _isCreatePanelOpen = false;
  bool _isCreatingGroup = false;
  bool _isDeleting = false;
  bool _isUpdatingGroup = false;
  bool _isAddingVerse = false;

  @override
  void initState() {
    super.initState();
    _bookmarkGroupsFuture = BibleDatabase.instance.getBookmarkGroups();
  }

  @override
  void dispose() {
    _createController.dispose();
    _createFocusNode.dispose();
    _renameController.dispose();
    _renameFocusNode.dispose();
    super.dispose();
  }

  void _refreshGroups() {
    setState(() {
      _bookmarkGroupsFuture = BibleDatabase.instance.getBookmarkGroups();
    });
  }

  Future<void> _refreshSelectedGroupAndVerses(int bookmarkGroupId) async {
    final updatedGroup = await BibleDatabase.instance.getBookmarkGroupById(
      bookmarkGroupId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedGroup = updatedGroup;
      _bookmarkGroupsFuture = BibleDatabase.instance.getBookmarkGroups();

      if (updatedGroup != null) {
        _bookmarkVersesFuture = BibleDatabase.instance.getBookmarkVerses(
          bookmarkGroupId: updatedGroup.bookmarkGroupId,
        );
      } else {
        _bookmarkVersesFuture = null;
      }
    });
  }

  void _openGroup(BibleBookmarkGroup group) {
    _cancelCreateGroup();
    _cancelRenameGroup();

    setState(() {
      _selectedGroup = group;
      _bookmarkVersesFuture = BibleDatabase.instance.getBookmarkVerses(
        bookmarkGroupId: group.bookmarkGroupId,
      );
    });
  }

  void _backToGroups() {
    _cancelCreateGroup();
    _cancelRenameGroup();

    setState(() {
      _selectedGroup = null;
      _bookmarkVersesFuture = null;
    });

    _refreshGroups();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _openBookmarkVerse(BibleBookmarkVerse bookmarkVerse) async {
    final BibleBook? book = await BibleDatabase.instance.getBookById(
      bookmarkVerse.bookId,
    );

    if (!mounted) {
      return;
    }

    if (book == null) {
      _showMessage('성경 책 정보를 찾을 수 없습니다.');
      return;
    }

    Navigator.pop(
      context,
      BiblePickerResult(
        book: book,
        chapter: bookmarkVerse.chapter,
        verse: bookmarkVerse.verse,
      ),
    );
  }

  void _startCreateGroup() {
    _cancelRenameGroup();

    setState(() {
      _isCreatePanelOpen = true;
      _createController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _createFocusNode.requestFocus();
      }
    });
  }

  void _cancelCreateGroup() {
    if (!_isCreatePanelOpen) {
      return;
    }

    setState(() {
      _isCreatePanelOpen = false;
      _createController.clear();
      _createFocusNode.unfocus();
    });
  }

  Future<void> _submitCreateGroup() async {
    final name = _createController.text.trim();

    if (name.isEmpty) {
      _showMessage('북마크 이름을 입력해주세요.');
      return;
    }

    if (_isCreatingGroup) {
      return;
    }

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final bookmarkGroupId = await BibleDatabase.instance.createBookmarkGroup(
        name,
      );

      final createdGroup = await BibleDatabase.instance.getBookmarkGroupById(
        bookmarkGroupId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatePanelOpen = false;
        _createController.clear();
        _createFocusNode.unfocus();

        _bookmarkGroupsFuture = BibleDatabase.instance.getBookmarkGroups();

        if (createdGroup != null) {
          _selectedGroup = createdGroup;
          _bookmarkVersesFuture = BibleDatabase.instance.getBookmarkVerses(
            bookmarkGroupId: createdGroup.bookmarkGroupId,
          );
        }
      });

      _showMessage('새 북마크를 만들었습니다.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('북마크 생성 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  Future<void> _deleteBookmarkVerse(BibleBookmarkVerse bookmarkVerse) async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await BibleDatabase.instance.removeBookmarkVerse(
        bookmarkVerseId: bookmarkVerse.bookmarkVerseId,
      );

      if (!mounted) {
        return;
      }

      await _refreshSelectedGroupAndVerses(bookmarkVerse.bookmarkGroupId);

      _showMessage('북마크에서 성구를 삭제했습니다.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('삭제 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _startRenameGroup(BibleBookmarkGroup group) {
    _cancelCreateGroup();

    setState(() {
      _editingGroup = group;
      _renameController.text = group.name;
      _renameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: group.name.length,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _renameFocusNode.requestFocus();
      }
    });
  }

  void _cancelRenameGroup() {
    if (_editingGroup == null) {
      return;
    }

    setState(() {
      _editingGroup = null;
      _renameController.clear();
      _renameFocusNode.unfocus();
    });
  }

  Future<void> _submitRenameGroup() async {
    final editingGroup = _editingGroup;

    if (editingGroup == null) {
      return;
    }

    final newName = _renameController.text.trim();

    if (newName.isEmpty) {
      _showMessage('북마크 이름을 입력해주세요.');
      return;
    }

    if (newName == editingGroup.name) {
      _cancelRenameGroup();
      return;
    }

    await _renameGroup(group: editingGroup, newName: newName);
  }

  Future<void> _renameGroup({
    required BibleBookmarkGroup group,
    required String newName,
  }) async {
    if (_isUpdatingGroup) {
      return;
    }

    setState(() {
      _isUpdatingGroup = true;
    });

    try {
      await BibleDatabase.instance.updateBookmarkGroupName(
        bookmarkGroupId: group.bookmarkGroupId,
        name: newName,
      );

      if (!mounted) {
        return;
      }

      final updatedGroup = BibleBookmarkGroup(
        bookmarkGroupId: group.bookmarkGroupId,
        name: newName,
        createdAt: group.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        verseCount: group.verseCount,
      );

      setState(() {
        if (_selectedGroup?.bookmarkGroupId == group.bookmarkGroupId) {
          _selectedGroup = updatedGroup;
        }

        _editingGroup = null;
        _renameController.clear();
        _renameFocusNode.unfocus();
        _bookmarkGroupsFuture = BibleDatabase.instance.getBookmarkGroups();
      });

      _showMessage('북마크 이름을 수정했습니다.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('북마크 이름 수정 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingGroup = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteGroup(BibleBookmarkGroup group) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('북마크 삭제'),
          content: Text('"${group.name}" 북마크를 삭제할까요?\n안에 저장된 성구도 모두 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    await _deleteGroup(group);
  }

  Future<void> _deleteGroup(BibleBookmarkGroup group) async {
    if (_isUpdatingGroup) {
      return;
    }

    setState(() {
      _isUpdatingGroup = true;
    });

    try {
      await BibleDatabase.instance.deleteBookmarkGroup(group.bookmarkGroupId);

      if (!mounted) {
        return;
      }

      setState(() {
        if (_selectedGroup?.bookmarkGroupId == group.bookmarkGroupId) {
          _selectedGroup = null;
          _bookmarkVersesFuture = null;
        }

        if (_editingGroup?.bookmarkGroupId == group.bookmarkGroupId) {
          _editingGroup = null;
          _renameController.clear();
          _renameFocusNode.unfocus();
        }

        _bookmarkGroupsFuture = BibleDatabase.instance.getBookmarkGroups();
      });

      _showMessage('북마크를 삭제했습니다.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('북마크 삭제 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingGroup = false;
        });
      }
    }
  }

  Future<void> _handleGroupMenuAction({
    required BibleBookmarkGroup group,
    required _BookmarkGroupMenuAction action,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) {
      return;
    }

    if (action == _BookmarkGroupMenuAction.rename) {
      _startRenameGroup(group);
      return;
    }

    if (action == _BookmarkGroupMenuAction.delete) {
      await _confirmDeleteGroup(group);
    }
  }

  Future<void> _openVersePickerAndAddToSelectedGroup() async {
    final selectedGroup = _selectedGroup;

    if (selectedGroup == null) {
      return;
    }

    if (_isAddingVerse) {
      return;
    }

    final result = await showModalBottomSheet<BiblePickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: widget.backgroundColor,
      showDragHandle: true,
      builder: (context) {
        return BiblePickerSheet(
          currentBook: widget.currentBook,
          currentChapter: widget.currentChapter,
          backgroundColor: widget.backgroundColor,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _isAddingVerse = true;
    });

    try {
      await BibleDatabase.instance.addBookmarkVersesToGroup(
        bookmarkGroupId: selectedGroup.bookmarkGroupId,
        bookId: result.book.bookId,
        chapter: result.chapter,
        verses: {result.verse},
      );

      if (!mounted) {
        return;
      }

      await _refreshSelectedGroupAndVerses(selectedGroup.bookmarkGroupId);

      _showMessage(
        '${result.book.nameKo} ${result.chapter}:${result.verse}을 추가했습니다.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('성구 추가 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingVerse = false;
        });
      }
    }
  }

  Widget _buildHeader() {
    final selectedGroup = _selectedGroup;

    return Row(
      children: [
        if (selectedGroup != null)
          IconButton(
            onPressed: _backToGroups,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Text(
            selectedGroup == null ? '북마크' : selectedGroup.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (selectedGroup != null) ...[
          IconButton(
            onPressed: _isAddingVerse
                ? null
                : _openVersePickerAndAddToSelectedGroup,
            icon: const Icon(Icons.add_rounded),
            tooltip: '성구 추가',
          ),
          PopupMenuButton<_BookmarkGroupMenuAction>(
            enabled: !_isUpdatingGroup,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              _handleGroupMenuAction(group: selectedGroup, action: action);
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<_BookmarkGroupMenuAction>(
                  value: _BookmarkGroupMenuAction.rename,
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('이름 수정'),
                    ],
                  ),
                ),
                PopupMenuItem<_BookmarkGroupMenuAction>(
                  value: _BookmarkGroupMenuAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('북마크 삭제'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ] else
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }

  Widget _buildCreateGroupArea() {
    if (_selectedGroup != null) {
      return const SizedBox.shrink();
    }

    if (!_isCreatePanelOpen) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isCreatingGroup ? null : _startCreateGroup,
            icon: const Icon(Icons.add_rounded),
            label: const Text('새 북마크 만들기'),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 북마크 만들기',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _createController,
                  focusNode: _createFocusNode,
                  enabled: !_isCreatingGroup,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _submitCreateGroup();
                  },
                  decoration: InputDecoration(
                    hintText: '예: 믿음, 기도, 회개',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.95),
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
              TextButton(
                onPressed: _isCreatingGroup ? null : _cancelCreateGroup,
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: _isCreatingGroup ? null : _submitCreateGroup,
                child: const Text('저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRenamePanel() {
    final editingGroup = _editingGroup;

    if (editingGroup == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '북마크 이름 수정',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _renameController,
                  focusNode: _renameFocusNode,
                  enabled: !_isUpdatingGroup,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _submitRenameGroup();
                  },
                  decoration: InputDecoration(
                    hintText: '북마크 이름',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.95),
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
              TextButton(
                onPressed: _isUpdatingGroup ? null : _cancelRenameGroup,
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: _isUpdatingGroup ? null : _submitRenameGroup,
                child: const Text('저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return FutureBuilder<List<BibleBookmarkGroup>>(
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
              '아직 저장된 북마크가 없습니다.\n위에서 새 북마크를 만들 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          itemCount: groups.length,
          separatorBuilder: (context, index) {
            return const Divider(height: 1);
          },
          itemBuilder: (context, index) {
            final group = groups[index];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
              title: Text(
                group.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${group.verseCount}개 성구',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<_BookmarkGroupMenuAction>(
                    enabled: !_isUpdatingGroup,
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) {
                      _handleGroupMenuAction(group: group, action: action);
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem<_BookmarkGroupMenuAction>(
                          value: _BookmarkGroupMenuAction.rename,
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('이름 수정'),
                            ],
                          ),
                        ),
                        PopupMenuItem<_BookmarkGroupMenuAction>(
                          value: _BookmarkGroupMenuAction.delete,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('북마크 삭제'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () {
                _openGroup(group);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildVerseList() {
    final bookmarkVersesFuture = _bookmarkVersesFuture;

    if (bookmarkVersesFuture == null) {
      return const Center(child: Text('북마크 성구를 불러오지 못했습니다.'));
    }

    return FutureBuilder<List<BibleBookmarkVerse>>(
      future: bookmarkVersesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }

        final bookmarkVerses = snapshot.data ?? [];

        if (bookmarkVerses.isEmpty) {
          return const Center(
            child: Text(
              '이 북마크에 저장된 성구가 없습니다.\n상단 + 버튼으로 성구를 추가할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          itemCount: bookmarkVerses.length,
          separatorBuilder: (context, index) {
            return const Divider(height: 1);
          },
          itemBuilder: (context, index) {
            final bookmarkVerse = bookmarkVerses[index];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _openBookmarkVerse(bookmarkVerse);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookmarkVerse.referenceText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              bookmarkVerse.verseText,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isDeleting
                            ? null
                            : () {
                                _deleteBookmarkVerse(bookmarkVerse);
                              },
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: '삭제',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return ColoredBox(
      color: widget.backgroundColor,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, bottomSafePadding + 18),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildCreateGroupArea(),
              _buildRenamePanel(),
              Expanded(
                child: _selectedGroup == null
                    ? _buildGroupList()
                    : _buildVerseList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BookmarkGroupMenuAction { rename, delete }
