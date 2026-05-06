import 'package:flutter/material.dart';

import '../../../services/reader_theme_service.dart';
import '../../../theme/app_colors.dart';
import 'body_background_mode_button.dart';
import 'reader_theme_option.dart';
import 'theme_color_button.dart';

class ReaderThemeSheet extends StatefulWidget {
  final String initialThemeId;
  final String initialBodyBackgroundMode;
  final ValueChanged<String> onThemeSelected;
  final ValueChanged<String> onBodyBackgroundModeSelected;

  const ReaderThemeSheet({
    super.key,
    required this.initialThemeId,
    required this.initialBodyBackgroundMode,
    required this.onThemeSelected,
    required this.onBodyBackgroundModeSelected,
  });

  @override
  State<ReaderThemeSheet> createState() => _ReaderThemeSheetState();
}

class _ReaderThemeSheetState extends State<ReaderThemeSheet> {
  late String _selectedThemeId;
  late String _bodyBackgroundMode;

  @override
  void initState() {
    super.initState();

    _selectedThemeId = widget.initialThemeId;
    _bodyBackgroundMode = widget.initialBodyBackgroundMode;
  }

  ReaderThemeOption get _selectedTheme {
    return ReaderThemeOption.findById(_selectedThemeId);
  }

  Color get _sheetBackgroundColor {
    if (_bodyBackgroundMode == ReaderThemeService.bodyBackgroundTinted) {
      return Color.lerp(Colors.white, _selectedTheme.color, 0.10)!;
    }

    return Colors.white;
  }

  void _selectTheme(String themeId) {
    setState(() {
      _selectedThemeId = themeId;
    });

    widget.onThemeSelected(themeId);
  }

  void _selectBodyBackgroundMode(String mode) {
    setState(() {
      _bodyBackgroundMode = mode;
    });

    widget.onBodyBackgroundModeSelected(mode);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: _sheetBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomSafePadding + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: ReaderThemeOption.options.map((option) {
                    final isSelected = option.id == _selectedThemeId;

                    return ThemeColorButton(
                      option: option,
                      isSelected: isSelected,
                      onTap: () {
                        _selectTheme(option.id);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.divider,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: BodyBackgroundModeButton(
                      label: '기본',
                      icon: Icons.format_color_reset_rounded,
                      isSelected:
                          _bodyBackgroundMode ==
                          ReaderThemeService.bodyBackgroundWhite,
                      onTap: () {
                        _selectBodyBackgroundMode(
                          ReaderThemeService.bodyBackgroundWhite,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BodyBackgroundModeButton(
                      label: '테마',
                      icon: Icons.opacity_rounded,
                      isSelected:
                          _bodyBackgroundMode ==
                          ReaderThemeService.bodyBackgroundTinted,
                      onTap: () {
                        _selectBodyBackgroundMode(
                          ReaderThemeService.bodyBackgroundTinted,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
