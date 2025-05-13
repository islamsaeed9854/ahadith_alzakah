import 'package:ahadith_alzakah/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';
import '../widgets/chpter_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/hadith.dart';
import '../providers/navigation_provider.dart';

// Provider to track expanded chapters
final expandedChapterProvider = StateProvider<int?>((ref) => null);

class ChaptersScreen extends ConsumerWidget {
  final List<Map<String, String>> chapters = List.generate(
    10,
    (index) => {
      'title': 'الفصل ${index + 1}',
      'text': "اسم الفصل سوف يكتب هنا",
    },
  );

  // Sample ahadith for demonstration
  final List<List<Hadith>> chapterAhadith = List.generate(
    10,
    (chapterIndex) => List.generate(
      5, // 5 ahadith per chapter
      (hadithIndex) => Hadith(
        hadithBook: 1,
        hadithFasl: chapterIndex + 1,
        hadithNumber: hadithIndex + 1,
        nameHadith: 'حديث ${hadithIndex + 1}',
        textHadith: 'نص الحديث ${hadithIndex + 1} للفصل ${chapterIndex + 1}',
        explanationHadith: 'شرح الحديث',
        translateNarrator: 'الراوي',
        ta5reegHadith: 'تخريج الحديث',
      ),
    ),
  );

  ChaptersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedChapter = ref.watch(expandedChapterProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              TextApp.appBackgroundWidget,
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 600 ? 20 : 40,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "الباب 1",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: const Color(0xfffcead0),
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: const Color.fromRGBO(0, 0, 0, 0.3),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "فرض الزكاة وفضلها",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: Color(0xfffcead0),
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: const Color.fromRGBO(0, 0, 0, 0.3),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chapters.length,
                          itemBuilder: (context, index) {
                            final isExpanded = expandedChapter == index;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ChapterCard(
                                    title: chapters[index]['title']!,
                                    text: chapters[index]['text']!,
                                    isLandscape: isLandscape,
                                    isExpanded: isExpanded,
                                    onTap: () {
                                      // Toggle expansion
                                      if (isExpanded) {
                                        ref
                                            .read(
                                              expandedChapterProvider.notifier,
                                            )
                                            .state = null;
                                      } else {
                                        ref
                                            .read(
                                              expandedChapterProvider.notifier,
                                            )
                                            .state = index;
                                      }
                                    },
                                  ),
                                ),
                                // Show ahadith if chapter is expanded
                                if (isExpanded)
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    margin: EdgeInsets.only(
                                      bottom: 16,
                                      right: 40,
                                      left: 40,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        255,
                                        255,
                                        255,
                                        0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color.fromRGBO(
                                          230,
                                          163,
                                          69,
                                          0.5,
                                        ),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color.fromRGBO(
                                            0,
                                            0,
                                            0,
                                            0.1,
                                          ),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: chapterAhadith[index].length,
                                        separatorBuilder:
                                            (context, i) => Divider(
                                              color: const Color.fromRGBO(
                                                230,
                                                163,
                                                69,
                                                0.3,
                                              ),
                                              height: 1,
                                              indent: 20,
                                              endIndent: 20,
                                            ),
                                        itemBuilder: (context, hadithIndex) {
                                          final hadith =
                                              chapterAhadith[index][hadithIndex];
                                          return ListTile(
                                            title: Text(
                                              hadith.nameHadith,
                                              style: ArabicTextStyle(
                                                arabicFont: ArabicFont.reemKufi,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff912929),
                                              ),
                                            ),
                                            subtitle: Text(
                                              hadith.textHadith.length > 50
                                                  ? '${hadith.textHadith.substring(0, 50)}...'
                                                  : hadith.textHadith,
                                              style: ArabicTextStyle(
                                                arabicFont: ArabicFont.reemKufi,
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: const Color(0xffe6a345),
                                            ),
                                            onTap: () {
                                              navNotifier.changeTab(1);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
