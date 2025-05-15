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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom; // Get keyboard height

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevent Scaffold from resizing with keyboard
        body: Stack(
          fit: StackFit.expand, // Ensure Stack fills the entire screen
          children: [
            // Full-screen background image with proper scaling
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: TextApp.appBackgroundWidget,
            ),

            // Dark overlay with gradient to match the image's ambiance
            Container(
              width: double.infinity,
              height: double.infinity,
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
              padding: EdgeInsets.only(
                top: screenHeight * 0.04, // Space for back button and title
                bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 20, // Adjust for keyboard
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - keyboardHeight, // Adjust minHeight based on keyboard
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Row(
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

                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 18),
                          width: isSmallScreen ? screenWidth * 0.9 : screenWidth * 0.9,
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
                              backgroundColor: const Color(0xff977c55),
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: Size(screenWidth * 0.1, 0),
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
                    // Footer padding adjusted for keyboard
                    SizedBox(height: 20),
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
          width: isSmallScreen ? screenWidth * 0.2 : screenWidth * 0.2,
          child: TextFormField(
            keyboardType: TextInputType.number,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isSmallScreen ? 10 : 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xffe2b97f),
                  width: 4.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xffe2b97f),
                  width: 4.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xffe2b97f),
                  width: 4.5,
                ),
              ),
              filled: true,
              fillColor: const Color.fromRGBO(248, 240, 227, 0.8),
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
            hintText: '',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isSmallScreen ? 10 : 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xffe2b97f),
                width: 4.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xffe2b97f),
                width: 4.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xffe2b97f),
                width: 4.5,
              ),
            ),
            filled: true,
            fillColor: const Color.fromRGBO(248, 240, 227, 0.8),
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