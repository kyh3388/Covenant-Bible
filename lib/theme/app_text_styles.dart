import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get appTitle => GoogleFonts.notoSansKr(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.topBarText,
    letterSpacing: -0.3,
  );

  static TextStyle get versionLabel => GoogleFonts.notoSansKr(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.topBarText,
  );

  static TextStyle verseNumber(double fontSize) {
    return GoogleFonts.notoSansKr(
      // 수정: 성구번호와 본문 폰트 크기는 동일
      fontSize: fontSize,

      // 수정: 성구번호는 굵기만 더 강하게
      fontWeight: FontWeight.w500,

      color: AppColors.textPrimary,
      height: 1.45,
    );
  }

  static TextStyle verseText(double fontSize) {
    return GoogleFonts.notoSansKr(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get sectionTitle => GoogleFonts.notoSansKr(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static TextStyle noteText(double fontSize) {
    return GoogleFonts.notoSansKr(
      fontSize: fontSize - 6,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppColors.noteText,
    );
  }

  static TextStyle get bottomAction =>
      GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.w600);
}
