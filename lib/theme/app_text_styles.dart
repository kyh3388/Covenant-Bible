import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.topBarText,
    letterSpacing: -0.3,
  );

  static const TextStyle versionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.topBarText,
  );

  static TextStyle verseNumber(double fontSize) {
    return TextStyle(
      fontSize: fontSize - 2,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.5,
    );
  }

  static TextStyle verseText(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      height: 1.62,
      letterSpacing: -0.25,
      color: AppColors.textPrimary,
    );
  }

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static TextStyle noteText(double fontSize) {
    return TextStyle(
      fontSize: fontSize - 6,
      height: 1.45,
      color: AppColors.noteText,
    );
  }

  static const TextStyle bottomAction = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
