import 'package:flutter/material.dart';
import 'package:arabic_font/arabic_font.dart';

// ======================= Responsive Breakpoints =======================
const double kMediumScreenBreakpoint = 600.0;
const double kLargeScreenBreakpoint = 1200.0;
const double kExtraLargeScreenBreakpoint = 1800.0;

// ======================= Responsive Helper Functions =======================

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
// ========================================================================

Widget buildSettingCard(
  BuildContext context, {
  required String label,
  required Widget child,
}) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Container(
    // Using fixed vertical margins for a consistent look
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
              // Using helper function for font size
              fontSize: _getResponsiveFontSize(screenWidth, small: 19.0, medium: 20.0, large: 22.0, extraLarge: 24.0),
            ),
          ),
        ),
        // Modifying the child to ensure that texts inside the card take on the same style
        DefaultTextStyle(
          style: ArabicTextStyle(
            arabicFont: ArabicFont.avenirArabic,
            fontWeight: FontWeight.w900,
            color: Colors.brown.shade800,
            fontSize: _getResponsiveFontSize(screenWidth, small: 18.0, medium: 19.0, large: 20.0, extraLarge: 22.0),
          ),
          child: child,
        ),
      ],
    ),
  );
}
