import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';

class ChapterCard extends StatelessWidget {
  final String title;
  final String text;
  final bool isLandscape;
  final VoidCallback? onTap;
  final bool isExpanded;

  const ChapterCard({
    super.key,
    required this.title,
    required this.text,
    required this.isLandscape,
    this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 30),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, .8),
              borderRadius: BorderRadius.circular(33),
              border: Border.all(
                color: const Color(0xffe6a345),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          title,
                          style: ArabicTextStyle(
                            arabicFont: ArabicFont.cairo,
                            fontSize: isLandscape ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xffe6a345),
                          ),
                        ),
                      ),
                      //const SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          text,
                          style: ArabicTextStyle(
                            arabicFont: ArabicFont.aalooBhaijaan,
                            fontSize: isLandscape ? 16 : 14,
                            color: Colors.black87,
                          ),
                          maxLines: isLandscape ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}