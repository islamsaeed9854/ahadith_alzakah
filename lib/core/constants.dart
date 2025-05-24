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
      fontSize: 30,
      color: AppTheme.primaryColor,
    ),
  );

  static Image appBackgroundWidget = Image.asset(
    'assets/opening-screen-crupped-blured.webp',
    fit: BoxFit.cover,
    height: double.infinity,
    width: double.infinity,
  );
  static Image appBackgroundWidgetForSplashScreen = Image.asset(
    'assets/backGround.webp',
    fit: BoxFit.cover,
    height: double.infinity,
    width: double.infinity,
  );
  static const AssetImage appBackgroundImage = AssetImage(
    'assets/opening-screen-crupped-blured.webp',
  );
  // زر الرجوع الذي يستخدم navigationProvider
  static IconButton backButton(WidgetRef ref) {
    final navNotifier = ref.read(navigationProvider.notifier);
    return IconButton(
      icon: const Icon(
        Icons.arrow_forward,
        color: AppTheme.secodaryColor,
        size: 30,
      ),
      onPressed: () => navNotifier.changeTab(0),
    );
  }

  static IconButton backButtonLoginAddRemovePages(context) {
    return IconButton(
      icon: const Icon(
        Icons.arrow_forward,
        color: AppTheme.secodaryColor,
        size: 30,
      ),
      onPressed: () =>  Navigator.of(context).pop(),
    );
  }
}
