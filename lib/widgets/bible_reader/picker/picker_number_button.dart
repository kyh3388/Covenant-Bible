import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class PickerNumberButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PickerNumberButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryBrown : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        splashColor: AppColors.primaryBrown.withValues(alpha: 0.22),
        highlightColor: AppColors.primaryBrown.withValues(alpha: 0.12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
