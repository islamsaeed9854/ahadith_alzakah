import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import '../core/constants.dart';
import '../data/models/hadith.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import '../providers/navigation_provider.dart';
import '../core/utils.dart';
import 'chapters_screen.dart';

final Hadith_Details_Helper_provider = StateProvider<String>((ref) {
  return '';
});

final searchControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final filteredResultsProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

final filterSearchProvider = Provider((ref) {
  return (String query, BuildContext context) async {
    if (query.trim().isEmpty) {
      ref.read(filteredResultsProvider.notifier).state = [];
      return;
    }

    try {
      final results = await ref.read(DataProvider.notifier).searchHadiths(query, context);
      final filteredResults = results.where((result) {
        final hadith = result['hadith'] as Hadith?;
        return hadith != null;
      }).map((result) {
        final hadith = result['hadith'] as Hadith;
        return {
          'title': '${hadith.chapter_title}:${hadith.section_title}:حديث${hadith.number}',
          'content': hadith.text,
          'hadith': hadith,
          'startIndex': result['startIndex'] as int? ?? 0,
          'length': result['length'] as int? ?? query.length,
        };
      }).toList();
      ref.read(filteredResultsProvider.notifier).state = filteredResults;
    } catch (e) {
      ref.read(filteredResultsProvider.notifier).state = [];
      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: 'حدث خطأ أثناء البحث: $e',
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        );
      }
    }
  };
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  Widget _buildResultTitle(Hadith hadith, bool isLandscape, double screenWidth) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: hadith.chapter_title ?? 'باب بدون عنوان',
            style: GoogleFonts.cairo(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
          TextSpan(
            text: ':',
            style: GoogleFonts.cairo(
              color: const Color.fromARGB(255, 12, 1, 1),
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
          TextSpan(
            text: hadith.section_title ?? 'قسم بدون عنوان',
            style: GoogleFonts.cairo(
              color: Color(0xff513c2e),
              fontWeight: FontWeight.bold,
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
          TextSpan(
            text: ':',
            style: GoogleFonts.cairo(
              color: Color(0xff977c55),
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
          TextSpan(
            text: 'حديث ${hadith.number}',
            style: GoogleFonts.cairo(
              color: Color(0xff977848),
              fontSize: isLandscape ? screenWidth * 0.018 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getSnippet(
    String text,
    String query,
    int startIndex,
    int length,
  ) {
    final Logger logger = Logger();
    final diacriticRegex = RegExp(r'[\p{P}\u0617-\u061A\u064B-\u065F]', unicode: true);

    if (startIndex < 0) {
      logger.w('startIndex ($startIndex) is negative, clamping to 0');
      startIndex = 0;
    }
    if (startIndex >= text.length) {
      logger.w(
        'startIndex ($startIndex) exceeds text length (${text.length}), clamping to ${text.length - 1}',
      );
      startIndex = text.length - 1;
      length = 0;
    }
    if (startIndex + length > text.length) {
      logger.w(
        'startIndex + length (${startIndex + length}) exceeds text length (${text.length}), adjusting length',
      );
      length = text.length - startIndex;
    }

    int nonDiacriticPos = 0;
    int adjustedStartIndex = 0;
    int adjustedEndIndex = text.length;
    bool startFound = false;
    for (int i = 0; i < text.length; i++) {
      if (!diacriticRegex.hasMatch(text[i])) {
        if (nonDiacriticPos == startIndex) {
          adjustedStartIndex = i;
          startFound = true;
        }
        if (startFound && nonDiacriticPos == startIndex + length) {
          adjustedEndIndex = i;
          break;
        }
        nonDiacriticPos++;
      }
    }

    if (!startFound) {
      adjustedStartIndex = startIndex.clamp(0, text.length - 1);
      adjustedEndIndex = (startIndex + length).clamp(
        adjustedStartIndex,
        text.length,
      );
    }

    final words = text.split(RegExp(r'\s'));
    int charPos = 0;
    int matchWordIndex = 0;

    for (int i = 0; i < words.length; i++) {
      int wordLen = words[i].length;
      if (charPos + wordLen >= adjustedStartIndex) {
        matchWordIndex = i;
        break;
      }
      charPos += wordLen + 1;
    }

    int startWord = (matchWordIndex - 15).clamp(0, words.length);
    int endWord = (matchWordIndex + 15 + 1).clamp(0, words.length);
    final snippetWords = words.sublist(startWord, endWord);
    final snippet = snippetWords.join(' ');

    int prefixLength = words
        .sublist(0, startWord)
        .fold(0, (sum, word) => sum + word.length + 1);
    int queryStart = (adjustedStartIndex - prefixLength).clamp(
      0,
      snippet.length,
    );
    int queryEnd = (adjustedEndIndex - prefixLength).clamp(
      queryStart,
      snippet.length,
    );
    String matchedQuery =
        queryStart < queryEnd ? snippet.substring(queryStart, queryEnd) : query;

    return {
      'snippet': snippet,
      'query': matchedQuery,
      'queryStart': queryStart,
      'queryEnd': queryEnd,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final filteredResults = ref.watch(filteredResultsProvider);

    final double horizontalPadding = isLandscape
        ? screenSize.width * 0.01
        : screenSize.width * 0.04;

    final double titleFontSize = isLandscape
        ? screenSize.width * 0.02
        : screenSize.width * 0.09;

    final double inputFontSize = isLandscape
        ? screenSize.width * 0.015
        : screenSize.width * 0.045;

    final double buttonFontSize = isLandscape
        ? screenSize.width * 0.016
        : screenSize.width * 0.05;

    final double sectionTitleFontSize = isLandscape
        ? screenSize.width * 0.018
        : screenSize.width * 0.055;

    final double emptyResultsFontSize = isLandscape
        ? screenSize.width * 0.016
        : screenSize.width * 0.045;

    final controller = ref.watch(searchControllerProvider);
    final filterSearch = ref.read(filterSearchProvider);

    void performSearch() {
      filterSearch(controller.text, context);
      FocusScope.of(context).unfocus();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Container(
        height: screenSize.height,
        child: isLandscape
            ? Row(
                children: [
                  Container(
                    width: screenSize.width * 0.35,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: screenSize.height * 0.02, // تقليل المسافة العمودية
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // العنوان مع زر الرجوع
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'البحث',
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
                        SizedBox(height: screenSize.height * 0.01), // تقليل المسافة

                        // حقل البحث
                        TextField(
                          controller: controller,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => performSearch(),
                          style: GoogleFonts.cairo(
                            color: Colors.black,
                            fontSize: inputFontSize,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اكتب هنا...',
                            hintStyle: GoogleFonts.cairo(
                              fontSize: inputFontSize,
                            ),
                            filled: true,
                            fillColor: const Color.fromRGBO(255, 255, 255, 0.9),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xffe6a345),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xffe6a345),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xffe6a345),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.008), // تقليل المسافة

                        // زر البحث
                        Center(
                          child: ElevatedButton(
                            onPressed: performSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF937848),
                              padding: EdgeInsets.symmetric(
                                vertical: screenSize.height * 0.008,
                                horizontal: screenSize.width * 0.03,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              'بحث',
                              style: GoogleFonts.cairo(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // الخط الفاصل
                  Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),

                  // منطقة النتائج
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عنوان نتائج البحث
                        Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Text(
                            'نتائج البحث',
                            style: GoogleFonts.cairo(
                              fontSize: sectionTitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // قائمة النتائج
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: filteredResults.isEmpty
                                ? Center(
                                    child: Text(
                                      'لا توجد نتائج مطابقة',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: emptyResultsFontSize,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filteredResults.length,
                                    itemBuilder: (context, index) {
                                      final result = filteredResults[index];
                                      final hadith = result['hadith'] as Hadith;
                                      final startIndex = result['startIndex'] as int;
                                      final length = result['length'] as int;
                                      final snippetInfo = _getSnippet(
                                        result['content']!,
                                        controller.text,
                                        startIndex,
                                        length,
                                      );

                                      return Padding(
                                        padding: EdgeInsets.only(bottom: screenSize.height * 0.01),
                                        child: GestureDetector(
                                          onTap: () {
                                            ref.watch(Hadith_Details_Helper_provider.notifier).state =
                                                ref.read(searchControllerProvider).text;
                                            ref.read(searchControllerProvider).text = '';
                                            ref.read(filteredResultsProvider.notifier).state = [];
                                            ref.read(selectedHadithProvider.notifier).state = hadith;
                                            ref.read(navigationProvider.notifier).changeTab(1);
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(255, 255, 255, .9),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xffe6a345),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildResultTitle(hadith, isLandscape, screenSize.width),
                                                SizedBox(height: 3),
                                                RichText(
                                                  text: TextSpan(
                                                    children: _buildHighlightedText(
                                                      snippetInfo['snippet'],
                                                      snippetInfo['query'],
                                                      snippetInfo['queryStart'],
                                                      snippetInfo['queryEnd'],
                                                      isLandscape,
                                                      screenSize.width,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'البحث',
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
                        SizedBox(height: screenSize.height * 0.03),

                        TextField(
                          controller: controller,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => performSearch(),
                          style: GoogleFonts.cairo(
                            color: Colors.black,
                            fontSize: inputFontSize,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اكتب هنا...',
                            hintStyle: GoogleFonts.cairo(
                              fontSize: inputFontSize,
                            ),
                            filled: true,
                            fillColor: const Color.fromRGBO(255, 255, 255, 0.9),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xffe6a345),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xffe6a345),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xffe6a345),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.025),

                        Center(
                          child: ElevatedButton(
                            onPressed: performSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF937848),
                              padding: EdgeInsets.symmetric(
                                vertical: screenSize.height * 0.012,
                                horizontal: screenSize.width * 0.10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(55),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              'بحث',
                              style: GoogleFonts.cairo(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.04),

                        Padding(
                          padding: EdgeInsets.only(right: screenSize.width * 0.02),
                          child: Text(
                            'نتائج البحث',
                            style: GoogleFonts.cairo(
                              fontSize: sectionTitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: filteredResults.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(screenSize.width * 0.05),
                                child: Text(
                                  'لا توجد نتائج مطابقة',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: emptyResultsFontSize,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: 20),
                              itemCount: filteredResults.length,
                              itemBuilder: (context, index) {
                                final result = filteredResults[index];
                                final hadith = result['hadith'] as Hadith;
                                final startIndex = result['startIndex'] as int;
                                final length = result['length'] as int;
                                final snippetInfo = _getSnippet(
                                  result['content']!,
                                  controller.text,
                                  startIndex,
                                  length,
                                );

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: screenSize.height * 0.02,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      ref.watch(Hadith_Details_Helper_provider.notifier).state =
                                          ref.read(searchControllerProvider).text;
                                      ref.read(searchControllerProvider).text = '';
                                      ref.read(filteredResultsProvider.notifier).state = [];
                                      ref.read(selectedHadithProvider.notifier).state = hadith;
                                      ref.read(navigationProvider.notifier).changeTab(1);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(255, 255, 255, .9),
                                        borderRadius: BorderRadius.circular(55),
                                        border: Border.all(
                                          color: const Color(0xffe6a345),
                                          width: 7,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildResultTitle(hadith, isLandscape, screenSize.width),
                                          SizedBox(height: 5),
                                          RichText(
                                            text: TextSpan(
                                              children: _buildHighlightedText(
                                                snippetInfo['snippet'],
                                                snippetInfo['query'],
                                                snippetInfo['queryStart'],
                                                snippetInfo['queryEnd'],
                                                isLandscape,
                                                screenSize.width,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(
    String text,
    String query,
    int start,
    int end,
    bool isLandscape,
    double screenWidth,
  ) {
    List<TextSpan> spans = [];
    final double fontSize = isLandscape ? screenWidth * 0.012 : 12;

    if (start >= 0 && end <= text.length) {
      if (start > 0) {
        spans.add(TextSpan(
          text: text.substring(0, start),
          style: GoogleFonts.cairo(
            color: Color(0xff513c2e),
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(start, end),
        style: GoogleFonts.cairo(
          color: AppTheme.redBlackColer,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ));

      if (end < text.length) {
        spans.add(TextSpan(
          text: text.substring(end),
          style: GoogleFonts.cairo(
            color: Color(0xff513c2e),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    } else {
      spans.add(TextSpan(
        text: text,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: fontSize,
        ),
      ));
    }

    return spans;
  }
}