import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:async/async.dart'; 
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import '../data/models/hadith.dart';
import '../core/utils.dart';
import '../core/methods.dart';
import 'search_state_provider.dart';

final Hadith_Details_Helper_provider = StateProvider<String>((ref) {
  return '';
});

final searchControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final filteredResultsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

final batchLoadingProvider = StateProvider<bool>((ref) => false);

final displayCountProvider = StateProvider<int>((ref) => 20);

class SearchProcessor {
  static Future<List<Map<String, dynamic>>> processSearchResults(
    List<Map<String, dynamic>> rawResults,
    String query,
  ) async {
    return await Isolate.run(() {
      final normalizedQuery = query
          .replaceAll(RegExp("[\\[\\]{}<>.,;:\"'!@#\$%^&*_+=|\\/~`-]"), '')
          .replaceAll('،', '')
          .trim()
          .toLowerCase();
      final searchWords =
          normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();

      return rawResults.where((result) {
        final hadith = result['hadith'] as Hadith?;
        return hadith != null;
      }).map((result) {
        final hadith = result['hadith'] as Hadith;
        final startIndex = result['startIndex'] as int? ?? 0;
        final length = result['length'] as int? ?? query.length;

        final snippetInfo =
            Methods.getSnippet(hadith.text, searchWords, startIndex, length);

        return {
          'title':
              '${hadith.chapter_title}:${hadith.section_title}:حديث${hadith.number}',
          'content': hadith.text,
          'hadith': hadith,
          'snippet': snippetInfo['snippet'],
          'searchWords': searchWords,
        };
      }).toList();
    });
  }
}

final filterSearchProvider = Provider((ref) {
  Timer? _debounceTimer;

  return (String query, BuildContext context) async {
    _debounceTimer?.cancel();
    final searchStateNotifier = ref.read(searchStateProvider.notifier);

    if (query.trim().isEmpty) {
      searchStateNotifier.stopSearch();
      ref.read(filteredResultsProvider.notifier).state = [];
      ref.read(displayCountProvider.notifier).state = 20;
      return;
    }

    final completer = Completer<void>();
    final cancelableOperation = CancelableOperation.fromFuture(completer.future);
    searchStateNotifier.startSearch(cancelableOperation);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await ref
            .read(DataProvider.notifier)
            .searchHadiths(query, context);

        if (cancelableOperation.isCanceled) return;

        if (results.isEmpty) {
          ref.read(filteredResultsProvider.notifier).state = [];
          searchStateNotifier.stopSearch();
          completer.complete();
          return;
        }

        final processedResults =
            await SearchProcessor.processSearchResults(results, query);
        
        if (cancelableOperation.isCanceled) return;

        final initialBatch = processedResults.take(20).toList();
        ref.read(filteredResultsProvider.notifier).state = initialBatch;
        ref.read(displayCountProvider.notifier).state = 20;

        if (processedResults.length > 20) {
          _loadResultsInBatches(ref, processedResults, 20);
        }

        searchStateNotifier.stopSearch();
        completer.complete();
      } catch (e) {
        if (!completer.isCompleted) {
            searchStateNotifier.stopSearch();
            ref.read(filteredResultsProvider.notifier).state = [];
            completer.completeError(e);
        }
      }
    });

    try {
        await completer.future;
    } catch(e) {
        if (context.mounted) {
            showSingleSnackBar(
            context,
            message: 'حدث خطأ أثناء البحث: $e',
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
            );
        }
    }
  };
});


void _loadResultsInBatches(
  Ref ref,
  List<Map<String, dynamic>> allResults,
  int startIndex,
) {
  const int batchSize = 15;

  Timer.periodic(const Duration(milliseconds: 100), (timer) {
    final currentCount = ref.read(displayCountProvider);

    if (currentCount >= allResults.length) {
      timer.cancel();
      return;
    }

    final nextBatch = allResults.take(currentCount + batchSize).toList();
    ref.read(filteredResultsProvider.notifier).state = nextBatch;
    ref.read(displayCountProvider.notifier).state = currentCount + batchSize;

    if (nextBatch.length >= allResults.length) {
      timer.cancel();
    }
  });
}

final loadMoreProvider = Provider((ref) {
  return () {
    final currentResults = ref.read(filteredResultsProvider);
    final currentCount = ref.read(displayCountProvider);

    if (currentResults.length > currentCount) {
      const int batchSize = 20;
      final newCount =
          (currentCount + batchSize).clamp(0, currentResults.length);
      ref.read(displayCountProvider.notifier).state = newCount;
    }
  };
});