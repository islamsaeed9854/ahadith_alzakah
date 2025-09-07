import 'package:ahadith_alzakah/core/constants.dart';
import '../core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/models/hadith.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import 'add_hadith.dart';
import '../core/utils.dart';
import 'package:arabic_font/arabic_font.dart';
import 'package:ahadith_alzakah/providers/data_manager_provider/local_storage_service/local_version_handler.dart';
import 'package:ahadith_alzakah/providers/data_manager_provider/network_service/remote_version_fetcher.dart';

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

final editButtonEnabledProvider = StateProvider<bool>((ref) => true);

class EditHadithScreen extends ConsumerWidget {
  final String selectedOption;
  final Hadith? hadithToEdit;

  const EditHadithScreen({
    super.key,
    required this.selectedOption,
    this.hadithToEdit,
  });

  void showMessage(
    BuildContext context,
    String message, {
    bool isSuccess = false,
  }) {
    if (context.mounted && message.isNotEmpty) {
      showSingleSnackBar(
        context,
        message: message,
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> updateHadith(BuildContext context, WidgetRef ref) async {
    if (!ref.read(editButtonEnabledProvider)) return;

    FocusScope.of(context).unfocus();

    ref.read(editButtonEnabledProvider.notifier).state = false;

    try {
      final dataManager = ref.read(DataProvider.notifier);
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

      if (text.isEmpty && (selectedOption == 'نص الحديث' || selectedOption == 'الكل')) {
        showMessage(context, 'نص الحديث مطلوب');
        return;
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
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
        default:
          flag = 5;
      }

      final updatedHadith = Hadith(
        id: existingHadith.id,
        deleted: existingHadith.deleted,
        bab: bab,
        fasl: fasl,
        number: number,
        text: text.isNotEmpty ? text : existingHadith.text,
        summary: summary.isNotEmpty ? summary : existingHadith.summary,
        reference: reference.isNotEmpty ? reference : existingHadith.reference,
        analysis: analysis.isNotEmpty ? analysis : existingHadith.analysis,
        chapter_title: existingHadith.chapter_title,
        section_title: existingHadith.section_title,
      );

      await dataManager.addHadith(updatedHadith, flag, context);

      ref.read(babControllerProvider).clear();
      ref.read(faslControllerProvider).clear();
      ref.read(numberControllerProvider).clear();
      ref.read(textControllerProvider).clear();
      ref.read(summaryControllerProvider).clear();
      ref.read(referenceControllerProvider).clear();
      ref.read(analysisControllerProvider).clear();
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('الحديث غير موجود')) {
        errorMessage = 'لم يتم العثور على الحديث المطلوب';
      } else {
        errorMessage = 'حدث خطأ أثناء التعديل: ${e.toString()}';
      }
      showMessage(context, errorMessage);
    } finally {
      ref.read(editButtonEnabledProvider.notifier).state = true;
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
                  child: _buildForm(context, ref, screenWidth),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, WidgetRef ref, double screenWidth) {
    final isButtonEnabled = ref.watch(editButtonEnabledProvider);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'تعديل حديث',
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
        if (selectedOption == 'نص الحديث' || selectedOption == 'الكل')
          _buildTextInputField('نص الحديث', controller: ref.watch(textControllerProvider), maxLines: 4),
        if (selectedOption == 'الخلاصة' || selectedOption == 'الكل')
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildTextInputField('الخلاصة', controller: ref.watch(summaryControllerProvider), maxLines: 3),
          ),
        if (selectedOption == 'التخريج' || selectedOption == 'الكل')
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildTextInputField('التخريج', controller: ref.watch(referenceControllerProvider), maxLines: 3),
          ),
        if (selectedOption == 'الدراسة' || selectedOption == 'الكل')
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildTextInputField('الدراسة', controller: ref.watch(analysisControllerProvider), maxLines: 5),
          ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff977c55),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveFontSize(screenWidth, small: 40, medium: 50, large: 60),
              vertical: _getResponsiveFontSize(screenWidth, small: 12, medium: 14, large: 16),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: isButtonEnabled ? () => updateHadith(context, ref) : null,
          child: isButtonEnabled
              ? Text("حفظ التعديلات", style: GoogleFonts.cairo(fontSize: _getResponsiveFontSize(screenWidth, small: 18, medium: 20, large: 22), fontWeight: FontWeight.bold))
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
