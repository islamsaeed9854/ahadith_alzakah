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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Background Image
            Image(
              image: TextApp.appBackgroundImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              color: Colors.black26,
              colorBlendMode: BlendMode.darken,
            ),
            // Content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Back Button in the Same Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'عن التطبيق',
                                  style: GoogleFonts.cairo(
                                    color: AppTheme.secodaryColor,
                                    fontSize: screenWidth * 0.08,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextApp.backButton(ref),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.04),
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
                                  'معلومات عنامعلومات عنامعلومات عنامعلومات عنامعلومات عنا معلومات عنا\n\n',
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
                                color: AppTheme.secodaryColor,
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
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
                                      "رقم الهاتف :123456789",
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
      ),
    );
  }
}
