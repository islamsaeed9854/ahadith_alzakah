import 'package:ahadith_alzakah/screens/chapters_screen.dart';
import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';

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
