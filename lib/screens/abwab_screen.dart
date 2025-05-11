import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:arabic_font/arabic_font.dart';
import '../widgets/bab_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
class BooksScreen extends ConsumerWidget {
  final List<Map<String, String>> cards = List.generate(
    6,
    (_) => {'title': 'الباب الاول', 'text': 'فرض الزكاة و\nفضلها'},
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive calculations
          final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
          final double cardHeight =
              isLandscape
                  ? constraints.maxHeight * 0.25
                  : constraints.maxHeight * 0.15;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background SVG
              Image.asset(
                'assets/opening-screen02.png',
                fit: BoxFit.cover,
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth < 600 ? 20 : 40,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "موسوعة أحاديث الزكاة",
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
                          SizedBox(height: 13),
                          // Search Box
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                width: 1,
                                color: const Color(0xffe6a345),
                              ),
                            ),
                            child: TextField(
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'ابحث...',
                                hintStyle: ArabicTextStyle(
                                  arabicFont: ArabicFont.reemKufi,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: const Color(0xffe6a345),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          // Responsive Grid View
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cards.length,
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: isLandscape ? 400 : 300,
                                  crossAxisSpacing: 50,
                                  mainAxisSpacing: 15,
                                  childAspectRatio: isLandscape ? 1.5 : 0.9,
                                  mainAxisExtent:
                                      isLandscape ? null : cardHeight,
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

                          // Footer Text
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 10),
                            child: Center(child: TextApp.drSamyKhalilName),
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
