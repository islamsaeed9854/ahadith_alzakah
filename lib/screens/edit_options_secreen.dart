import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_hadith_screen.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils.dart';
import 'package:arabic_font/arabic_font.dart';

// ======================= Responsive Breakpoints =======================
const double kMediumScreenBreakpoint = 600.0;
const double kLargeScreenBreakpoint = 1200.0;
const double kExtraLargeScreenBreakpoint = 1800.0;
// ========================================================================

// ====== Helper Functions for Responsive Design ======

/// Determines the max width of the content area.
double _getMaxContentWidth(double screenWidth) {
  if (screenWidth > kLargeScreenBreakpoint) return screenWidth * 0.7; // 70% for extra-large screens
  if (screenWidth > kMediumScreenBreakpoint) return 600; // Fixed width for tablets and desktops
  return screenWidth; // Full width for mobile
}

/// A generic helper function to determine font sizes based on screen size.
double _getResponsiveFontSize(double screenWidth, {
  required double small,
  required double medium,
  required double large,
  double? extraLarge,
}) {
  if (screenWidth > kExtraLargeScreenBreakpoint) return extraLarge ?? large * 1.1;
  if (screenWidth > kLargeScreenBreakpoint) return large;
  if (screenWidth > kMediumScreenBreakpoint) return medium;
  return small;
}
// ======================================================

final selectedEditFieldProvider = StateProvider<String>((ref) => '');

class EditOptionsScreen extends ConsumerWidget {
  const EditOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOption = ref.watch(selectedEditFieldProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = _getMaxContentWidth(screenWidth);

    final options = ['نص الحديث', 'الخلاصة', 'التخريج', 'الدراسة', 'الكل'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                'assets/opening-screen-crupped-blured.webp',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth >= kMediumScreenBreakpoint ? 0 : 20,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title and back button
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              "تعديل حديث",
                              style: GoogleFonts.cairo(
                                color: AppTheme.secodaryColor,
                                fontSize: _getResponsiveFontSize(screenWidth, small: 34, medium: 38, large: 42),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextApp.backButtonLoginAddRemovePages(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),
                        // Main content (options + button)
                        Column(
                          children: [
                            // Options list
                            Column(
                              children: options.map((option) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: RadioListTile<String>(
                                    value: option,
                                    groupValue: selectedOption,
                                    activeColor: const Color(0xfffcf3e8),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: selectedOption == option ? AppTheme.primaryColor : Colors.transparent, width: 2),
                                    ),
                                    tileColor: selectedOption == option ? AppTheme.primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                                    onChanged: (val) => ref.read(selectedEditFieldProvider.notifier).state = val!,
                                    title: Text(
                                      option,
                                      textAlign: TextAlign.right,
                                      style: ArabicTextStyle(
                                        arabicFont: ArabicFont.avenirArabic,
                                        color: Colors.white,
                                        fontSize: _getResponsiveFontSize(screenWidth, small: 20, medium: 22, large: 24),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 50),
                            // Next button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff977c55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: _getResponsiveFontSize(screenWidth, small: 50, medium: 60, large: 70),
                                  vertical: _getResponsiveFontSize(screenWidth, small: 12, medium: 14, large: 16),
                                ),
                              ),
                              onPressed: () {
                                if (selectedOption.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditHadithScreen(
                                        selectedOption: selectedOption,
                                      ),
                                    ),
                                  );
                                } else {
                                  showSingleSnackBar(
                                    context,
                                    message: 'اختر أحد الحقول أولاً',
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 3),
                                  );
                                }
                              },
                              child: Text(
                                'التالي',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: _getResponsiveFontSize(screenWidth, small: 18, medium: 20, large: 22),
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

