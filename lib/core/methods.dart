import 'package:number_to_word_arabic/number_to_word_arabic.dart';

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
    String query,
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
    String matchedQuery =
        queryStart < queryEnd ? snippet.substring(queryStart, queryEnd) : query;

    return {
      'snippet': snippet,
      'query': matchedQuery,
      'queryStart': queryStart,
      'queryEnd': queryEnd,
    };
  }
}
