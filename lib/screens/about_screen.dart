import 'dart:math' as math; // For math.pi
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final double horizontalPadding = isLandscape ? screenWidth * 0.01 : screenWidth * 0.04;
    final double titleFontSize = isLandscape ? screenWidth * 0.02 : screenWidth * 0.09;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with 180-degree rotation
          Transform(
            transform: Matrix4.rotationZ(math.pi), // Rotate 180 degrees
            alignment: Alignment.center,
            child: Image(
              image: TextApp.appBackgroundImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              color: Colors.black26,
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey,
                ); // Fallback if image fails
              },
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Title and Back Button Header
                Container(
                  padding: EdgeInsets.only(
                    top: 16,
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'عن التطبيق',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize,
                            color: const Color(0xfffcead0),
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextApp.backButton(ref),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: screenHeight * 0.02,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // About Us Content
                          SizedBox(
                            width: screenWidth * 0.92, // Consistent width
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.8,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(
                                      158,
                                      158,
                                      158,
                                      0.2,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.015,
                              ),
                              child: Text(
                                 'تطبيق أحاديث الزكاة هو مرجع شامل يحتوي على مجموعة من الأحاديث النبوية الشريفة المتعلقة بالزكاة وأحكامها. يهدف التطبيق إلى تسهيل الوصول إلى هذه الأحاديث المباركة وتعلم أحكام الزكاة من السنة النبوية الشريفة.',
                                style: GoogleFonts.cairo(
                                  color: Colors.brown.shade800,
                                  fontSize: screenWidth * 0.045,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          // Contact Us Title
                          Text(
                            'تواصل معنا',
                            style: GoogleFonts.cairo(
                              color: const Color(0xfffcead0),
                              fontSize: screenWidth * 0.08,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          // Contact Us Content
                          SizedBox(
                            width: screenWidth * 0.92, // Consistent width
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.8,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(
                                      158,
                                      158,
                                      158,
                                      0.2,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.015,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'البريد الإلكتروني: support@appname.com',
                                    style: GoogleFonts.cairo(
                                      color: Colors.brown.shade800,
                                      fontSize: screenWidth * 0.045,
                                      height: 1.6,
                                    ),
                                  ),
                                  Text(
                                    "رقم الهاتف : 00966505137789",
                                    style: GoogleFonts.cairo(
                                      color: Colors.brown.shade800,
                                      fontSize: screenWidth * 0.045,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}