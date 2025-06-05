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

class HadithDetails extends ConsumerWidget {
  const HadithDetails({super.key});

  List<TextSpan> _buildFormattedText(String text, bool isDark, double fontSize) {
    List<TextSpan> spans = [];
    
    // Helper function to add spans with proper spacing
    void addTextSpan(String text, TextStyle style, {bool addSpace = true}) {
      if (text.isEmpty) return;
      // Clean the text while preserving single spaces between words
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      // Only add a space if it's not already there and we need one
      bool needsSpace = addSpace && !text.endsWith(' ') && text != '*';
      spans.add(TextSpan(text: text + (needsSpace ? ' ' : ''), style: style));
    }

    // Base text style
    final baseStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: fontSize,
      height: 1.8,
    );

    // Clean input text and normalize newlines
    text = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    
    RegExp pattern = RegExp(r'(X[^X]+X|O[^O]+O|\[[^\]]+\]|\*)');
    int lastIndex = 0;
    
    for (final match in pattern.allMatches(text)) {
      // Add text before match
      String before = text.substring(lastIndex, match.start).trim();
      if (before.isNotEmpty) {
        addTextSpan(before, baseStyle);
      }

      // Handle special formatting
      String matchText = match.group(0)!;
      if (matchText.startsWith('X') && matchText.endsWith('X')) {
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: Colors.green)
        );
      } else if (matchText.startsWith('O') && matchText.endsWith('O')) {
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: Colors.red)
        );
      } else if (matchText.startsWith('[') && matchText.endsWith(']')) {
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: Colors.blue)
        );
      } else if (matchText == '*') {
        addTextSpan(
          matchText,
          baseStyle.copyWith(fontWeight: FontWeight.bold),
          addSpace: false
        );
      }
      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      String remaining = text.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        addTextSpan(
          remaining,
          baseStyle,
          addSpace: false
        );
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = ref.watch(themeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = ref.watch(fontSizeProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final selectedHadith = ref.watch(selectedHadithProvider);
    final dailyHadith = ref.watch(dailyHadithProvider);
    final controller = ref.watch(Hadith_Details_Helper_provider.notifier);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final hadithToDisplay = selectedHadith ?? dailyHadith;

    if (hadithToDisplay == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 7,
              valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : AppTheme.primaryColor),
              backgroundColor: isDark ? Colors.black26 : Colors.brown[100],
            ),
          ),
        ),
      );
    }

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
              body: Column(
                children: [
                  // Header section
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      right: 16,
                      left: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الباب ${Methods.numberToArabicText(hadithToDisplay.bab)}: ${hadithToDisplay.chapter_title}',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'الفصل ${Methods.numberToArabicText(hadithToDisplay.fasl)}: ${hadithToDisplay.section_title} | حديث رقم: ${hadithToDisplay.number}',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward,
                            color: isDark ? AppTheme.arrowBackdark : AppTheme.arrowBackLight,
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
                  
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Main hadith text section
                  Container(
                    height: screenHeight * 0.35,
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            children: _buildFormattedText(
                              hadithToDisplay.text.trim().replaceAll(RegExp(r'\s+'), ' '),
                              isDark,
                              fontSize.toDouble(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // TabBar
                  TabBar(
                    indicatorColor: AppTheme.redBlackColer,
                    labelColor: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                    unselectedLabelColor: const Color(0xff977c55),
                    labelStyle: GoogleFonts.notoKufiArabic(
                      fontSize: fontSize.toDouble() * 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.notoKufiArabic(
                      fontSize: fontSize.toDouble() * 0.8,
                    ),
                    tabs: const [
                      Tab(text: 'الخلاصة'),
                      Tab(text: 'التخريج'),
                      Tab(text: 'الدراسة'),
                    ],
                  ),
                  
                  // Tab content section
                  Expanded(
                    child: TabBarView(
                      children: [
                        TabContent(
                          text: hadithToDisplay.summary,
                          isDark: isDark,
                        ),
                        TabContent(
                          text: hadithToDisplay.reference,
                          isDark: isDark,
                        ),
                        TabContent(
                          text: hadithToDisplay.analysis,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TabContent extends ConsumerWidget {
  final String text;
  final bool isDark;

  const TabContent({
    Key? key,
    required this.text,
    required this.isDark,
  }) : super(key: key);

  List<TextSpan> _buildFormattedText(String text, bool isDark, double fontSize) {
    List<TextSpan> spans = [];
    
    // Helper function to add spans with proper spacing
    void addTextSpan(String text, TextStyle style, {bool addSpace = true}) {
      if (text.isEmpty) return;
      // Clean the text while preserving single spaces between words
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      // Only add a space if it's not already there and we need one
      bool needsSpace = addSpace && !text.endsWith(' ') && text != '*';
      spans.add(TextSpan(text: text + (needsSpace ? ' ' : ''), style: style));
    }

    // Base text style
    final baseStyle = TextStyle(
      color: isDark ? const Color(0xffd6c9b3) : const Color(0xffa37635),
      fontSize: fontSize,
      height: 1.8,
    );

    // Clean input text and normalize newlines
    text = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    
    RegExp pattern = RegExp(r'(X[^X]+X|O[^O]+O|\[[^\]]+\]|\*)');
    int lastIndex = 0;
    
    for (final match in pattern.allMatches(text)) {
      // Add text before match
      String before = text.substring(lastIndex, match.start).trim();
      if (before.isNotEmpty) {
        addTextSpan(before, baseStyle);
      }

      // Handle special formatting
      String matchText = match.group(0)!;
      if (matchText.startsWith('X') && matchText.endsWith('X')) {
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: Colors.green)
        );
      } else if (matchText.startsWith('O') && matchText.endsWith('O')) {
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: Colors.red)
        );
      } else if (matchText.startsWith('[') && matchText.endsWith(']')) {
        addTextSpan(
          matchText.substring(1, matchText.length - 1),
          baseStyle.copyWith(color: Colors.blue)
        );
      } else if (matchText == '*') {
        addTextSpan(
          matchText,
          baseStyle.copyWith(fontWeight: FontWeight.bold),
          addSpace: false
        );
      }
      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      String remaining = text.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        addTextSpan(
          remaining,
          baseStyle,
          addSpace: false
        );
      }
    }

    return spans;
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          overscroll: false,
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: _buildFormattedText(
                text,
                isDark,
                fontSize.toDouble(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}