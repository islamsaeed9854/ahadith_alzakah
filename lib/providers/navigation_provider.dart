import 'package:flutter/material.dart';
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
final tapCountProvider = StateProvider<int>((ref) => 0);
final lastTapTimeProvider = StateProvider<DateTime?>((ref) => null);
// navigation_provider.dart
final innerBooksScreenProvider = StateProvider<Widget?>((ref) => null);

