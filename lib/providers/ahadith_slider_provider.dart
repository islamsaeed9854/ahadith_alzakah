import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class HadithState {
  final int currentIndex;
  final List<Map<String, dynamic>> hadiths;
  final bool isLoading;
  final int chapterId;
  final String? errorMessage;
  final double dragOffset;
  final bool isDragging;

  HadithState({
    this.currentIndex = 0,
    this.hadiths = const [],
    this.isLoading = false,
    this.chapterId = 1,
    this.errorMessage,
    this.dragOffset = 0.0,
    this.isDragging = false,
  });

  bool get hasError => errorMessage != null;
  bool get hasData => hadiths.isNotEmpty;
  bool get canGoNext => currentIndex < hadiths.length - 1;
  bool get canGoPrevious => currentIndex > 0;

  HadithState copyWith({
    int? currentIndex,
    List<Map<String, dynamic>>? hadiths,
    bool? isLoading,
    int? chapterId,
    String? errorMessage,
    double? dragOffset,
    bool? isDragging,
  }) {
    return HadithState(
      currentIndex: currentIndex ?? this.currentIndex,
      hadiths: hadiths ?? this.hadiths,
      isLoading: isLoading ?? this.isLoading,
      chapterId: chapterId ?? this.chapterId,
      errorMessage: errorMessage ?? this.errorMessage,
      dragOffset: dragOffset ?? this.dragOffset,
      isDragging: isDragging ?? this.isDragging,
    );
  }
}

class HadithNotifier extends StateNotifier<HadithState> {
  final PageController _pageController;

  HadithNotifier(this._pageController) : super(HadithState());

  Future<void> loadHadiths(int chapterId) async {
    if (state.chapterId == chapterId && state.hasData) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      chapterId: chapterId,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final hadiths = List.generate(5, (index) => {
        'id': '${chapterId}_${index + 1}',
        'text': 'حديث رقم ${index + 1} من الفصل $chapterId: قال رسول الله ﷺ...',
        'reference': 'صحيح البخاري ${index + 1}',
        'chapterId': chapterId.toString(),
      });

      state = state.copyWith(
        hadiths: hadiths,
        currentIndex: 0,
        isLoading: false,
      );

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load hadiths: ${e.toString()}',
      );
    }
  }

  void handlePageChanged(int index) {
    if (index != state.currentIndex && index >= 0 && index < state.hadiths.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void startDrag() {
    state = state.copyWith(isDragging: true, dragOffset: 0.0);
  }

  void updateDrag(double delta) {
    state = state.copyWith(dragOffset: delta);
  }

  void endDrag(double velocity, BuildContext context) {
    final currentPage = _pageController.page ?? state.currentIndex.toDouble();
    
    if (velocity.abs() > 1000) {
      // Swipe
      if (velocity > 0) {
        nextHadith();
      } else {
        previousHadith();
      }
    } else {
      // Drag release
      if (currentPage - currentPage.floor() > 0.3) {
        nextHadith();
      } else {
        previousHadith();
      }
    }
    
    state = state.copyWith(isDragging: false, dragOffset: 0.0);
  }

  void nextHadith() {
    if (state.canGoNext) {
      final nextIndex = state.currentIndex + 1;
      state = state.copyWith(currentIndex: nextIndex);
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousHadith() {
    if (state.canGoPrevious) {
      final prevIndex = state.currentIndex - 1;
      state = state.copyWith(currentIndex: prevIndex);
      _pageController.animateToPage(
        prevIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> refresh() async {
    await loadHadiths(state.chapterId);
  }
}

final hadithProvider = StateNotifierProvider<HadithNotifier, HadithState>((ref) {
  final controller = ref.read(pageControllerProvider);
  return HadithNotifier(controller);
});