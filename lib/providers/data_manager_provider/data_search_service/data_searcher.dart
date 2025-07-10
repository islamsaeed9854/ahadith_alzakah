import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../data/models/hadith.dart';
import '../../../core/utils.dart';
import 'text_normalizer.dart';

// Helper class to pass arguments to the isolate
class _SearchIsolateData {
  final SendPort sendPort;
  final String query;
  final List<Hadith> hadiths;

  _SearchIsolateData(this.sendPort, this.query, this.hadiths);
}

// This is the top-level function that will run in the isolate
void _isolateSearch(_SearchIsolateData isolateData) {
  final normalizer = TextNormalizer();

  String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'O\(|\)O'), '')
        .replaceAll(RegExp(r'[a-zA-Z]'), '')
        .replaceAll('،', '')
        .replaceAll(RegExp("[\\[\\]{}<>.,;:\"'!@#\$%^&*_+=|\\/~`-]"), '');
  }

  final normalizedQuery =
      normalizer.normalizeArabicText(cleanText(isolateData.query));
  final allQueryWords =
      normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();

  allQueryWords.sort((a, b) => b.length.compareTo(a.length));
  final queryWords = allQueryWords.take(20).toSet();

  if (queryWords.isEmpty) {
    isolateData.sendPort.send([]);
    return;
  }

  final allMatches = <Map<String, dynamic>>[];
  final hadithSnippets = <String, Set<String>>{};

  for (final hadith in isolateData.hadiths) {
    final combinedText = cleanText(hadith.text);
    final normalizedText = normalizer.normalizeArabicText(combinedText);
    String hadithKey = "${hadith.bab}-${hadith.fasl}-${hadith.number}";
    hadithSnippets[hadithKey] = hadithSnippets[hadithKey] ?? <String>{};

    int index = 0;
    while ((index = normalizedText.indexOf(normalizedQuery, index)) != -1) {
      if (normalizedQuery.isEmpty) break;
      final snippet =
          _getSnippetForDedup(combinedText, index, normalizedQuery.length);
      final normalizedSnippet = normalizer.normalizeArabicText(snippet);
      bool isHighlyOverlapping = hadithSnippets[hadithKey]!
          .any((prev) => _isHighlyOverlapping(normalizedSnippet, prev));

      if (!isHighlyOverlapping) {
        allMatches.add({
          'hadith': hadith,
          'startIndex': index,
          'length': normalizedQuery.length,
          'content': combinedText,
          'matchedWords': [normalizedQuery],
          'type': 'full',
          'snippetForDedup': snippet,
        });
        hadithSnippets[hadithKey]!.add(normalizedSnippet);
      }
      int oldIndex = index;
      index += normalizedQuery.length;
      if (index == oldIndex) break;
      if (allMatches.length >= 100) break;
    }
    if (allMatches.length >= 100) break;
  }

  for (final word in queryWords) {
    if (allMatches.length >= 100) break;
    for (final hadith in isolateData.hadiths) {
      if (allMatches.length >= 100) break;
      String hadithKey = "${hadith.bab}-${hadith.fasl}-${hadith.number}";
      final combinedText = cleanText(hadith.text);
      final normalizedText = normalizer.normalizeArabicText(combinedText);

      if (word.isEmpty || word.length < 2) continue;

      int wordIndex = 0;
      while ((wordIndex = normalizedText.indexOf(word, wordIndex)) != -1) {
        if (allMatches.length >= 100) break;
        if (word.isEmpty) break;
        final snippet =
            _getSnippetForDedup(combinedText, wordIndex, word.length);
        final normalizedSnippet = normalizer.normalizeArabicText(snippet);
        bool isHighlyOverlapping = hadithSnippets[hadithKey]!
            .any((prev) => _isHighlyOverlapping(normalizedSnippet, prev));

        if (!isHighlyOverlapping) {
          allMatches.add({
            'hadith': hadith,
            'startIndex': wordIndex,
            'length': word.length,
            'content': combinedText,
            'matchedWords': [word],
            'type': 'partial',
            'snippetForDedup': snippet,
          });
          hadithSnippets[hadithKey]!.add(normalizedSnippet);
        }

        int oldWordIndex = wordIndex;
        wordIndex += word.length;
        if (wordIndex == oldWordIndex) break;
      }
    }
  }

  List<String> searchWordsList =
      isolateData.query.split(' ').where((w) => w.isNotEmpty).toList();
  allMatches.sort((a, b) {
    if (a['type'] == 'full' && b['type'] != 'full') return -1;
    if (a['type'] != 'full' && b['type'] == 'full') return 1;

    int aUnique = _countUniqueSearchWordsInSnippet(
        a['snippetForDedup'], searchWordsList, normalizer);
    int bUnique = _countUniqueSearchWordsInSnippet(
        b['snippetForDedup'], searchWordsList, normalizer);
    if (aUnique != bUnique) return bUnique.compareTo(aUnique);

    int aTotal = _countTotalSearchWordsInSnippet(
        a['snippetForDedup'], searchWordsList, normalizer);
    int bTotal = _countTotalSearchWordsInSnippet(
        b['snippetForDedup'], searchWordsList, normalizer);
    if (aTotal != bTotal) return bTotal.compareTo(aTotal);

    bool aOnlyShort =
        _snippetHasOnlyShortWords(a['snippetForDedup'], searchWordsList);
    bool bOnlyShort =
        _snippetHasOnlyShortWords(b['snippetForDedup'], searchWordsList);
    if (aOnlyShort && !bOnlyShort) return 1;
    if (!aOnlyShort && bOnlyShort) return -1;
    return 0;
  });

  isolateData.sendPort.send(allMatches);
}

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

    final trimmedQuery = query
        .replaceAll(RegExp("[\\[\\]{}<>.,;:\"'!@#\$%^&*_+=|\\/~`-]"), '')
        .replaceAll('،', '')
        .trim();
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
      final receivePort = ReceivePort();
      await Isolate.spawn(
          _isolateSearch,
          _SearchIsolateData(
              receivePort.sendPort, trimmedQuery, currentHadiths));

      final results = await receivePort.first as List<Map<String, dynamic>>;

      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: results.isEmpty
              ? 'لم يتم العثور على نتائج'
              : 'تم العثور على ${results.where((m) => m['type'] == 'full').length} نتائج مطابقة و ${results.where((m) => m['type'] == 'partial').length} نتائج مشابهة',
          backgroundColor: results.isEmpty ? Colors.redAccent : Colors.green,
          duration: const Duration(seconds: 3),
        );
      }
      _logger.i('Search for "$query" returned ${results.length} matches');
      return results;
    } catch (e, st) {
      _logger.e('Search error: $e', stackTrace: st);
      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: 'خطأ في البحث',
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

// Helper functions to be used inside the isolate
String _getSnippetForDedup(String text, int start, int length) {
  String clean = text
      .replaceAll(RegExp(r'O\(|\)O'), '')
      .replaceAll(RegExp(r'[a-zA-Z]'), '')
      .replaceAll('،', '')
      .replaceAll(RegExp("[\\[\\]{}<>.,;:\"'!@#\$%^&*_+=|\\/~`-]"), '');
  final diacriticRegex = RegExp(
    r'[\p{P}\u0617-\u061A\u064B-\u065F]',
    unicode: true,
  );
  int nonDiacriticPos = 0;
  int adjustedStartIndex = 0;
  int adjustedEndIndex = clean.length;
  bool startFound = false;
  for (int i = 0; i < clean.length; i++) {
    if (!diacriticRegex.hasMatch(clean[i])) {
      if (nonDiacriticPos == start) {
        adjustedStartIndex = i;
        startFound = true;
      }
      if (startFound && nonDiacriticPos == start + length) {
        adjustedEndIndex = i;
        break;
      }
      nonDiacriticPos++;
    }
  }

  if (!startFound || adjustedStartIndex >= adjustedEndIndex) {
    adjustedStartIndex = 0;
    adjustedEndIndex = clean.length;
  }
  adjustedStartIndex = adjustedStartIndex.clamp(0, clean.length - 1);
  adjustedEndIndex = adjustedEndIndex.clamp(adjustedStartIndex, clean.length);
  final words = clean.split(RegExp(r'\s'));
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

  if (startWord >= endWord) {
    startWord = 0;
    endWord = words.length;
  }
  final snippetWords = words.sublist(startWord, endWord);
  final snippet = snippetWords.join(' ');
  return snippet;
}

int _countUniqueSearchWordsInSnippet(
    String snippet, List<String> searchWords, TextNormalizer normalizer) {
  Set<String> found = {};
  String normalizedSnippet = normalizer.normalizeArabicText(snippet);
  for (final word in searchWords) {
    if (word.trim().isEmpty) continue;
    String normalizedWord = normalizer.normalizeArabicText(word);
    if (normalizedSnippet.contains(normalizedWord)) found.add(normalizedWord);
  }
  return found.length;
}

int _countTotalSearchWordsInSnippet(
    String snippet, List<String> searchWords, TextNormalizer normalizer) {
  int total = 0;
  String normalizedSnippet = normalizer.normalizeArabicText(snippet);
  for (final word in searchWords) {
    if (word.trim().isEmpty) continue;
    String normalizedWord = normalizer.normalizeArabicText(word);
    int idx = 0;
    while ((idx = normalizedSnippet.indexOf(normalizedWord, idx)) != -1) {
      total++;
      idx += normalizedWord.length;
    }
  }
  return total;
}

bool _snippetHasOnlyShortWords(String snippet, List<String> searchWords) {
  for (final word in searchWords) {
    if (word.trim().length > 3 && snippet.contains(word)) return false;
  }
  return true;
}

bool _isHighlyOverlapping(String a, String b) {
  final aWords = a.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final bWords = b.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (aWords.isEmpty || bWords.isEmpty) return false;
  int overlap = 0;
  for (final word in aWords) {
    if (bWords.contains(word)) overlap++;
  }
  double ratioA = overlap / aWords.length;
  double ratioB = overlap / bWords.length;
  return ratioA >= .75 || ratioB >= .75;
}