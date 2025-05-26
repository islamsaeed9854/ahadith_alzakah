import 'package:flutter/material.dart';

Widget searchCard(
  BuildContext context, {
  required String title,
  required String content,
  required String query,
  required int startIndex,
  required int length,
  required Map<String, dynamic> Function(String, String, int, int) getSnippet,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final snippetData = getSnippet(content, query, startIndex, length);
  final snippet = snippetData['snippet'] as String;
  final queryStart = snippetData['queryStart'] as int;
  final queryEnd = snippetData['queryEnd'] as int;

  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: screenWidth * 0.9,
      minWidth: screenWidth * 0.9,
    ),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color.fromRGBO(255, 255, 255, 0.9),
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
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: snippet.substring(0, queryStart),
                    style: TextStyle(
                      color: Colors.brown.shade800,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  TextSpan(
                    text: snippet.substring(queryStart, queryEnd),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: snippet.substring(queryEnd),
                    style: TextStyle(
                      color: Colors.brown.shade800,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    ),
  );
}