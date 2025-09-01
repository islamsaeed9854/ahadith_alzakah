import 'package:ahadith_alzakah/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/hadith.dart';
import '../providers/navigation_provider.dart';
import '../core/theme.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import '../widgets/chpter_card.dart';
import '../core/methods.dart';

final expandedSectionProvider = StateProvider<int?>((ref) => null);
final selectedHadithProvider = StateProvider<Hadith?>((ref) => null);

// ====== دوال مساعدة للتصميم المتجاوب ======

// تحديد عرض المحتوى الرئيسي بناءً على عرض الشاشة
double getContentWidth(double screenWidth) {
  if (screenWidth > 1800) return 1100; // Extra Large
  if (screenWidth > 1200) return 950;  // Large
  if (screenWidth > 600) return 700;   // Medium
  return screenWidth * 0.9; // Small screens (90% of width)
}

// تحديد حجم الخط للعناوين الرئيسية
double getTitleFontSize(double screenWidth) {
  if (screenWidth > 1800) return 32.0;
  if (screenWidth > 1200) return 30.0;
  if (screenWidth > 600) return 28.0;
  return 25.0;
}

// تحديد الهامش الأفقي لقائمة الأحاديث المنسدلة
double getDetailsHorizontalMargin(double screenWidth) {
  if (screenWidth > 600) return 40.0;
  return 20.0;
}

// ===========================================

class ChaptersScreen extends ConsumerStatefulWidget {
  final int? chapterNumber;
  const ChaptersScreen({super.key, this.chapterNumber});

  @override
  ConsumerState<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends ConsumerState<ChaptersScreen> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _sectionKeys = [];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String maskEnglishLetters(String text) {
    text = text.replaceAllMapped(RegExp(r'\[(\d+)\]'), (match) => '⟨${match.group(1)}⟩');
    text = text.replaceAll(RegExp(r'[XO]'), '');
    text = text.replaceAll('⟨', '[').replaceAll('⟩', ']');
    return text;
  }

