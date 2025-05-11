import 'package:flutter/material.dart';

Widget SearchCard(
  BuildContext context, {
  required String title,
  required String content,
}) {
  final screenWidth = MediaQuery.of(context).size.width;

  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: screenWidth * 0.9, // Set a fixed width (90% of screen width)
      minWidth: screenWidth * 0.9, // Ensure the width doesn't shrink below this
    ),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الفصل: $title',
              style: const TextStyle(
                color: Color(0xFFE6A345),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                color: Colors.brown.shade800,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}