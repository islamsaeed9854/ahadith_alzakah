import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/search_card.dart';
import '../core/constants.dart';
final searchControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final searchResultsProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {
      'title': 'بوجود الإحطاء سيريًا ما',
      'content': 'صنعت بين بالولون واجتماعية حول أربعين بيئياً',
    },
    {
      'title': 'التأثيرات البيئية الحديثة',
      'content': 'دراسة حول التغيرات المناخية وتأثيرها على المجتمعات',
    },
    {
      'title': 'الإحطاء في العصر الحديث',
      'content': 'تحليل اجتماعي للتحديات البيئية في المدن الكبرى',
    },
  ];
});

final filteredResultsProvider = StateProvider<List<Map<String, String>>>((ref) {
  final allResults = ref.watch(searchResultsProvider);
  return List.from(allResults);
});

final filterSearchProvider = Provider((ref) {
  final controller = ref.watch(searchControllerProvider);
  final results = ref.watch(searchResultsProvider);
  return (String query) {
    final lowerQuery = query.trim().toLowerCase();
    final filtered = lowerQuery.isEmpty
        ? List<Map<String, String>>.from(results)
        : results.where((result) {
            final title = result['title']!.toLowerCase();
            final content = result['content']!.toLowerCase();
            return title.contains(lowerQuery) ||
                content.contains(lowerQuery);
          }).toList();
    ref.read(filteredResultsProvider.notifier).state = filtered;
  };
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final controller = ref.watch(searchControllerProvider);
    final filteredResults = ref.watch(filteredResultsProvider);

    // Initialize filtering on text change
    ref.listen(searchControllerProvider, (prev, next) {
      ref.read(filterSearchProvider)(next.text);
    });
  
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/opening-screen02.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              children: [
                // العنوان وزر الرجوع
                SizedBox(height: screenHeight * 0.04),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'البحث',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.09,
                          color: const Color(0xfffcead0),
                          shadows: [
                            Shadow(
                              blurRadius: screenWidth * 0.03,
                              color: const Color(0xfffcead0),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: TextApp.backButton(ref),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                // شريط البحث
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: screenWidth * 0.01,
                        offset: Offset(0, screenWidth * 0.005),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'ابحث هنا...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.04,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                      suffixIcon: const Icon(
                        Icons.search,
                        color: Color(0xff912929),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                // نتائج البحث
                filteredResults.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: Text(
                          'لا توجد نتائج مطابقة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      )
                    : Column(
                        children: filteredResults.map((result) {
                          return Column(
                            children: [
                              SearchCard(
                                context,
                                title: result['title']!,
                                content: result['content']!,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                            ],
                          );
                        }).toList(),
                      ),
                SizedBox(height: screenHeight * 0.03),
                Center(child: TextApp.drSamyKhalilName),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
