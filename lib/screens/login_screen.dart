import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/navigation_provider.dart';
import '../providers/login_providers.dart';
import '../widgets/login_text_field.dart';

// مزود لـ SupabaseClient
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// مزود لحالة التحميل
final isLoadingProvider = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  // دالة للتحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // دالة تسجيل الدخول
  Future<void> _login(BuildContext context, WidgetRef ref) async {
    final loginFormState = ref.read(loginFormProvider);
    final email = loginFormState.emailController.text.trim();
    final password = loginFormState.passwordController.text.trim();
    final supabase = ref.read(supabaseProvider);

    // التحقق من المدخلات قبل تسجيل الدخول
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            email.isEmpty && password.isEmpty
                ? 'يرجى إدخال البريد الإلكتروني وكلمة المرور'
                : email.isEmpty
                    ? 'يرجى إدخال البريد الإلكتروني'
                    : 'يرجى إدخال كلمة المرور',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'البريد الإلكتروني غير صالح، يرجى إدخال بريد إلكتروني صحيح (مثال: user@example.com)',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // تعيين حالة التحميل
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // مسح الحقول بعد تسجيل الدخول الناجح
        loginFormState.emailController.clear();
        loginFormState.passwordController.clear();

        // عرض SnackBar عند النجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تسجيل الدخول بنجاح! مرحبًا بك',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // الانتقال إلى الصفحة الرئيسية
        ref.read(navigationProvider.notifier).changeTab(3);
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      // معالجة الأخطاء مع رسائل واضحة
      String errorMessage;
      if (e.toString().contains('invalid login credentials')) {
        errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (e.toString().contains('network')) {
        errorMessage = 'فشل الاتصال بالإنترنت، يرجى التحقق من الشبكة';
      } else {
        errorMessage = 'حدث خطأ غير متوقع: $e';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // إعادة تعيين حالة التحميل
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final navNotifier = ref.read(navigationProvider.notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
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
                top: screenHeight * 0.04,
                bottom: keyboardHeight > 0
                    ? keyboardHeight + screenHeight * 0.1
                    : screenHeight * 0.1,
                left: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.1,
                right: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.1,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - keyboardHeight,
                ),
                child: IntrinsicHeight(
                  child: isLandscape
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _buildLoginForm(
                                context,
                                ref,
                                screenWidth,
                                screenHeight,
                                isSmallScreen,
                                isLandscape: true,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLoginForm(
                              context,
                              ref,
                              screenWidth,
                              screenHeight,
                              isSmallScreen,
                              isLandscape: false,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            // Back Button at Top Left
            Positioned(
              top: screenHeight * 0.1,
              left: screenWidth * 0.05,
              child: GestureDetector(
                onTap: () {
                  navNotifier.changeTab(3);
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: TextApp.backButtonLoginAddRemovePages(context),
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
    double screenHeight,
    bool isSmallScreen, {
    required bool isLandscape,
  }) {
    final loginFormState = ref.watch(loginFormProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Container(
      padding: EdgeInsets.all(
        isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.08,
      ),
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
              fontSize: isLandscape ? 36 : 29,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenWidth * 0.08),
          buildTextField(
            'البريد الالكترونى',
            controller: loginFormState.emailController,
            focusNode: loginFormState.emailFocusNode,
            isFocused: loginFormState.emailFocused,
            isPassword: false,
          ),
          SizedBox(height: screenWidth * 0.05),
          buildTextField(
            'كلمة السر',
            controller: loginFormState.passwordController,
            focusNode: loginFormState.passwordFocusNode,
            isFocused: loginFormState.passwordFocused,
            isPassword: true,
          ),
          SizedBox(height: screenWidth * 0.08),
          SizedBox(
            width: isLandscape ? screenWidth * 0.2 : screenWidth * 0.3,
            height: isLandscape ? screenHeight * 0.15 : screenHeight * 0.05,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF977c55),
                foregroundColor: const Color(0xFF977c55),
                overlayColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 30 : 33),
                ),
              ),
              onPressed: isLoading ? null : () => _login(context, ref),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "تسجيل دخول",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: isLandscape ? screenWidth * 0.02 : screenWidth * 0.03,
                        color: const Color(0xfffcead0),
                        shadows: [
                          Shadow(
                            blurRadius: screenWidth * 0.09,
                            color: const Color(0xfffcead0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          SizedBox(height: screenWidth * 0.05),
        ],
      ),
    );
  }
}