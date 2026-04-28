import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class BiblePickerHeader extends StatelessWidget {
  final String title;
  final bool canGoBack;
  final VoidCallback onBackPressed;

  const BiblePickerHeader({
    super.key,
    required this.title,
    required this.canGoBack,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack)
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
