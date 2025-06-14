import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/models/hadith.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import 'package:logger/logger.dart';
import '../providers/data_manager_provider/data_manager/data_loader.dart';
import '../core/utils.dart';
import 'package:arabic_font/arabic_font.dart';

// Provider للتحكم في حالة الزر (معطل أو لا)
final addButtonEnabledProvider = StateProvider<bool>((ref) => true);

// Providers for text controllers
final babControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final faslControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final numberControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final textControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final summaryControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final referenceControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final analysisControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

class AddHadithScreen extends ConsumerWidget {
  const AddHadithScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Get controllers from providers
    final babController = ref.watch(babControllerProvider);
    final faslController = ref.watch(faslControllerProvider);
    final numberController = ref.watch(numberControllerProvider);
    final textController = ref.watch(textControllerProvider);
    final summaryController = ref.watch(summaryControllerProvider);
    final referenceController = ref.watch(referenceControllerProvider);
    final analysisController = ref.watch(analysisControllerProvider);

    // Get DataManager from provider
    final dataManager = ref.read(DataProvider.notifier);

    // حالة الزر (معطل/شغال)
    final isButtonEnabled = ref.watch(addButtonEnabledProvider);

    // Show message function using showSingleSnackBar
    void showMessage(BuildContext context, String message, {bool isSuccess = false}) {
      if (context.mounted) {
        showSingleSnackBar(
          context,
          message: message,
          backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
          duration: const Duration(seconds: 3),
        );
      }
    }

    // Hide keyboard function
    void _hideKeyboard() {
      FocusScope.of(context).unfocus();
    }

    // Check chapter and section existence
    Future<Map<String, dynamic>> _checkChapterAndSectionExistence(int bab, int fasl) async {
      final jsonData = await dataManager.getJsonData();
      final logger = Logger();

      try {
        if (jsonData == null || jsonData is! Map<String, dynamic> || jsonData['chapters'] is! List) {
          logger.e('Invalid JSON data for chapter/section check');
          return {
            'isChapterMissing': true,
            'isSectionMissing': true,
            'chapterTitle': null,
          };
        }

        final chapters = jsonData['chapters'] as List<dynamic>;
        final isChapterMissing = !chapters.any((ch) => ch['chapter_number'] == bab);

        bool isSectionMissing = true;
        String? existingChapterTitle;

        if (!isChapterMissing) {
          final chapter = chapters.firstWhere((ch) => ch['chapter_number'] == bab);
          existingChapterTitle = chapter['chapter_title'] as String?;
          final sections = chapter['sections'] as List<dynamic>? ?? [];
          isSectionMissing = !sections.any((sec) => sec['section_number'] == fasl);
        }

        return {
          'isChapterMissing': isChapterMissing,
          'isSectionMissing': isSectionMissing,
          'chapterTitle': existingChapterTitle,
        };
      } catch (e) {
        logger.e('Error checking chapter/section existence: $e');
        return {
          'isChapterMissing': true,
          'isSectionMissing': true,
          'chapterTitle': null,
        };
      }
    }

