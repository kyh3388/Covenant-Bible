import 'package:flutter/material.dart';

class ReaderThemeOption {
  final String id;
  final String label;
  final Color color;
  final Color softColor;
  final Color foregroundColor;

  const ReaderThemeOption({
    required this.id,
    required this.label,
    required this.color,
    required this.softColor,
    required this.foregroundColor,
  });

  static const Color _darkText = Color(0xFF111111);
  static const Color _lightText = Color(0xFFFFFFFF);

  static const List<ReaderThemeOption> options = [
    ReaderThemeOption(
      id: 'emerald',
      label: '녹보석',
      color: Color(0xFF006B3C),
      softColor: Color(0xFF0A8F55),
      foregroundColor: _lightText,
    ),
    ReaderThemeOption(
      id: 'jasper',
      label: '벽옥',
      color: Color(0xFF5BBCEB),
      softColor: Color(0xFF84D0F2),
      foregroundColor: _darkText,
    ),
    ReaderThemeOption(
      id: 'sapphire',
      label: '남보석',
      color: Color(0xFF1F3A93),
      softColor: Color(0xFF3E5DB8),
      foregroundColor: _lightText,
    ),
    ReaderThemeOption(
      id: 'chalcedony',
      label: '옥수',
      color: Color(0xFF9BDCDE),
      softColor: Color(0xFFB8ECEE),
      foregroundColor: _darkText,
    ),
    ReaderThemeOption(
      id: 'sardonyx',
      label: '홍마노',
      color: Color(0xFFFF4500),
      softColor: Color(0xFFFF6A33),
      foregroundColor: _darkText,
    ),
    ReaderThemeOption(
      id: 'sardius',
      label: '홍보석',
      color: Color(0xFFD81B60),
      softColor: Color(0xFFE83E7C),
      foregroundColor: _lightText,
    ),
    ReaderThemeOption(
      id: 'chrysolite',
      label: '황옥',
      color: Color(0xFFF2B705),
      softColor: Color(0xFFFFCC33),
      foregroundColor: _darkText,
    ),
    ReaderThemeOption(
      id: 'beryl',
      label: '녹옥',
      color: Color(0xFF45E8BC),
      softColor: Color(0xFF70F0D0),
      foregroundColor: _darkText,
    ),
    ReaderThemeOption(
      id: 'topaz',
      label: '담황옥',
      color: Color(0xFFEB8717),
      softColor: Color(0xFFF5A64A),
      foregroundColor: _darkText,
    ),
    ReaderThemeOption(
      id: 'chrysoprase',
      label: '비취옥',
      color: Color(0xFF4BF010),
      softColor: Color(0xFF73F548),
      foregroundColor: _darkText,
    ),
    ReaderThemeOption(
      id: 'jacinth',
      label: '청옥',
      color: Color(0xFF0033A0),
      softColor: Color(0xFF1D4ED8),
      foregroundColor: _lightText,
    ),
    ReaderThemeOption(
      id: 'amethyst',
      label: '자정',
      color: Color(0xFFD41279),
      softColor: Color(0xFFE83E98),
      foregroundColor: _lightText,
    ),
    ReaderThemeOption(
      id: 'black',
      label: '검정',
      color: Color(0xFF202124),
      softColor: Color(0xFF303134),
      foregroundColor: _lightText,
    ),
    ReaderThemeOption(
      id: 'white',
      label: '하양',
      color: Color(0xFFF8F9FA),
      softColor: Color(0xFFE9ECEF),
      foregroundColor: _darkText,
    ),
    ReaderThemeOption(
      id: 'gray',
      label: '회색',
      color: Color(0xFF6B7280),
      softColor: Color(0xFF9CA3AF),
      foregroundColor: _darkText,
    ),
  ];

  static ReaderThemeOption findById(String id) {
    return options.firstWhere(
      (option) => option.id == id,
      orElse: () => options[12],
    );
  }
}
