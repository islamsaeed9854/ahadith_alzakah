import 'package:ahadith_alzakah/screens/chapters_screen.dart';
import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';

class BabCard extends ConsumerWidget {
  final String title;
  final String text;
  final int chapterNumber;

  const BabCard({
    super.key,
    required this.title,
    required this.text,
    required this.chapterNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      // ### START RESPONSIVE CARD LAYOUT LOGIC ###
      
      final double cardWidth = constraints.maxWidth;
      final double screenWidth = MediaQuery.of(context).size.width;
      
      // Determine screen size category
      final ScreenSize size;
      if (screenWidth >= 1800) {
        size = ScreenSize.extraLarge;
      } else if (screenWidth >= 1200) {
        size = ScreenSize.large;
      } else if (screenWidth >= 600) {
        size = ScreenSize.medium;
      } else {
        size = ScreenSize.small;
      }

      // Responsive font sizes based on card size and screen category
      final double titleFontSize = switch (size) {
        ScreenSize.extraLarge => (cardWidth * 0.12).clamp(28.0, 42.0),
        ScreenSize.large => (cardWidth * 0.13).clamp(24.0, 36.0),
        ScreenSize.medium => (cardWidth * 0.14).clamp(20.0, 30.0),
        ScreenSize.small => (cardWidth * 0.15).clamp(14.0, 22.0),
      };

      final double subTitleFontSize = switch (size) {
        ScreenSize.extraLarge => (cardWidth * 0.09).clamp(22.0, 34.0),
        ScreenSize.large => (cardWidth * 0.07).clamp(20.0, 30.0),
        ScreenSize.medium => (cardWidth * 0.11).clamp(14.0, 24.0),
        ScreenSize.small => (cardWidth * 0.12).clamp(12.0, 18.0),
      };

      final double cardPadding = switch (size) {
        ScreenSize.extraLarge => 24.0,
        ScreenSize.large => 20.0,
        ScreenSize.medium => 16.0,
        ScreenSize.small => 12.0,
      };

      final double borderRadius = switch (size) {
        ScreenSize.extraLarge => 24,
        ScreenSize.large => 20,
        ScreenSize.medium => 18,
        ScreenSize.small => 12,
      };

      final double borderWidth = switch (size) {
        ScreenSize.extraLarge => 4,
        ScreenSize.large => 3.5,
        ScreenSize.medium => 3,
        ScreenSize.small => 2,
      };

      final double elevation = switch (size) {
        ScreenSize.extraLarge => 8,
        ScreenSize.large => 6,
        ScreenSize.medium => 5,
        ScreenSize.small => 3,
      };

      // ### END RESPONSIVE CARD LAYOUT LOGIC ###

      return Directionality(
        textDirection: TextDirection.rtl,
        child: GestureDetector(
          onTap: () {
            ref.read(expandedSectionProvider.notifier).state = null;
            ref.read(innerBooksScreenProvider.notifier).state = ChaptersScreen(
              chapterNumber: chapterNumber,
            );
            debugPrint('Navigate to ChaptersScreen with chapter: $chapterNumber');
          },
          child: Material(
            elevation: elevation,
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: const Color.fromRGBO(255, 255, 255, 0.8),
                border: Border.all(
                  color: const Color(0xffe6a345), 
                  width: borderWidth,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title (Wrapped in Expanded and FittedBox)
                  Expanded(
                    flex: 2, // Give title a bit more space
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: ArabicTextStyle(
                          arabicFont: ArabicFont.cairo,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xffe6a345),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: titleFontSize * 0.2),
                  // Chapter Content (Wrapped in Expanded and FittedBox)
                  Expanded(
                    flex: 3, // Give content more space
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: ArabicTextStyle(
                          arabicFont: ArabicFont.avenirArabic,
                          fontWeight: FontWeight.w900,
                          fontSize: subTitleFontSize,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// Screen size enum (should be shared across the app)
enum ScreenSize {
  small,    // Less than 600px
  medium,   // 600px - 1200px  
  large,    // 1200px - 1800px
  extraLarge, // More than 1800px
}