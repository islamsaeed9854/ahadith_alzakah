import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Dark Mode Status
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// Font Size
final fontSizeProvider = StateProvider<int>((ref) => 20);

// App Theme
final themeProvider = Provider<ThemeData>((ref) {
  final isDarkMode = ref.watch(isDarkModeProvider);

  return ThemeData(
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
    primaryColor: const Color(0xff912929),
    scaffoldBackgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFDF5EC),
    cardColor: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFDF5EC),
      elevation: 0,
      iconTheme: IconThemeData(
        color: isDarkMode ? Colors.amber[200] : Colors.black,
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        color: isDarkMode ? const Color.fromRGBO(255, 255, 255, 0.9) : Colors.brown,
        fontSize: 16,
        height: 1.7,
      ),
      titleLarge: TextStyle(
        color: isDarkMode ? Colors.white : const Color(0xff912929),
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: IconThemeData(
      color: isDarkMode ? Colors.amber[200] : Colors.brown,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: isDarkMode ? Colors.amber[200] : const Color(0xff912929),
      unselectedLabelColor: isDarkMode ? Colors.grey[500] : Colors.brown,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isDarkMode ? const Color(0xFF1c1c1c) : const Color(0xFFFDF5EC),
      selectedItemColor: isDarkMode ? Colors.amber[200] : const Color.fromARGB(255, 192, 144, 76),
      unselectedItemColor: isDarkMode ? Colors.grey[400] : const Color.fromARGB(255, 26, 23, 23),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
});



