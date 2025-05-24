import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/hadith.dart';
import 'data_loader.dart';
import 'data_adder.dart';
import 'data_deleter.dart';
import '../data_search_service/data_searcher.dart';

final DataProvider =
    StateNotifierProvider<DataManager, AsyncValue<List<Hadith>>>(
      (ref) => DataManager(ref),
    );

class DataManager extends StateNotifier<AsyncValue<List<Hadith>>> {
  final Ref ref;
  final DataLoader _loader;
  final DataAdder _adder;
  final DataDeleter _deleter;
  final DataSearcher _searcher;

  DataManager(this.ref)
    : _loader = DataLoader(),
      _adder = DataAdder(),
      _deleter = DataDeleter(),
      _searcher = DataSearcher(),
      super(const AsyncValue.loading()) {
    loadHadiths();
  }

  Future<void> loadHadiths() async {
    state = const AsyncValue.loading();
    try {
      final hadiths = await _loader.loadHadiths((hadiths) {
        if (hadiths == null) {
          state = AsyncValue.error(
            Exception('No hadiths available'),
            StackTrace.current,
          );
        } else {
          state = AsyncValue.data(hadiths);
        }
        return state;
      });
      if (hadiths != null && hadiths.isNotEmpty)
        state = AsyncValue.data(hadiths);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<dynamic> getJsonData() async {
    return await _loader.getJsonData(); // Delegate to DataLoader
  }

  Future<List<Map<String, dynamic>>> searchHadiths(
    String query,
    BuildContext context,
  ) async {
    return await _searcher.searchHadiths(
      query,
      context,
      state.valueOrNull ?? [],
    );
  }

  Future<void> addHadith(
    Hadith newHadith,
    int flag,
    BuildContext context,
  ) async {
    await _adder.addHadith(
      newHadith,
      flag,
      context,
      state.valueOrNull ?? [],
      (hadiths) => state = AsyncValue.data(hadiths),
    );
  }

  Future<void> deleteHadith(
    int bab,
    int fasl,
    int number,
    BuildContext context,
  ) async {
    await _deleter.deleteHadith(
      bab,
      fasl,
      number,
      context,
      state.valueOrNull ?? [],
      (hadiths) => state = AsyncValue.data(hadiths),
    );
  }

  // دالة جديدة لاسترجاع حديث بناءً على bab و fasl و number
  Future<Hadith> retrieveHadith(
    int bab,
    int fasl,
    int number,
    BuildContext context,
  ) async {
    try {
      // التأكد من أن الأحاديث تم تحميلها
      if (state.valueOrNull == null) {
        await loadHadiths();
      }

      // البحث عن الحديث في القائمة الحالية
      final currentHadiths = state.valueOrNull ?? [];
      final hadith = currentHadiths.firstWhere(
        (h) => h.bab == bab && h.fasl == fasl && h.number == number,
        orElse:
            () =>
                Hadith.empty(), // إرجاع حديث فارغ إذا لم يتم العثور على الحديث
      );

      return hadith;
    } catch (e) {
      // إذا حدث خطأ، يمكننا إرجاع حديث فارغ أو رمي استثناء بناءً على الحاجة
      rethrow; // رمي الاستثناء ليتم التعامل معه في الشاشة المستدعية
    }
  }
}
