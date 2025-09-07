import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import 'add_hadith.dart';
import '../data/models/hadith.dart';
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
  if (screenWidth > kMediumScreenBreakpoint) return 600; // Fixed width for tablets and desktops
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

final isDeletingProvider = StateProvider<bool>((ref) => false);

class RemoveHadithScreen extends ConsumerWidget {
  const RemoveHadithScreen({super.key});

  void _showMessage(
    BuildContext context,
    String message, {
    bool isSuccess = false,
  }) {
    if (context.mounted) {
      showSingleSnackBar(
        context,
        message: message,
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> deleteHadith(BuildContext context, WidgetRef ref) async {
    ref.read(isDeletingProvider.notifier).state = true;
    FocusScope.of(context).unfocus();

    final babController = ref.read(babControllerProvider);
    final faslController = ref.read(faslControllerProvider);
    final numberController = ref.read(numberControllerProvider);
    final dataManager = ref.read(DataProvider.notifier);

    final bab = int.tryParse(babController.text.trim()) ?? -1;
    final fasl = int.tryParse(faslController.text.trim()) ?? -1;
    final number = int.tryParse(numberController.text.trim()) ?? -1;

    if (bab <= 0 || fasl <= 0 || number <= 0) {
      _showMessage(context, 'رقم الباب أو الفصل أو الحديث يجب أن يكون أكبر من صفر');
      ref.read(isDeletingProvider.notifier).state = false;
      return;
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none && context.mounted) {
      _showMessage(context, 'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة');
      ref.read(isDeletingProvider.notifier).state = false;
      return;
    }

    if (context.mounted) {
      try {
        final remoteVersion = await RemoteVersionFetcher().fetchRemoteVersion();
        final localVersion = await LocalVersionHandler().getLocalVersion();
        if (localVersion < remoteVersion) {
          _showMessage(context, 'بياناتك ليست محدّثة. يرجى تحديث الأحاديث أولاً.');
          ref.read(isDeletingProvider.notifier).state = false;
          return;
        }
      } catch (e) {
        _showMessage(context, 'فشل التحقق من تحديث البيانات. حاول مرة أخرى.');
        ref.read(isDeletingProvider.notifier).state = false;
        return;
      }
    }

    try {
      final currentHadiths = ref.read(DataProvider).value ?? [];
      final hadithToDelete = currentHadiths.firstWhere(
        (hadith) => hadith.bab == bab && hadith.fasl == fasl && hadith.number == number,
        orElse: () => Hadith.empty(),
      );
      
      if (hadithToDelete.id == 0){
         _showMessage(context, 'لم يتم العثور على الحديث المطلوب للحذف.');
          ref.read(isDeletingProvider.notifier).state = false;
          return;
      }

      await dataManager.deleteHadith(
        hadithToDelete.bab,
        hadithToDelete.fasl,
        hadithToDelete.number,
        context,
      );

      babController.clear();
      faslController.clear();
      numberController.clear();
    } catch (e) {
      _showMessage(context, 'حدث خطأ أثناء الحذف، يرجى المحاولة لاحقًا');
    } finally {
      ref.read(isDeletingProvider.notifier).state = false;
    }
  }

  void _showConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFFFDF5EC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'تأكيد الحذف',
            style: ArabicTextStyle(
              arabicFont: ArabicFont.avenirArabic,
              color: Color(0xff912929),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذا الحديث؟',
            style: ArabicTextStyle(
              arabicFont: ArabicFont.avenirArabic,
              color: Color.fromARGB(255, 10, 6, 6),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء', style: ArabicTextStyle(arabicFont: ArabicFont.avenirArabic, fontWeight: FontWeight.w900, color: Colors.brown)),
            ),
            Consumer(
              builder: (context, ref, _) {
                final isDeleting = ref.watch(isDeletingProvider);
                return TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          await deleteHadith(context, ref);
                        },
                  child: isDeleting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('حذف', style: ArabicTextStyle(arabicFont: ArabicFont.avenirArabic, fontWeight: FontWeight.w900, color: Colors.red)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = _getMaxContentWidth(screenWidth);
    final isDeleting = ref.watch(isDeletingProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: TextApp.appBackgroundWidget.image,
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth >= kMediumScreenBreakpoint ? 0 : 20,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Vertically centers the content
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'حذف حديث',
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
                      const SizedBox(height: 60), // Space between title and form
                      _buildLabeledInputField('رقم الباب', ref.watch(babControllerProvider), screenWidth),
                      const SizedBox(height: 24),
                      _buildLabeledInputField('رقم الفصل', ref.watch(faslControllerProvider), screenWidth),
                      const SizedBox(height: 24),
                      _buildLabeledInputField('رقم الحديث', ref.watch(numberControllerProvider), screenWidth),
                      const SizedBox(height: 60), // Space between form and button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff912929),
                          padding: EdgeInsets.symmetric(
                             horizontal: _getResponsiveFontSize(screenWidth, small: 50, medium: 60, large: 70),
                             vertical: _getResponsiveFontSize(screenWidth, small: 12, medium: 14, large: 16),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isDeleting ? null : () => _showConfirmationDialog(context, ref),
                        child: isDeleting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.secodaryColor, strokeWidth: 2.5))
                            : Text(
                                'حذف الحديث',
                                style: ArabicTextStyle(
                                  arabicFont: ArabicFont.avenirArabic,
                                  fontSize: _getResponsiveFontSize(screenWidth, small: 18, medium: 20, large: 22),
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secodaryColor,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledInputField(
    String label,
    TextEditingController controller,
    double screenWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: ArabicTextStyle(
              arabicFont: ArabicFont.avenirArabic,
              color: AppTheme.secodaryColor,
              fontSize: _getResponsiveFontSize(screenWidth, small: 20, medium: 22, large: 24),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xffe6a345), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xffe6a345), width: 2.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xffe6a345), width: 2),
              ),
            ),
            cursorColor: const Color(0xff6f4f2d),
            style: TextStyle(fontSize: _getResponsiveFontSize(screenWidth, small: 16, medium: 18, large: 20), color: Colors.black87),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}

