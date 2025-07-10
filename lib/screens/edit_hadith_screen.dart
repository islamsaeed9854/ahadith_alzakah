import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
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

final editButtonEnabledProvider = StateProvider<bool>((ref) => true);

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
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final isSmallScreen = screenWidth < 400;
        final isLandscape = orientation == Orientation.landscape;
        final keyboardHeight = mediaQuery.viewInsets.bottom;

        final paddingHorizontal =
            isLandscape ? screenWidth * 0.06 : screenWidth * 0.04;
        final paddingVertical =
            isLandscape ? screenHeight * 0.03 : screenHeight * 0.04;
        final titleFontSize =
            isLandscape ? screenWidth * 0.06 : screenWidth * 0.09;
        final inputFontSize =
            isSmallScreen
                ? 14.0
                : isLandscape
                ? 12.0
                : 16.0;
        final labelFontSize =
            isSmallScreen
                ? 18.0
                : isLandscape
                ? 16.0
                : 22.0;
        final buttonFontSize =
            isSmallScreen
                ? 16.0
                : isLandscape
                ? 14.0
                : 18.0;

        final babController = ref.watch(babControllerProvider);
        final faslController = ref.watch(faslControllerProvider);
        final numberController = ref.watch(numberControllerProvider);
        final textController = ref.watch(textControllerProvider);
        final summaryController = ref.watch(summaryControllerProvider);
        final referenceController = ref.watch(referenceControllerProvider);
        final analysisController = ref.watch(analysisControllerProvider);

        final dataManager = ref.read(DataProvider.notifier);

        final currentHadiths = ref.watch(DataProvider).value ?? [];
        final hadith =
            hadithToEdit ??
            (currentHadiths.isNotEmpty
                ? currentHadiths.first
                : Hadith(
                  id: 0,
                  deleted: false,
                  bab: 0,
                  fasl: 0,
                  number: 0,
                  text: '',
                  summary: '',
                  reference: '',
                  analysis: '',
                  chapter_title: '',
                  section_title: '',
                ));

        final isButtonEnabled = ref.watch(editButtonEnabledProvider);

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

        Future<void> updateHadith() async {
          if (!isButtonEnabled) return;

          FocusScope.of(context).unfocus();

          ref.read(editButtonEnabledProvider.notifier).state = false;

          try {
              final bab = int.tryParse(babController.text.trim()) ?? -1;
              final fasl = int.tryParse(faslController.text.trim()) ?? -1;
              final number = int.tryParse(numberController.text.trim()) ?? -1;
              final text = textController.text.trim();
              final summary = summaryController.text.trim();
              final reference = referenceController.text.trim();
              final analysis = analysisController.text.trim();

              if (bab <= 0 || fasl <= 0 || number <= 0) {
                showMessage(
                  context,
                  'رقم الباب أو الفصل أو الحديث يجب أن يكون أكبر من صفر',
                );
                return;
              }

              if (text.isEmpty &&
                  (selectedOption == 'نص الحديث' || selectedOption == 'الكل')) {
                showMessage(context, 'نص الحديث مطلوب');
                return;
              }

              // MODIFIED: Pre-emptive checks for network and data freshness
              final connectivityResult = await Connectivity().checkConnectivity();
              if (connectivityResult == ConnectivityResult.none) {
                showMessage(
                  context,
                  'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة',
                );
                return;
              }

              if (context.mounted) {
                try {
                  final remoteVersion =
                      await RemoteVersionFetcher().fetchRemoteVersion();
                  final localVersion =
                      await LocalVersionHandler().getLocalVersion();
                  if (localVersion < remoteVersion) {
                    showMessage(
                      context,
                      'بياناتك ليست محدّثة. يرجى تحديث الأحاديث أولاً.',
                    );
                    return;
                  }
                } catch (e) {
                  showMessage(
                    context,
                    'فشل التحقق من تحديث البيانات. حاول مرة أخرى.',
                  );
                  return;
                }
              }

              final existingHadith = await dataManager.retrieveHadith(
                bab,
                fasl,
                number,
                context,
              );

              

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

              babController.clear();
              faslController.clear();
              numberController.clear();
              textController.clear();
              summaryController.clear();
              referenceController.clear();
              analysisController.clear();

          } catch (e) {
            String errorMessage;
            if (e.toString().contains('الحديث غير موجود')) {
              errorMessage = 'لم يتم العثور على الحديث المطلوب';
            } else if (e.toString().contains('network') ||
                e.toString().contains('timeout')) {
              errorMessage =
                  'فشل الاتصال بالخادم، يرجى التحقق من الإنترنت وإعادة المحاولة';
            } else if (e.toString().contains('permission') ||
                e.toString().contains('unauthorized')) {
              errorMessage =
                  'لا يوجد إذن كافٍ لتعديل الحديث، يرجى التحقق من الصلاحيات';
            } else if (e.toString().contains('storage') ||
                e.toString().contains('io')) {
              errorMessage =
                  'مشكلة في التخزين المحلي، يرجى التأكد من المساحة المتاحة';
            } else {
              errorMessage = 'حدث خطأ أثناء التعديل: ${e.toString()}';
            }
            showMessage(context, errorMessage);
          } finally {
            ref.read(editButtonEnabledProvider.notifier).state = true;
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
                Container(),
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top:
                        paddingVertical +
                        (keyboardHeight > 0 ? keyboardHeight * 0.1 : 0),
                    bottom: keyboardHeight > 0 ? keyboardHeight + 40 : 40,
                    left: paddingHorizontal,
                    right: paddingHorizontal,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - keyboardHeight,
                      maxWidth: screenWidth * 0.95,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'تعديل حديث',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: titleFontSize,
                                      color: const Color(0xfffcead0),
                                      shadows: [
                                        Shadow(
                                          blurRadius: screenWidth * 0.03,
                                          color: Color(0xfffcead0),
                                        ),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextApp.backButtonLoginAddRemovePages(context),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Container(
                              padding: EdgeInsets.all(
                                isSmallScreen
                                    ? 12
                                    : isLandscape
                                    ? 16
                                    : 18,
                              ),
                              width:
                                  isLandscape
                                      ? screenWidth * 0.85
                                      : screenWidth * 0.9,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 15 : 20,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.1),
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
                                    controller: babController,
                                    fontSize: inputFontSize,
                                    labelFontSize: labelFontSize,
                                    isLandscape: isLandscape,
                                    screenWidth: screenWidth,
                                  ),
                                  SizedBox(height: screenHeight * 0.015),
                                  _buildNumberInputRow(
                                    'رقم الفصل',
                                    controller: faslController,
                                    fontSize: inputFontSize,
                                    labelFontSize: labelFontSize,
                                    isLandscape: isLandscape,
                                    screenWidth: screenWidth,
                                  ),
                                  SizedBox(height: screenHeight * 0.015),
                                  _buildNumberInputRow(
                                    'رقم الحديث',
                                    controller: numberController,
                                    fontSize: inputFontSize,
                                    labelFontSize: labelFontSize,
                                    isLandscape: isLandscape,
                                    screenWidth: screenWidth,
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Divider(
                                    color: Colors.white,
                                    thickness: 2.0,
                                    indent: 16.0,
                                    endIndent: 16.0,
                                  ),
                                  SizedBox(height: screenHeight * 0.015),
                                  if (selectedOption == 'نص الحديث' ||
                                      selectedOption == 'الكل')
                                    _buildTextInputField(
                                      'نص الحديث',
                                      controller: textController,
                                      fontSize: inputFontSize,
                                      labelFontSize: labelFontSize,
                                      maxLines: isLandscape ? 2 : 3,
                                      heightFactor: isLandscape ? 0.06 : 0.08,
                                      screenHeight: screenHeight,
                                      isSmallScreen: isSmallScreen,
                                      isLandscape: isLandscape,
                                    ),
                                  if (selectedOption == 'نص الحديث' ||
                                      selectedOption == 'الكل')
                                    SizedBox(height: screenHeight * 0.015),
                                  if (selectedOption == 'الخلاصة' ||
                                      selectedOption == 'الكل')
                                    _buildTextInputField(
                                      'الخلاصة',
                                      controller: summaryController,
                                      fontSize: inputFontSize,
                                      labelFontSize: labelFontSize,
                                      maxLines: isLandscape ? 2 : 3,
                                      heightFactor: isLandscape ? 0.06 : 0.08,
                                      screenHeight: screenHeight,
                                      isSmallScreen: isSmallScreen,
                                      isLandscape: isLandscape,
                                    ),
                                  if (selectedOption == 'الخلاصة' ||
                                      selectedOption == 'الكل')
                                    SizedBox(height: screenHeight * 0.015),
                                  if (selectedOption == 'التخريج' ||
                                      selectedOption == 'الكل')
                                    _buildTextInputField(
                                      'التخريج',
                                      controller: referenceController,
                                      fontSize: inputFontSize,
                                      labelFontSize: labelFontSize,
                                      maxLines: isLandscape ? 2 : 3,
                                      heightFactor: isLandscape ? 0.06 : 0.08,
                                      screenHeight: screenHeight,
                                      isSmallScreen: isSmallScreen,
                                      isLandscape: isLandscape,
                                    ),
                                  if (selectedOption == 'التخريج' ||
                                      selectedOption == 'الكل')
                                    SizedBox(height: screenHeight * 0.015),
                                  if (selectedOption == 'الدراسة' ||
                                      selectedOption == 'الكل')
                                    _buildTextInputField(
                                      'الدراسة',
                                      controller: analysisController,
                                      fontSize: inputFontSize,
                                      labelFontSize: labelFontSize,
                                      maxLines: isLandscape ? 2 : 3,
                                      heightFactor: isLandscape ? 0.06 : 0.08,
                                      screenHeight: screenHeight,
                                      isSmallScreen: isSmallScreen,
                                      isLandscape: isLandscape,
                                    ),
                                  if (selectedOption == 'الدراسة' ||
                                      selectedOption == 'الكل')
                                    SizedBox(height: screenHeight * 0.04),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width:
                                    isLandscape
                                        ? screenWidth * 0.3
                                        : screenWidth * 0.4,
                                height:
                                    isLandscape
                                        ? screenHeight * 0.1
                                        : screenHeight * 0.06,
                                child: Material(
                                  color:
                                      isButtonEnabled
                                          ? const Color(0xff977c55)
                                          : Colors.grey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(30),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap:
                                        isButtonEnabled ? updateHadith : null,
                                    splashColor: Colors.white.withOpacity(0.3),
                                    highlightColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    child: Center(
                                      child:
                                          isButtonEnabled
                                              ? Text(
                                                "حفظ التعديلات",
                                                style: ArabicTextStyle(
                                                  arabicFont:
                                                      ArabicFont.avenirArabic,
                                                  color: Colors.white,
                                                  fontSize: buttonFontSize,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                              : const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height:
                              isLandscape
                                  ? screenHeight * 0.03
                                  : screenHeight * 0.02,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberInputRow(
    String label, {
    required TextEditingController controller,
    required double fontSize,
    required double labelFontSize,
    required bool isLandscape,
    required double screenWidth,
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
            fontSize: labelFontSize,
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
                vertical: fontSize * 0.8,
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
              fillColor: Color.fromRGBO(255, 255, 255, 0.8),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
            style: TextStyle(fontSize: fontSize, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputField(
    String label, {
    required TextEditingController controller,
    required double fontSize,
    required double labelFontSize,
    int maxLines = 1,
    required double heightFactor,
    required double screenHeight,
    required bool isSmallScreen,
    required bool isLandscape,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ArabicTextStyle(
            arabicFont: ArabicFont.avenirArabic,
            fontWeight: FontWeight.w500,
            color: AppTheme.secodaryColor,
            fontSize: labelFontSize,
          ),
        ),
        SizedBox(
          height:
              isSmallScreen
                  ? 5
                  : isLandscape
                  ? 5
                  : 8,
        ),
        SizedBox(
          height: screenHeight * heightFactor * (isLandscape ? 3 : 1),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines,
            decoration: InputDecoration(
              hintText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: fontSize * 0.8,
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
              fillColor: Color.fromRGBO(255, 255, 255, 0.8),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
            style: TextStyle(fontSize: fontSize, color: Colors.black),
            expands: false,
          ),
        ),
      ],
    );
  }
}