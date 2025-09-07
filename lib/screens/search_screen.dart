import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/search_state_provider.dart';
import '../data/models/hadith.dart';
import '../providers/navigation_provider.dart';
import 'chapters_screen.dart';
import '../widgets/search_card.dart';
import '../providers/search_providers.dart';

// ======================= Responsive Breakpoints =======================
const double kMediumScreenBreakpoint = 700.0;
const double kLargeScreenBreakpoint = 1200.0;
const double kExtraLargeScreenBreakpoint = 1800.0;
// ========================================================================



double _getMaxContentWidth(double screenWidth) {
  if (screenWidth > kLargeScreenBreakpoint) return screenWidth * 0.7; // Large Desktop (70%)
  if (screenWidth > kMediumScreenBreakpoint) return 800;  // Medium / Tablet
  return screenWidth; // Small / Mobile (full width)
}


double _getResponsiveFontSize(double screenWidth, {
  required double small,
  required double medium,
  required double large,
  double? extraLarge,
}) {
  if (screenWidth > kExtraLargeScreenBreakpoint) return extraLarge ?? large * 1.1;
  if (screenWidth > kLargeScreenBreakpoint) return large;
  if (screenWidth > kMediumScreenBreakpoint) return medium;
  return small;
}


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasInitiatedSearch = false; 

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
  
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final filteredResults = ref.read(filteredResultsProvider);
      final displayCount = ref.read(displayCountProvider);
      final batchLoading = ref.read(batchLoadingProvider);

      if (displayCount < filteredResults.length && !batchLoading) {
        ref.read(loadMoreProvider)();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final controller = ref.read(searchControllerProvider);
    if (controller.text.trim().isEmpty) return;
    
    FocusScope.of(context).unfocus();

  
    if (!_hasInitiatedSearch) {
      setState(() {
        _hasInitiatedSearch = true;
      });
    }

 
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  

    ref.read(filterSearchProvider)(controller.text, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final contentWidth = _getMaxContentWidth(screenWidth);

          return SafeArea(
            child: Center(
              child: Container(
                width: contentWidth,
                padding: EdgeInsets.symmetric(
               
                  horizontal: screenWidth < kMediumScreenBreakpoint ? 20 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                   
                    _buildSearchControls(screenWidth),
                    const SizedBox(height: 16),
                
                    Expanded(
                      child: _buildResultsColumn(screenWidth),
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

  
  Widget _buildSearchControls(double screenWidth) {
    final searchState = ref.watch(searchStateProvider);
    final controller = ref.watch(searchControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'البحث',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: _getResponsiveFontSize(screenWidth, small: 30, medium: 34, large: 38, extraLarge: 42),
                  color: const Color(0xfffcead0),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextApp.backButton(ref)
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
          style: GoogleFonts.cairo(
            color: Colors.black,
            fontSize: _getResponsiveFontSize(screenWidth, small: 15, medium: 16, large: 17),
          ),
          decoration: InputDecoration(
            hintText: 'اكتب هنا للبحث في الأحاديث...',
            filled: true,
            fillColor: const Color.fromRGBO(255, 255, 255, 0.9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xffe6a345), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xffe6a345), width: 2.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xffe6a345), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: searchState.isSearching ? null : _performSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF937848),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(55)),
            elevation: 3,
          ),
          child: searchState.isSearching
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'بحث',
                  style: GoogleFonts.cairo(
                    fontSize: _getResponsiveFontSize(screenWidth, small: 18, medium: 20, large: 22),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
  
 
  Widget _buildResultsColumn(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
          child: Text(
            'نتائج البحث',
            style: GoogleFonts.cairo(
              fontSize: _getResponsiveFontSize(screenWidth, small: 22, medium: 24, large: 26),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(child: _buildResultsList(screenWidth)),
      ],
    );
  }

  
  Widget _buildResultsList(double screenWidth) {
    final searchState = ref.watch(searchStateProvider);
    final filteredResults = ref.watch(filteredResultsProvider);
    final displayCount = ref.watch(displayCountProvider);
    final batchLoading = ref.watch(batchLoadingProvider);

    if (searchState.isSearching && filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xffe6a345)),
                strokeWidth: 4),
            const SizedBox(height: 16),
            Text('جاري البحث...', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18)),
          ],
        ),
      );
    }

  
    if (!_hasInitiatedSearch) {
      return Center(
        child: Text(
          'أدخل كلمة للبحث عنها في الموسوعة',
          style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: _getResponsiveFontSize(screenWidth, small: 16, medium: 17, large: 18)),
        ),
      );
    }

    if (filteredResults.isEmpty) {
      return Center(
        child: Text(
          'لم يتم العثور على نتائج',
          style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: _getResponsiveFontSize(screenWidth, small: 16, medium: 17, large: 18)),
        ),
      );
    }

    final displayedResults = filteredResults.take(displayCount).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: displayedResults.length + (batchLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayedResults.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
                child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xffe6a345)),
                        strokeWidth: 3))),
          );
        }

        final result = displayedResults[index];
        final hadith = result['hadith'] as Hadith;
        final snippet = result['snippet'] as String;
        final searchWords = result['searchWords'] as List<String>;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () {
              ref.read(Hadith_Details_Helper_provider.notifier).state = ref.read(searchControllerProvider).text;
              ref.read(searchControllerProvider).text = '';
              ref.read(filteredResultsProvider.notifier).state = [];
              ref.read(selectedHadithProvider.notifier).state = hadith;
              ref.read(navigationProvider.notifier).changeTab(1);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, .9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffe6a345), width: 2.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildResultTitle(hadith, screenWidth),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 8),
                  buildResultSnippet(
                    snippet: snippet,
                    searchWords: searchWords,
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

