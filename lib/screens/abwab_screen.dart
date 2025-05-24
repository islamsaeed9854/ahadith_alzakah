import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/navigation_provider.dart';
import 'chapters_screen.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';

class BooksScreen extends ConsumerWidget {
  BooksScreen({super.key});
  String numberToArabicText(int number) {
  const List<String> ones = [
    '', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع'
  ];
  const List<String> tens = [
    '', '', 'العشرون', 'الثلاثون', 'الأربعون', 'الخمسون', 'الستون', 'السبعون', 'الثمانون', 'التسعون'
  ];
  const List<String> teens = [
    'العاشر', 'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر', 'السادس عشر',
    'السابع عشر', 'الثامن عشر', 'التاسع عشر'
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
  return number.toString(); // للأرقام الأكبر من 99، يمكن توسيع الدالة لاحقًا
}
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadithState = ref.watch(DataProvider);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final double baseFontSize = size.width * 0.04;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double paddingHorizontal = constraints.maxWidth < 600 ? 35 : 60;
          final double gridMaxWidth = isLandscape ? constraints.maxWidth / 3 : constraints.maxWidth / 2;

          return hadithState.when(
            data: (hadiths) {
              // تجميع الأحاديث حسب الباب (chapter_number)
              final chaptersMap = <int, Map<String, dynamic>>{};
              for (final hadith in hadiths) {
                if (!hadith.deleted) {
                  if (!chaptersMap.containsKey(hadith.bab)) {
                    chaptersMap[hadith.bab] = {
                      'chapter_number': hadith.bab,
                      'chapter_title': 'باب رقم ${hadith.bab}', // سيتم تحديثه لاحقًا إذا كان لديك chapter_title
                    };
                  }
                }
              }

              final dynamicChapters = chaptersMap.entries.map((entry) => entry.value).toList()
                ..sort((a, b) => (a['chapter_number'] as int).compareTo(b['chapter_number'] as int));

              return Stack(
                fit: StackFit.expand,
                children: [
                  TextApp.appBackgroundWidget,
                  Container(color: const Color.fromRGBO(0, 0, 0, 0.15)),
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: paddingHorizontal,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: isLandscape ? 6 : 12),
                              Text(
                                "موسوعة",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: baseFontSize * (isLandscape ? 1.1 : 2),
                                  color: const Color(0xfffcead0),
                                  shadows: [
                                    Shadow(
                                      blurRadius: 6,
                                      color: const Color.fromRGBO(0, 0, 0, 0.3),
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "أحاديث الزكاة",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: baseFontSize * (isLandscape ? 1.1 : 2),
                                  color: const Color(0xfffcead0),
                                  shadows: [
                                    Shadow(
                                      blurRadius: 6,
                                      color: const Color.fromRGBO(0, 0, 0, 0.3),
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isLandscape ? 8 : 16),
                              GestureDetector(
                                onTap: () {
                                  ref.read(navigationProvider.notifier).changeTab(2);
                                },
                                child: Container(
                                  width: constraints.maxWidth * 0.85,
                                  margin: const EdgeInsets.symmetric(vertical: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: .02,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(255, 255, 255, 0.9),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      width: 1,
                                      color: const Color(0xffe6a345),
                                    ),
                                  ),
                                  child: TextField(
                                    enabled: false,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      hintText: 'البحث عن حديث...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: baseFontSize * 0.85,
                                      ),
                                      border: InputBorder.none,
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: const Color(0xffe6a345),
                                        size: baseFontSize * 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isLandscape ? 8 : 16),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dynamicChapters.length,
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: gridMaxWidth,
                                  crossAxisSpacing: isLandscape ? 68 : 77,
                                  mainAxisSpacing: isLandscape ? 33 : 55,
                                  childAspectRatio: isLandscape ? 1.4 : 1.2,
                                ),
                                itemBuilder: (context, index) {
                                  final chapter = dynamicChapters[index];
                                  return buildBabCard(
                                    context,
                                    ref,
                                    'الباب ${numberToArabicText(chapter['chapter_number'] as int)}',
                                    chapter['chapter_title'] as String,
                                    isLandscape,
                                    chapter['chapter_number'] as int,
                                  );
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 20, bottom: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('خطأ: $error')),
          );
        },
      ),
    );
  }
}

Widget buildBabCard(
  BuildContext context,
  WidgetRef ref,
  String title,
  String text,
  bool isLandscape,
  int chapterNumber, // إضافة chapterNumber لتمريره إلى ChaptersScreen
) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: GestureDetector(
      onTap: () {
        // تمرير رقم الباب إلى ChaptersScreen
        ref.read(innerBooksScreenProvider.notifier).state = ChaptersScreen(chapterNumber: chapterNumber);
      },
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color.fromRGBO(255, 255, 255, 0.8),
                border: Border.all(color: const Color(0xffe6a345), width: 3),
              ),
              padding: EdgeInsets.all(isLandscape ? 8 : 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: ArabicTextStyle(
                      arabicFont: ArabicFont.amiri,
                      fontSize: isLandscape ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffe6a345),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: ArabicTextStyle(
                      arabicFont: ArabicFont.amiri,
                      fontSize: isLandscape ? 20 : 16,
                      color: Colors.black87,
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