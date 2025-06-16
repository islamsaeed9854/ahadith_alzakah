import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
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

class HadithDetails extends ConsumerWidget {
  const HadithDetails({super.key});

  List<TextSpan> _buildFormattedText(
    String text,
    bool isDark,
    double fontSize,
  ) {
    List<TextSpan> spans = [];

    void addTextSpan(String text, TextStyle style, {bool addSpace = true}) {
      if (text.isEmpty) return;
  
      bool needsSpace = addSpace && !text.endsWith(' ') && text != '*';
      spans.add(TextSpan(text: text + (needsSpace ? ' ' : ''), style: style));
    }

    final baseStyle = TextStyle(
      color: isDark ? Colors.white : Color(0xff513c2e),
      fontSize: fontSize,
      height: 1.8,
    );

   

    RegExp pattern = RegExp(r'(X[^X]+X|O[^O]+O|\[[^\]]+\]|\*)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      String before = text.substring(lastIndex, match.start); 
      if (before.isNotEmpty) addTextSpan(before, baseStyle);

      String matchText = match.group(0)!;
      if (matchText.startsWith('X') && matchText.endsWith('X')) {
        final mcolor = isDark ? Color(0xffe09d3c) : Color(0xff10834b);
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: mcolor),
        );
      } else if (matchText.startsWith('O') && matchText.endsWith('O')) {
        final mcolor = isDark ? Color(0xffb5a7a7) : Color(0xff912929);
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: mcolor),
        );
      } else if (matchText.startsWith('[') && matchText.endsWith(']')) {
        final mcolor = isDark ? Color(0xffa5947b) : Color(0xffa37635);
        addTextSpan(
          matchText.substring(0, matchText.length),
          baseStyle.copyWith(color: mcolor),
        );
      } else if (matchText == '*') {
        addTextSpan(
          matchText,
          baseStyle.copyWith(fontWeight: FontWeight.bold),
          addSpace: false,
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      String remaining = text.substring(lastIndex); 
      if (remaining.isNotEmpty)
        addTextSpan(remaining, baseStyle, addSpace: false);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsInitializerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = ref.watch(themeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = ref.watch(fontSizeProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final selectedHadith = ref.watch(selectedHadithProvider);
    final dailyHadith = ref.watch(dailyHadithProvider);
    final showDaily = ref.watch(showDailyHadithProvider);
    final controller = ref.watch(Hadith_Details_Helper_provider.notifier);
    final backgroundColor = theme.scaffoldBackgroundColor;

    final hadithToDisplay =
        showDaily ? dailyHadith : (selectedHadith ?? dailyHadith);
    final allHadithsAsyncValue = ref.watch(DataProvider);

    return allHadithsAsyncValue.when(
      loading:
          () => Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 7,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : AppTheme.primaryColor,
              ),
              backgroundColor: isDark ? Colors.black26 : Colors.brown[100],
            ),
          ),
        ),
      ),
      error:
          (error, stack) => Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: _buildErrorWidget(
            theme,
            'لا توجد أحاديث لعرضها حاليًا',
            Icons.error_outline,
          ),
        ),
      ),
      data: (allHadiths) {
        if (allHadiths.isEmpty || hadithToDisplay == null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward,
                    color:
                        isDark
                            ? AppTheme.arrowBackdark
                            : AppTheme.arrowBackLight,
                    size: 30,
                  ),
                  onPressed: () {
                    controller.state = '';
                    navNotifier.changeTab(0);
                  },
                ),
              ],
            ),
            body: Center(
              child: _buildErrorWidget(
                theme,
                'لا توجد أحاديث لعرضها حاليًا',
                Icons.info_outline,
              ),
            ),
          );
        }

        final currentIndex = allHadiths.indexWhere(
          (h) =>
              h.bab == hadithToDisplay.bab &&
              h.fasl == hadithToDisplay.fasl &&
              h.number == hadithToDisplay.number,
        );

        final initialPage = currentIndex != -1 ? currentIndex : 0;
        final pageController = PageController(initialPage: initialPage);

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) {
              controller.state = '';
              navNotifier.changeTab(0);
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
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: allHadiths.length,
                      onPageChanged: (index) {
                        ref.read(selectedHadithProvider.notifier).state =
                            allHadiths[index];
                      },
                      itemBuilder: (context, index) {
                        final hadith = allHadiths[index];
                        return Column(
                          children: [
                            SizedBox(
                              height:  screenWidth > screenHeight ? 50 : 100,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 0,
                                  left:
                                      screenWidth > screenHeight
                                          ? 15
                                          : MediaQuery.of(
                                                  context,
                                                ).padding.left +
                                              16,
                                  right:
                                      screenWidth > screenHeight
                                          ? 15
                                          : MediaQuery.of(
                                                  context,
                                                ).padding.right +
                                              16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الباب ${Methods.numberToArabicText(hadith.bab)}: ${hadith.chapter_title}',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isDark
                                                      ? AppTheme.primaryColor
                                                      : AppTheme.redBlackColer,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'الفصل ${Methods.numberToArabicText(hadith.fasl)}: ${hadith.section_title} | حديث رقم: ${hadith.number}',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isDark
                                                      ? AppTheme.primaryColor
                                                      : AppTheme.redBlackColer,
                                              fontSize: 13,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_forward,
                                        color:
                                            isDark
                                                ? AppTheme.arrowBackdark
                                                : AppTheme.arrowBackLight,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        controller.state = '';
                                        navNotifier.changeTab(0);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.00),
                            Expanded(
                              flex: 9,
                              child: Container(
                                padding: const EdgeInsets.only(top: 0.0),
                                margin: EdgeInsets.symmetric(
                                  horizontal:
                                      screenWidth > screenHeight
                                          ? 15
                                          : MediaQuery.of(
                                                  context,
                                                ).padding.left +
                                              screenWidth * 0.06,
                                ),
                                child: ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(
                                    context,
                                  ).copyWith(scrollbars: false),
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: RichText(
                                      textAlign: TextAlign.justify,
                                      text: TextSpan(
                             
                                        children: _buildFormattedText(
                                          hadith.text.trim(),
                                          isDark,
                                          fontSize.toDouble(),
                                        ),
                         
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: screenWidth > screenHeight ? 4 : 2,
                              child: TabBar(
                                indicatorColor:
                                    isDark
                                        ? AppTheme.primaryColor
                                        : AppTheme.redBlackColer,
                                labelColor:
                                    isDark
                                        ? AppTheme.primaryColor
                                        : AppTheme.redBlackColer,
                                unselectedLabelColor: const Color(0xff977c55),
                                labelStyle: GoogleFonts.notoKufiArabic(
                                  fontSize: fontSize.toDouble() * 0.8,
                                  fontWeight: FontWeight.bold,
                                ),
                                unselectedLabelStyle: ArabicTextStyle(
                                  arabicFont: ArabicFont.avenirArabic,
                                  fontSize: fontSize.toDouble() * 0.8,
                                ),
                                tabs: const [
                                  Tab(text: 'الخلاصة'),
                                  Tab(text: 'التخريج'),
                                  Tab(text: 'الدراسة'),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 9,
                              child: TabBarView(
                                children: [
                                  TabContent(
                                    text: hadith.summary,
                                    isDark: isDark,
                                    screenHeight: screenHeight,
                                    screenWidth: screenWidth,
                                  ),
                                  TabContent(
                                    text: hadith.reference,
                                    isDark: isDark,
                                    screenHeight: screenHeight,
                                    screenWidth: screenWidth,
                                  ),
                                  TabContent(
                                    text: hadith.analysis,
                                    isDark: isDark,
                                    screenHeight: screenHeight,
                                    screenWidth: screenWidth,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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
            color: AppTheme.redBlackColer,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class TabContent extends ConsumerWidget {
  final String text;
  final bool isDark;
  final double screenHeight;
  final double screenWidth;
  const TabContent({
    Key? key,
    required this.text,
    required this.isDark,
    required this.screenHeight,
    required this.screenWidth,
  }) : super(key: key);

  List<TextSpan> _buildFormattedText(
    String text,
    bool isDark,
    double fontSize,
  ) {
    List<TextSpan> spans = [];

    void addTextSpan(String text, TextStyle style, {bool addSpace = true}) {
      if (text.isEmpty) return;
     
      bool needsSpace = addSpace && !text.endsWith(' ') && text != '*';
      spans.add(TextSpan(text: text + (needsSpace ? ' ' : ''), style: style));
    }

    final baseStyle = TextStyle(
      color: isDark ? const Color(0xffd6c9b3) : const Color(0xff513c2e),
      fontSize: fontSize,
      height: 1.8,
    );

  

    RegExp pattern = RegExp(r'(X[^X]+X|O[^O]+O|\[[^\]]+\]|\*)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      String before = text.substring(lastIndex, match.start); // .trim() is removed
      if (before.isNotEmpty) addTextSpan(before, baseStyle);

      String matchText = match.group(0)!;
      if (matchText.startsWith('X') && matchText.endsWith('X')) {
        final mcolor = isDark ? Color(0xffe09d3c) : const Color(0xff10834b);
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: mcolor),
        );
      } else if (matchText.startsWith('O') && matchText.endsWith('O')) {
        final mcolor = isDark ? Color(0xffb5a7a7) : const Color(0xff912929);
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: mcolor),
        );
      } else if (matchText.startsWith('[') && matchText.endsWith(']')) {
        final mcolor = isDark ? Color(0xffa5947b) : const Color(0xffa37635);
        addTextSpan(
          matchText.substring(0, matchText.length),
          baseStyle.copyWith(color: mcolor),
        );
      } else if (matchText == '*') {
        addTextSpan(
          matchText,
          baseStyle.copyWith(fontWeight: FontWeight.bold),
          addSpace: false,
        );
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      String remaining = text.substring(lastIndex); 
      if (remaining.isNotEmpty)
        addTextSpan(remaining, baseStyle, addSpace: false);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            MediaQuery.of(context).padding.left +
            (screenHeight < screenWidth ? 8.0 : 22.0),
        vertical: MediaQuery.of(context).padding.right + 8.0,
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false, overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: _buildFormattedText(text.trim(), isDark, fontSize.toDouble()),
            ),
          ),
        ),
      ),
    );
  }
}