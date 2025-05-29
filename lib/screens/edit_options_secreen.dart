import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_hadith_screen.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils.dart'; // استيراد ملف utils.dart لاستخدام showSingleSnackBar

final selectedEditFieldProvider = StateProvider<String>((ref) => '');

class EditOptionsScreen extends ConsumerWidget {
  const EditOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOption = ref.watch(selectedEditFieldProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    final options = ['نص الحديث', 'الخلاصة', 'التخريج', 'الدراسة', 'الكل'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // الخلفية
            Positioned.fill(
              child: Image.asset(
                'assets/opening-screen-crupped-blured.webp',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان والعودة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "تعديل حديث",
                          style: GoogleFonts.cairo(
                            color: AppTheme.secodaryColor,
                            fontSize: screenWidth * 0.08,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextApp.backButtonLoginAddRemovePages(context),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // المحتوى الرئيسي (اختيارات + زر)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // قائمة الاختيارات
                            SizedBox(
                              width:
                                  isLandscape
                                      ? screenWidth * 0.85
                                      : screenWidth * 0.9,
                              child: Column(
                                children:
                                    options.map((option) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 25,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: RadioListTile<String>(
                                          value: option,
                                          groupValue: selectedOption,
                                          activeColor: const Color(0xfffcf3e8),
                                          onChanged:
                                              (val) =>
                                                  ref
                                                      .read(
                                                        selectedEditFieldProvider
                                                            .notifier,
                                                      )
                                                      .state = val!,
                                          title: Text(
                                            option,
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.reemKufi(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            const SizedBox(height: 35),
                            // زر التالي
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff977c55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                if (selectedOption.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => EditHadithScreen(
                                            selectedOption: selectedOption,
                                          ),
                                    ),
                                  );
                                } else {
                                  showSingleSnackBar(
                                    context,
                                    message: 'اختر أحد الحقول أولاً',
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 3),
                                  );
                                }
                              },
                              child: Text(
                                'التالي',
                                style: GoogleFonts.reemKufi(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
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
          ],
        ),
      ),
    );
  }
}
