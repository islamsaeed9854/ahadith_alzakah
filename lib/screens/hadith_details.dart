import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/chapters_screen.dart';
import 'search_screen.dart';
import '../notification_service.dart';
import '../data/models/hadith.dart';

class HadithDetails extends ConsumerWidget {
  const HadithDetails({super.key});

  List<TextSpan> _buildFormattedText(
    String text,
    String searchQuery,
    bool isDark,
    double fontSize,
  ) {
    List<TextSpan> spans = [];

    String cleanSearchQuery = _removeDiacritics(
      searchQuery.toLowerCase().trim(),
    );

    RegExp xPattern = RegExp(r'X([^X]+)X');

    int lastIndex = 0;

    Iterable<RegExpMatch> xMatches = xPattern.allMatches(text);

    for (RegExpMatch match in xMatches) {
      String beforeMatch = text.substring(lastIndex, match.start);
      if (beforeMatch.isNotEmpty) {
        spans.addAll(
          _highlightSearchTerms(
            beforeMatch,
            cleanSearchQuery,
            isDark,
            fontSize,
            false,
          ),
        );
      }

      String boldText = match.group(1) ?? '';
      spans.addAll(
        _highlightSearchTerms(
          boldText,
          cleanSearchQuery,
          isDark,
          fontSize,
          true,
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      String remainingText = text.substring(lastIndex);
      spans.addAll(
        _highlightSearchTerms(
          remainingText,
          cleanSearchQuery,
          isDark,
          fontSize,
          false,
        ),
      );
    }

    return spans;
  }

  List<TextSpan> _highlightSearchTerms(
    String text,
    String searchQuery,
    bool isDark,
    double fontSize,
    bool isBold,
  ) {
    List<TextSpan> spans = [];

    if (searchQuery.isEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: fontSize,
            height: 1.8,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
      return spans;
    }

    int lastIndex = 0;

    for (int i = 0; i <= text.length - 1; i++) {
      for (
        int j = i + searchQuery.length;
        j <= text.length && j <= i + searchQuery.length + 10;
        j++
      ) {
        String potentialMatch = text.substring(i, j);
        String cleanPotentialMatch = _removeDiacritics(
          potentialMatch.toLowerCase().trim(),
        );

        if (cleanPotentialMatch == searchQuery) {
          if (i > lastIndex) {
            spans.add(
              TextSpan(
                text: text.substring(lastIndex, i),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: fontSize,
                  height: 1.8,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }

          spans.add(
            TextSpan(
              text: potentialMatch,
              style: TextStyle(
                color: AppTheme.redBlackColer,
                fontSize: fontSize,
                height: 1.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          lastIndex = j;
          i = j - 1;
          break;
        }
      }
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: fontSize,
            height: 1.8,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return spans;
  }

  String _removeDiacritics(String text) {
    final diacritics = RegExp(
      r'[\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
      unicode: true,
    );
    String normalized =
        text
            .replaceAll(diacritics, '')
            .replaceAll(
              RegExp(r'[\u0622\u0623\u0625]'),
              '\u0627',
            ) 
            .replaceAll('\u064A', '\u0649') 
            .replaceAll('\u0629', '\u0647')
            .toLowerCase();
    return normalized;
  }

  String numberToArabicText(int number) {
    const List<String> ones = [
      '',
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'السابع',
      'الثامن',
      'التاسع',
    ];
    const List<String> tens = [
      '',
      '',
      'العشرون',
      'الثلاثون',
      'الأربعون',
      'الخمسون',
      'الستون',
      'السبعون',
      'الثمانون',
      'التسعون',
    ];
    const List<String> teens = [
      'العاشر',
      'الحادي عشر',
      'الثاني عشر',
      'الثالث عشر',
      'الرابع عشر',
      'الخامس عشر',
      'السادس عشر',
      'السابع عشر',
      'الثامن عشر',
      'التاسع عشر',
    ];

    if (number == 0) return 'الصفر';
    if (number >= 1 && number <= 9) return ones[number];
    if (number >= 10 && number <= 19) return teens[number - 10];
    if (number >= 20 && number <= 99) {
      int ten = (number ~/ 10) * 10;
      int one = number % 10;
      if (one == 0) return tens[number ~/ 10];
      return '${ones[one]} و${tens[number ~/ 10]}';
    }
    return number.toString();
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
    final searchQuery = controller.state;

    // Use selected hadith or fall back to daily hadith
    final hadithToDisplay = selectedHadith ?? dailyHadith;
    if (hadithToDisplay == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 64,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              const SizedBox(height: 16),
              Text(
                'لا يوجد حديث متاح',
                style: TextStyle(
                  fontSize: fontSize.toDouble(),
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        controller.state = '';
        navNotifier.changeTab(0);
        return false;
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: theme,
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
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
                                  'الباب ${numberToArabicText(hadithToDisplay.bab)}:${hadithToDisplay.chapter_title}',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  'الفصل ${numberToArabicText(hadithToDisplay.fasl)}:${hadithToDisplay.section_title} | حديث رقم: ${hadithToDisplay.number}',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward,
                              color: isDark ? AppTheme.arrowBackdark : AppTheme.arrowBackLight,
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

                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.00,
                      ),
                      height: screenHeight * 0.4,
                      padding: EdgeInsets.all(screenWidth * 0.01),
                      child: SingleChildScrollView(
                        child: RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            children: _buildFormattedText(
                              hadithToDisplay.text.trim(),
                              searchQuery,
                              isDark,
                              fontSize.toDouble(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 1.0,
                      ),
                      child: TabBar(
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
                    ),

                    Container(
                      height: screenHeight * 0.5,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: TabBarView(
                        children: [
                          TabContent(
                            text: hadithToDisplay.summary,
                            isDark: isDark,
                            searchQuery: searchQuery,
                          ),
                          TabContent(
                            text: hadithToDisplay.reference,
                            isDark: isDark,
                            searchQuery: searchQuery,
                          ),
                          TabContent(
                            text: hadithToDisplay.analysis,
                            isDark: isDark,
                            searchQuery: searchQuery,
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
      ),
    );
  }
}

class TabContent extends ConsumerWidget {
  final String text;
  final bool isDark;
  final String searchQuery;

  const TabContent({
    super.key,
    required this.text,
    required this.isDark,
    this.searchQuery = '',
  });

  List<TextSpan> _buildFormattedText(
    String text,
    String searchQuery,
    bool isDark,
    double fontSize,
  ) {
    List<TextSpan> spans = [];
    String cleanSearchQuery = _removeDiacritics(searchQuery.toLowerCase().trim());
    RegExp xPattern = RegExp(r'X([^X]+)X');
    int lastIndex = 0;
    Iterable<RegExpMatch> xMatches = xPattern.allMatches(text);

    for (RegExpMatch match in xMatches) {
      String beforeMatch = text.substring(lastIndex, match.start);
      if (beforeMatch.isNotEmpty) {
        spans.addAll(
          _highlightSearchTerms(beforeMatch, cleanSearchQuery, isDark, fontSize, false),
        );
      }

      String boldText = match.group(1) ?? '';
      spans.addAll(
        _highlightSearchTerms(boldText, cleanSearchQuery, isDark, fontSize, true),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      String remainingText = text.substring(lastIndex);
      spans.addAll(
        _highlightSearchTerms(remainingText, cleanSearchQuery, isDark, fontSize, false),
      );
    }

    return spans;
  }

  List<TextSpan> _highlightSearchTerms(
    String text,
    String searchQuery,
    bool isDark,
    double fontSize,
    bool isBold,
  ) {
    List<TextSpan> spans = [];

    if (searchQuery.isEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            color: isDark ? Color(0xffd6c9b3) : const Color(0xffa37635),
            fontSize: fontSize,
            height: 1.8,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
      return spans;
    }

    int lastIndex = 0;

    for (int i = 0; i <= text.length - 1; i++) {
      for (
        int j = i + searchQuery.length;
        j <= text.length && j <= i + searchQuery.length + 10;
        j++
      ) {
        String potentialMatch = text.substring(i, j);
        String cleanPotentialMatch = _removeDiacritics(potentialMatch.toLowerCase().trim());

        if (cleanPotentialMatch == searchQuery) {
          if (i > lastIndex) {
            spans.add(
              TextSpan(
                text: text.substring(lastIndex, i),
                style: TextStyle(
                  color: isDark ? Color(0xffd6c9b3) : const Color(0xffa37635),
                  fontSize: fontSize,
                  height: 1.8,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }

          spans.add(
            TextSpan(
              text: potentialMatch,
              style: TextStyle(
                color: AppTheme.redBlackColer,
                fontSize: fontSize,
                height: 1.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          lastIndex = j;
          i = j - 1;
          break;
        }
      }
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: TextStyle(
            color: isDark ? Color(0xffd6c9b3) : const Color(0xffa37635),
            fontSize: fontSize,
            height: 1.8,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return spans;
  }

  String _removeDiacritics(String text) {
    final diacritics = RegExp(
      r'[\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
      unicode: true,
    );
    String normalized = text
        .replaceAll(diacritics, '')
        .replaceAll(RegExp(r'[\u0622\u0623\u0625]'), '\u0627')
        .replaceAll('\u064A', '\u0649')
        .replaceAll('\u0629', '\u0647')
        .toLowerCase();
    return normalized;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            children: _buildFormattedText(
              text.trim(),
              searchQuery,
              isDark,
              fontSize.toDouble(),
            ),
          ),
        ),
      ),
    );
  }
}