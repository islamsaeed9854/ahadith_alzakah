import 'package:number_to_word_arabic/number_to_word_arabic.dart';
import 'package:flutter/painting.dart';

class Methods {
  static String numberToArabicText_100(int number) {
    const List<String> ones = [
      '',
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'السابع',
      'الثامن',
      'التاسع',
    ];
    const List<String> tens = [
      '',
      '',
      'العشرون',
      'الثلاثون',
      'الأربعون',
      'الخمسون',
      'الستون',
      'السبعون',
      'الثمانون',
      'التسعون',
    ];
    const List<String> teens = [
      'العاشر',
      'الحادي عشر',
      'الثاني عشر',
      'الثالث عشر',
      'الرابع عشر',
      'الخامس عشر',
      'السادس عشر',
      'السابع عشر',
      'الثامن عشر',
      'التاسع عشر',
    ];

    if (number == 0) return 'الصفر';
    if (number >= 1 && number <= 9) return ones[number];
    if (number >= 10 && number <= 19) return teens[number - 10];
    if (number >= 20 && number <= 99) {
      int one = number % 10;
      if (one == 0) return tens[number ~/ 10];
      return '${ones[one]} و${tens[number ~/ 10]}';
    }
    return number.toString();
  }

  static String numberToArabicText(int number) {
    if (number >= 100) {
      return 'ال${Tafqeet.convert(number.toString())}';
    } else {
      return numberToArabicText_100(number);
    }
  }

  static Map<String, dynamic> getSnippet(
    String text,
    List<String> queries,
    int startIndex,
    int length,
  ) {
    final diacriticRegex = RegExp(
      r'[\p{P}\u0617-\u061A\u064B-\u065F]',
      unicode: true,
    );
    if (startIndex < 0) {
      startIndex = 0;
    }
    if (startIndex >= text.length) {
      startIndex = text.length - 1;
      length = 0;
    }
    if (startIndex + length > text.length) {
      length = text.length - startIndex;
    }
    int nonDiacriticPos = 0;
    int adjustedStartIndex = 0;
    int adjustedEndIndex = text.length;
    bool startFound = false;
    for (int i = 0; i < text.length; i++) {
      if (!diacriticRegex.hasMatch(text[i])) {
        if (nonDiacriticPos == startIndex) {
          adjustedStartIndex = i;
          startFound = true;
        }
        if (startFound && nonDiacriticPos == startIndex + length) {
          adjustedEndIndex = i;
          break;
        }
        nonDiacriticPos++;
      }
    }
    if (!startFound) {
      adjustedStartIndex = startIndex.clamp(0, text.length - 1);
      adjustedEndIndex = (startIndex + length).clamp(
        adjustedStartIndex,
        text.length,
      );
    }
    final words = text.split(RegExp(r'\s'));
    int charPos = 0;
    int matchWordIndex = 0;
    for (int i = 0; i < words.length; i++) {
      int wordLen = words[i].length;
      if (charPos + wordLen >= adjustedStartIndex) {
        matchWordIndex = i;
        break;
      }
      charPos += wordLen + 1;
    }
    int startWord = (matchWordIndex - 15).clamp(0, words.length);
    int endWord = (matchWordIndex + 15 + 1).clamp(0, words.length);
    final snippetWords = words.sublist(startWord, endWord);
    final snippet = snippetWords.join(' ');
    int prefixLength = words
        .sublist(0, startWord)
        .fold(0, (sum, word) => sum + word.length + 1);
    int queryStart = (adjustedStartIndex - prefixLength).clamp(
      0,
      snippet.length,
    );
    int queryEnd = (adjustedEndIndex - prefixLength).clamp(
      queryStart,
      snippet.length,
    );
    return {
      'snippet': snippet,
      'queryStart': queryStart,
      'queryEnd': queryEnd,
    };
  }

  static List<InlineSpan> highlightWords(String text, List<String> words, TextStyle normalStyle, TextStyle highlightStyle) {
    if (words.isEmpty) {
      return [TextSpan(text: text, style: normalStyle)];
    }
   
    String normalize(String s) {
      final diacritics = RegExp(r'[\p{P}\u0617-\u061A\u064B-\u065F]', unicode: true);
      return s.replaceAll(diacritics, '')
          .replaceAll(RegExp(r'[\u0622\u0623\u0625]'), '\u0627')
          .replaceAll('\u064A', '\u0649')
          .replaceAll('\u0629', '\u0647')
          .toLowerCase();
    }
    final normalizedText = normalize(text);
    final matchRanges = <Map<String, int>>[];
    for (final word in words) {
      if (word.trim().isEmpty) continue;
      final normalizedWord = normalize(word);
      int start = 0;
      while (true) {
        final index = normalizedText.indexOf(normalizedWord, start);
        if (index == -1) break;
       
        int origStart = _originalIndexFromNormalized(text, index, normalize);
        int origEnd = _originalIndexFromNormalized(text, index + normalizedWord.length, normalize);
        matchRanges.add({'start': origStart, 'end': origEnd});
        start = index + normalizedWord.length;
      }
    }
    // دمج التداخلات
    matchRanges.sort((a, b) => a['start']!.compareTo(b['start']!));
    List<Map<String, int>> merged = [];
    for (final m in matchRanges) {
      if (merged.isEmpty) {
        merged.add(m);
      } else {
        var last = merged.last;
        if (m['start']! <= last['end']!) {
          last['end'] = m['end']! > last['end']! ? m['end']! : last['end']!;
        } else {
          merged.add(m);
        }
      }
    }
    int last = 0;
    List<InlineSpan> spans = [];
    for (final match in merged) {
      if (match['start']! > last) {
        spans.add(TextSpan(text: text.substring(last, match['start']!), style: normalStyle));
      }
      spans.add(TextSpan(text: text.substring(match['start']!, match['end']!), style: highlightStyle));
      last = match['end']!;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: normalStyle));
    }
    return spans;
  }

  static int _originalIndexFromNormalized(String original, int normalizedIndex, String Function(String) normalize) {
    int origIdx = 0;
    int normIdx = 0;
    while (origIdx < original.length && normIdx < normalizedIndex) {
      String char = original[origIdx];
      if (!RegExp(r'[\p{P}\u0617-\u061A\u064B-\u065F]', unicode: true).hasMatch(char)) {
        normIdx++;
      }
      origIdx++;
    }
    return origIdx;
  }
}
