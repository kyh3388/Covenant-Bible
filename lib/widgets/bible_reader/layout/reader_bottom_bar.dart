import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class ReaderBottomBar extends StatelessWidget {
  final bool canGoPrevious;
  final bool canGoNext;
  final Color barColor;
  final Color barTextColor;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final VoidCallback onMenuPressed;

  const ReaderBottomBar({
    super.key,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.barColor,
    required this.barTextColor,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = barTextColor.withValues(alpha: 0.35);

    return SafeArea(
      top: false,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: barColor,
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            IconButton(
              onPressed: canGoPrevious ? onPreviousPressed : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                Icons.chevron_left_rounded,
                size: 35,
                color: canGoPrevious ? barTextColor : disabledColor,
              ),
            ),
            IconButton(
              onPressed: canGoNext ? onNextPressed : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                Icons.chevron_right_rounded,
                size: 35,
                color: canGoNext ? barTextColor : disabledColor,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onMenuPressed,
              icon: Icon(Icons.menu_rounded, size: 32, color: barTextColor),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
