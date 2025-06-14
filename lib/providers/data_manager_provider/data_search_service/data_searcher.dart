import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../data/models/hadith.dart';
import '../../../core/utils.dart';
import 'text_normalizer.dart';

class DataSearcher {
  final Logger _logger = Logger();
  final TextNormalizer _normalizer = TextNormalizer();

  DataSearcher();

  Future<List<Map<String, dynamic>>> searchHadiths(
    String query,
    BuildContext context,
    List<Hadith> currentHadiths,
  ) async {
    if (currentHadiths.isEmpty) {
      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: 'لا توجد أحاديث للبحث',
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        );
      }
      return [];
    }

    if (query.trim().isEmpty) {
      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: 'يرجى إدخال كلمة بحث صالحة',
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        );
      }
      return [];
    }

    try {
      final normalizedQuery = normalizeArabicText(query);
      final queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();
      final matches = <Map<String, dynamic>>[];

      // Search for the full phrase
      for (final hadith in currentHadiths) {
        final combinedText = hadith.text;
        final normalizedText = normalizeArabicText(combinedText);
        int index = -1;
        while ((index = normalizedText.indexOf(normalizedQuery, index + 1)) != -1) {
          matches.add({
            'hadith': hadith,
            'startIndex': index,
            'length': query.length,
            'content': combinedText,
          });
          if (matches.length >= 111) break;
        }
        if (matches.length >= 111) break;
      }

      // Search for individual words
      for (final hadith in currentHadiths) {
        final combinedText = hadith.text;
        final normalizedText = normalizeArabicText(combinedText);
        for (final word in queryWords) {
          int index = -1;
          while ((index = normalizedText.indexOf(word, index + 1)) != -1) {
            matches.add({
              'hadith': hadith,
              'startIndex': index,
              'length': word.length,
              'content': combinedText,
            });
            if (matches.length >= 111) break;
          }
          if (matches.length >= 111) break;
        }
        if (matches.length >= 111) break;
      }

      // Sort matches by relevance
      matches.sort((a, b) {
        final aText = normalizeArabicText(
            '${(a['hadith'] as Hadith).text} ${(a['hadith'] as Hadith).reference} ${(a['hadith'] as Hadith).summary} ${(a['hadith'] as Hadith).analysis}');
        final bText = normalizeArabicText(
            '${(b['hadith'] as Hadith).text} ${(b['hadith'] as Hadith).reference} ${(b['hadith'] as Hadith).summary} ${(b['hadith'] as Hadith).analysis}');
        final aScore = queryWords.fold(0, (sum, word) => sum + (aText.contains(word) ? 1 : 0));
        final bScore = queryWords.fold(0, (sum, word) => sum + (bText.contains(word) ? 1 : 0));
        return bScore.compareTo(aScore);
      });

      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: matches.isEmpty
              ? 'لم يتم العثور على نتائج'
              : 'تم العثور على ${matches.length} تطابق',
          backgroundColor: matches.isEmpty ? Colors.redAccent : Colors.green,
          duration: const Duration(seconds: 3),
        );
      }

      _logger.i('Search for "$query" returned ${matches.length} matches');
      return matches;
    } catch (e, st) {
      _logger.e('Search error: $e', stackTrace: st);
      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: 'خطأ في البحث: ${e.toString()}',
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        );
      }
      return [];
    }
  }

  String normalizeArabicText(String text) {
    return _normalizer.normalizeArabicText(text);
  }
}