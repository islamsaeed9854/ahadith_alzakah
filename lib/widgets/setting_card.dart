import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';

// دالة مساعدة لتحديد حجم خط عنوان البطاقة
double _getCardLabelFontSize(double screenWidth) {
  if (screenWidth > 1200) return 22.0; // كبير جدًا
  if (screenWidth > 600) return 20.0;  // متوسط
  return 19.0; // صغير
}

// دالة مساعدة لتحديد حجم خط المحتوى داخل البطاقة (مثل الأرقام)
double _getCardContentFontSize(double screenWidth) {
  if (screenWidth > 1200) return 20.0;
  if (screenWidth > 600) return 19.0;
  return 18.0;
}


Widget buildSettingCard(
  BuildContext context, {
  required String label,
  required Widget child,
}) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Container(
    // استخدام هوامش رأسية ثابتة لمظهر متناسق
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    padding: const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 12.0,
    ),
    decoration: BoxDecoration(
      color: const Color.fromRGBO(255, 255, 255, 0.8),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(158, 158, 158, 0.2),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ArabicTextStyle(
              arabicFont: ArabicFont.avenirArabic,
              fontWeight: FontWeight.w900,
              color: Colors.brown.shade800,
              // استخدام دالة مساعدة لحجم الخط
              fontSize: _getCardLabelFontSize(screenWidth),
            ),
          ),
        ),
        // تعديل الـ child لضمان أن النصوص داخل البطاقة تأخذ نفس النمط
        DefaultTextStyle(
          style: ArabicTextStyle(
            arabicFont: ArabicFont.avenirArabic,
            fontWeight: FontWeight.w900,
            color: Colors.brown.shade800,
            fontSize: _getCardContentFontSize(screenWidth),
          ),
          child: child,
        ),
      ],
    ),
  );
}