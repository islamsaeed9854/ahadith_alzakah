// providers/navigation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>(
  (ref) => NavigationNotifier(),
);

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0); // Default to Home (index 4)

  void changeTab(int index) {
    state = index;
  }
}