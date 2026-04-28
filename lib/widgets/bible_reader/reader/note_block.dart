import 'package:flutter/material.dart';

import '../../../models/bible_note.dart';
import '../../../theme/app_colors.dart';

class NoteBlock extends StatelessWidget {
  final List<BibleNote> notes;
  final double fontSize;

  const NoteBlock({super.key, required this.notes, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final noteFontSize = (fontSize - 3).clamp(10.0, 19.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notes.map((note) {
          final marker = note.marker.trim();
          final noteText = note.noteText.trim();

          return Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (marker.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Text(
                      marker,
                      style: TextStyle(
                        fontSize: noteFontSize,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.noteText,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    noteText,
                    style: TextStyle(
                      fontSize: noteFontSize,
                      height: 1.25,
                      color: AppColors.noteText,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
