import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/models/hadith.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import 'add_hadith.dart';

class EditHadithScreen extends ConsumerWidget {
  final String selectedOption;
  final Hadith? hadithToEdit;

  const EditHadithScreen({
    super.key,
    required this.selectedOption,
    this.hadithToEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenWidth < 400;
        final isLandscape = orientation == Orientation.landscape;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        // جلب الـ Controllers من المزودات
        final babController = ref.watch(babControllerProvider);
        final faslController = ref.watch(faslControllerProvider);
        final numberController = ref.watch(numberControllerProvider);
        final textController = ref.watch(textControllerProvider);
        final summaryController = ref.watch(summaryControllerProvider);
        final referenceController = ref.watch(referenceControllerProvider);
        final analysisController = ref.watch(analysisControllerProvider);

        // جلب DataManager من المزود
        final dataManager = ref.read(DataProvider.notifier);

        // تحديد الحديث المراد تعديله
        final currentHadiths = ref.watch(DataProvider).value ?? [];
        final hadith = hadithToEdit ?? (currentHadiths.isNotEmpty ? currentHadiths.first : Hadith.empty());

        // تفريغ الحقول عند بناء الشاشة
        WidgetsBinding.instance.addPostFrameCallback((_) {
          babController.clear();
          faslController.clear();
          numberController.clear();
          textController.clear();
          summaryController.clear();
          referenceController.clear();
          analysisController.clear();
        });

        // دالة لعرض رسالة الخطأ أو النجاح
        void _showMessage(BuildContext context, String message, {bool isSuccess = false}) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
                backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        // دالة لتحديث الحديث
        Future<void> updateHadith() async {
          final bab = int.tryParse(babController.text.trim()) ?? -1;
          final fasl = int.tryParse(faslController.text.trim()) ?? -1;
          final number = int.tryParse(numberController.text.trim()) ?? -1;
          final text = textController.text.trim();
          final summary = summaryController.text.trim();
          final reference = referenceController.text.trim();
          final analysis = analysisController.text.trim();

          // التحقق من البيانات الأساسية
          if (bab <= 0 || fasl <= 0 || number <= 0) {
            _showMessage(context, 'رقم الباب أو الفصل أو الحديث يجب أن يكون أكبر من صفر');
            return;
          }

          if (text.isEmpty && (selectedOption == 'نص الحديث' || selectedOption == 'الكل')) {
            _showMessage(context, 'نص الحديث مطلوب');
            return;
          }

          // التحقق من الاتصال بالإنترنت
          final connectivityResult = await (Connectivity().checkConnectivity());
          if (connectivityResult == ConnectivityResult.none) {
            _showMessage(context, 'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة');
            return;
          }

          try {
            final existingHadith = await dataManager.retrieveHadith(bab, fasl, number, context);

            int flag;
            switch (selectedOption) {
              case 'نص الحديث':
                flag = 3;
                break;
              case 'الخلاصة':
                flag = 0;
                break;
              case 'التخريج':
                flag = 2;
                break;
              case 'الدراسة':
                flag = 1;
                break;
              case 'الكل':
                flag = 5;
                break;
              default:
                flag = 5;
            }

            final updatedHadith = Hadith(
              id: hadith.id,
              deleted: hadith.deleted,
              bab: bab,
              fasl: fasl,
              number: number,
              text: text.isNotEmpty ? text : hadith.text,
              summary: summary.isNotEmpty ? summary : hadith.summary,
              reference: reference.isNotEmpty ? reference : hadith.reference,
              analysis: analysis.isNotEmpty ? analysis : hadith.analysis,
              chapter_title: existingHadith.chapter_title,
              section_title: existingHadith.section_title,
            );

            await dataManager.addHadith(updatedHadith, flag, context);
            _showMessage(context, 'تم تعديل الحديث بنجاح', isSuccess: true);

            babController.clear();
            faslController.clear();
            numberController.clear();
            textController.clear();
            summaryController.clear();
            referenceController.clear();
            analysisController.clear();

            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            String errorMessage;
            if (e.toString().contains('الحديث غير موجود')) {
              errorMessage = 'لم يتم العثور على الحديث المطلوب';
            } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
              errorMessage = 'فشل الاتصال بالخادم، يرجى التحقق من الإنترنت وإعادة المحاولة';
            } else if (e.toString().contains('permission') || e.toString().contains('unauthorized')) {
              errorMessage = 'لا يوجد إذن كافٍ لتعديل الحديث، يرجى التحقق من الصلاحيات';
            } else if (e.toString().contains('storage') || e.toString().contains('io')) {
              errorMessage = 'مشكلة في التخزين المحلي، يرجى التأكد من المساحة المتاحة';
            } else {
              errorMessage = 'حدث خطأ أثناء التعديل، يرجى المحاولة لاحقًا';
            }
            _showMessage(context, errorMessage);
          }
        }

        final title = hadith.chapter_title != null && hadith.section_title != null
            ? '${hadith.chapter_title} - ${hadith.section_title}'
            : 'تعديل حديث';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: Stack(
              fit: StackFit.expand,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: TextApp.appBackgroundWidget,
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(100, 0, 0, 0),
                        Color.fromARGB(150, 0, 0, 0),
                      ],
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final maxHeight = constraints.maxHeight;
                    final paddingHorizontal = isLandscape ? maxWidth * 0.06 : maxWidth * 0.04;
                    final paddingVertical = isLandscape ? maxHeight * 0.03 : maxHeight * 0.04;

                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: paddingVertical + (keyboardHeight > 0 ? keyboardHeight * 0.1 : 0),
                        bottom: keyboardHeight > 0 ? keyboardHeight + 40 : 40,
                        left: paddingHorizontal,
                        right: paddingHorizontal,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: maxHeight - keyboardHeight,
                          maxWidth: maxWidth * 0.95,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isLandscape ? maxWidth * 0.06 : maxWidth * 0.07,
                                          color: const Color(0xfffcead0),
                                          shadows: [
                                            Shadow(
                                              blurRadius: maxWidth * 0.03,
                                              color: const Color(0xfffcead0),
                                            ),
                                          ],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextApp.backButtonLoginAddRemovePages(context),
                                  ],
                                ),
                                SizedBox(height: maxHeight * 0.02),
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 12 : isLandscape ? 16 : 18),
                                  width: isLandscape ? maxWidth * 0.85 : maxWidth * 0.9,
                                  decoration: BoxDecoration(
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildNumberInputRow(
                                        'رقم الباب',
                                        maxWidth,
                                        maxHeight,
                                        controller: babController,
                                        isSmallScreen: isSmallScreen,
                                        isLandscape: isLandscape,
                                      ),
                                      SizedBox(height: maxHeight * 0.015),
                                      _buildNumberInputRow(
                                        'رقم الفصل',
                                        maxWidth,
                                        maxHeight,
                                        controller: faslController,
                                        isSmallScreen: isSmallScreen,
                                        isLandscape: isLandscape,
                                      ),
                                      SizedBox(height: maxHeight * 0.015),
                                      _buildNumberInputRow(
                                        'رقم الحديث',
                                        maxWidth,
                                        maxHeight,
                                        controller: numberController,
                                        isSmallScreen: isSmallScreen,
                                        isLandscape: isLandscape,
                                      ),
                                      SizedBox(height: maxHeight * 0.02),
                                      Divider(
                                        color: Colors.white,
                                        thickness: 2.0,
                                        indent: 16.0,
                                        endIndent: 16.0,
                                      ),
                                      SizedBox(height: maxHeight * 0.015),
                                      if (selectedOption == 'نص الحديث' || selectedOption == 'الكل')
                                        _buildTextInputField(
                                          'نص الحديث',
                                          maxWidth,
                                          maxHeight,
                                          controller: textController,
                                          isSmallScreen: isSmallScreen,
                                          maxLines: isLandscape ? 2 : 3,
                                          heightFactor: isLandscape ? 0.06 : 0.08,
                                          isLandscape: isLandscape,
                                        ),
                                      if (selectedOption == 'نص الحديث' || selectedOption == 'الكل')
                                        SizedBox(height: maxHeight * 0.015),
                                      if (selectedOption == 'الخلاصة' || selectedOption == 'الكل')
                                        _buildTextInputField(
                                          'الخلاصة',
                                          maxWidth,
                                          maxHeight,
                                          controller: summaryController,
                                          isSmallScreen: isSmallScreen,
                                          maxLines: isLandscape ? 2 : 3,
                                          heightFactor: isLandscape ? 0.06 : 0.08,
                                          isLandscape: isLandscape,
                                        ),
                                      if (selectedOption == 'الخلاصة' || selectedOption == 'الكل')
                                        SizedBox(height: maxHeight * 0.015),
                                      if (selectedOption == 'التخريج' || selectedOption == 'الكل')
                                        _buildTextInputField(
                                          'التخريج',
                                          maxWidth,
                                          maxHeight,
                                          controller: referenceController,
                                          isSmallScreen: isSmallScreen,
                                          maxLines: isLandscape ? 2 : 3,
                                          heightFactor: isLandscape ? 0.06 : 0.08,
                                          isLandscape: isLandscape,
                                        ),
                                      if (selectedOption == 'التخريج' || selectedOption == 'الكل')
                                        SizedBox(height: maxHeight * 0.015),
                                      if (selectedOption == 'الدراسة' || selectedOption == 'الكل')
                                        _buildTextInputField(
                                          'الدراسة',
                                          maxWidth,
                                          maxHeight,
                                          controller: analysisController,
                                          isSmallScreen: isSmallScreen,
                                          maxLines: isLandscape ? 2 : 3,
                                          heightFactor: isLandscape ? 0.06 : 0.08,
                                          isLandscape: isLandscape,
                                        ),
                                      if (selectedOption == 'الدراسة' || selectedOption == 'الكل')
                                        SizedBox(height: maxHeight * 0.04),
                                    ],
                                  ),
                                ),
                                SizedBox(height: maxHeight * 0.02),
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff977c55),
                                      foregroundColor: const Color(0xff977c55),
                                      overlayColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isLandscape ? 30 : 24,
                                        vertical: isSmallScreen ? 12 : isLandscape ? 10 : 14,
                                      ),
                                      minimumSize: const Size(0, 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: () => updateHadith(),
                                    child: Text(
                                      "حفظ التعديلات",
                                      style: GoogleFonts.amiri(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 16 : isLandscape ? 14 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isLandscape ? maxHeight * 0.03 : maxHeight * 0.02),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberInputRow(
    String label,
    double screenWidth,
    double screenHeight,
    {
    required TextEditingController controller,
    required bool isSmallScreen,
    required bool isLandscape,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.reemKufi(
            fontWeight: FontWeight.w500,
            color: AppTheme.secodaryColor,
            fontSize: isSmallScreen ? 18 : isLandscape ? 16 : 22,
          ),
        ),
        SizedBox(
          width: isLandscape ? screenWidth * 0.25 : screenWidth * 0.2,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isSmallScreen ? 8 : isLandscape ? 6 : 12,
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
              fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : isLandscape ? 12 : 16,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputField(
    String label,
    double screenWidth,
    double screenHeight,
    {
    required TextEditingController controller,
    int maxLines = 1,
    required bool isSmallScreen,
    double? heightFactor,
    required bool isLandscape,
  }) {
    final baseHeight = heightFactor != null ? screenHeight * heightFactor : screenHeight * 0.06;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w500,
            color: AppTheme.secodaryColor,
            fontSize: isSmallScreen ? 18 : isLandscape ? 16 : 22,
          ),
        ),
        SizedBox(height: isSmallScreen ? 5 : isLandscape ? 4 : 8),
        SizedBox(
          height: baseHeight * (isLandscape ? 1.2 : 1),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines,
            decoration: InputDecoration(
              hintText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isSmallScreen ? 8 : isLandscape ? 6 : 12,
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
              fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : isLandscape ? 12 : 16,
              color: Colors.black,
            ),
            expands: false,
          ),
        ),
      ],
    );
  }
}