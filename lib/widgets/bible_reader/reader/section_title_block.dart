import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SectionTitleBlock extends StatelessWidget {
  final List<String> sectionTitles;

  const SectionTitleBlock({super.key, required this.sectionTitles});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 7, bottom: 2),
      padding: const EdgeInsets.only(left: 2, right: 0, bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionTitles.map((title) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(top: 1, right: 6),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: Text(
                  '〔$title〕',
                  textAlign: TextAlign.left,
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
