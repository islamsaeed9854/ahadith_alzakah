import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';

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
                                'الباب الأول: فرض الزكاة وفضلها',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'الفصل الأول: وجوب الزكاة | حديث رقم: 1',
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

                  // Hadith Text Section (Made Larger)
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.00,
                    ),
                    height: screenHeight * 0.4, // Increased from 0.3 to 0.4
                    padding: EdgeInsets.all(screenWidth * 0.01),
                    child: SingleChildScrollView(
                      child: Text(
                        'عن أبي هريرة رضي الله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الالله عنه قال: قال رسول الله صلى الله عليه وسلم: من آتى الزكاة طيبة بها نفسه فله أجرها...',
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
                    padding: const EdgeInsets.symmetric(horizontal: 2.0,vertical:1.0),
                    child: TabBar(
                      indicatorColor: const Color(0xFFb58d8d),
                      labelColor: isDark ? AppTheme.primaryColor : AppTheme.redBlackColer,
                      unselectedLabelColor: const Color(0xff977c55),
                      labelStyle: TextStyle(
                        fontSize: fontSize.toDouble() * 0.8,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: TextStyle(
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
                          text: 'الخلاصة: هذا الحديث يبين وجوب الزكاة وأهميتها في الإسلام...',
                          isDark: isDark,
                        ),
                        TabContent(
                          text: 'التخريج: أخرجه أبو داود في سننه برقم 1561، وصححه الألباني.',
                          isDark: isDark,
                        ),
                        TabContent(
                          text: 'الدراسة: الحديث يدل على عدالة توزيع المال...',
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
          text,
          textAlign: TextAlign.justify,
          style: GoogleFonts.cairo(
            color: isDark ? Color(0xffd6c9b3) : const Color(0xffa37635),
            fontSize: fontSize.toDouble(),
            height: 1.8,
          ),
        ),
      ),
    );
  }
}