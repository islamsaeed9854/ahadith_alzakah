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

// 1. إنشاء مزود لحالة الحذف
final isDeletingProvider = StateProvider<bool>((ref) => false);

class RemoveHadithScreen extends ConsumerWidget {
  const RemoveHadithScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isDeleting = ref.watch(isDeletingProvider);

    // جلب الـ Controllers من المزودات
    final babController = ref.watch(babControllerProvider);
    final faslController = ref.watch(faslControllerProvider);
    final numberController = ref.watch(numberControllerProvider);

    // جلب DataManager من المزود
    final dataManager = ref.read(DataProvider.notifier);

    // دالة لعرض رسالة الخطأ أو النجاح
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

    // دالة لحذف الحديث
    Future<void> deleteHadith(BuildContext dialogContext) async {
      ref.read(isDeletingProvider.notifier).state = true;
      
      final bab = int.tryParse(babController.text.trim()) ?? -1;
      final fasl = int.tryParse(faslController.text.trim()) ?? -1;
      final number = int.tryParse(numberController.text.trim()) ?? -1;

      // التحقق من البيانات الأساسية
      if (bab <= 0 || fasl <= 0 || number <= 0) {
        _showMessage(
          context,
          'رقم الباب أو الفصل أو الحديث يجب أن يكون أكبر من صفر',
        );
        ref.read(isDeletingProvider.notifier).state = false;
        return;
      }

      // التحقق من الاتصال بالإنترنت
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        _showMessage(context, 'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة');
        ref.read(isDeletingProvider.notifier).state = false;
        return;
      }

      try {
        // البحث عن الحديث بناءً على الأرقام المدخلة
        final currentHadiths = ref.read(DataProvider).value ?? [];
        final hadithToDelete = currentHadiths.firstWhere(
          (hadith) =>
              hadith.bab == bab &&
              hadith.fasl == fasl &&
              hadith.number == number,
          orElse: () => Hadith.empty(),
        );

        // حذف الحديث باستخدام DataManager
        await dataManager.deleteHadith(
          hadithToDelete.bab,
          hadithToDelete.fasl,
          hadithToDelete.number,
          context,
        );

        // إعادة تعيين الحقول بعد الحذف الناجح
        babController.clear();
        faslController.clear();
        numberController.clear();

        // العودة إلى الشاشة السابقة
        //if (context.mounted) Navigator.pop(context);
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            SizedBox.expand(child: TextApp.appBackgroundWidget),
            Container(color: const Color.fromRGBO(0, 0, 0, 0.3)),
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
                                            // إخفاء الكيبورد أولاً
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            // انتظار قليل لضمان إخفاء الكيبورد
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
                                            style: GoogleFonts.reemKufi(
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
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.reemKufi(
              color: AppTheme.secodaryColor,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
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
            style: TextStyle(
              color: Color(0xff912929),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذا الحديث؟',
            style: TextStyle(
              color: Color.fromARGB(255, 10, 6, 6),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.brown),
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
                      : const Text('حذف', style: TextStyle(color: Colors.red)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}