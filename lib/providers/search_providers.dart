import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import '../data/models/hadith.dart';
import '../core/utils.dart';
final Hadith_Details_Helper_provider = StateProvider<String>((ref) {
  return '';
});

final searchControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final filteredResultsProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

final filterSearchProvider = Provider((ref) {
  return (String query, BuildContext context) async {
    if (query.trim().isEmpty) {
      ref.read(filteredResultsProvider.notifier).state = [];
      return;
    }

    try {
      final results = await ref.read(DataProvider.notifier).searchHadiths(query, context);
      final filteredResults = results.where((result) {
        final hadith = result['hadith'] as Hadith?;
        return hadith != null;
      }).map((result) {
        final hadith = result['hadith'] as Hadith;
        return {
          'title': '${hadith.chapter_title}:${hadith.section_title}:حديث${hadith.number}',
          'content': hadith.text,
          'hadith': hadith,
          'startIndex': result['startIndex'] as int? ?? 0,
          'length': result['length'] as int? ?? query.length,
        };
      }).toList();
      ref.read(filteredResultsProvider.notifier).state = filteredResults;
    } catch (e) {
      ref.read(filteredResultsProvider.notifier).state = [];
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