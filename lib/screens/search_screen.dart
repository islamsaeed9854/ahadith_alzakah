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
import 'package:arabic_font/arabic_font.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final filteredResults = ref.watch(filteredResultsProvider);
    final displayCount = ref.watch(displayCountProvider);
    final batchLoading = ref.watch(batchLoadingProvider);
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
    final loadMore = ref.read(loadMoreProvider);

    final ScrollController _scrollController = ScrollController();

   
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
       
        if (displayCount < filteredResults.length && !batchLoading) {
          loadMore();
        }
      }
    });

    void performSearch() {
      if (controller.text.trim().isEmpty) return;
      
      try {
        
        FocusScope.of(context).unfocus();
        
       
        ref.read(filteredResultsProvider.notifier).state = [];
        ref.read(displayCountProvider.notifier).state = 20;
        
        final searchStateNotifier = ref.read(searchStateProvider.notifier);
        searchStateNotifier.stopSearch();
        searchStateNotifier.setIsSearching(true);
        
        final operation = CancelableOperation.fromFuture(
          Future(() async {
            await filterSearch(controller.text, context);
            
            if (context.mounted) {
            
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0.0,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
            
            searchStateNotifier.setIsSearching(false);
          }),
        );
        
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
      body: SafeArea(
        child: Container(
          height: screenSize.height,
          child: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // جانب البحث
                    Flexible(
                      flex: 1,
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
                              width: double.infinity,
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
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: horizontalPadding,
                          left: horizontalPadding / 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  top: screenSize.height * 0.01,
                                  bottom: screenSize.height * 0.01),
                              child: Row(
                                children: [
                                  Text(
                                    'نتائج البحث',
                                    style: GoogleFonts.cairo(
                                      fontSize: sectionTitleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (filteredResults.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Text(
                                        '(${displayCount}/${filteredResults.length})',
                                        style: GoogleFonts.cairo(
                                          fontSize: sectionTitleFontSize * 0.8,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _buildResultsList(
                                filteredResults,
                                displayCount,
                                _scrollController,
                                screenSize,
                                isLandscape,
                                ref,
                                batchLoading,
                                emptyResultsFontSize,
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
                    // قسم البحث
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
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
                                style: ArabicTextStyle(
                                  arabicFont: ArabicFont.avenirArabic,
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
                    // قسم النتائج
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final searchState = ref.watch(searchStateProvider);
                            return searchState.isSearching
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: isLandscape ? screenSize.width * 0.06 : 60,
                                          height: isLandscape ? screenSize.width * 0.06 : 60,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffe6a345)),
                                            strokeWidth: 6,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'جاري البحث...',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: emptyResultsFontSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            top: screenSize.height * 0.01,
                                            bottom: screenSize.height * 0.01),
                                        child: Row(
                                          children: [
                                            Text(
                                              'نتائج البحث',
                                              style: GoogleFonts.cairo(
                                                fontSize: sectionTitleFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            // if (filteredResults.isNotEmpty)
                                            //   Padding(
                                            //     padding: EdgeInsets.only(right: 8),
                                            //     child: Text(
                                            //       '(${displayCount}/${filteredResults.length})',
                                            //       style: GoogleFonts.cairo(
                                            //         fontSize: sectionTitleFontSize * 0.8,
                                            //         color: Colors.white70,
                                            //       ),
                                            //     ),
                                            //   ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildResultsList(
                                          filteredResults,
                                          displayCount,
                                          _scrollController,
                                          screenSize,
                                          isLandscape,
                                          ref,
                                          batchLoading,
                                          emptyResultsFontSize,
                                        ),
                                      ),
                                    ],
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

  Widget _buildResultsList(
    List<Map<String, dynamic>> filteredResults,
    int displayCount,
    ScrollController scrollController,
    Size screenSize,
    bool isLandscape,
    WidgetRef ref,
    bool batchLoading,
    double emptyResultsFontSize,
  ) {
    if (filteredResults.isEmpty) {
      return Center(
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
      );
    }

    final displayedResults = filteredResults.take(displayCount).toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification &&
            scrollNotification.metrics.pixels >=
                scrollNotification.metrics.maxScrollExtent - 200) {
          // عند الاقتراب من نهاية القائمة، زد عدد النتائج المعروضة تدريجيًا
          if (displayCount < filteredResults.length && !batchLoading) {
            Future.delayed(const Duration(milliseconds: 100), () {
              ref.read(displayCountProvider.notifier).state =
                  (displayCount + 20).clamp(0, filteredResults.length);
            });
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.only(bottom: 80),
        itemCount: displayedResults.length + (batchLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayedResults.length) {
            return Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xffe6a345)),
                    strokeWidth: 3,
                  ),
                ),
              ),
            );
          }

          final result = displayedResults[index];
          final hadith = result['hadith'] as Hadith;
          final snippet = result['snippet'] as String;
          final searchWords = result['searchWords'] as List<String>;

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
                    buildResultSnippet(
                      snippet: snippet,
                      searchWords: searchWords,
                      isLandscape: isLandscape,
                      screenWidth: screenSize.width,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}