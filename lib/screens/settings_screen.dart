import 'package:ahadith_alzakah/screens/login_screen.dart';
import 'package:ahadith_alzakah/screens/remove_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/theme_provider.dart';
import '../screens/add_hadith.dart';
import '../providers/navigation_provider.dart';
import 'edit_options_secreen.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import '../core/utils.dart';
import '../providers/notification_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/setting_card.dart';
import '../widgets/clickable_setting_card.dart';
import 'package:arabic_font/arabic_font.dart';
import '../providers/data_manager_provider/data_sync_service/auth_checker.dart';
import '../core/startup_manager.dart';
import 'dart:io';

const double kMediumScreenBreakpoint = 600.0;
const double kLargeScreenBreakpoint = 1200.0;
const double kExtraLargeScreenBreakpoint = 1800.0;

double _getMaxContentWidth(double screenWidth) {
  if (screenWidth > kLargeScreenBreakpoint) return screenWidth * 0.7; 
  if (screenWidth > 800) return 700; 
  return screenWidth; 
}

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

final authStateProvider = StreamProvider<bool>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) {
    return supabase.auth.currentUser != null;
  });
});

final notificationsEnabledProvider = StateProvider<bool>((ref) => false);
final autoStartupEnabledProvider = StateProvider<bool>((ref) => false);

final notificationHourProvider = StateProvider<int>((ref) => 12);
final notificationMinuteProvider = StateProvider<int>((ref) => 0);

final settingsInitializerProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final fontSize = prefs.getInt('font_size') ?? 20;
  ref.read(fontSizeProvider.notifier).state = fontSize;
  final isDarkMode = prefs.getBool('dark_mode') ?? false;
  ref.read(isDarkModeProvider.notifier).state = isDarkMode;
  
  bool isEnabled = prefs.getBool('notifications_enabled') ?? true;
  ref.read(notificationsEnabledProvider.notifier).state = isEnabled;
  
  // Check auto-startup status
  if (Platform.isWindows) {
    final isAutoStartupEnabled = await StartupManager.isAutoStartupEnabled();
    ref.read(autoStartupEnabledProvider.notifier).state = isAutoStartupEnabled;
  }
  
  final hour = prefs.getInt('daily_notification_hour') ?? 12;
  final minute = prefs.getInt('daily_notification_minute') ?? 0;
  ref.read(notificationHourProvider.notifier).state = hour;
  ref.read(notificationMinuteProvider.notifier).state = minute;
  
  // Schedule notifications on init if enabled
  if (isEnabled) {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleDailyHadithNotification();
  }
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleNotifications(bool value, WidgetRef ref, BuildContext context) async {
    final notificationService = ref.read(notificationServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    
    ref.read(notificationsEnabledProvider.notifier).state = value;
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      await notificationService.scheduleDailyHadithNotification();
      showSingleSnackBar(context,
          message: 'تم تفعيل الإشعارات اليومية',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2));
    } else {
      await notificationService.cancelNotifications();
      showSingleSnackBar(context,
          message: 'تم إلغاء الإشعارات اليومية',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2));
    }
  }

  Future<void> _toggleAutoStartup(bool value, WidgetRef ref, BuildContext context) async {
    if (!Platform.isWindows) {
      showSingleSnackBar(context,
          message: 'البدء التلقائي متاح فقط على نظام Windows',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3));
      return;
    }

    try {
      bool success;
      if (value) {
        success = await StartupManager.enableAutoStartup();
      } else {
        success = await StartupManager.disableAutoStartup();
      }

      if (success) {
        ref.read(autoStartupEnabledProvider.notifier).state = value;
        showSingleSnackBar(context,
            message: value 
                ? 'تم تفعيل البدء التلقائي مع النظام' 
                : 'تم إلغاء البدء التلقائي مع النظام',
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2));
      } else {
        showSingleSnackBar(context,
            message: 'فشل في ${value ? "تفعيل" : "إلغاء"} البدء التلقائي',
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3));
      }
    } catch (e) {
      showSingleSnackBar(context,
          message: 'حدث خطأ في إعداد البدء التلقائي: $e',
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3));
    }
  }

  
  void _handleTitleTap(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final lastTapTime = ref.read(lastTapTimeProvider);
    final tapCount = ref.read(tapCountProvider.notifier);
    if (lastTapTime == null ||
        now.difference(lastTapTime) > const Duration(seconds: 2)) {
      tapCount.state = 1;
    } else {
      tapCount.state++;
    }
    ref.read(lastTapTimeProvider.notifier).state = now;
    final AuthChecker _authChecker = AuthChecker();
    if (tapCount.state >= 5 && !_authChecker.isUserAuthenticated()) {
      ref.read(isLoadingProvider.notifier).state = false;
      tapCount.state = 0;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _showLogoutConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'تأكيد تسجيل الخروج',
              style: GoogleFonts.cairo(
                  color: Colors.brown.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            content: Text(
              'هل أنت متأكد أنك تريد تسجيل الخروج؟',
              style: ArabicTextStyle(
                  arabicFont: ArabicFont.avenirArabic,
                  fontWeight: FontWeight.w900,
                  color: Colors.brown.shade600,
                  fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء',
                    style: ArabicTextStyle(
                        arabicFont: ArabicFont.avenirArabic,
                        fontWeight: FontWeight.w900,
                        color: Colors.brown.shade400,
                        fontSize: 16)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _logout(context, ref);
                },
                child: Text('تسجيل الخروج',
                    style: ArabicTextStyle(
                        arabicFont: ArabicFont.avenirArabic,
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final supabase = ref.watch(supabaseProvider);
    try {
      await supabase.auth.signOut();
      showSingleSnackBar(context,
          message: 'تم تسجيل الخروج بنجاح!',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2));
      ref.read(navigationProvider.notifier).changeTab(0);
    } catch (e) {
      showSingleSnackBar(context,
          message: e.toString().contains('network')
              ? 'فشل الاتصال بالإنترنت، يرجى التحقق من الشبكة'
              : 'حدث خطأ أثناء تسجيل الخروج: $e',
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3));
    }
  }

  Future<void> _updateFontSize(int newSize, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(fontSizeProvider.notifier).state = newSize;
    await prefs.setInt('font_size', newSize);
  }

  Future<void> _toggleDarkMode(bool value, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(isDarkModeProvider.notifier).state = value;
    await prefs.setBool('dark_mode', value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsInitializerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = _getMaxContentWidth(screenWidth);

    final fontSize = ref.watch(fontSizeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final isNotificationsEnabled = ref.watch(notificationsEnabledProvider);
    final isAutoStartupEnabled = ref.watch(autoStartupEnabledProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 800 ? 0 : 20,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _handleTitleTap(context, ref),
                          child: Text(
                            'الاعدادات',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: _getResponsiveFontSize(screenWidth, small: 34.0, medium: 38.0, large: 42.0),
                              color: const Color(0xfffcead0),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextApp.backButton(ref)
                        ),
                      ],
                    ),
                  ),
                  buildSettingCard(context,
                      label: 'حجم الخط',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Color(0xff977c55)),
                            onPressed: fontSize > 10 ? () => _updateFontSize(fontSize - 1, ref) : null,
                          ),
                          Text(fontSize.toStringAsFixed(0)),
                          IconButton(
                            icon: const Icon(Icons.add, color: Color(0xff977c55)),
                            onPressed: fontSize < 30 ? () => _updateFontSize(fontSize + 1, ref) : null,
                          ),
                        ],
                      )),
                  buildSettingCard(context,
                      label: 'القراءة الليلية',
                      child: Switch.adaptive(
                        value: isDarkMode,
                        onChanged: (value) => _toggleDarkMode(value, ref),
                        activeColor: const Color(0xff977c55),
                        inactiveTrackColor: Colors.grey[300],
                      )),
                  if (Platform.isWindows)
                    buildSettingCard(context,
                        label: 'البدء التلقائي مع النظام',
                        child: Switch.adaptive(
                          value: isAutoStartupEnabled,
                          onChanged: (value) => _toggleAutoStartup(value, ref, context),
                          activeColor: const Color(0xff977c55),
                          inactiveTrackColor: Colors.grey[300],
                        )),
                  buildSettingCard(context,
                      label: 'الإشعارات اليومية',
                      child: Switch.adaptive(
                        value: isNotificationsEnabled,
                        onChanged: (value) => _toggleNotifications(value, ref, context),
                        activeColor: const Color(0xff977c55),
                        inactiveTrackColor: Colors.grey[300],
                      )),
                  buildSettingCard(context,
                      label: 'وقت الإشعار اليومي',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final hour = ref.watch(notificationHourProvider);
                              final minute = ref.watch(notificationMinuteProvider);
                              final timeText = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                              return Text(timeText);
                            },
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: ref.read(notificationHourProvider),
                                    minute: ref.read(notificationMinuteProvider)),
                              );
                              if (picked != null) {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setInt('daily_notification_hour', picked.hour);
                                await prefs.setInt('daily_notification_minute', picked.minute);
                                ref.read(notificationHourProvider.notifier).state = picked.hour;
                                ref.read(notificationMinuteProvider.notifier).state = picked.minute;
                                
                           
                                if(ref.read(notificationsEnabledProvider)) {
                                  final notificationService = ref.read(notificationServiceProvider);
                                  await notificationService.scheduleDailyHadithNotification();
                                }

                                showSingleSnackBar(context,
                                    message: 'تم حفظ وقت الإشعار: ${picked.format(context)}',
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff977c55)),
                            child: const Text('اختر وقت'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final notificationService = ref.read(notificationServiceProvider);
                             await notificationService.sendImmediateNotificationTest();
                              showSingleSnackBar(context,
                                  message: 'تم إرسال إشعار تجريبي',
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                            child: const Text('إرسال تجريبي'),
                          ),
                        ],
                      )),
                  authState.when(
                    data: (isAuthenticated) {
                      if (isAuthenticated) {
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            buildClickableSettingCard(context,
                                label: 'إضافة حديث',
                                icon: const Icon(Icons.add, color: Color(0xff977c55), size: 20),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddHadithScreen()))),
                            buildClickableSettingCard(context,
                                label: 'حذف حديث',
                                icon: const Icon(Icons.delete, color: Color(0xff977c55), size: 20),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemoveHadithScreen()))),
                            buildClickableSettingCard(context,
                                label: 'تعديل حديث',
                                icon: const Icon(Icons.edit, color: Color(0xff977c55), size: 20),
                                onTap: () {
                              ref.watch(DataProvider).when(
                                    data: (hadiths) {
                                      if (hadiths.isNotEmpty) {
                                        ref.read(selectedEditFieldProvider.notifier).state = '';
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditOptionsScreen()));
                                      } else {
                                        showSingleSnackBar(context,
                                            message: 'لا يوجد أحاديث للتعديل',
                                            backgroundColor: Colors.redAccent,
                                            duration: const Duration(seconds: 2));
                                      }
                                    },
                                    loading: () {},
                                    error: (error, stackTrace) {},
                                  );
                            }),
                            buildClickableSettingCard(context,
                                label: 'تسجيل الخروج',
                                icon: const Icon(Icons.logout, color: Color(0xff977c55), size: 20),
                                onTap: () => _showLogoutConfirmationDialog(context, ref)),
                          ],
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => const Center(child: Text('')),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}