import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/navigation_provider.dart';
import '../widgets/bab_card.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import '../core/utils.dart';
import '../core/methods.dart';
import '../core/theme.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadithState = ref.watch(DataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit HomeScreen background
      body: LayoutBuilder(
        builder: (context, constraints) {
          // ### START ENHANCED ADAPTIVE LAYOUT LOGIC ###

          // 1. Define Breakpoints
          const double mediumScreen = 600;
          const double largeScreen = 1200;
          const double extraLargeScreen = 1800;

          // 2. Determine Screen Size Category
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final bool isLandscape = screenWidth > screenHeight;
          
          final ScreenSize size;
          if (screenWidth >= extraLargeScreen) {
            size = ScreenSize.extraLarge;
          } else if (screenWidth >= largeScreen) {
            size = ScreenSize.large;
          } else if (screenWidth >= mediumScreen) {
            size = ScreenSize.medium;
          } else {
            size = ScreenSize.small;
          }

          // 3. Define Adaptive Values based on Screen Size and Orientation
          final double horizontalPadding = switch (size) {
            ScreenSize.extraLarge => isLandscape ? 200 : 150,
            ScreenSize.large => isLandscape ? 120 : 100,
            ScreenSize.medium => isLandscape ? 60 : 40,
            ScreenSize.small => isLandscape ? 20 : 10,
          };

          final double verticalPadding = switch (size) {
            ScreenSize.extraLarge => isLandscape ? 40 : 60,
            ScreenSize.large => isLandscape ? 30 : 50,
            ScreenSize.medium => isLandscape ? 20 : 30,
            ScreenSize.small => isLandscape ? 10 : 15,
          };

          final double titleFontSize = switch (size) {
            ScreenSize.extraLarge => isLandscape ? 60 : 64,
            ScreenSize.large => isLandscape ? 50 : 54,
            ScreenSize.medium => isLandscape ? 40 : 44,
            ScreenSize.small => isLandscape ? 24 : 28,
          };

          final double subTitleFontSize = switch (size) {
            ScreenSize.extraLarge => isLandscape ? 32 : 36,
            ScreenSize.large => isLandscape ? 26 : 30,
            ScreenSize.medium => isLandscape ? 22 : 26,
            ScreenSize.small => isLandscape ? 16 : 20,
          };

          final int gridCrossAxisCount = switch (size) {
            ScreenSize.extraLarge => 3,
            ScreenSize.large => 3,
            ScreenSize.medium => isLandscape ? 3 : 3,
            ScreenSize.small => isLandscape ? 2 : 2,
          };
          
          final double gridChildAspectRatio = switch (size) {
            ScreenSize.extraLarge => 3/1.3,
            ScreenSize.large => 3/1.3,
            ScreenSize.medium => 3/1.5,
            ScreenSize.small => 3/1.5,
          };
          
          final double gridSpacing = switch (size) {
            ScreenSize.extraLarge => isLandscape ? 50 : 40,
            ScreenSize.large => isLandscape ? 40 : 30,
            ScreenSize.medium => isLandscape ? 50 : 20,
            ScreenSize.small => isLandscape ? 90 : 40,
          };

          final double searchBarWidth = switch (size) {
            ScreenSize.extraLarge => (screenWidth * 0.4).clamp(500, 1000),
            ScreenSize.large => (screenWidth * 0.5).clamp(400, 800),
            ScreenSize.medium => (screenWidth * 0.6).clamp(300, 600),
            ScreenSize.small => (screenWidth * 0.85).clamp(200, 400),
          };

          final double spacingAfterAuthor = switch (size) {
            ScreenSize.extraLarge => 45,
            ScreenSize.large => 10,
            ScreenSize.medium => 30,
            ScreenSize.small => 15,
          };

          final double spacingAfterSearch = switch (size) {
            ScreenSize.extraLarge => 50,
            ScreenSize.large => 40,
            ScreenSize.medium => 30,
            ScreenSize.small => 15,
          };

          // ### END ENHANCED ADAPTIVE LAYOUT LOGIC ###

          return hadithState.when(
            data: (hadiths) {
              final chaptersMap = <int, Map<String, dynamic>>{};
              for (final hadith in hadiths) {
                if (!hadith.deleted) {
                  if (!chaptersMap.containsKey(hadith.bab)) {
                    chaptersMap[hadith.bab] = {
                      'chapter_number': hadith.bab,
                      'chapter_title': hadith.chapter_title,
                    };
                  }
                }
              }

              final dynamicChapters =
                  chaptersMap.entries.map((entry) => entry.value).toList()
                    ..sort(
                      (a, b) => (a['chapter_number'] as int).compareTo(
                        b['chapter_number'] as int,
                      ),
                    );

              return SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 
                        MediaQuery.of(context).padding.top - 
                        MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title 1
                          Text(
                            "موسوعة",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize,
                              color: const Color(0xfffcead0),
                              shadows: [
                                const Shadow(
                                  blurRadius: 6,
                                  color: Color.fromRGBO(0, 0, 0, 0.3),
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          // Title 2
                          Text(
                            "أحاديث الزكاة",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize,
                              color: const Color(0xfffcead0),
                              shadows: [
                                const Shadow(
                                  blurRadius: 6,
                                  color: Color.fromRGBO(0, 0, 0, 0.3),
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          // Author
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: spacingAfterAuthor,
                            ),
                            child: Text(
                              "د/سامى الخليل",
                              style: ArabicTextStyle(
                                arabicFont: ArabicFont.avenirArabic,
                                fontWeight: FontWeight.bold,
                                fontSize: subTitleFontSize,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          // Search Bar
                          GestureDetector(
                            onTap: () {
                              ref.read(navigationProvider.notifier).changeTab(2);
                            },
                            child: Container(
                              width: searchBarWidth,
                              margin: EdgeInsets.symmetric(
                                vertical: verticalPadding * 0.0,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: size == ScreenSize.small ? 8 : 16,
                                vertical: size == ScreenSize.small ? 2 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.9),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  width: size == ScreenSize.small ? 2 : 3,
                                  color: const Color(0xffe6a345),
                                ),
                              ),
                              child: TextField(
                                enabled: false,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  hintText: 'البحث عن حديث...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: (titleFontSize * 0.35).clamp(10, 18),
                                  ),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: const Color(0xffe6a345),
                                    size: (titleFontSize * 0.5).clamp(14, 28),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingAfterSearch),
                       
                          Center(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: switch (size) {
                                  ScreenSize.extraLarge => 1400,
                                  ScreenSize.large => 1200,
                                  ScreenSize.medium => 900,
                                  ScreenSize.small => screenWidth - (horizontalPadding * 2),
                                },
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dynamicChapters.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCrossAxisCount,
                                  crossAxisSpacing: gridSpacing,
                                  mainAxisSpacing: gridSpacing,
                                  childAspectRatio: gridChildAspectRatio,
                                ),
                                itemBuilder: (context, index) {
                                  final chapter = dynamicChapters[index];
                                  return BabCard(
                                    title:
                                        'الباب ${Methods.numberToArabicText(chapter['chapter_number'] as int)}',
                                    text: chapter['chapter_title'] as String,
                                    chapterNumber: chapter['chapter_number'] as int,
                                  );
                                },
                              ),
                            ),
                          ),
                          // Bottom spacing
                          SizedBox(height: verticalPadding),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                _buildErrorWidget(context, ref, constraints),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, BoxConstraints constraints) {
    // Apply same responsive logic to error widget
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final bool isLandscape = screenWidth > screenHeight;
    
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

    final double iconSize = switch (size) {
      ScreenSize.extraLarge => isLandscape ? 120 : 140,
      ScreenSize.large => isLandscape ? 100 : 120,
      ScreenSize.medium => isLandscape ? 80 : 100,
      ScreenSize.small => isLandscape ? 60 : 70,
    };

    final double fontSize = switch (size) {
      ScreenSize.extraLarge => isLandscape ? 28 : 32,
      ScreenSize.large => isLandscape ? 24 : 28,
      ScreenSize.medium => isLandscape ? 20 : 24,
      ScreenSize.small => isLandscape ? 14 : 16,
    };

    final double buttonFontSize = switch (size) {
      ScreenSize.extraLarge => isLandscape ? 20 : 22,
      ScreenSize.large => isLandscape ? 18 : 20,
      ScreenSize.medium => isLandscape ? 16 : 18,
      ScreenSize.small => isLandscape ? 12 : 14,
    };

    final double spacing = switch (size) {
      ScreenSize.extraLarge => isLandscape ? 24 : 28,
      ScreenSize.large => isLandscape ? 20 : 24,
      ScreenSize.medium => isLandscape ? 18 : 20,
      ScreenSize.small => isLandscape ? 12 : 14,
    };

    final double buttonPadding = switch (size) {
      ScreenSize.extraLarge => isLandscape ? 40 : 44,
      ScreenSize.large => isLandscape ? 32 : 36,
      ScreenSize.medium => isLandscape ? 24 : 28,
      ScreenSize.small => isLandscape ? 16 : 20,
    };

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.signal_wifi_off,
                color: const Color(0xfffcead0),
                size: iconSize,
              ),
              SizedBox(height: spacing),
              Text(
                'حدث خطأ أثناء التحميل\nمن فضلك تأكد من الاتصال بالإنترنت',
                textAlign: TextAlign.center,
                style: ArabicTextStyle(
                  arabicFont: ArabicFont.avenirArabic,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xfffcead0),
                ),
              ),
              SizedBox(height: spacing * 1.5),
              ElevatedButton(
                onPressed: () async {
                  final connectivityResult =
                      await Connectivity().checkConnectivity();
                  if (connectivityResult == ConnectivityResult.none) {
                    showSingleSnackBar(
                      context,
                      message: 'لا يوجد اتصال بالإنترنت',
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 3),
                    );
                  } else {
                    ref.refresh(DataProvider);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffe6a345),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      size == ScreenSize.small ? 10 : 16,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonPadding,
                    vertical: buttonPadding * 0.4,
                  ),
                ),
                child: Text(
                  'إعادة التحميل',
                  style: ArabicTextStyle(
                    arabicFont: ArabicFont.avenirArabic,
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xfffcead0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Enum to represent different screen size categories
enum ScreenSize {
  small,    // Less than 600px
  medium,   // 600px - 1200px
  large,    // 1200px - 1800px
  extraLarge, // More than 1800px
}