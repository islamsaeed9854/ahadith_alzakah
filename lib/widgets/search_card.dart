import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import '../data/models/hadith.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/methods.dart';

// دالة مساعدة لتحديد حجم خط مقتطف الحديث
double _getSnippetFontSize(double screenWidth) {
  if (screenWidth > 1200) return 17.0; // Large
  if (screenWidth > 600) return 16.0;  // Medium
  return 15.0; // Small
}

// دالة مساعدة لتحديد حجم خط عنوان الحديث
double _getTitleFontSize(double screenWidth) {
  if (screenWidth > 1200) return 18.0; // Large
  if (screenWidth > 600) return 17.0;  // Medium
  return 16.0; // Small
}


Widget buildResultSnippet({
  required String snippet,
  required List<String> searchWords,
  required double screenWidth, // تم إزالة isLandscape
}) {
  String displaySnippet = snippet.replaceAll('O', '').replaceAll('X', '');
  final double fontSize = _getSnippetFontSize(screenWidth);

  return RichText(
    text: TextSpan(
      children: Methods.highlightWords(
        displaySnippet,
        searchWords,
        GoogleFonts.cairo(
          fontSize: fontSize,
          color: const Color(0xff513c2e),
          height: 1.6, // تحسين المسافة بين السطور
        ),
        GoogleFonts.cairo(
          fontSize: fontSize,
          color: AppTheme.redBlackColer,
          fontWeight: FontWeight.bold,
          height: 1.6,
        ),
      ),
    ),
    maxLines: 5,
    overflow: TextOverflow.ellipsis,
    textDirection: TextDirection.rtl,
  );
}

Widget buildResultTitle(Hadith hadith, double screenWidth) { // تم إزالة isLandscape
  final double fontSize = _getTitleFontSize(screenWidth);

  return RichText(
    textDirection: TextDirection.rtl,
    text: TextSpan(
      children: [
        TextSpan(
          text: '${hadith.chapter_title}: ',
          style: GoogleFonts.cairo(
            color: const Color(0xffc59441),
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        TextSpan(
          text: '${hadith.section_title}: ',
          style: GoogleFonts.cairo(
            color: const Color(0xff513c2e),
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        TextSpan(
          text: 'حديث ${hadith.number}',
          style: GoogleFonts.cairo(
            color: const Color(0xff977848),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}