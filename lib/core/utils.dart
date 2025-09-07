import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Displays a customized SnackBar, ensuring only one is visible at a time.
///
/// This function first removes any currently displayed SnackBar and then shows a new one.
/// It includes a safety check to ensure the [BuildContext] is still active before proceeding.
void showSingleSnackBar(
  BuildContext context, {
  required String message,
  Color backgroundColor = Colors.green,
  Duration duration = const Duration(seconds: 2),
}) {
  // Safety check: Do not proceed if the widget's context is no longer active.
  // This prevents the "Looking up a deactivated widget's ancestor is unsafe" error.
  if (!context.mounted) return;

  // Get the ScaffoldMessenger once to avoid multiple lookups.
  final messenger = ScaffoldMessenger.of(context);

  // Remove any existing SnackBar before showing the new one.
  messenger.removeCurrentSnackBar();

  // Show the new SnackBar.
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating, // Makes the SnackBar float above the content
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.all(10.0),
    ),
  );
}
