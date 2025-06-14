import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';

Widget buildSettingCard(
  BuildContext context, {
  required String label,
  required Widget child,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Container(
    margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
    padding: EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenHeight * 0.015,
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
              fontSize: screenWidth * 0.045,
            ),
          ),
        ),
        child,
      ],
    ),
  );
}