import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBrown,
        brightness: Brightness.light,
        primary: AppColors.primaryBrown,
        surface: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.topBar,
        foregroundColor: AppColors.topBarText,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );

    return baseTheme.copyWith(
      // 수정: 앱 전체 기본 글꼴을 Noto Sans KR로 통일
      textTheme: GoogleFonts.notoSansKrTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.notoSansKrTextTheme(
        baseTheme.primaryTextTheme,
      ),
    );
  }
}
