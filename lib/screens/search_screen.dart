import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import '../widgets/search_card.dart';
import '../core/constants.dart';
import '../data/models/hadith.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import '../providers/navigation_provider.dart';
import 'chapters_screen.dart';

// مزود للتحكم في حقل البحث
final searchControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

// مزود لتخزين نتائج البحث
final filteredResultsProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

// مزود لتنفيذ البحث باستخدام DataProvider
final filterSearchProvider = Provider((ref) {
  return (String query, BuildContext context) async {
    if (query.trim().isEmpty) {
      ref.read(filteredResultsProvider.notifier).state = [];
      return;
    }
    try {
      final results = await ref.read(DataProvider.notifier).searchHadiths(query, context);
      // تصفية النتائج للتأكد من أن جميع الحقول المطلوبة ليست null
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
    }
  };
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  // دالة لبناء عنوان النتيجة مع تنسيقات مختلفة
  Widget _buildResultTitle(Hadith hadith) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: hadith.chapter_title ?? 'باب بدون عنوان',
            style: GoogleFonts.cairo(
              color: Colors.amber, // لون اسم الباب
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          TextSpan(
            text: ':',
            style: GoogleFonts.cairo(
              color: const Color.fromARGB(255, 12, 1, 1),
              fontSize: 16,
            ),
          ),
          TextSpan(
            text: hadith.section_title ?? 'قسم بدون عنوان',
            style: GoogleFonts.cairo(
              color: Color(0xff513c2e), // لون اسم الفصل
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          TextSpan(
            text: ':',
            style: GoogleFonts.cairo(
              color: Color(0xff977c55),
              fontSize: 16,
            ),
          ),
          TextSpan(
            text: 'حديث ${hadith.number}',
            style: GoogleFonts.cairo(
              color: Color(0xff977c55), // لون رقم الحديث
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لاستخراج جزء من النص مع إبراز الكلمة المطابقة
  Map<String, dynamic> _getSnippet(
    String text,
    String query,
    int startIndex,
    int length,
  ) {
    final Logger logger = Logger();
    final diacriticRegex = RegExp(r'[\p{P}\u0617-\u061A\u064B-\u065F]', unicode: true);

    // Validate and adjust indices
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

    // Adjust indices based on original text (accounting for diacritics)
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

    // Extract snippet based on word boundaries
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
    final filteredResults = ref.watch(filteredResultsProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final controller = ref.watch(searchControllerProvider);
    final filterSearch = ref.read(filterSearchProvider);

    void performSearch() {
      filterSearch(controller.text, context);
      FocusScope.of(context).unfocus();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.04,
            vertical: screenSize.height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'البحث',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width * 0.09,
                      color: const Color(0xfffcead0),
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                  TextApp.backButton(ref),
                ],
              ),
              SizedBox(height: screenSize.height * 0.03),

              // Search Field - محفوظ كما هو في الكود الأصلي
              TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => performSearch(),
                style: GoogleFonts.cairo(
                  color: Colors.black,
                  fontSize: screenSize.width * 0.045,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب هنا...',
                  filled: true,
                  fillColor: const Color.fromRGBO(255, 255, 255, 0.9),
                  contentPadding: const EdgeInsets.symmetric(
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

              // Search Button - محفوظ كما هو في الكود الأصلي
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
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.04),

              // Results Section
              Padding(
                padding: EdgeInsets.only(right: screenSize.width * 0.02),
                child: Text(
                  'نتائج البحث',
                  style: GoogleFonts.cairo(
                    fontSize: screenSize.width * 0.055,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.02),

              // Results List - الجزء المعدل فقط لعرض النتائج
              SizedBox(
                height: screenSize.height * 0.4,
                child: filteredResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(screenSize.width * 0.05),
                          child: Text(
                            'لا توجد نتائج مطابقة',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: screenSize.width * 0.045,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 20,
                        ),
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
                                    // العنوان مع الألوان المختلفة
                                    _buildResultTitle(hadith),
                                    SizedBox(height:5),
                                    // نص الحديث مع تمييز نتيجة البحث
                                    RichText(
                                      text: TextSpan(
                                        children: _buildHighlightedText(
                                          snippetInfo['snippet'],
                                          snippetInfo['query'],
                                          snippetInfo['queryStart'],
                                          snippetInfo['queryEnd'],
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
            ],
          ),
        ),
      ),
    );
  }

  // دالة لبناء النص مع تمييز نتيجة البحث
  List<TextSpan> _buildHighlightedText(String text, String query, int start, int end) {
    List<TextSpan> spans = [];
    
    if (start >= 0 && end <= text.length) {
      if (start > 0) {
        spans.add(TextSpan(
          text: text.substring(0, start),
          style: GoogleFonts.cairo(
            color: Color(0xff513c2e),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ));
      }
      
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: GoogleFonts.cairo(
          color: AppTheme.redBlackColer,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      if (end < text.length) {
        spans.add(TextSpan(
          text: text.substring(end),
          style: GoogleFonts.cairo(
            color: Color(0xff513c2e),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    } else {
      spans.add(TextSpan(
        text: text,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 12,
        ),
      ));
    }
    
    return spans;
  }
}