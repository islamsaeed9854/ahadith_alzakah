import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    brightness: Brightness.light,
   // primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Colors.white,
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
   // primarySwatch: Colors.red,
    scaffoldBackgroundColor: Color(0xff1c1c1c),
  );

  ThemeData appTheme = ThemeData(
    fontFamily: 'Kafyan',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18),
      bodyMedium: TextStyle(fontSize: 16),
      titleLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
  );

   static const Color primaryColor = Color(0xffecbd79);
   static const Color secodaryColor = Color(0xfffcead0);
   static const Color redBlackColer = Color(0xff912929);
   static const Color arrowBackLight = Color.fromARGB(255, 9, 5, 5);
   static const Color arrowBackdark = Color.fromARGB(255, 255, 246, 246);

}
