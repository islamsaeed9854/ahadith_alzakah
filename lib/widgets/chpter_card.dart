import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';

class ChapterCard extends StatelessWidget {
  final String title;
  final String text;
  final double screenWidth; //  تم التغيير من isLandscape إلى screenWidth
  final VoidCallback? onTap;
  final bool isExpanded;

  const ChapterCard({
    super.key,
    required this.title,
    required this.text,
    required this.screenWidth, // مطلوب الآن
    this.onTap,
    this.isExpanded = false,
  });

  // دالة مساعدة لتحديد حجم خط العنوان بناءً على عرض الشاشة
  double _getTitleFontSize(double width) {
    if (width > 1800) return 22.0; // كبير جدًا
    if (width > 1200) return 20.0; // كبير
    if (width > 600) return 19.0;  // متوسط
    return 18.0; // صغير
  }

  // دالة مساعدة لتحديد حجم خط النص بناءً على عرض الشاشة
  double _getTextFontSize(double width) {
    if (width > 1800) return 17.0; // كبير جدًا
    if (width > 1200) return 16.0; // كبير
    if (width > 600) return 15.0;  // متوسط
    return 14.0; // صغير
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
            // تم إزالة الهامش الأفقي ليتم التحكم به من الشاشة الرئيسية
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
                            fontSize: _getTitleFontSize(screenWidth), // حجم خط متجاوب
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
                            fontSize: _getTextFontSize(screenWidth), // حجم خط متجاوب
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