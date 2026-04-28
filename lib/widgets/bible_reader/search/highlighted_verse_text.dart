import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class HighlightedVerseText extends StatelessWidget {
  final String text;
  final String keyword;

  const HighlightedVerseText({
    super.key,
    required this.text,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = trimmedKeyword.toLowerCase();

    final spans = <TextSpan>[];
    int currentIndex = 0;

    while (true) {
      final matchIndex = lowerText.indexOf(lowerKeyword, currentIndex);

      if (matchIndex < 0) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
        break;
      }

      if (matchIndex > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, matchIndex),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

      final endIndex = matchIndex + trimmedKeyword.length;

      spans.add(
        TextSpan(
          text: text.substring(matchIndex, endIndex),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            backgroundColor: Colors.amber.withValues(alpha: 0.45),
          ),
        ),
      );

      currentIndex = endIndex;
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }
}
