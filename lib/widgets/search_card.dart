import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import '../data/models/hadith.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/methods.dart';

Widget buildResultSnippet({
  required String snippet,
  required List<String> searchWords,
  required bool isLandscape,
  required double screenWidth,
}) {
  String displaySnippet = snippet.replaceAll('O', '').replaceAll('X', '');
  return RichText(
    text: TextSpan(
      children: Methods.highlightWords(
        displaySnippet,
        searchWords,
        GoogleFonts.cairo(
          fontSize: isLandscape ? screenWidth * 0.018 : 15,
          color: Color(0xff513c2e),
        ),
        GoogleFonts.cairo(
          fontSize: isLandscape ? screenWidth * 0.018 : 15,
          color: AppTheme.redBlackColer,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    maxLines: 5,
    overflow: TextOverflow.ellipsis,
    textDirection: TextDirection.rtl,
  );
}

Widget buildResultTitle(Hadith hadith, bool isLandscape, double screenWidth) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: hadith.chapter_title,
            style: GoogleFonts.cairo(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
          TextSpan(
            text: ':',
            style: GoogleFonts.cairo(
              color: const Color.fromARGB(255, 12, 1, 1),
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
          TextSpan(
            text: hadith.section_title,
            style: GoogleFonts.cairo(
              color: Color(0xff513c2e),
              fontWeight: FontWeight.bold,
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
          TextSpan(
            text: ':',
            style: GoogleFonts.cairo(
              color: Color(0xff977c55),
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
          TextSpan(
            text: 'حديث ${hadith.number}',
            style: GoogleFonts.cairo(
              color: Color(0xff977848),
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
        ],
      ),
    );
  }