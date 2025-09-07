import 'package:ahadith_alzakah/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/models/hadith.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import 'package:logger/logger.dart';
import '../core/utils.dart';
import 'package:arabic_font/arabic_font.dart';
import 'package:ahadith_alzakah/providers/data_manager_provider/local_storage_service/local_version_handler.dart';
import 'package:ahadith_alzakah/providers/data_manager_provider/network_service/remote_version_fetcher.dart';
import '../core/theme.dart';
// ======================= Responsive Breakpoints =======================
const double kMediumScreenBreakpoint = 600.0;
const double kLargeScreenBreakpoint = 1200.0;
const double kExtraLargeScreenBreakpoint = 1800.0;
// ========================================================================

// ====== Helper Functions for Responsive Design ======

/// Determines the max width of the content area.
double _getMaxContentWidth(double screenWidth) {
  if (screenWidth > kLargeScreenBreakpoint) return screenWidth * 0.7; // 70% for extra-large screens
  if (screenWidth > kMediumScreenBreakpoint) return 700; // Fixed width for tablets and desktops
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

final addButtonEnabledProvider = StateProvider<bool>((ref) => true);

final babControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final faslControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final numberControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final textControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final summaryControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final referenceControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final analysisControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class AddHadithScreen extends ConsumerWidget {
  const AddHadithScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = _getMaxContentWidth(screenWidth);

    // This function will be passed to the form widget
    void _hideKeyboard() {
      FocusScope.of(context).unfocus();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: TextApp.appBackgroundWidget.image,
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: GestureDetector(
              onTap: _hideKeyboard,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth >= kMediumScreenBreakpoint ? 0 : 20,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: contentWidth,
                    child: _AddHadithForm(), // Extracted form to its own widget
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A widget that contains the entire form logic and UI
class _AddHadithForm extends ConsumerWidget {
  void _hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

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

  Future<Map<String, dynamic>> _checkChapterAndSectionExistence(WidgetRef ref, int bab, int fasl) async {
    final dataManager = ref.read(DataProvider.notifier);
    final jsonData = await dataManager.getJsonData();
    final logger = Logger();

    try {
      if (jsonData == null || jsonData is! Map<String, dynamic> || jsonData['chapters'] is! List) {
        return {'isChapterMissing': true, 'isSectionMissing': true, 'chapterTitle': null};
      }
      final chapters = jsonData['chapters'] as List<dynamic>;
      final chapterData = chapters.firstWhere((ch) => ch['chapter_number'] == bab, orElse: () => null);
      if (chapterData == null) {
        return {'isChapterMissing': true, 'isSectionMissing': true, 'chapterTitle': null};
      }
      final existingChapterTitle = chapterData['chapter_title'] as String?;
      final sections = chapterData['sections'] as List<dynamic>? ?? [];
      final isSectionMissing = !sections.any((sec) => sec['section_number'] == fasl);
      return {'isChapterMissing': false, 'isSectionMissing': isSectionMissing, 'chapterTitle': existingChapterTitle};
    } catch (e) {
      logger.e('Error checking chapter/section existence: $e');
      return {'isChapterMissing': true, 'isSectionMissing': true, 'chapterTitle': null};
    }
  }

  Future<Map<String, String?>?> _showTitleInputDialog(
    BuildContext context, {
    required bool isChapterMissing,
    required bool isSectionMissing,
    String? existingChapterTitle,
  }) async {
    final chapterTitleController = TextEditingController();
    final sectionTitleController = TextEditingController();

    void forceHideKeyboard() {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }

    return await showDialog<Map<String, String?>?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إدخال العناوين المفقودة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xff977c55))),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isChapterMissing && existingChapterTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('اسم الباب الموجود:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.green[700])),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[200]!)),
                            child: Text(existingChapterTitle, style: GoogleFonts.cairo(color: Colors.green[800], fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  if (isChapterMissing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('اسم الباب (مطلوب)', style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.w500)),
                          _buildTextInputField('اسم الباب الجديد', controller: chapterTitleController, maxLines: 1),
                        ],
                      ),
                    ),
                  if (isSectionMissing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('اسم الفصل (مطلوب)', style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.w500)),
                        _buildTextInputField('اسم الفصل الجديد', controller: sectionTitleController, maxLines: 1),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  forceHideKeyboard();
                  Navigator.pop(dialogContext, null);
                },
                child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff977c55)),
                onPressed: () {
                  forceHideKeyboard();
                  final chapterTitle = isChapterMissing ? chapterTitleController.text.trim() : existingChapterTitle;
                  final sectionTitle = isSectionMissing ? sectionTitleController.text.trim() : null;
                  if ((isChapterMissing && (chapterTitle == null || chapterTitle.isEmpty)) || (isSectionMissing && (sectionTitle == null || sectionTitle.isEmpty))) {
                    showMessage(dialogContext, 'يرجى إدخال جميع البيانات المطلوبة');
                    return;
                  }
                  Navigator.pop(dialogContext, {'chapterTitle': chapterTitle, 'sectionTitle': sectionTitle});
                },
                child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> addHadith(BuildContext context, WidgetRef ref) async {
    _hideKeyboard(context);
    if (!ref.read(addButtonEnabledProvider)) return;
    ref.read(addButtonEnabledProvider.notifier).state = false;

    try {
      final bab = int.tryParse(ref.read(babControllerProvider).text.trim()) ?? -1;
      final fasl = int.tryParse(ref.read(faslControllerProvider).text.trim()) ?? -1;
      final number = int.tryParse(ref.read(numberControllerProvider).text.trim()) ?? -1;
      final text = ref.read(textControllerProvider).text.trim();
      final summary = ref.read(summaryControllerProvider).text.trim();
      final reference = ref.read(referenceControllerProvider).text.trim();
      final analysis = ref.read(analysisControllerProvider).text.trim();

      if (bab <= 0 || fasl <= 0 || number <= 0) {
        showMessage(context, 'رقم الباب أو الفصل أو الحديث يجب أن يكون أكبر من صفر');
        return;
      }
      if (text.isEmpty) {
        showMessage(context, 'نص الحديث مطلوب');
        return;
      }

      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none && context.mounted) {
        showMessage(context, 'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة');
        return;
      }

      if (context.mounted) {
        try {
          final remoteVersion = await RemoteVersionFetcher().fetchRemoteVersion();
          final localVersion = await LocalVersionHandler().getLocalVersion();
          if (localVersion < remoteVersion) {
            showMessage(context, 'بياناتك ليست محدّثة. يرجى تحديث الأحاديث أولاً.');
            return;
          }
        } catch (e) {
          showMessage(context, 'فشل التحقق من تحديث البيانات. حاول مرة أخرى.');
          return;
        }
      }

      final existenceCheck = await _checkChapterAndSectionExistence(ref, bab, fasl);
      final isChapterMissing = existenceCheck['isChapterMissing'] as bool;
      final isSectionMissing = existenceCheck['isSectionMissing'] as bool;
      final existingChapterTitle = existenceCheck['chapterTitle'] as String?;
      final hadithInSameSection = (ref.read(DataProvider).value ?? []).firstWhere(
        (h) => h.bab == bab && h.fasl == fasl,
        orElse: () => Hadith.empty(),
      );
      final existingSectionTitle = hadithInSameSection.section_title;

      String? chapterTitle = existingChapterTitle;
      String? sectionTitle = existingSectionTitle;

      if (isChapterMissing || isSectionMissing) {
        final result = await _showTitleInputDialog(context, isChapterMissing: isChapterMissing, isSectionMissing: isSectionMissing, existingChapterTitle: existingChapterTitle);
        if (result == null) {
          showMessage(context, 'لا يمكن إضافة الحديث بدون إدخال البيانات المطلوبة');
          return;
        }
        if (isChapterMissing) chapterTitle = result['chapterTitle'];
        if (isSectionMissing) sectionTitle = result['sectionTitle'];
        if ((isChapterMissing && (chapterTitle == null || chapterTitle.isEmpty)) || (isSectionMissing && (sectionTitle == null || sectionTitle.isEmpty))) {
          showMessage(context, 'يرجى إدخال جميع العناوين المطلوبة');
          return;
        }
      }

      final newHadith = Hadith(id: 0, deleted: false, bab: bab, fasl: fasl, number: number, text: text, summary: summary, reference: reference, analysis: analysis, chapter_title: chapterTitle ?? "", section_title: sectionTitle ?? "");
      await ref.read(DataProvider.notifier).addHadith(newHadith, 4, context);

      if (context.mounted) {
        ref.read(babControllerProvider).clear();
        ref.read(faslControllerProvider).clear();
        ref.read(numberControllerProvider).clear();
        ref.read(textControllerProvider).clear();
        ref.read(summaryControllerProvider).clear();
        ref.read(referenceControllerProvider).clear();
        ref.read(analysisControllerProvider).clear();
      }
    } catch (e) {
      if (context.mounted) {
        showMessage(context, 'حدث خطأ: ${e.toString()}');
      }
    } finally {
      ref.read(addButtonEnabledProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isButtonEnabled = ref.watch(addButtonEnabledProvider);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'إضافة حديث',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveFontSize(screenWidth, small: 34, medium: 38, large: 42),
                color: const Color(0xfffcead0),
                shadows: [Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.3))],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextApp.backButtonLoginAddRemovePages(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNumberInputRow('رقم الباب', controller: ref.watch(babControllerProvider)),
        const SizedBox(height: 16),
        _buildNumberInputRow('رقم الفصل', controller: ref.watch(faslControllerProvider)),
        const SizedBox(height: 16),
        _buildNumberInputRow('رقم الحديث', controller: ref.watch(numberControllerProvider)),
        const SizedBox(height: 24),
        const Divider(color: Color(0x55fcead0), thickness: 1.0, indent: 16.0, endIndent: 16.0),
        const SizedBox(height: 24),
        _buildTextInputField('نص الحديث', controller: ref.watch(textControllerProvider), maxLines: 4),
        const SizedBox(height: 16),
        _buildTextInputField('الخلاصة', controller: ref.watch(summaryControllerProvider), maxLines: 3),
        const SizedBox(height: 16),
        _buildTextInputField('التخريج', controller: ref.watch(referenceControllerProvider), maxLines: 3),
        const SizedBox(height: 16),
        _buildTextInputField('الدراسة', controller: ref.watch(analysisControllerProvider), maxLines: 5),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff977c55),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveFontSize(screenWidth, small: 50, medium: 60, large: 70),
              vertical: _getResponsiveFontSize(screenWidth, small: 12, medium: 14, large: 16),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: isButtonEnabled ? () => addHadith(context, ref) : null,
          child: isButtonEnabled
              ? Text("إضافة حديث", style: GoogleFonts.cairo(fontSize: _getResponsiveFontSize(screenWidth, small: 18, medium: 20, large: 22), fontWeight: FontWeight.bold))
              : const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
        ),
      ],
    );
  }

  Widget _buildNumberInputRow(String label, {required TextEditingController controller}) {
    return Builder(builder: (context) {
       final screenWidth = MediaQuery.of(context).size.width;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ArabicTextStyle(arabicFont: ArabicFont.avenirArabic, fontWeight: FontWeight.w500, color: AppTheme.secodaryColor, fontSize: _getResponsiveFontSize(screenWidth, small: 18, medium: 20, large: 22))),
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLines: 1,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xffe2b97f), width: 2.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xffe2b97f), width: 3.0)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xffe2b97f), width: 2.5)),
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
              ),
              style: TextStyle(fontSize: _getResponsiveFontSize(screenWidth, small: 16, medium: 17, large: 18), color: Colors.black),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTextInputField(String label, {required TextEditingController controller, int maxLines = 1}) {
     return Builder(builder: (context) {
       final screenWidth = MediaQuery.of(context).size.width;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ArabicTextStyle(arabicFont: ArabicFont.avenirArabic, fontWeight: FontWeight.w500, color: AppTheme.secodaryColor, fontSize: _getResponsiveFontSize(screenWidth, small: 18, medium: 20, large: 22))),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xffe2b97f), width: 2.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xffe2b97f), width: 3.0)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xffe2b97f), width: 2.5)),
              filled: true,
              fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
            ),
            style: TextStyle(fontSize: _getResponsiveFontSize(screenWidth, small: 16, medium: 17, large: 18), color: Colors.black, height: 1.5),
          ),
        ],
      );
    });
  }
}