  void _scrollToSelectedSection(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sectionKeys.isNotEmpty && index < _sectionKeys.length && _sectionKeys[index].currentContext != null) {
        Scrollable.ensureVisible(
          _sectionKeys[index].currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hadithState = ref.watch(DataProvider);
    final expandedSection = ref.watch(expandedSectionProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          // استخدام الدوال المساعدة للحصول على القيم المتجاوبة
          final double contentWidth = getContentWidth(screenWidth);
          final double titleFontSize = getTitleFontSize(screenWidth);
          final double detailsMargin = getDetailsHorizontalMargin(screenWidth);

          return hadithState.when(
            data: (hadiths) {
              final chaptersMap = <int, Map<String, dynamic>>{};
              for (final hadith in hadiths) {
                if (!hadith.deleted &&
                    (widget.chapterNumber == null ||
                        hadith.bab == widget.chapterNumber)) {
                  if (!chaptersMap.containsKey(hadith.bab)) {
                    chaptersMap[hadith.bab] = {
                      'chapter_number': hadith.bab,
                      'chapter_title': hadith.chapter_title ?? 'باب رقم ${hadith.bab}',
                      'sections': <int, Map<String, dynamic>>{},
                    };
                  }
                  final chapter = chaptersMap[hadith.bab]!;
                  final sections = chapter['sections'] as Map<int, Map<String, dynamic>>;
                  if (!sections.containsKey(hadith.fasl)) {
                    sections[hadith.fasl] = {
                      'section_number': hadith.fasl,
                      'section_title': '${hadith.section_title}',
                      'ahadith': <Hadith>[],
                    };
                  }
                  final section = sections[hadith.fasl]!;
                  (section['ahadith'] as List<Hadith>).add(hadith);
                }
              }

              final dynamicChapters = chaptersMap.entries.map((entry) {
                final chapter = entry.value;
                final sections = (chapter['sections'] as Map<int, Map<String, dynamic>>)
                    .entries
                    .map((sectionEntry) => sectionEntry.value)
                    .toList()
                  ..sort((a, b) => (a['section_number'] as int)
                      .compareTo(b['section_number'] as int));
                chapter['sections'] = sections;
                return chapter;
              }).toList()
                ..sort((a, b) => (a['chapter_number'] as int)
                    .compareTo(b['chapter_number'] as int));

              final allSections = dynamicChapters
                  .expand((chapter) => chapter['sections'] as List)
                  .toList();

              if (_sectionKeys.length != allSections.length) {
                _sectionKeys =
                    List.generate(allSections.length, (_) => GlobalKey());
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  TextApp.appBackgroundWidget,
                  SafeArea(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        // توسيط المحتوى وتحديد عرضه
                        child: Center(
                          child: SizedBox(
                            width: contentWidth,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(width: 48),
                                    Expanded(
                                      child: Text(
                                        dynamicChapters.isNotEmpty
                                            ? 'الباب ${Methods.numberToArabicText(dynamicChapters[0]['chapter_number'] as int)}'
                                            : 'الباب الأول',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: titleFontSize, // حجم خط متجاوب
                                          color: const Color(0xfffcead0),
                                          shadows: [
                                            const Shadow(
                                              blurRadius: 10,
                                              color: Color.fromRGBO(0, 0, 0, 0.3),
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_forward,
                                        color: AppTheme.secodaryColor,
                                      ),
                                      onPressed: () => ref
                                          .read(innerBooksScreenProvider.notifier)
                                          .state = null,
                                    ),
                                  ],
                                ),
                                Text(
                                  dynamicChapters.isNotEmpty
                                      ? dynamicChapters[0]['chapter_title'] as String
                                      : "فرض الزكاة وفضلها",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleFontSize, // حجم خط متجاوب
                                    color: const Color(0xfffcead0),
                                    shadows: [
                                      const Shadow(
                                        blurRadius: 10,
                                        color: Color.fromRGBO(0, 0, 0, 0.3),
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: allSections.length,
                                  itemBuilder: (context, index) {
                                    final section = allSections[index];
                                    final isExpanded = expandedSection == index;
                                    return Column(
                                      key: _sectionKeys[index],
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: ChapterCard(
                                            title: 'الفصل ${Methods.numberToArabicText(section['section_number'] as int)}',
                                            text: section['section_title'] as String,
                                            screenWidth: screenWidth, // تمرير عرض الشاشة
                                            isExpanded: isExpanded,
                                            onTap: () {
                                              if (isExpanded) {
                                                ref.read(expandedSectionProvider.notifier).state = null;
                                              } else {
                                                ref.read(expandedSectionProvider.notifier).state = index;
                                                _scrollToSelectedSection(index);
                                              }
                                            },
                                          ),
                                        ),
                                        if (isExpanded)
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            margin: EdgeInsets.only(
                                              bottom: 16,
                                              right: detailsMargin, // هامش متجاوب
                                              left: detailsMargin, // هامش متجاوب
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(255, 255, 255, 0.9),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: AppTheme.primaryColor,
                                                width: 3.5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Directionality(
                                              textDirection: TextDirection.rtl,
                                              child: ListView.separated(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: (section['ahadith'] as List<Hadith>).length,
                                                separatorBuilder: (context, index) => const Divider(
                                                  height: 1,
                                                  thickness: 0.5,
                                                  color: Color.fromRGBO(230, 163, 69, 0.3),
                                                  indent: 16,
                                                  endIndent: 16,
                                                ),
                                                itemBuilder: (context, hadithIndex) {
                                                  final hadith = (section['ahadith'] as List<Hadith>)[hadithIndex];
                                                  return ListTile(
                                                    dense: true,
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 4,
                                                    ),
                                                    title: Text(
                                                      'الحديث ${hadith.number}',
                                                      style: const ArabicTextStyle(
                                                        arabicFont: ArabicFont.reemKufi,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xff912929),
                                                      ),
                                                    ),
                                                    subtitle: Padding(
                                                      padding: const EdgeInsets.only(top: 2.0),
                                                      child: Text(
                                                        hadith.text.length > 150
                                                            ? '${maskEnglishLetters(hadith.text.trim()).substring(0, 150)}...'
                                                            : '${maskEnglishLetters(hadith.text.trim())}...',
                                                        style: const ArabicTextStyle(
                                                          arabicFont: ArabicFont.avenirArabic,
                                                          fontSize: 14,
                                                          color: Colors.black54,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    trailing: const Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16,
                                                      color: Color(0xffe6a345),
                                                    ),
                                                    onTap: () {
                                                      ref.read(selectedHadithProvider.notifier).state = hadith;
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
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('خطأ: $error')),
          );
        },
      ),
    );
  }
}