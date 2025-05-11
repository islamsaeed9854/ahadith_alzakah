import 'package:flutter/material.dart';

class AddHadithScreen extends StatelessWidget {
  const AddHadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset(
                'assets/opening-screen02.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            
            // Dark overlay with proper sizing
            Container(
              width: screenWidth,
              height: screenHeight,
              color: Colors.black.withOpacity(0.3),
            ),
            
            // Content with proper scrolling
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: screenHeight * 0.05),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                          margin: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : screenWidth * 0.1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF5EC).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'إضافة حديث',
                                style: TextStyle(
                                  color: Color(0xff912929),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              _buildInputField('رقم الباب'),
                              SizedBox(height: screenHeight * 0.02),
                              _buildInputField('رقم الفصل'),
                              SizedBox(height: screenHeight * 0.02),
                              _buildInputField('رقم الحديث'),
                              SizedBox(height: screenHeight * 0.02),
                              _buildInputField('نص الحديث'),
                              SizedBox(height: screenHeight * 0.02),
                              _buildInputField("الخلاصة"),
                              SizedBox(height: screenHeight * 0.02),
                              _buildInputField("التخريج"),
                              SizedBox(height: screenHeight * 0.02),
                              _buildInputField('الدراسة'),
                              SizedBox(height: screenHeight * 0.02),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE6A345),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    "اضافة الحديث",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Add bottom padding to prevent cutoff
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, {int maxLines = 1}) {
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.brown),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6A345)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6A345), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
      ),
    );
  }
}