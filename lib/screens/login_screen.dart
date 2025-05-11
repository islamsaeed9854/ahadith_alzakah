import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;

    final navNotifier = ref.read(navigationProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, Object? result) async {
        if (!didPop ) {
          navNotifier.changeTab(3); 
          Navigator.of(context).pop();
        }
      },

        child: Scaffold(
          body: Stack(
            children: [
              SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: Image.asset(
                  'assets/opening-screen02.png',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.3),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              SingleChildScrollView(
                child: Container(
                  width: screenWidth,
                  height: screenHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : screenWidth * 0.1,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF5EC).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'تسجيل دخول',
                              style: TextStyle(
                                color: Color(0xff912929),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.08),
                            _buildTextField('البريد الالكترونى'),
                            SizedBox(height: screenWidth * 0.05),
                            _buildTextField("كلمة السر", isPassword: true),
                            SizedBox(height: screenWidth * 0.08),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE6A345),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {},
                                child: const Text(
                                  'دخول',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.05),
                          ],
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
    );
  }

  Widget _buildTextField(String label, {bool isPassword = false}) {
    return TextFormField(
      obscureText: isPassword,
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
