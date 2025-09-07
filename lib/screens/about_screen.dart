import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import 'package:arabic_font/arabic_font.dart';

// ======================= Responsive Breakpoints =======================
const double kMediumScreenBreakpoint = 600.0;
const double kLargeScreenBreakpoint = 1200.0;
const double kExtraLargeScreenBreakpoint = 1800.0;

// ======================= Responsive Helper Functions =======================

/// Determines the maximum width for the main content area based on screen size.
/// On large screens, it creates a centered view (70% content, 15% margins).
double _getMaxContentWidth(double screenWidth) {
  if (screenWidth > kLargeScreenBreakpoint) {
    return screenWidth * 0.70; // 70% for large and extra-large screens
  }
  if (screenWidth > kMediumScreenBreakpoint) {
    return 850; // A fixed max-width for medium screens looks better.
  }
  return screenWidth; // Full width for small screens
}

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
          SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  children: [
                    // Header with centered title and left-aligned button
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < kMediumScreenBreakpoint ? 20 : 0,
                        vertical: 16,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Centered Title
                          Text(
                            'عن التطبيق',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: _getResponsiveFontSize(screenWidth, small: 34.0, medium: 38.0, large: 42.0, extraLarge: 46.0),
                              color: const Color(0xfffcead0),
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                          // Back Button aligned to the left of the content area
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextApp.backButton(ref),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < kMediumScreenBreakpoint ? 20 : 0,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                  ],
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

class InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const InfoSection({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: const Color(0xfffcead0),
              fontSize: _getResponsiveFontSize(screenWidth, small: 26.0, medium: 28.0, large: 30.0, extraLarge: 32.0),
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
            padding: const EdgeInsets.all(16.0),
            child: Text(
              content,
              style: ArabicTextStyle(
                arabicFont: ArabicFont.avenirArabic,
                fontWeight: FontWeight.w900,
                color: Colors.brown.shade800,
                fontSize: _getResponsiveFontSize(screenWidth, small: 18.0, medium: 19.0, large: 20.0, extraLarge: 21.0),
                height: 1.7, // Improved line height for readability
              ),
            ),
          ),
        ],
      ),
    );
  }
}

