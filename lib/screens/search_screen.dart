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
  final allResults = ref.watch(searchResultsProvider);
  return List.from(allResults);
});

final filterSearchProvider = Provider((ref) {
  final results = ref.watch(searchResultsProvider);
  return (String query) {
    final lowerQuery = query.trim().toLowerCase();
    final filtered =
        lowerQuery.isEmpty
            ? List<Map<String, String>>.from(results)
            : results.where((result) {
              final title = result['title']!.toLowerCase();
              final content = result['content']!.toLowerCase();
              return title.contains(lowerQuery) || content.contains(lowerQuery);
            }).toList();
    ref.read(filteredResultsProvider.notifier).state = filtered;
  };
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late FocusNode searchFocusNode;

  @override
  void initState() {
    super.initState();
    searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocusNode);
    });
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final controller = ref.watch(searchControllerProvider);
    final filteredResults = ref.watch(filteredResultsProvider);

    // الكشف عن ارتفاع لوحة المفاتيح
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // تأكد من أنها false
        body: Stack(
          children: [
            Image(
              image: TextApp.appBackgroundImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height:
                  screenHeight -
                  keyboardHeight, // تعديل الارتفاع بناءً على لوحة المفاتيح
              color: Colors.black26,
              colorBlendMode: BlendMode.darken,
            ),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.04),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
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
                        textAlign: TextAlign.left,
                      ),
                      TextApp.backButton(ref),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.0),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(158, 158, 158, 0.2),
                          blurRadius: screenWidth * 0.01,
                          offset: Offset(0, screenWidth * 0.005),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: searchFocusNode,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'اكتب هنا...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: screenWidth * 0.04,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(55.0),
                          borderSide: BorderSide(
                            color: Color(0xffe2b97f),
                            width: 4.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(55.0),
                          borderSide: BorderSide(
                            color: Color(0xffe2b97f),
                            width: 4.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Color(0xfff8f0e3),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.015,
                        ),
                        suffixIcon: const Icon(
                          Icons.search,
                          color: Color(0xff977c55),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(filterSearchProvider)(controller.text);
                        FocusScope.of(context).unfocus(); // يخفي الكيبورد
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF937848),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(55),
                        ),
                      ),
                      child: Text(
                        'بحث',
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.02),
                    child: Text(
                      'نتائج البحث',
                      style: GoogleFonts.cairo(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
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
                        children:
                            filteredResults.map((result) {
                              return Column(
                                children: [
                                  searchCard(
                                    context,
                                    title: result['title']!,
                                    content: result['content']!,
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                ],
                              );
                            }).toList(),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
