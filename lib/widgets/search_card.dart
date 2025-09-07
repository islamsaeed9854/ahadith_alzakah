import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import '../data/models/hadith.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/methods.dart';

// ======================= Responsive Breakpoints =======================
const double kMediumScreenBreakpoint = 600.0;
const double kLargeScreenBreakpoint = 1200.0;
const double kExtraLargeScreenBreakpoint = 1800.0;

// ======================= Responsive Helper Functions =======================

/// A generic helper function to determine font sizes based on screen size.
double _getResponsiveFontSize(double screenWidth, {
  required double small,
  required double medium,
  required double large,
  double? extraLarge,
}) {
  if (screenWidth > kExtraLargeScreenBreakpoint) return extraLarge ?? large * 1.1;
  if (screenWidth > kLargeScreenBreakpoint) return large;
  if (screenWidth > kMediumScreenBreakpoint) return medium;
  return small;
}


Widget buildResultSnippet({
  required String snippet,
  required List<String> searchWords,
  required double screenWidth,
}) {
  String displaySnippet = snippet.replaceAll('O', '').replaceAll('X', '');
  final double fontSize = _getResponsiveFontSize(screenWidth, small: 15.0, medium: 16.0, large: 17.0, extraLarge: 18.0);

  return RichText(
    text: TextSpan(
      children: Methods.highlightWords(
        displaySnippet,
        searchWords,
        GoogleFonts.cairo(
          fontSize: fontSize,
          color: const Color(0xff513c2e),
          height: 1.6, // Improve line spacing
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

Widget buildResultTitle(Hadith hadith, double screenWidth) {
  final double fontSize = _getResponsiveFontSize(screenWidth, small: 16.0, medium: 17.0, large: 18.0, extraLarge: 19.0);

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
