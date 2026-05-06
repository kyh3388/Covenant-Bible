import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class FontSizeSheet extends StatefulWidget {
  final Color backgroundColor;
  final double initialFontSize;
  final double minFontSize;
  final double maxFontSize;
  final ValueChanged<double> onFontSizeChanged;

  const FontSizeSheet({
    super.key,
    required this.backgroundColor,
    required this.initialFontSize,
    required this.minFontSize,
    required this.maxFontSize,
    required this.onFontSizeChanged,
  });

  @override
  State<FontSizeSheet> createState() => _FontSizeSheetState();
}

class _FontSizeSheetState extends State<FontSizeSheet> {
  late double _fontSize;

  @override
  void initState() {
    super.initState();

    _fontSize = widget.initialFontSize
        .clamp(widget.minFontSize, widget.maxFontSize)
        .toDouble();
  }

  void _decreaseFontSize() {
    if (_fontSize <= widget.minFontSize) {
      return;
    }

    final nextFontSize = (_fontSize - 1)
        .clamp(widget.minFontSize, widget.maxFontSize)
        .toDouble();

    setState(() {
      _fontSize = nextFontSize;
    });

    widget.onFontSizeChanged(nextFontSize);
  }

  void _increaseFontSize() {
    if (_fontSize >= widget.maxFontSize) {
      return;
    }

    final nextFontSize = (_fontSize + 1)
        .clamp(widget.minFontSize, widget.maxFontSize)
        .toDouble();

    setState(() {
      _fontSize = nextFontSize;
    });

    widget.onFontSizeChanged(nextFontSize);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return ColoredBox(
      color: widget.backgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 8, 22, bottomSafePadding + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  '태초에 하나님이 천지를 창조하시니라',
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 1.65,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _fontSize <= widget.minFontSize
                        ? null
                        : _decreaseFontSize,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${_fontSize.toInt()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _fontSize >= widget.maxFontSize
                        ? null
                        : _increaseFontSize,
                    icon: const Icon(Icons.add),
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
