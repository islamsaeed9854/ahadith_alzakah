import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
// Theme Data Provider
final themeProvider = Provider<ThemeData>((ref) {
  final isDarkMode = ref.watch(isDarkModeProvider);
  return ThemeData(
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
    primaryColor: const Color(0xff912929),
    scaffoldBackgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFDF5EC),
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        color: isDarkMode ? Colors.white : Colors.brown,
        fontSize: 16, // Default font size, will be overridden by fontSizeProvider
      ),
      titleLarge: TextStyle(
        color: isDarkMode ? Colors.white : const Color(0xff912929),
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFDF5EC),
      elevation: 0,
    ),
  );
});

// Font Size Provider
final fontSizeProvider = StateProvider<int>((ref) => 19); // Default font size

// Dark Mode Provider
final isDarkModeProvider = StateProvider<bool>((ref) => false); // Default dark mode off