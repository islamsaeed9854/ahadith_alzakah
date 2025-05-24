import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/chapters_screen.dart'; // لاستخدام numberToArabicText

class HadithDetails extends ConsumerWidget {
  const HadithDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = ref.watch(themeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = ref.watch(fontSizeProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final selectedHadith = ref.watch(selectedHadithProvider); // جلب الحديث المختار

    // التحقق من وجود حديث مختار
    if (selectedHadith == null) {
      return Scaffold(
        body: Center(child: Text('لم يتم اختيار حديث')),
      );
    }

    // دالة لتحويل الأرقام إلى نصوص عربية (يمكن نقلها إلى ملف مشترك)
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
      return number.toString();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: theme,
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Row
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
                                'الباب ${numberToArabicText(selectedHadith.bab)}: ${selectedHadith.bab == 3 ? "باب رقم 3" : "فرض الزكاة وفضلها"}', // يمكن تحديثه ديناميكيًا
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'الفصل ${numberToArabicText(selectedHadith.fasl)}: قسم رقم ${selectedHadith.fasl} | حديث رقم: ${selectedHadith.number}',
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
                          onPressed: () => navNotifier.changeTab(0),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Hadith Text Section
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.00,
                    ),
                    height: screenHeight * 0.4,
                    padding: EdgeInsets.all(screenWidth * 0.01),
                    child: SingleChildScrollView(
                      child: Text(
                        selectedHadith.text,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: fontSize.toDouble(),
                          height: 1.8,
                        ),
                      ),
                    ),
                  ),

                  // TabBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
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

                  // TabBarView
                  Container(
                    height: screenHeight * 0.5,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                    ),
                    child: TabBarView(
                      children: [
                        TabContent(
                          text: selectedHadith.summary,
                          isDark: isDark,
                        ),
                        TabContent(
                          text: selectedHadith.reference,
                          isDark: isDark,
                        ),
                        TabContent(
                          text: selectedHadith.analysis,
                          isDark: isDark,
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
    );
  }
}

class TabContent extends ConsumerWidget {
  final String text;
  final bool isDark;

  const TabContent({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Text(
          text.trim(),
         textAlign: TextAlign.justify,
          style: TextStyle(
            color: isDark ? Color(0xffd6c9b3) : const Color(0xffa37635),
            fontSize: fontSize.toDouble(),
            height: 1.8,
          ),
        ),
      ),
    );
  }
}