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
      'title': 'فرض الزكاة وفضلها',
      'content':
          'وجوب الزكاة: حديث: «١ فقيه» عمران، وقال الرجل: أوجبتني في كل أربعين درهمًا',
    },
    {
      'title': 'أهمية الصلاة',
      'content': 'الصلاة عماد الدين من أقامها فقد أقام الدين',
    },
  ];
});

final filteredResultsProvider = StateProvider<List<Map<String, String>>>((ref) {
  return ref.watch(searchResultsProvider);
});

final filterSearchProvider = Provider((ref) {
  return (String query) {
    final results = ref.read(searchResultsProvider);
    final lowerQuery = query.trim().toLowerCase();

    final filtered =
        lowerQuery.isEmpty
            ? results
            : results.where((result) {
              final title = result['title']!.toLowerCase();
              final content = result['content']!.toLowerCase();
              return title.contains(lowerQuery) || content.contains(lowerQuery);
            }).toList();

    ref.read(filteredResultsProvider.notifier).state = filtered;
  };
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final filteredResults = ref.watch(filteredResultsProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final controller = ref.watch(searchControllerProvider);
    final filterSearch = ref.read(filterSearchProvider);

    void performSearch() {
      filterSearch(controller.text);
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

              // Search Field
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
                  fillColor: const Color(0xfffcead0),
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

              // Search Button
              Center(
                child: ElevatedButton(
                  onPressed: performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF937848),
                    padding: EdgeInsets.symmetric(
                      vertical: screenSize.height * 0.018,
                      horizontal: screenSize.width * 0.15,
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

              // Results List
              SizedBox(
                height: screenSize.height * 0.4,
                child:
                    filteredResults.isEmpty
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
                            bottom:
                                keyboardHeight > 0 ? keyboardHeight + 20 : 20,
                          ),
                          itemCount: filteredResults.length,
                          itemBuilder: (context, index) {
                            final result = filteredResults[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: screenSize.height * 0.02,
                              ),
                              child: searchCard(
                                context,
                                title: result['title']!,
                                content: result['content']!,
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
}
