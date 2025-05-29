import 'package:ahadith_alzakah/screens/chapters_screen.dart';
import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';

Widget buildBabCard(
  BuildContext context,
  WidgetRef ref,
  String title,
  String text,
  bool isLandscape,
  int chapterNumber,
) {
  // Get the screen width and height for responsive sizing
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  // Calculate font sizes based on screen width with more balanced ranges
  final baseFontSize = (screenWidth * 0.04).clamp(14.0, 22.0); // More conservative range
  final subFontSize = (screenWidth * 0.035).clamp(12.0, 18.0); // Adjusted for readability

  // Adjust padding based on screen size
  final padding = screenWidth * 0.015; // Reduced to 1.5% for better fit

  return Directionality(
    textDirection: TextDirection.rtl,
    child: GestureDetector(
      onTap: () {
        // Update the provider to navigate to Chapters
        // Screen
        
        ref.read(innerBooksScreenProvider.notifier).state = ChaptersScreen(
          chapterNumber: chapterNumber,
        );
        debugPrint('Navigate to ChaptersScreen with chapter: $chapterNumber');
      },
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color.fromRGBO(255, 255, 255, 0.8),
                border: Border.all(color: const Color(0xffe6a345), width: 3),
              ),
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allow up to 2 lines for long titles
                    overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                    style: ArabicTextStyle(
                      arabicFont: ArabicFont.cairo,
                      fontSize: baseFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffe6a345),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01), // 1% of screen height
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 3, // Allow up to 3 lines for longer text
                    overflow: TextOverflow.ellipsis, // Handle overflow
                    style: ArabicTextStyle(
                      arabicFont: ArabicFont.reemKufi,
                      fontSize: subFontSize,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}