    // Show title input dialog
    Future<Map<String, String?>?> _showTitleInputDialog(
      BuildContext context, {
      required bool isChapterMissing,
      required bool isSectionMissing,
      String? existingChapterTitle,
    }) async {
      final chapterTitleController = TextEditingController();
      final sectionTitleController = TextEditingController();

      return await showDialog<Map<String, String?>?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'إدخال العناوين المفقودة',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: const Color(0xff977c55),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isChapterMissing && existingChapterTitle != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اسم الباب الموجود:',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            existingChapterTitle,
                            style: GoogleFonts.cairo(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  if (isChapterMissing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اسم الباب (مطلوب)',
                          style: GoogleFonts.cairo(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextInputField(
                          'أدخل اسم الباب',
                          MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height,
                          controller: chapterTitleController,
                          isSmallScreen: true,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  if (isSectionMissing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isChapterMissing) SizedBox(height: 16),
                        Text(
                          'اسم الفصل (مطلوب)',
                          style: GoogleFonts.cairo(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildTextInputField(
                          'أدخل اسم الفصل',
                          MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height,
                          controller: sectionTitleController,
                          isSmallScreen: true,
                          maxLines: 1,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(color: Colors.red),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff977c55),
                ),
                onPressed: () {
                  final chapterTitle = isChapterMissing ? chapterTitleController.text.trim() : existingChapterTitle;
                  final sectionTitle = isSectionMissing ? sectionTitleController.text.trim() : null;

                  if ((isChapterMissing && (chapterTitle == null || chapterTitle.isEmpty)) ||
                      (isSectionMissing && (sectionTitle == null || sectionTitle.isEmpty))) {
                    showMessage(context, 'يرجى إدخال جميع البيانات المطلوبة');
                    return;
                  }

                  Navigator.pop(context, {
                    'chapterTitle': chapterTitle,
                    'sectionTitle': sectionTitle,
                  });
                },
                child: Text(
                  'حفظ',
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    }

    // Add hadith function
    Future<void> addHadith() async {
      _hideKeyboard();

      if (!isButtonEnabled) return;

      ref.read(addButtonEnabledProvider.notifier).state = false;

      final bab = int.tryParse(babController.text.trim()) ?? -1;
      final fasl = int.tryParse(faslController.text.trim()) ?? -1;
      final number = int.tryParse(numberController.text.trim()) ?? -1;
      final text = textController.text.trim();
      final summary = summaryController.text.trim();
      final reference = referenceController.text.trim();
      final analysis = analysisController.text.trim();

      if (bab <= 0 || fasl <= 0 || number <= 0) {
        showMessage(context, 'رقم الباب أو الفصل أو الحديث يجب أن يكون أكبر من صفر');
        ref.read(addButtonEnabledProvider.notifier).state = true;
        return;
      }
      if (text.isEmpty) {
        showMessage(context, 'نص الحديث مطلوب');
        ref.read(addButtonEnabledProvider.notifier).state = true;
        return;
      }

      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        showMessage(context, 'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة');
        ref.read(addButtonEnabledProvider.notifier).state = true;
        return;
      }

      try {
        final existenceCheck = await _checkChapterAndSectionExistence(bab, fasl);
        final isChapterMissing = existenceCheck['isChapterMissing'] as bool;
        final isSectionMissing = existenceCheck['isSectionMissing'] as bool;
        final existingChapterTitle = existenceCheck['chapterTitle'] as String?;

        String? chapterTitle = existingChapterTitle;
        String? sectionTitle;

        if (isChapterMissing || isSectionMissing) {
          final result = await _showTitleInputDialog(
            context,
            isChapterMissing: isChapterMissing,
            isSectionMissing: isSectionMissing,
            existingChapterTitle: existingChapterTitle,
          );

          if (result == null) {
            showMessage(context, 'لا يمكن إضافة الحديث بدون إدخال البيانات المطلوبة');
            ref.read(addButtonEnabledProvider.notifier).state = true;
            return;
          }

          if (isChapterMissing) chapterTitle = result['chapterTitle'];
          sectionTitle = result['sectionTitle'];

          if ((isChapterMissing && (chapterTitle == null || chapterTitle.isEmpty)) ||
              (isSectionMissing && (sectionTitle == null || sectionTitle.isEmpty))) {
            showMessage(context, 'يرجى إدخال جميع العناوين المطلوبة');
            ref.read(addButtonEnabledProvider.notifier).state = true;
            return;
          }
        }

        final newHadith = Hadith(
          id: 0,
          deleted: false,
          bab: bab,
          fasl: fasl,
          number: number,
          text: text,
          summary: summary.isNotEmpty ? summary : "",
          reference: reference.isNotEmpty ? reference : "",
          analysis: analysis.isNotEmpty ? analysis : "",
          chapter_title: chapterTitle ?? "",
          section_title: sectionTitle ?? "",
        );

        await dataManager.addHadith(newHadith, 4, context);
        //showMessage(context, 'تم إضافة الحديث بنجاح', isSuccess: true);

        babController.clear();
        faslController.clear();
        numberController.clear();
        textController.clear();
        summaryController.clear();
        referenceController.clear();
        analysisController.clear();

        ref.read(addButtonEnabledProvider.notifier).state = true;
      } catch (e) {
        String errorMessage;
        if (e.toString().contains('network') || e.toString().contains('timeout')) {
          errorMessage = 'فشل الاتصال بالخادم، يرجى التحقق من الإنترنت وإعادة المحاولة';
        } else if (e.toString().contains('permission') || e.toString().contains('unauthorized')) {
          errorMessage = 'لا يوجد إذن كافٍ لإضافة الحديث، يرجى التحقق من الصلاحيات';
        } else if (e.toString().contains('storage') || e.toString().contains('io')) {
          errorMessage = 'مشكلة في التخزين المحلي، يرجى التأكد من المساحة المتاحة';
        } else {
          errorMessage = 'حدث خطأ أثناء الحفظ، يرجى المحاولة لاحقًا';
        }
        showMessage(context, errorMessage);

        ref.read(addButtonEnabledProvider.notifier).state = true;
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container( // إضافة Container للتحكم في الخلفية
          decoration: BoxDecoration(
            image: DecorationImage(
              image: TextApp.appBackgroundWidget.image, // استخدام الخلفية الموجودة
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: GestureDetector(
              onTap: _hideKeyboard,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.04,
                      bottom: keyboardHeight > 0 ? keyboardHeight + 40 : 40,
                      left: screenWidth * 0.04,
                      right: screenWidth * 0.04,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight - keyboardHeight,
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
                                      screenWidth,
                                      screenHeight,
                                      controller: babController,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                    SizedBox(height: screenHeight * 0.015),
                                    _buildNumberInputRow(
                                      'رقم الفصل',
                                      screenWidth,
                                      screenHeight,
                                      controller: faslController,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                    SizedBox(height: screenHeight * 0.015),
                                    _buildNumberInputRow(
                                      'رقم الحديث',
                                      screenWidth,
                                      screenHeight,
                                      controller: numberController,
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
                                      screenHeight,
                                      controller: textController,
                                      isSmallScreen: isSmallScreen,
                                      maxLines: 3,
                                      heightFactor: 0.08,
                                    ),
                                    SizedBox(height: screenHeight * 0.015),
                                    _buildTextInputField(
                                      'الخلاصة',
                                      screenWidth,
                                      screenHeight,
                                      controller: summaryController,
                                      isSmallScreen: isSmallScreen,
                                      maxLines: 3,
                                      heightFactor: 0.08,
                                    ),
                                    SizedBox(height: screenHeight * 0.015),
                                    _buildTextInputField(
                                      'التخريج',
                                      screenWidth,
                                      screenHeight,
                                      controller: referenceController,
                                      isSmallScreen: isSmallScreen,
                                      maxLines: 3,
                                      heightFactor: 0.08,
                                    ),
                                    SizedBox(height: screenHeight * 0.015),
                                    _buildTextInputField(
                                      'الدراسة',
                                      screenWidth,
                                      screenHeight,
                                      controller: analysisController,
                                      isSmallScreen: isSmallScreen,
                                      maxLines: 3,
                                      heightFactor: 0.08,
                                    ),
                                    SizedBox(height: screenHeight * 0.04),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Align(
                                alignment: Alignment.center,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff977c55),
                                    foregroundColor: const Color(0xff977c55),
                                    overlayColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: isSmallScreen ? 12 : 14,
                                    ),
                                    minimumSize: const Size(0, 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: isButtonEnabled ? () => addHadith() : null,
                                  child: Text(
                                    "إضافة حديث",
                                    style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInputRow(
    String label,
    double screenWidth,
    double screenHeight, {
    required TextEditingController controller,
    required bool isSmallScreen,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
            fontWeight: FontWeight.w500,
            color: AppTheme.secodaryColor,
            fontSize: isSmallScreen ? 20 : 22,
          ),
        ),
        SizedBox(
          width: isSmallScreen ? screenWidth * 0.2 : screenWidth * 0.2,
          child: TextFormField(
            controller: controller,
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
    double screenWidth,
    double screenHeight, {
    required TextEditingController controller,
    int maxLines = 1,
    required bool isSmallScreen,
    double? heightFactor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final baseHeight = heightFactor != null ? screenHeight * heightFactor + 10 : screenHeight * 0.06;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
            fontWeight: FontWeight.w500,
            color: AppTheme.secodaryColor,
            fontSize: isSmallScreen ? 20 : 22,
          ),
        ),
        SizedBox(height: isSmallScreen ? 5 : 8),
        SizedBox(
          height: baseHeight,
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines,
            keyboardType: keyboardType,
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
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.black,
            ),
            expands: false,
          ),
        ),
      ],
    );
  }
}