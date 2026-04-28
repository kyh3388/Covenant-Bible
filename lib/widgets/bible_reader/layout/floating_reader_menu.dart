import 'package:flutter/material.dart';

class FloatingReaderMenu extends StatelessWidget {
  final Color barColor;
  final Color iconColor;
  final VoidCallback onThemeColorPressed;
  final VoidCallback onFontSizePressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onBookmarkPressed;

  const FloatingReaderMenu({
    super.key,
    required this.barColor,
    required this.iconColor,
    required this.onThemeColorPressed,
    required this.onFontSizePressed,
    required this.onSearchPressed,
    required this.onBookmarkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FloatingReaderMenuIconButton(
              icon: Icons.palette_rounded,
              iconColor: iconColor,
              onPressed: onThemeColorPressed,
            ),
            const SizedBox(width: 4),
            _FloatingReaderMenuIconButton(
              icon: Icons.text_fields_rounded,
              iconColor: iconColor,
              onPressed: onFontSizePressed,
            ),
            const SizedBox(width: 4),
            _FloatingReaderMenuIconButton(
              icon: Icons.search_rounded,
              iconColor: iconColor,
              onPressed: onSearchPressed,
            ),
            const SizedBox(width: 4),
            _FloatingReaderMenuIconButton(
              icon: Icons.bookmarks_rounded,
              iconColor: iconColor,
              onPressed: onBookmarkPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingReaderMenuIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _FloatingReaderMenuIconButton({
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: SizedBox(
        width: 46,
        height: 42,
        child: Icon(icon, color: iconColor, size: 25),
      ),
    );
  }
}
