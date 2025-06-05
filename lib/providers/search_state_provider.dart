import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:async/async.dart';

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
      searchOperation: searchOperation ?? this.searchOperation,
    );
  }
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(SearchState());

  void startSearch(CancelableOperation<void> operation) {
    // Cancel any existing search operation
    state.searchOperation?.cancel();
    
    // Start new search
    state = SearchState(
      isSearching: true,
      searchOperation: operation,
    );
  }

  void stopSearch() {
    state.searchOperation?.cancel();
    state = SearchState(
      isSearching: false,
      searchOperation: null,
    );
  }
}

final searchStateProvider = StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});
