import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showSingleSnackBar(
  BuildContext context, {
  required String message,
  Color backgroundColor = Colors.green,
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.cairo(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      backgroundColor: backgroundColor,
      duration: duration,
    ),
  );
}