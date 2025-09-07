import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/navigation_provider.dart';
import '../providers/login_providers.dart';
import '../core/utils.dart';
import '../widgets/login_text_field.dart';

// ======================= Responsive Breakpoints =======================
const double kMediumScreenBreakpoint = 600.0;
const double kLargeScreenBreakpoint = 1200.0;
const double kExtraLargeScreenBreakpoint = 1800.0;
// ========================================================================

// ====== Helper Functions for Responsive Design ======

/// Determines the max width of the content area.
double _getMaxContentWidth(double screenWidth) {
  if (screenWidth > kLargeScreenBreakpoint) return screenWidth * 0.4; // 40% for extra-large screens
  if (screenWidth > kMediumScreenBreakpoint) return 500; // Fixed width for tablets and desktops
  return screenWidth; // Full width for mobile
}

/// A generic helper function to determine font sizes based on screen size.
double _getResponsiveFontSize(double screenWidth, {
  required double small,
  required double medium,
  required double large,
  double? extraLarge,
}) {
  if (screenWidth > kExtraLargeScreenBreakpoint) return extraLarge ?? large * 1.1;
  if (screenWidth > kLargeScreenBreakpoint) return large;
  if (screenWidth > kMediumScreenBreakpoint) return medium;
  return small;
}
// ======================================================

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final isLoadingProvider = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _login(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();

    final loginFormState = ref.read(loginFormProvider);
    final email = loginFormState.emailController.text.trim();
    final password = loginFormState.passwordController.text.trim();
    final supabase = ref.read(supabaseProvider);

    if (email.isEmpty || password.isEmpty) {
      showSingleSnackBar(
        context,
        message: email.isEmpty && password.isEmpty
            ? 'يرجى إدخال البريد الإلكتروني وكلمة المرور'
            : email.isEmpty
                ? 'يرجى إدخال البريد الإلكتروني'
                : 'يرجى إدخال كلمة المرور',
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      showSingleSnackBar(
        context,
        message: 'البريد الإلكتروني غير صالح، يرجى إدخال بريد إلكتروني صحيح (مثال: user@example.com)',
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (password.length < 6) {
      showSingleSnackBar(
        context,
        message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        loginFormState.emailController.clear();
        loginFormState.passwordController.clear();

        showSingleSnackBar(
          context,
          message: 'تم تسجيل الدخول بنجاح! مرحبًا بك',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        );
        ref.read(navigationProvider.notifier).changeTab(3);
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (e.toString().contains('network') || e.toString().contains('Failed host lookup')) {
        errorMessage = 'فشل الاتصال بالإنترنت، يرجى التحقق من الشبكة';
      } else {
        errorMessage = 'حدث خطأ غير متوقع: $e';
      }
      showSingleSnackBar(
        context,
        message: errorMessage,
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = _getMaxContentWidth(screenWidth);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(child: TextApp.appBackgroundWidget),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth >= kMediumScreenBreakpoint ? 0 : 20,
                  vertical: 20,
                ),
                child: SizedBox(
                  width: contentWidth,
                  child: _buildLoginForm(context, ref, screenWidth),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    WidgetRef ref,
    double screenWidth,
  ) {
    final loginFormState = ref.watch(loginFormProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Centered Title
            Text(
              'تسجيل دخول',
              style: GoogleFonts.cairo(
                color: AppTheme.arrowBackdark,
                fontSize: _getResponsiveFontSize(screenWidth, small: 29, medium: 32, large: 36),
                fontWeight: FontWeight.bold,
              ),
            ),
            // Back button aligned to the left of the content area
            Align(
              alignment: Alignment.centerLeft,
              // Using the original back button from constants without modification
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_forward,
                  color: AppTheme.secodaryColor,
                  size: 30,
                ),
                onPressed: () {
                  // This is the correct logic for this specific button
                  navNotifier.changeTab(3);
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth > kMediumScreenBreakpoint ? 40 : 30),
        buildTextField(
          'البريد الالكتروني',
          controller: loginFormState.emailController,
          focusNode: loginFormState.emailFocusNode,
          isFocused: loginFormState.emailFocused,
          isPassword: false,
        ),
        const SizedBox(height: 20),
        buildTextField(
          'كلمة السر',
          controller: loginFormState.passwordController,
          focusNode: loginFormState.passwordFocusNode,
          isFocused: loginFormState.passwordFocused,
          isPassword: true,
        ),
        SizedBox(height: screenWidth > kMediumScreenBreakpoint ? 40 : 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF977c55),
              foregroundColor: const Color(0xfffcead0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(33),
              ),
            ),
            onPressed: isLoading ? null : () => _login(context, ref),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    "تسجيل دخول",
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: _getResponsiveFontSize(screenWidth, small: 18, medium: 19, large: 20),
                        color: const Color(0xfffcead0),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

