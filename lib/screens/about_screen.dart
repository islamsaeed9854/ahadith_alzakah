import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import 'package:arabic_font/arabic_font.dart';

// ======================= Responsive Helper Functions =======================

// Determines the maximum width for the content on large screens
double _getMaxContentWidth(double screenWidth) {
  if (screenWidth > 900) return 850; // For large desktop screens
  return screenWidth; // For smaller screens
}

// Determines the font size for the main title "عن التطبيق"
double _getMainTitleFontSize(double screenWidth) {
  if (screenWidth > 1200) return 42.0;
  if (screenWidth > 600) return 38.0;
  return 34.0;
}
// ========================================================================

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = _getMaxContentWidth(screenWidth);

    return Scaffold(
      body: Stack(
        children: [
          TextApp.appBackgroundWidget,
          Center(
            child: SizedBox(
              width: contentWidth,
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      // Apply horizontal padding only on smaller screens
                      horizontal: screenWidth >= 900 ? 0 : 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'عن التطبيق',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _getMainTitleFontSize(screenWidth),
                                  color: const Color(0xfffcead0),
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextApp.backButton(ref),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // The 'const' keyword has been removed from here to fix the error
                        InfoSection(
                          title: 'تعريف الموسوعة',
                          content: TextApp.encyclopediaDefinition,
                        ),
                        InfoSection(
                          title: 'منهج التخريج',
                          content: TextApp.Ta58reegText,
                        ),
                        InfoSection(
                          title: 'منهج الدراسة',
                          content: TextApp.studyMethodology,
                        ),
                        InfoSection(
                          title: 'تواصل معنا',
                          content: TextApp.contactInfo,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= Info Section Widget =======================

// Determines the font size for the section title (e.g., "تعريف الموسوعة")
double _getSectionTitleFontSize(double screenWidth) {
  if (screenWidth > 1200) return 30.0;
  if (screenWidth > 600) return 28.0;
  return 26.0;
}

// Determines the font size for the content inside the card
double _getSectionContentFontSize(double screenWidth) {
  if (screenWidth > 1200) return 20.0;
  if (screenWidth > 600) return 19.0;
  return 18.0;
}
// ========================================================================

class InfoSection extends StatelessWidget {
  final String title;
  final String content;

  // Constructor is not const anymore
  const InfoSection({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      // Using a fixed bottom margin for consistent spacing
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: const Color(0xfffcead0),
              fontSize: _getSectionTitleFontSize(screenWidth),
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.3)),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(158, 158, 158, 0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            // Using fixed padding for a clean look
            padding: const EdgeInsets.all(16.0),
            child: Text(
              content,
              style: ArabicTextStyle(
                arabicFont: ArabicFont.avenirArabic,
                fontWeight: FontWeight.w900,
                color: Colors.brown.shade800,
                fontSize: _getSectionContentFontSize(screenWidth),
                height: 1.7, // Improved line height for readability
              ),
            ),
          ),
        ],
      ),
    );
  }
}