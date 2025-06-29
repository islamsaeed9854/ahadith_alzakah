import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchState {
  final bool isSearching;
  final CancelableOperation<void>? searchOperation;

  SearchState({
    this.isSearching = false,
    this.searchOperation,
  });

  SearchState copyWith({
    bool? isSearching,
    CancelableOperation<void>? searchOperation,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      searchOperation: searchOperation, // Allow setting it to null
    );
  }
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(SearchState());

  void startSearch(CancelableOperation<void> operation) {
    state.searchOperation?.cancel();
    state = state.copyWith(
      isSearching: true,
      searchOperation: operation,
    );
  }

  void stopSearch() {
    state.searchOperation?.cancel();
    state = state.copyWith(
      isSearching: false,
      searchOperation: null,
    );
  }
}

final searchStateProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});