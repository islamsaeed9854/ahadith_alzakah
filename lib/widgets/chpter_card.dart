import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';

class ChapterCard extends StatelessWidget {
  final String title;
  final String text;
  final double screenWidth; 
  final VoidCallback? onTap;
  final bool isExpanded;

  const ChapterCard({
    super.key,
    required this.title,
    required this.text,
    required this.screenWidth, 
    this.onTap,
    this.isExpanded = false,
  });

  
  double _getTitleFontSize(double width) {
    if (width > 1800) return 22.0; 
    if (width > 1200) return 20.0; 
    if (width > 600) return 19.0; 
    return 18.0; 
  }

  
  double _getTextFontSize(double width) {
    if (width > 1800) return 17.0; 
    if (width > 1200) return 16.0; 
    if (width > 600) return 15.0;  
    return 14.0; 
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            
            margin: const EdgeInsets.symmetric(vertical: 4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          title,
                          style: ArabicTextStyle(
                            arabicFont: ArabicFont.cairo,
                            fontSize: _getTitleFontSize(screenWidth), 
                            fontWeight: FontWeight.bold,
                            color: const Color(0xffe6a345),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          text,
                          style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                            fontWeight: FontWeight.w900,
                            fontSize: _getTextFontSize(screenWidth), 
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}