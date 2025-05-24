// import 'package:logger/logger.dart';

class TextNormalizer {
  //final Logger _logger = Logger();

  String normalizeArabicText(String text) {
    final diacritics = RegExp(r'[\p{P}\u0617-\u061A\u064B-\u065F]', unicode: true);
    String normalized = text.replaceAll(diacritics, '')
        .replaceAll(RegExp(r'[\u0622\u0623\u0625]'), '\u0627')
        .replaceAll('\u064A', '\u0649')
        .replaceAll('\u0629', '\u0647')
       // .replaceAll(RegExp(r'\s+'), ' ')
       // .trim()
        .toLowerCase();
   // _logger.d('Normalized text: "$text" -> "$normalized"');
    return normalized;
  }
}