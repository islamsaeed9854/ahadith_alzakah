import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AddHadithScreen extends ConsumerWidget {
  const AddHadithScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Full-screen background image with proper scaling
            SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: TextApp.appBackgroundWidget,
            ),

            // Dark overlay with gradient to match the image's ambiance
            Container(
              width: screenWidth,
              height: screenHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(100, 0, 0, 0), // Lighter at top
                    Color.fromARGB(150, 0, 0, 0), // Darker at bottom
                  ],
                ),
              ),
            ),

            // Content with proper scrolling
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: screenHeight * 0.04),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'إضافة حديث',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.09,
                                  color: const Color(0xfffcead0),
                                  shadows: [
                                    Shadow(
                                      blurRadius: screenWidth * 0.03,
                                      color: const Color(0xfffcead0),
                                    ),
                                  ],
                                ),
                              ),
                              TextApp.backButtonLoginAddRemovePages(context),
                            ],
                          ),
                        ),

                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 18),
                          width:
                              isSmallScreen
                                  ? screenWidth * 0.9
                                  : screenWidth * 0.9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNumberInputRow(
                                'رقم الباب',
                                screenWidth,
                                isSmallScreen: isSmallScreen,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              _buildNumberInputRow(
                                'رقم الفصل',
                                screenWidth,
                                isSmallScreen: isSmallScreen,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              _buildNumberInputRow(
                                'رقم الحديث',
                                screenWidth,
                                isSmallScreen: isSmallScreen,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Divider(
                                color: Colors.white,
                                thickness: 2.0,
                                indent: 16.0,
                                endIndent: 16.0,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              _buildTextInputField(
                                'نص الحديث',
                                screenWidth,
                                isSmallScreen: isSmallScreen,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              _buildTextInputField(
                                'الخلاصة',
                                screenWidth,
                                isSmallScreen: isSmallScreen,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              _buildTextInputField(
                                'التخريج',
                                screenWidth,
                                isSmallScreen: isSmallScreen,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              _buildTextInputField(
                                'الدراسة',
                                screenWidth,
                                isSmallScreen: isSmallScreen,
                              ),

                              SizedBox(height: screenHeight * 0.04),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: screenWidth * 0.4,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xff977c55,
                              ), // Match SearchScreen button color
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  30,
                                ), // Match SearchScreen button radius
                              ),
                              minimumSize: Size(
                                screenWidth * 0.1,
                                0,
                              ), // Minimum width of 10% of screen width
                            ),
                            onPressed: () {},
                            child: Text(
                              "إضافة حديث",
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Footer text and bottom padding
                    Padding(
                      padding: EdgeInsets.only(
                        top: screenHeight * 0.02,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInputRow(
    String label,
    double screenWidth, {
    required bool isSmallScreen,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppTheme.secodaryColor,
            fontSize: isSmallScreen ? 20 : 22,
          ),
        ),
        SizedBox(
          width:
              isSmallScreen
                  ? screenWidth * 0.2
                  : screenWidth * 0.2, // Adjusted for balance
          child: TextFormField(
            keyboardType: TextInputType.number,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: '', // Empty hint to keep box empty
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isSmallScreen ? 10 : 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30), // Match SearchScreen
                borderSide: const BorderSide(
                  color: Color(0xffe2b97f),
                  width: 4.5,
                ), // Match SearchScreen
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30), // Match SearchScreen
                borderSide: const BorderSide(
                  color: Color(0xffe2b97f),
                  width: 4.5,
                ), // Match SearchScreen
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30), // Match SearchScreen
                borderSide: const BorderSide(
                  color: Color(0xffe2b97f),
                  width: 4.5,
                ), // Match SearchScreen
              ),
              filled: true,
              fillColor: const Color.fromRGBO(
                248,
                240,
                227,
                0.8,
              ), // Match SearchScreen
            ),
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputField(
    String label,
    double screenWidth, {
    int maxLines = 1,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppTheme.secodaryColor,
            fontSize: isSmallScreen ? 20 : 22,
          ),
        ),
        SizedBox(height: isSmallScreen ? 5 : 8),
        TextFormField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: '', // Empty hint to keep box empty
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isSmallScreen ? 10 : 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), // Match SearchScreen
              borderSide: const BorderSide(
                color: Color(0xffe2b97f),
                width: 4.5,
              ), // Match SearchScreen
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), // Match SearchScreen
              borderSide: const BorderSide(
                color: Color(0xffe2b97f),
                width: 4.5,
              ), // Match SearchScreen
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), // Match SearchScreen
              borderSide: const BorderSide(
                color: Color(0xffe2b97f),
                width: 4.5,
              ), // Match SearchScreen
            ),
            filled: true,
            fillColor: const Color.fromRGBO(
              248,
              240,
              227,
              0.8,
            ), // Match SearchScreen
          ),
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
