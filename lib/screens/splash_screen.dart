import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/home_screen.dart';
import 'package:arabic_font/arabic_font.dart';
import '../core/constants.dart';
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // SVG Background
          SvgPicture.asset(
            'assets/opening-screen-croped.svg', // Your SVG file path
            fit: BoxFit.cover,
          ),
          
          // Semi-transparent overlay (optional)
          Container(
            color: Colors.black.withOpacity(0.2), // Adjust opacity as needed
          ),
          
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Expanded(flex: 4, child: SizedBox(height: 1)),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Text(
                        "موسوعة",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 50,
                          color: const Color(0xffecbd79),
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "أحاديث",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 50,
                          color: const Color(0xffecbd79),
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "ألزكاة",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 43.1,
                          color: const Color(0xffecbd79),
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex:10,
                  child: Center(child: TextApp.drSamyKhalilName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}