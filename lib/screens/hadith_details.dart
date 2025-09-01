import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/chapters_screen.dart';
import '../notification_service.dart';
import '../providers/search_providers.dart';
import '../core/methods.dart';
import 'settings_screen.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import 'package:arabic_font/arabic_font.dart';
import '../core/hadith_text_parser.dart';
import '../core/utils.dart';

// ======================= Helper Functions for UI and Logic =======================

// Determines the maximum width for the content area.
double _getMaxContentWidth(double screenWidth) {
  if (screenWidth > 950) return 900; // For large screens
  return screenWidth; // For small and medium screens
}

// Determines the font size for headers (Bab and Fasl).
double _getHeaderFontSize(double screenWidth, {bool isSubHeader = false}) {
  if (screenWidth > 900) return isSubHeader ? 16.0 : 18.0;
  if (screenWidth > 600) return isSubHeader ? 14.0 : 16.0;
  return isSubHeader ? 13.0 : 15.0;
}

// Cleans text by removing special markers before copying.
String _cleanTextForCopying(String rawText) {
  return rawText
      .replaceAll('O', '')
      .replaceAll('X', '')
      .replaceAll('P', 'ﷺ')
      .trim();
}
// ========================================================================

class HadithDetails extends ConsumerWidget {
  const HadithDetails({super.key});

