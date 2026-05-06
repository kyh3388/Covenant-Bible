import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'reader_theme_option.dart';

class ThemeColorButton extends StatelessWidget {
  final ReaderThemeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeColorButton({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: option.color,
                border: Border.all(
                  color: isSelected ? AppColors.textPrimary : AppColors.divider,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: option.foregroundColor,
                      size: 24,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
