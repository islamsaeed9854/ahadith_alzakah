import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/home_screen.dart';
import 'package:arabic_font/arabic_font.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(flex: 4, child: SizedBox(height: 1,)),
            Expanded(
              flex:6,
              child: Column(
                children: [
                  Text(
                    "موسوعة",
                    style: GoogleFonts.amiri(
                      fontWeight: FontWeight.bold,
                      fontSize: 50,
                      color: Color(0xffecbd79),
                    ),
                  ),
                  Text(
                    "أحاديث",
                    style: GoogleFonts.amiri(
                      fontWeight: FontWeight.bold,
                      fontSize: 45,
                      color: Color(0xffecbd79),
                    ),
                  ),
                  Text(
                    "ألزكاة",
                    style: GoogleFonts.amiri(
                      fontWeight: FontWeight.bold,
                      fontSize: 43.1,
                      color: Color(0xffecbd79),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 8,
              child: Text(
                    "د/سامى خليل",
                    style: ArabicTextStyle(arabicFont: ArabicFont.dubai,fontSize:25),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
