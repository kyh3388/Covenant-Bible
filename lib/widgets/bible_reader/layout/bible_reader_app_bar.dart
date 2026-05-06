import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';

class BibleReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final String versionText;
  final Color barColor;
  final Color barSoftColor;
  final Color barTextColor;
  final VoidCallback onTitlePressed;
  final VoidCallback onVersionPressed;

  const BibleReaderAppBar({
    super.key,
    required this.titleText,
    required this.versionText,
    required this.barColor,
    required this.barSoftColor,
    required this.barTextColor,
    required this.onTitlePressed,
    required this.onVersionPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(55);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: barColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 10,
      title: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: barTextColor.withValues(alpha: 0.12),
                highlightColor: barTextColor.withValues(alpha: 0.06),
                onTap: onTitlePressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: barSoftColor,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 22,
                          color: barTextColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          titleText,
                          style: AppTextStyles.appTitle.copyWith(
                            color: barTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 수정: 우측 버전 표시를 선택 가능한 버튼으로 변경
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              splashColor: barTextColor.withValues(alpha: 0.12),
              highlightColor: barTextColor.withValues(alpha: 0.06),
              onTap: onVersionPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: barSoftColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  versionText,
                  style: AppTextStyles.versionLabel.copyWith(
                    color: barTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
