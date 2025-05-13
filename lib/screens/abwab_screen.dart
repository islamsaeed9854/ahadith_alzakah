import 'package:arabic_font/arabic_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/navigation_provider.dart';
import 'chapters_screen.dart';

class BooksScreen extends ConsumerWidget {
  final List<Map<String, String>> cards = List.generate(
    6,
    (_) => {'title': 'الباب الأول', 'text': 'فرض الزكاة وفضلها'},
  );

  BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final double baseFontSize = size.width * 0.04;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double paddingHorizontal = constraints.maxWidth < 600 ? 12 : 24;
          final double gridMaxWidth =
              isLandscape
                  ? constraints.maxWidth / 3.2
                  : constraints.maxWidth / 2.2;
          final double cardHeight =
              isLandscape
                  ? constraints.maxHeight * 0.55
                  : constraints.maxHeight * 0.16;
          final double cardWidth =
              isLandscape
                  ? constraints.maxWidth / 3.5
                  : constraints.maxWidth / 2.5;

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
                              fontSize:
                                  baseFontSize * (isLandscape ? 1.1 : 1.2),
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
                              fontSize:
                                  baseFontSize * (isLandscape ? 1.1 : 1.2),
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
                              ref
                                  .read(navigationProvider.notifier)
                                  .changeTab(2);
                            },
                            child: Container(
                              width: constraints.maxWidth * 0.85,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
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
                            itemCount: cards.length,
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: gridMaxWidth,
                                  crossAxisSpacing: 76,
                                  mainAxisSpacing: 30,
                                  childAspectRatio:
                                      isLandscape
                                          ? 1
                                          : cardWidth / (cardHeight * 0.8),
                                  mainAxisExtent: cardHeight,
                                ),
                            itemBuilder: (context, index) {
                              return buildBabCard(
                                context,
                                ref,
                                cards[index]['title']!,
                                cards[index]['text']!,
                                isLandscape,
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 12),
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
) {
  return GestureDetector(
    onTap: () {
      ref.read(innerBooksScreenProvider.notifier).state = ChaptersScreen();
    },
    child: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color.fromRGBO(255, 255, 255, .8),
          border: Border.all(color: const Color(0xffe6a345), width: 3),
        ),
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 16 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: ArabicTextStyle(
                  arabicFont: ArabicFont.reemKufi,
                  fontSize: isLandscape ? 26 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffe6a345),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: true,
                maxLines: null,
                style: ArabicTextStyle(
                  arabicFont: ArabicFont.reemKufi,
                  fontSize: isLandscape ? 22 : 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
