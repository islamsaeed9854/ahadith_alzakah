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
import '../core/theme.dart';
import 'package:arabic_font/arabic_font.dart';
final authStateProvider = StreamProvider<bool>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) {
    return supabase.auth.currentUser != null;
  });
});

final notificationsEnabledProvider = StateProvider<bool>((ref) {
  return false;
});

// Providers to manage tap count and timing
final tapCountProvider = StateProvider<int>((ref) => 0);
final lastTapTimeProvider = StateProvider<DateTime?>((ref) => null);

final settingsInitializerProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final notificationService = ref.read(notificationServiceProvider);

  // Load font size
  final fontSize = prefs.getInt('font_size') ?? 20;
  ref.read(fontSizeProvider.notifier).state = fontSize;

  // Load dark mode
  final isDarkMode = prefs.getBool('dark_mode') ?? false;
  ref.read(isDarkModeProvider.notifier).state = isDarkMode;

  // Load notifications enabled state
  bool isEnabled = prefs.getBool('notifications_enabled') ?? false;
  ref.read(notificationsEnabledProvider.notifier).state = isEnabled;

  // Configure notifications based on state
  if (isEnabled) {
    bool hasPermission = await notificationService.hasNotificationPermission();
    if (hasPermission) {
      await notificationService.scheduleDailyHadithNotification();
    } else {
      // If permission is revoked after initial approval, disable notifications
      await prefs.setBool('notifications_enabled', false);
      ref.read(notificationsEnabledProvider.notifier).state = false;
      await notificationService.cancelNotifications();
    }
  } else {
    await notificationService.cancelNotifications();
  }
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Handle tapping the title to trigger login screen after 5 taps
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

    if (tapCount.state >= 5) {
      tapCount.state = 0;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // Show logout confirmation dialog
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'تأكيد تسجيل الخروج',
              style: GoogleFonts.cairo(
                color: Colors.brown.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              'هل أنت متأكد أنك تريد تسجيل الخروج؟',
              style:ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                        fontWeight: FontWeight.w900,
                color: Colors.brown.shade600,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'إلغاء',
                  style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                        fontWeight: FontWeight.w900,
                    color: Colors.brown.shade400,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _logout(context, ref);
                },
                child: Text(
                  'تسجيل الخروج',
                  style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Handle logout
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final supabase = ref.watch(supabaseProvider);
    try {
      await supabase.auth.signOut();
      showSingleSnackBar(
        context,
        message: 'تم تسجيل الخروج بنجاح!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
      ref.read(navigationProvider.notifier).changeTab(0);
    } catch (e) {
      showSingleSnackBar(
        context,
        message:
            e.toString().contains('network')
                ? 'فشل الاتصال بالإنترنت، يرجى التحقق من الشبكة'
                : 'حدث خطأ أثناء تسجيل الخروج: $e',
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _updateFontSize(int newSize, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(fontSizeProvider.notifier).state = newSize;
    await prefs.setInt('font_size', newSize);
  }

  // Toggle dark mode and persist in SharedPreferences
  Future<void> _toggleDarkMode(bool value, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(isDarkModeProvider.notifier).state = value;
    await prefs.setBool('dark_mode', value);
  }

  Future<void> _toggleNotifications(
    bool value,
    WidgetRef ref,
    BuildContext context,
  ) async {
    final notificationService = ref.read(notificationServiceProvider);
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      bool hasPermission =
          await notificationService.hasNotificationPermission();
      if (!hasPermission) {
        hasPermission =
            await notificationService.requestNotificationPermission();
        if (!hasPermission) {
          ref.read(notificationsEnabledProvider.notifier).state = false;
          await prefs.setBool('notifications_enabled', false);
          showSingleSnackBar(
            context,
            message:
                'يرجى تفعيل أذونات الإشعارات من إعدادات الهاتف لتلقي الإشعارات اليومية',
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          );
          return;
        }
      }
      await notificationService.scheduleDailyHadithNotification();
      ref.read(notificationsEnabledProvider.notifier).state = true;
      await prefs.setBool('notifications_enabled', true);
      showSingleSnackBar(
        context,
        message: 'تم تفعيل الإشعارات اليومية',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } else {
      await notificationService.cancelNotifications();
      ref.read(notificationsEnabledProvider.notifier).state = false;
      await prefs.setBool('notifications_enabled', false);
      showSingleSnackBar(
        context,
        message: 'تم إلغاء الإشعارات اليومية',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsInitializerProvider);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final fontSize = ref.watch(fontSizeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final isNotificationsEnabled = ref.watch(notificationsEnabledProvider);
    final authState = ref.watch(authStateProvider);
    final double padding = screenWidth * 0.04;

    final double titleFontSize = isLandscape ? screenWidth * 0.06 : screenWidth * 0.09;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: () => _handleTitleTap(context, ref),
                      child: Text(
                        'الاعدادات',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                          color: const Color(0xfffcead0),
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextApp.backButton(ref),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              buildSettingCard(
                context,
                label: 'حجم الخط',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove,
                        color: Color(0xff977c55),
                      ),
                      onPressed: fontSize > 10
                          ? () => _updateFontSize(fontSize - 1, ref)
                          : null,
                    ),
                    Text(
                      fontSize.toStringAsFixed(0),
                      style: ArabicTextStyle(
                            arabicFont: ArabicFont.avenirArabic,
                        fontWeight: FontWeight.w900,
                        color: Colors.brown.shade800,
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xff977c55),
                      ),
                      onPressed: fontSize < 30
                          ? () => _updateFontSize(fontSize + 1, ref)
                          : null,
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              buildSettingCard(
                context,
                label: 'القراءة الليلية',
                child: Switch.adaptive(
                  value: isDarkMode,
                  onChanged: (value) => _toggleDarkMode(value, ref),
                  activeColor: const Color(0xff977c55),
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              buildSettingCard(
                context,
                label: 'الإشعارات اليومية',
                child: Switch.adaptive(
                  value: isNotificationsEnabled,
                  onChanged: (value) => _toggleNotifications(value, ref, context),
                  activeColor: const Color(0xff977c55),
                  inactiveTrackColor: Colors.grey[300],
                ),
              ),
              authState.when(
                data: (isAuthenticated) {
                  if (isAuthenticated) {
                    return Column(
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        buildClickableSettingCard(
                          context,
                          label: 'إضافة حديث',
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xff977c55),
                            size: 20,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddHadithScreen(),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        buildClickableSettingCard(
                          context,
                          label: 'حذف حديث',
                          icon: const Icon(
                            Icons.delete,
                            color: Color(0xff977c55),
                            size: 20,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RemoveHadithScreen(),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        buildClickableSettingCard(
                          context,
                          label: 'تعديل حديث',
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xff977c55),
                            size: 20,
                          ),
                          onTap: () {
                            ref.watch(DataProvider).when(
                              data: (hadiths) {
                                if (hadiths.isNotEmpty) {
                                  ref
                                      .read(selectedEditFieldProvider.notifier)
                                      .state = '';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditOptionsScreen(),
                                    ),
                                  );
                                } else {
                                  showSingleSnackBar(
                                    context,
                                    message: 'لا يوجد أحاديث للتعديل',
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              },
                              loading: () {
                                showSingleSnackBar(
                                  context,
                                  message: 'لا يوجد أحاديث للتعديل',
                                  backgroundColor: Colors.redAccent,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              error: (error, stackTrace) {
                                showSingleSnackBar(
                                  context,
                                  message: 'لا يوجد أحاديث للتعديل',
                                  backgroundColor: Colors.redAccent,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        buildClickableSettingCard(
                          context,
                          label: 'تسجيل الخروج',
                          icon: const Icon(
                            Icons.logout,
                            color: Color(0xff977c55),
                            size: 20,
                          ),
                          onTap: () => _showLogoutConfirmationDialog(context, ref),
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => Center(child: Text('خطأ: $error')),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}