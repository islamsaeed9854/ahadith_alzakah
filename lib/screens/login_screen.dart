import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';

// Static method definition for the back button
IconButton backButtonLoginAddRemovePages(BuildContext context, WidgetRef ref) {
  final navNotifier = ref.read(navigationProvider.notifier);
  return IconButton(
    icon: const Icon(
      Icons.arrow_forward,
      color: AppTheme.secodaryColor,
      size: 30,
    ),
    padding: const EdgeInsets.all(16.0), // Increase tappable area
    onPressed: () {
      navNotifier.changeTab(3); // Change to tab 3
      Navigator.of(context, rootNavigator: true).pop();
    },
  );
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom; // Get keyboard height

    final navNotifier = ref.read(navigationProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevent Scaffold from resizing with keyboard
        body: Stack(
          fit: StackFit.expand, // Ensure Stack fills the entire screen
          children: [
            // Background Image
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: TextApp.appBackgroundWidget,
            ),
            // Content
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: screenHeight * 0.04, // Adjust top padding for back button
                bottom: keyboardHeight > 0 ? keyboardHeight + screenHeight * 0.1 : screenHeight * 0.1, // Add padding for keyboard
                left: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.1,
                right: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.1,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - keyboardHeight, // Adjust minHeight based on keyboard
                ),
                child: IntrinsicHeight(
                  child: isLandscape
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _buildLoginForm(context, screenWidth, screenHeight, isSmallScreen),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLoginForm(context, screenWidth, screenHeight, isSmallScreen),
                          ],
                        ),
                ),
              ),
            ),
            // Back Button at Top Left (Placed last in Stack to ensure it’s on top)
            Positioned(
              top: screenHeight * 0.04,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () {
                  navNotifier.changeTab(3);
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: backButtonLoginAddRemovePages(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, double screenWidth, double screenHeight, bool isSmallScreen) {
    // Controllers and Focus Nodes for each field
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final emailFocusNode = FocusNode();
    final passwordFocusNode = FocusNode();

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.08),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(253, 245, 236, 0.0),
            borderRadius: BorderRadius.circular(isSmallScreen ? 15 : 20),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.1),
                blurRadius: isSmallScreen ? 5 : 10,
                spreadRadius: isSmallScreen ? 1 : 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تسجيل دخول',
                style: GoogleFonts.cairo(
                  color: AppTheme.arrowBackdark,
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenWidth * 0.08),
              _buildTextField(
                'البريد الالكترونى',
                controller: emailController,
                focusNode: emailFocusNode,
                isFocused: emailFocusNode.hasFocus,
                setState: setState,
                isPassword: false,
              ),
              SizedBox(height: screenWidth * 0.05),
              _buildTextField(
                'كلمة السر',
                controller: passwordController,
                focusNode: passwordFocusNode,
                isFocused: passwordFocusNode.hasFocus,
                setState: setState,
                isPassword: true,
              ),
              SizedBox(height: screenWidth * 0.08),
              SizedBox(
                width: screenHeight * 0.1,
                height: screenHeight * 0.08,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF977c55),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? screenHeight * 0.02 : screenHeight * 0.03,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 30 : 33),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "تسجيل دخول",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.03,
                      color: const Color(0xfffcead0),
                      shadows: [
                        Shadow(
                          blurRadius: screenWidth * 0.09,
                          color: const Color(0xfffcead0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.05),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required StateSetter setState,
    bool isPassword = false,
  }) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        setState(() {});
      },
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: isFocused ? null : label,
          hintText: null,
          labelStyle: const TextStyle(color: Colors.brown),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(33),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(33),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(33),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 5,
            ),
          ),
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
          contentPadding: EdgeInsets.symmetric(
            vertical: isFocused ? 15.0 : 10.0,
            horizontal: 15.0,
          ),
        ),
        style: const TextStyle(color: Colors.black),
      ),
    );
  }
}