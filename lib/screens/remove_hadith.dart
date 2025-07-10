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

final isDeletingProvider = StateProvider<bool>((ref) => false);

class RemoveHadithScreen extends ConsumerWidget {
  const RemoveHadithScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isDeleting = ref.watch(isDeletingProvider);

    final babController = ref.watch(babControllerProvider);
    final faslController = ref.watch(faslControllerProvider);
    final numberController = ref.watch(numberControllerProvider);

    final dataManager = ref.read(DataProvider.notifier);

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

    Future<void> deleteHadith(BuildContext dialogContext) async {
      ref.read(isDeletingProvider.notifier).state = true;

      final bab = int.tryParse(babController.text.trim()) ?? -1;
      final fasl = int.tryParse(faslController.text.trim()) ?? -1;
      final number = int.tryParse(numberController.text.trim()) ?? -1;

      if (bab <= 0 || fasl <= 0 || number <= 0) {
        _showMessage(
          context,
          'رقم الباب أو الفصل أو الحديث يجب أن يكون أكبر من صفر',
        );
        ref.read(isDeletingProvider.notifier).state = false;
        return;
      }
      
      // MODIFIED: Pre-emptive checks for network and data freshness
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
          (hadith) =>
              hadith.bab == bab &&
              hadith.fasl == fasl &&
              hadith.number == number,
          orElse: () => Hadith.empty(),
        );

        

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
        String errorMessage;
        if (e.toString().contains('network') ||
            e.toString().contains('timeout')) {
          errorMessage =
              'فشل الاتصال بالخادم، يرجى التحقق من الإنترنت وإعادة المحاولة';
        } else if (e.toString().contains('permission') ||
            e.toString().contains('unauthorized')) {
          errorMessage =
              'لا يوجد إذن كافٍ لحذف الحديث، يرجى التحقق من الصلاحيات';
        } else if (e.toString().contains('storage') ||
            e.toString().contains('io')) {
          errorMessage =
              'مشكلة في التخزين المحلي، يرجى التأكد من المساحة المتاحة';
        } else {
          errorMessage = 'حدث خطأ أثناء الحذف، يرجى المحاولة لاحقًا';
        }
        _showMessage(context, errorMessage);
      } finally {
        ref.read(isDeletingProvider.notifier).state = false;
      }
    }

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
            child: Stack(
              fit: StackFit.expand,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: screenSize.height * 0.04,
                        bottom: keyboardHeight > 0 ? keyboardHeight + 30 : 30,
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - keyboardHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'حذف حديث',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenSize.width * 0.09,
                                      color: const Color(0xfffcead0),
                                      shadows: [
                                        Shadow(
                                          blurRadius: screenSize.width * 0.03,
                                          color: const Color(0xfffcead0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextApp.backButtonLoginAddRemovePages(context),
                                ],
                              ),
                              SizedBox(height: screenSize.height * 0.04),
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildLabeledInputField(
                                      'رقم الباب',
                                      babController,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildLabeledInputField(
                                      'رقم الفصل',
                                      faslController,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildLabeledInputField(
                                      'رقم الحديث',
                                      numberController,
                                    ),
                                    const SizedBox(height: 30),
                                    Align(
                                      alignment: Alignment.center,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xff912929),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          minimumSize: const Size(0, 0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: isDeleting
                                            ? null
                                            : () {
                                                FocusManager.instance.primaryFocus?.unfocus();
                                                Future.delayed(const Duration(milliseconds: 100), () {
                                                  _showConfirmationDialog(
                                                    context,
                                                    deleteHadith,
                                                  );
                                                });
                                              },
                                        child: isDeleting
                                            ? const CircularProgressIndicator(
                                                color: AppTheme.secodaryColor,
                                              )
                                            : Text(
                                                'حذف الحديث',
                                                style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.secodaryColor,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledInputField(
    String label,
    TextEditingController controller,
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
              fontSize: 25,
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
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xffe6a345),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xffe6a345),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Color(0xffe6a345), width: 2),
              ),
            ),
            cursorColor: const Color(0xff6f4f2d),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    Future<void> Function(BuildContext) deleteHadith,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFFFDF5EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
              child: const Text(
                'إلغاء',
                style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                        fontWeight: FontWeight.w900,color: Colors.brown),
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final isDeleting = ref.watch(isDeletingProvider);
                return TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          await deleteHadith(dialogContext);
                        },
                  child: isDeleting
                      ? const CircularProgressIndicator()
                      : const Text('حذف', style:ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                        fontWeight: FontWeight.w900,color: Colors.red)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}