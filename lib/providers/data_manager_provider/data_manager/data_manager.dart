import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/hadith.dart';
import 'data_loader.dart';
import 'data_adder.dart';
import 'data_deleter.dart';
import '../data_search_service/data_searcher.dart';
import '../../../screens/add_hadith.dart';
import '../../../screens/edit_hadith_screen.dart';
import '../../../screens/remove_hadith.dart';
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
      _adder = DataAdder(ref),
      _deleter = DataDeleter(),
      _searcher = DataSearcher(),
      super(const AsyncValue.loading()) {
    loadHadiths();
  }

  Future<void> loadHadiths() async {
    ref.read(addButtonEnabledProvider.notifier).state = true;
    ref.read(editButtonEnabledProvider.notifier).state = true;
     ref.read(isDeletingProvider.notifier).state = false;
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
      // Ensure the final state is set correctly, even if the stream was updated before.
      if (state.isLoading) {
        if (hadiths.isNotEmpty) {
           state = AsyncValue.data(hadiths);
        } else {
           state = AsyncValue.error(Exception('No hadiths available or failed to load.'), StackTrace.current);
        }
      }
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

      // FIX: After the operation, force a full reload from the source of truth
      // to ensure complete data consistency, fixing the missing titles issue.
      await loadHadiths();

    } catch (e) {
      // The adder handles showing snackbar messages. We just rethrow to signal failure.
      rethrow;
    }
  }

  Future<void> deleteHadith(
    int bab,
    int fasl,
    int number,
    BuildContext context,
  ) async {
     try {
        await _deleter.deleteHadith(
          bab,
          fasl,
          number,
          context,
          state.valueOrNull ?? [],
          (hadiths) => state = AsyncValue.data(hadiths),
        );
        // FIX: After deletion, force a full reload.
        await loadHadiths();
    } catch (e) {
      // The deleter handles showing snackbar messages.
      rethrow;
    }
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