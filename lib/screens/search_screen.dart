import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:async/async.dart';
import '../core/constants.dart';
import '../providers/search_state_provider.dart';
import '../data/models/hadith.dart';
import '../providers/navigation_provider.dart';
import 'chapters_screen.dart';
import '../widgets/search_card.dart';
import '../providers/search_providers.dart';
import '../core/methods.dart';
import 'package:arabic_font/arabic_font.dart';
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final filteredResults = ref.watch(filteredResultsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding =
        isLandscape ? screenSize.width * 0.01 : screenSize.width * 0.04;

    final double titleFontSize =
        isLandscape ? screenSize.width * 0.02 : screenSize.width * 0.09;

    final double inputFontSize =
        isLandscape ? screenSize.width * 0.015 : screenSize.width * 0.045;

    final double buttonFontSize =
        isLandscape ? screenSize.width * 0.016 : screenSize.width * 0.05;

    final double sectionTitleFontSize =
        isLandscape ? screenSize.width * 0.018 : screenSize.width * 0.055;

    final double emptyResultsFontSize =
        isLandscape ? screenSize.width * 0.016 : screenSize.width * 0.045;

    final controller = ref.watch(searchControllerProvider);
    final filterSearch = ref.read(filterSearchProvider);

    void performSearch() {
      if (controller.text.trim().isEmpty) return;

      try {
        final searchStateNotifier = ref.read(searchStateProvider.notifier);

        // Cancel any existing search operation
        searchStateNotifier.stopSearch();

        // Create a new cancellable search operation
        final operation = CancelableOperation.fromFuture(
          Future(() async {
            await filterSearch(controller.text, context);
            if (context.mounted) {
              FocusScope.of(context).unfocus();
            }
          }),
        );

        // Start the new search operation
        searchStateNotifier.startSearch(operation);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء البحث: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea( // إضافة SafeArea لتجنب القص
        child: Container(
          height: screenSize.height,
          child: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // حقل البحث (ربع العرض) في الـ Landscape
                    Flexible(
                      flex: 1, // 1/4 من العرض
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding / 2,
                          bottom: screenSize.height * 0.02,
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
                            SizedBox(height: screenSize.height * 0.01),
                            Container(
                              width: double.infinity, // تأكد إن الحقل يملأ العرض المتاح
                              child: TextField(
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
                                  fillColor: const Color.fromRGBO(
                                    255,
                                    255,
                                    255,
                                    0.9,
                                  ),
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
                            ),
                            SizedBox(height: screenSize.height * 0.025),
                            Center(
                              child: ElevatedButton(
                                onPressed: performSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF937848),
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenSize.height * 0.012,
                                    horizontal: screenSize.width * 0.03,
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
                          ],
                        ),
                      ),
                    ),
                    // نتائج البحث (ثلاثة أرباع العرض) في الـ Landscape
                    Expanded(
                      flex: 3, // 3/4 من العرض
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: horizontalPadding,
                          left: horizontalPadding / 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: screenSize.height * 0.01, bottom: screenSize.height * 0.01),
                              child: Text(
                                'نتائج البحث',
                                style: GoogleFonts.cairo(
                                  fontSize: sectionTitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
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
                                        final snippetInfo = Methods.getSnippet(
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
                                              ref
                                                  .watch(
                                                    Hadith_Details_Helper_provider
                                                        .notifier,
                                                  )
                                                  .state = ref
                                                      .read(searchControllerProvider)
                                                      .text;
                                              ref.read(searchControllerProvider).text = '';
                                              ref
                                                  .read(filteredResultsProvider.notifier)
                                                  .state = [];
                                              ref
                                                  .read(selectedHadithProvider.notifier)
                                                  .state = hadith;
                                              ref.read(navigationProvider.notifier).changeTab(1);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                color: const Color.fromRGBO(
                                                  255,
                                                  255,
                                                  255,
                                                  .9,
                                                ),
                                                borderRadius: BorderRadius.circular(55),
                                                border: Border.all(
                                                  color: const Color(0xffe6a345),
                                                  width: 3,
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
                                                  buildResultTitle(
                                                    hadith,
                                                    isLandscape,
                                                    screenSize.width,
                                                  ),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(                   
                        screenWidth * 0.04,
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
                              fillColor: const Color.fromRGBO(
                                255,
                                255,
                                255,
                                0.9,
                              ),
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
                                style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.04),
                          Padding(
                            padding: EdgeInsets.only(
                              right: screenSize.width * 0.02,
                            ),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: filteredResults.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(screenSize.width * 0.05),
                                  child: Text(
                                    'لا توجد نتائج مطابقة',
                                    style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                        fontWeight: FontWeight.w900,
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
                                  final snippetInfo = Methods.getSnippet(
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
                                        ref
                                            .watch(
                                              Hadith_Details_Helper_provider
                                                  .notifier,
                                            )
                                            .state = ref
                                                .read(searchControllerProvider)
                                                .text;
                                        ref.read(searchControllerProvider).text = '';
                                        ref
                                            .read(filteredResultsProvider.notifier)
                                            .state = [];
                                        ref
                                            .read(selectedHadithProvider.notifier)
                                            .state = hadith;
                                        ref.read(navigationProvider.notifier).changeTab(1);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                            255,
                                            255,
                                            255,
                                            .9,
                                          ),
                                          borderRadius: BorderRadius.circular(55),
                                          border: Border.all(
                                            color: const Color(0xffe6a345),
                                            width: 3,
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
                                            buildResultTitle(
                                              hadith,
                                              isLandscape,
                                              screenSize.width,
                                            ),
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
    final double fontSize = isLandscape ? screenWidth * 0.012 : 12;
    final normalStyle = GoogleFonts.cairo(
      color: const Color(0xff513c2e),
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
    );
    final highlightStyle = GoogleFonts.cairo(
      color: AppTheme.redBlackColer,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );

    // Helper: remove English letters only (a-zA-Z)
    String removeEnglishLetters(String s) {
      return s.replaceAll(RegExp(r'[a-zA-Z]'), '');
    }

    List<TextSpan> spans = [];
    if (start >= 0 && end <= text.length) {
      if (start > 0) {
        spans.add(TextSpan(
          text: removeEnglishLetters(text.substring(0, start)),
          style: normalStyle,
        ));
      }
      spans.add(TextSpan(
        text: removeEnglishLetters(text.substring(start, end)),
        style: highlightStyle,
      ));
      if (end < text.length) {
        spans.add(TextSpan(
          text: removeEnglishLetters(text.substring(end)),
          style: normalStyle,
        ));
      }
    } else {
      spans.add(TextSpan(
        text: removeEnglishLetters(text),
        style: normalStyle,
      ));
    }
    return spans;
  }
}