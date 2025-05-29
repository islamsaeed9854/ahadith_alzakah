import 'package:flutter/material.dart';
import '../data/models/hadith.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildResultTitle(Hadith hadith, bool isLandscape, double screenWidth) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: hadith.chapter_title ?? 'باب بدون عنوان',
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
            text: hadith.section_title ?? 'قسم بدون عنوان',
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