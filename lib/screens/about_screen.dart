import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import 'package:arabic_font/arabic_font.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double titleFontSize =
        isLandscape ? screenWidth * 0.035 : screenWidth * 0.09;

    return Scaffold(
      body: Stack(
        children: [
          TextApp.appBackgroundWidget,

          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.04,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'عن التطبيق',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize,
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
                    SizedBox(height: screenWidth * 0.05),

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
    );
  }
}

class InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const InfoSection({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fonstSizeTitle = screenWidth  > screenHeight ?  screenWidth * 0.03 :screenWidth * 0.07;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: const Color(0xfffcead0),
              fontSize:  fonstSizeTitle,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.3)),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.015),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(158, 158, 158, 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.015,
            ),
            child: Text(
              content,
              style: ArabicTextStyle(
                arabicFont: ArabicFont.avenirArabic,
                fontWeight: FontWeight.w900,
                color: Colors.brown.shade800,
                fontSize: screenWidth * 0.045,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