  // Sets the status bar style based on the current theme (dark/light).
  void _setStatusBarStyle(bool isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsInitializerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = _getMaxContentWidth(screenWidth);
    final theme = ref.watch(themeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = ref.watch(fontSizeProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final selectedHadith = ref.watch(selectedHadithProvider);
    final dailyHadith = ref.watch(dailyHadithProvider);
    final showDaily = ref.watch(showDailyHadithProvider);
    final controller = ref.watch(Hadith_Details_Helper_provider.notifier);
    final backgroundColor = theme.scaffoldBackgroundColor;

    _setStatusBarStyle(isDark);

    final hadithToDisplay =
        showDaily ? dailyHadith : (selectedHadith ?? dailyHadith);
    final allHadithsAsyncValue = ref.watch(DataProvider);

    return allHadithsAsyncValue.when(
      loading: () => Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : AppTheme.primaryColor)))),
      error: (error, stack) => Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
              child: _buildErrorWidget(theme, 'لا توجد أحاديث لعرضها حاليًا',
                  Icons.error_outline))),
      data: (allHadiths) {
        if (allHadiths.isEmpty || hadithToDisplay == null) {
          return Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                  backgroundColor: backgroundColor,
                  elevation: 0,
                  actions: [
                    IconButton(
                        icon: Icon(Icons.arrow_forward,
                            color: isDark
                                ? AppTheme.arrowBackdark
                                : AppTheme.arrowBackLight,
                            size: 30),
                        onPressed: () {
                          controller.state = '';
                          navNotifier.changeTab(0);
                          ref.read(showDailyHadithProvider.notifier).state =
                              false;
                          _setStatusBarStyle(false);
                        })
                  ]),
              body: Center(
                  child: _buildErrorWidget(theme, 'لا توجد أحاديث لعرضها حاليًا',
                      Icons.info_outline)));
        }

        final currentIndex = allHadiths.indexWhere((h) =>
            h.bab == hadithToDisplay.bab &&
            h.fasl == hadithToDisplay.fasl &&
            h.number == hadithToDisplay.number);

        final initialPage = currentIndex != -1 ? currentIndex : 0;
        final pageController = PageController(initialPage: initialPage);

        // Ensure the selected hadith provider is initialized with the first displayed hadith.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (allHadiths.isNotEmpty && ref.read(selectedHadithProvider) == null) {
             ref.read(selectedHadithProvider.notifier).state = allHadiths[initialPage];
          }
        });


        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) {
              controller.state = '';
              navNotifier.changeTab(0);
              ref.read(showDailyHadithProvider.notifier).state = false;
              _setStatusBarStyle(false);
            }
          },
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Theme(
              data: theme,
              child: DefaultTabController(
                length: 3,
                child: Scaffold(
                  backgroundColor: backgroundColor,
                  body: SafeArea(
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PageView.builder(
                              controller: pageController,
                              itemCount: allHadiths.length,
                              onPageChanged: (index) {
                                ref
                                    .read(selectedHadithProvider.notifier)
                                    .state = allHadiths[index];
                              },
                              itemBuilder: (context, index) {
                                final hadith = allHadiths[index];
                                return Column(
                                  children: [
                                    _buildHadithHeader(context, ref, hadith,
                                        isDark, screenWidth),
                                    Expanded(
                                      flex: 9,
                                      child: _buildHadithMainText(context,
                                          hadith.text, isDark, fontSize),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: _buildTabBar(isDark, fontSize),
                                    ),
                                    Expanded(
                                      flex: 9,
                                      child: TabBarView(
                                        children: [
                                          TabContent(
                                            text: hadith.summary,
                                            isDark: isDark,
                                          ),
                                          TabContent(
                                            text: hadith.reference,
                                            isDark: isDark,
                                          ),
                                          TabContent(
                                            text: hadith.analysis,
                                            isDark: isDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                             // Navigation Buttons for Desktop
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Next Button (on the left for RTL)
                                    IconButton(
                                      icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white54 : Colors.black54),
                                      onPressed: () {
                                        pageController.nextPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                    ),
                                    // Previous Button (on the right for RTL)
                                    IconButton(
                                      icon: Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white54 : Colors.black54),
                                      onPressed: () {
                                        pageController.previousPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                    ),
                                  ],
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildHadithHeader(BuildContext context, WidgetRef ref, hadith,
      bool isDark, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 100,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'الباب ${Methods.numberToArabicText(hadith.bab)}: ${hadith.chapter_title}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                    fontSize: _getHeaderFontSize(screenWidth),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'الفصل ${Methods.numberToArabicText(hadith.fasl)}: ${hadith.section_title} | حديث رقم: ${hadith.number}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                    fontSize: _getHeaderFontSize(screenWidth, isSubHeader: true),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: isDark ? const Color(0xFF2d2d2d) : Colors.white,
            icon: Icon(Icons.content_copy, color: isDark ? AppTheme.arrowBackdark : AppTheme.arrowBackLight, size: 26),
            onSelected: (value) {
                final String textToCopy;
                final String message;
                if (value == 'copy_text') {
                    textToCopy = hadith.text;
                    message = 'تم نسخ نص الحديث بنجاح!';
                } else {
                    textToCopy = hadith.summary;
                    message = 'تم نسخ الخلاصة بنجاح!';
                }
                final String cleanedText = _cleanTextForCopying(textToCopy);
                Clipboard.setData(ClipboardData(text: cleanedText));
                showSingleSnackBar(
                  context,
                  message: message,
                  backgroundColor: Colors.green.shade600,
                  duration: const Duration(seconds: 2),
                );
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                    value: 'copy_text',
                    child: Text('نسخ نص الحديث', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                ),
                PopupMenuItem<String>(
                    value: 'copy_summary',
                    child: Text('نسخ الخلاصة', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: isDark ? AppTheme.arrowBackdark : AppTheme.arrowBackLight,
              size: 30,
            ),
            onPressed: () {
              ref.read(Hadith_Details_Helper_provider.notifier).state = '';
              ref.read(navigationProvider.notifier).changeTab(0);
              ref.read(showDailyHadithProvider.notifier).state = false;
              _setStatusBarStyle(false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHadithMainText(
      BuildContext context, String text, bool isDark, int fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ScrollConfiguration(
        behavior:
            ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: parseHadithText(
                  text.trim(), isDark, fontSize.toDouble()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark, int fontSize) {
    return TabBar(
      indicatorColor: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
      labelColor: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
      unselectedLabelColor: const Color(0xff977c55),
      labelStyle: GoogleFonts.notoKufiArabic(
        fontSize: fontSize.toDouble() * 0.8,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'AvenirArabic',
        fontSize: fontSize.toDouble() * 0.8,
      ),
      tabs: const [
        Tab(text: 'الخلاصة'),
        Tab(text: 'التخريج'),
        Tab(text: 'الدراسة'),
      ],
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String message, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: AppTheme.primaryColor),
        const SizedBox(height: 20),
        Text(
          message,
          style: ArabicTextStyle(
              arabicFont: ArabicFont.avenirArabic,
              color: AppTheme.redBlackColer),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ======================= Widget for Tab Content =======================
class TabContent extends ConsumerWidget {
  final String text;
  final bool isDark;

  const TabContent({
    Key? key,
    required this.text,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(scrollbars: false, overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: parseHadithText(
                  text.trim(), isDark, fontSize.toDouble()),
            ),
          ),
        ),
      ),
    );
  }
}

