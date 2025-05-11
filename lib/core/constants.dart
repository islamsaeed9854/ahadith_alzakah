import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import '../providers/navigation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextApp {
  static Text drSamyKhalilName = Text(
    "د/سامى خليل",
    style: GoogleFonts.amiri(
      fontWeight: FontWeight.bold,
      fontSize: 16.6,
      color: AppTheme.secodaryColor,
    ),
  );

  // زر الرجوع الذي يستخدم navigationProvider
  static IconButton backButton(WidgetRef ref) {
    final navNotifier = ref.read(navigationProvider.notifier);
    return IconButton(
      icon: const Icon(
        Icons.arrow_back,
        color: AppTheme.secodaryColor,
        size: 30,
      ),
      onPressed: () => navNotifier.changeTab(0),
    );
  }
}
