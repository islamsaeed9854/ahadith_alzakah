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

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
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
      final normalizedQuery = normalizeArabicText(trimmedQuery);
      final queryWords =
          normalizedQuery.split(' ').where((w) => w.isNotEmpty).toSet();
      if (queryWords.isEmpty) {
        return [];
      }

      final fullPhraseMatches = <Map<String, dynamic>>[];
      final potentialPartials = <Map<String, dynamic>>[];
      for (final hadith in currentHadiths) {
        final combinedText = hadith.text;
        final normalizedText = normalizeArabicText(combinedText);
        int index = normalizedText.indexOf(normalizedQuery);
        if (index != -1) {
          fullPhraseMatches.add({
            'hadith': hadith,
            'startIndex': index,
            'length': normalizedQuery.length,
            'content': combinedText,
          });
        }
      }

      for (final hadith in currentHadiths) {
        final combinedText = hadith.text;
        final normalizedText = normalizeArabicText(combinedText);
        
        final normalizedTextWords = normalizedText.split(' ').toSet();
        final matchedWords = queryWords.intersection(normalizedTextWords);

        if (matchedWords.isNotEmpty) {
          int firstMatchIndex = -1;
          int firstMatchLength = 0;

          for (final queryWord in queryWords) {
            if (matchedWords.contains(queryWord)) {
              int index = normalizedText.indexOf(queryWord);
              
              if (index != -1) {
                firstMatchIndex = index;
                firstMatchLength = queryWord.length;
                break;
              }
            }
          }

          if (firstMatchIndex != -1) {
            potentialPartials.add({
              'hadith': hadith,
              'startIndex': firstMatchIndex,
              'length': firstMatchLength,
              'content': combinedText,
              'matchScore': matchedWords.length,
            });
          }
        }
      }

  
      potentialPartials.sort((a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int));

      final allMatches = <Map<String, dynamic>>[];

      final addedHadithKeys = <String>{};
      for (final match in fullPhraseMatches) {
        final hadith = match['hadith'] as Hadith;
        final compositeKey = "${hadith.bab}-${hadith.fasl}-${hadith.number}";
        if (addedHadithKeys.add(compositeKey)) {
          allMatches.add(match);
        }
      }
      for (final match in potentialPartials) {
        final hadith = match['hadith'] as Hadith;
        final compositeKey = "${hadith.bab}-${hadith.fasl}-${hadith.number}";
        if (addedHadithKeys.add(compositeKey)) {
          allMatches.add(match);
        }
      }

      final finalResults = allMatches.take(111).toList();

      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: finalResults.isEmpty
              ? 'لم يتم العثور على نتائج'
              : 'تم العثور على ${finalResults.length} تطابق',
          backgroundColor:
              finalResults.isEmpty ? Colors.redAccent : Colors.green,
          duration: const Duration(seconds: 3),
        );
      }

      _logger.i('Search for "$query" returned ${finalResults.length} matches');
      return finalResults;
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