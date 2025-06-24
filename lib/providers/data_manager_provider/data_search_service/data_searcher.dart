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

    final trimmedQuery = query.replaceAll(RegExp("[\\[\\]{}<>.,;:\"'!@#\$%^&*_+=|\\/~`-]"), '').replaceAll('،', '').trim();
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
   
      String cleanText(String text) {
      
        return text
            .replaceAll(RegExp(r'O\(|\)O'), '')
            .replaceAll(RegExp(r'[a-zA-Z]'), '')
            .replaceAll('،', '') 
    
      .replaceAll(RegExp("[\\[\\]{}<>.,;:\"'!@#\$%^&*_+=|\\/~`-]"), '');
      }
      final normalizedQuery = normalizeArabicText(cleanText(trimmedQuery));
      final allQueryWords =
          normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();

      allQueryWords.sort((a, b) => b.length.compareTo(a.length));
      final queryWords = allQueryWords.take(5).toSet();
      bool shouldLimit = false;
      while (queryWords.length > 1 &&
          queryWords.elementAt(queryWords.length - 1).length < 3) {
        queryWords.remove(queryWords.elementAt(queryWords.length - 1));
      }
      if (queryWords.isEmpty) {
        return [];
      }
      if (queryWords.elementAt(queryWords.length - 1).length < 3) {
        shouldLimit = true;
      }
      final allMatches = <Map<String, dynamic>>[];
      final hadithSnippets = <String, Set<String>>{};
      bool reachedLimit = false;
      shouldLimit = shouldLimit ? true : trimmedQuery.length <= 3;
    
      final DateTime wordSearchStart = DateTime.now();
      bool timeLimitReached = false;
      for (final hadith in currentHadiths) {
        if (shouldLimit && reachedLimit) break;
        final combinedText = cleanText(hadith.text);
        final normalizedText = normalizeArabicText(combinedText);
        String hadithKey = "${hadith.bab}-${hadith.fasl}-${hadith.number}";
        hadithSnippets[hadithKey] = hadithSnippets[hadithKey] ?? <String>{};

        int index = 0;
        while ((index = normalizedText.indexOf(normalizedQuery, index)) != -1) {
     
          if (normalizedQuery.isEmpty || normalizedQuery.length == 0) break;
          final snippet = _getSnippetForDedup(
            combinedText,
            index,
            normalizedQuery.length,
          );
          final normalizedSnippet = normalizeArabicText(snippet);
          bool isHighlyOverlapping = hadithSnippets[hadithKey]!.any(
            (prev) => _isHighlyOverlapping(normalizedSnippet, prev),
          );
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
            if (shouldLimit && allMatches.length >= 111) {
              reachedLimit = true;
              break;
            }
          }
         
          int oldIndex = index;
          index += normalizedQuery.length;
          if (index == oldIndex) break;
        }

        if (shouldLimit && reachedLimit) break;

    
        for (final word in queryWords) {
          if (word.isEmpty || word.length < 2) continue;
      
          if (allMatches.length % 10 == 0) {
            final elapsed = DateTime.now().difference(wordSearchStart).inMilliseconds;
            if (elapsed > 5000) {
              timeLimitReached = true;
              break;
            }
          }
          int wordIndex = 0;
          while ((wordIndex = normalizedText.indexOf(word, wordIndex)) != -1) {
          
            if (word.isEmpty || word.length == 0) break;
            final snippet = _getSnippetForDedup(
              combinedText,
              wordIndex,
              word.length,
            );
            final normalizedSnippet = normalizeArabicText(snippet);
            bool isHighlyOverlapping = hadithSnippets[hadithKey]!.any(
              (prev) => _isHighlyOverlapping(normalizedSnippet, prev),
            );
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
              if (shouldLimit && allMatches.length >= 111) {
                reachedLimit = true;
                break;
              }
            }
          
            int oldWordIndex = wordIndex;
            wordIndex += word.length;
            if (wordIndex == oldWordIndex) break;
          }
          if (shouldLimit && reachedLimit) break;
          if (timeLimitReached) break;
        }
        if (timeLimitReached) break;
      }

      List<String> searchWordsList =
          trimmedQuery.split(' ').where((w) => w.isNotEmpty).toList();
      allMatches.sort((a, b) {
        if (a['type'] == 'full' && b['type'] != 'full') return -1;
        if (a['type'] != 'full' && b['type'] == 'full') return 1;

        int aUnique = _countUniqueSearchWordsInSnippet(
          a['snippetForDedup'],
          searchWordsList,
        );
        int bUnique = _countUniqueSearchWordsInSnippet(
          b['snippetForDedup'],
          searchWordsList,
        );
        if (aUnique != bUnique) return bUnique.compareTo(aUnique);

        int aTotal = _countTotalSearchWordsInSnippet(
          a['snippetForDedup'],
          searchWordsList,
        );
        int bTotal = _countTotalSearchWordsInSnippet(
          b['snippetForDedup'],
          searchWordsList,
        );
        if (aTotal != bTotal) return bTotal.compareTo(aTotal);

        bool aOnlyShort = _snippetHasOnlyShortWords(
          a['snippetForDedup'],
          searchWordsList,
        );
        bool bOnlyShort = _snippetHasOnlyShortWords(
          b['snippetForDedup'],
          searchWordsList,
        );
        if (aOnlyShort && !bOnlyShort) return 1;
        if (!aOnlyShort && bOnlyShort) return -1;
        return 0;
      });

      final finalResults =
          shouldLimit ? allMatches.take(111).toList() : allMatches.take(100).toList();
      if (context.mounted) {
        showSingleSnackBar(
          context,
          message:
              finalResults.isEmpty
                  ? 'لم يتم العثور على نتائج'
                  : 'تم العثور على ${finalResults.where((m) => m['type'] == 'full').length} نتائج مطابقة و ${finalResults.where((m) => m['type'] == 'partial').length} نتائج مشابهة',
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
    String snippet,
    List<String> searchWords,
  ) {
    Set<String> found = {};
    String normalizedSnippet = normalizeArabicText(snippet);
    for (final word in searchWords) {
      if (word.trim().isEmpty) continue;
      String normalizedWord = normalizeArabicText(word);
      if (normalizedSnippet.contains(normalizedWord)) found.add(normalizedWord);
    }
    return found.length;
  }

  int _countTotalSearchWordsInSnippet(
    String snippet,
    List<String> searchWords,
  ) {
    int total = 0;
    String normalizedSnippet = normalizeArabicText(snippet);
    for (final word in searchWords) {
      if (word.trim().isEmpty) continue;
      String normalizedWord = normalizeArabicText(word);
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
}
