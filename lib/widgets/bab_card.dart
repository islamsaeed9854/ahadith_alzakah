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
  {required double baseFontSize} // Add baseFontSize as a required parameter
) {
  // Calculate subFontSize based on baseFontSize with clamping
  final subFontSize = (baseFontSize * 0.9).clamp(2.0, 18.0); // Adjusted for readability

  return Directionality(
    textDirection: TextDirection.rtl,
    child: GestureDetector(
      onTap: () {
        // Reset expanded section when opening a new chapter
        ref.read(expandedSectionProvider.notifier).state = null;
        // Update the provider to navigate to ChaptersScreen
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
   
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 5,
                    child: Text(
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
                  ),
                  SizedBox(height: baseFontSize * 0.2), // Dynamic spacing based on font size
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 3, // Allow up to 3 lines for longer text
                      overflow: TextOverflow.ellipsis, // Handle overflow
                      style: ArabicTextStyle(
                        arabicFont: ArabicFont.avenirArabic,
                        fontWeight: FontWeight.w900,
                        fontSize: subFontSize,
                        color: Colors.black87,
                      ),
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