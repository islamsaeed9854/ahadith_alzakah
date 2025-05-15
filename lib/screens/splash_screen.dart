import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../screens/home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(
       context
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          TextApp.appBackgroundWidgetForSplashScreen,
          Container(color: const Color.fromRGBO(0, 0, 0, 0.2)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;
                final baseFontSize =
                    isLandscape
                        ? constraints.maxHeight * 0.12
                        : constraints.maxWidth * 0.11;
                final subFontSize =
                    isLandscape
                        ? constraints.maxHeight * 0.10
                        : constraints.maxWidth * 0.095;

                return SingleChildScrollView(
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 1),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "موسوعة",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: baseFontSize,
                                color: const Color(0xffecbd79),
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: const Color.fromRGBO(0, 0, 0, 0.3),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "أحاديث",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: baseFontSize,
                                color: const Color(0xffecbd79),
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: const Color.fromRGBO(0, 0, 0, 0.3),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "ألزكاة",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: subFontSize,
                                color: const Color(0xffecbd79),
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: const Color.fromRGBO(0, 0, 0, 0.3),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        TextApp.drSamyKhalilName,
                        const SizedBox(height: 1),
                        const SizedBox(height: 1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
