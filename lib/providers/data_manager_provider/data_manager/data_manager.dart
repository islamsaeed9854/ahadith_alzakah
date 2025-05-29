import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/hadith.dart';
import 'data_loader.dart';
import 'data_adder.dart';
import 'data_deleter.dart';
import '../data_search_service/data_searcher.dart';
import '../local_storage_service/local_version_handler.dart';
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
  final LocalVersionHandler _versionHandler;

  DataManager(this.ref)
      : _loader = DataLoader(),
        _adder = DataAdder(ref),
        _deleter = DataDeleter(),
        _searcher = DataSearcher(),
         _versionHandler = LocalVersionHandler(),
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
      if (hadiths != null && hadiths.isNotEmpty) state = AsyncValue.data(hadiths);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<dynamic> getJsonData() async {
    return await _loader.getJsonData();
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
    try {
      await _adder.addHadith(
        newHadith,
        flag,
        context,
        state.valueOrNull ?? [],
        (hadiths) => state = AsyncValue.data(hadiths),
      );

      if (state.valueOrNull != null) {
        await _loader.updateJsonData(state.valueOrNull!,await _versionHandler.getLocalVersion());
      }
    } catch (e) {
      rethrow;
    }
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

  Future<Hadith> retrieveHadith(
    int bab,
    int fasl,
    int number,
    BuildContext context,
  ) async {
    try {
      if (state.valueOrNull == null) {
        await loadHadiths();
      }
      final currentHadiths = state.valueOrNull ?? [];
      final hadith = currentHadiths.firstWhere(
        (h) => h.bab == bab && h.fasl == fasl && h.number == number,
        orElse: () => Hadith.empty(),
      );
      return hadith;
    } catch (e) {
      rethrow;
    }
  }
}