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

// Provider for Supabase auth state
final authStateProvider = StreamProvider<bool>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) {
    return supabase.auth.currentUser != null;
  });
});

// Provider for notifications enabled state
final notificationsEnabledProvider = StateProvider<bool>((ref) {
  return false; // Default to false to avoid showing enabled when permissions denied
});

// Provider for notification permission denied state
final permissionDeniedProvider = StateProvider<bool>((ref) {
  return false; // Default; updated by initializer
});

// Initialize all settings from SharedPreferences
final settingsInitializerProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final notificationService = ref.read(notificationServiceProvider);

  // Load font size
  final fontSize = prefs.getInt('font_size') ?? 20; // Default font size
  ref.read(fontSizeProvider.notifier).state = fontSize;

  // Load dark mode
  final isDarkMode = prefs.getBool('dark_mode') ?? false; // Default to false
  ref.read(isDarkModeProvider.notifier).state = isDarkMode;

  // Load permission denied state
  final isPermissionDenied = await notificationService.isPermissionDenied();
  ref.read(permissionDeniedProvider.notifier).state = isPermissionDenied;

  // Load notifications enabled state
  bool isEnabled = prefs.getBool('notifications_enabled') ?? false;

  // If permissions are denied, force notifications to be disabled
  if (isPermissionDenied) {
    isEnabled = false;
    await prefs.setBool('notifications_enabled', false);
    await notificationService.cancelNotifications();
  }

  ref.read(notificationsEnabledProvider.notifier).state = isEnabled;

  // Configure notifications based on state
  if (isEnabled && !isPermissionDenied) {
    bool hasPermission = await notificationService.hasNotificationPermission();
    if (hasPermission) {
      await notificationService.scheduleDailyHadithNotification();
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

    if (lastTapTime == null || now.difference(lastTapTime) > const Duration(seconds: 2)) {
      tapCount.state = 1;
    } else {
      tapCount.state++;
    }

    ref.read(lastTapTimeProvider.notifier).state = now;

    if (tapCount.state >= 5) {
      tapCount.state = 0;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  // Show logout confirmation dialog
  Future<void> _showLogoutConfirmationDialog(BuildContext context, WidgetRef ref) async {
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
              style: GoogleFonts.reemKufi(
                color: Colors.brown.shade600,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(
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
                  style: GoogleFonts.cairo(
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
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      showSingleSnackBar(
        context,
        message: e.toString().contains('network')
            ? 'فشل الاتصال بالإنترنت، يرجى التحقق من الشبكة'
            : 'حدث خطأ أثناء تسجيل الخروج: $e',
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Update font size and persist in SharedPreferences
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

  // Toggle notifications and persist state in SharedPreferences
  Future<void> _toggleNotifications(bool value, WidgetRef ref, BuildContext context) async {
    final notificationService = ref.read(notificationServiceProvider);
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      bool hasPermission = await notificationService.hasNotificationPermission();
      if (!hasPermission) {
        hasPermission = await notificationService.requestNotificationPermission();
        if (!hasPermission) {
          // User denied permission; keep toggle off
          ref.read(notificationsEnabledProvider.notifier).state = false;
          ref.read(permissionDeniedProvider.notifier).state = true;
          await prefs.setBool('notifications_enabled', false);
          showSingleSnackBar(
            context,
            message: 'يرجى تفعيل أذونات الإشعارات لتلقي الإشعارات اليومية',
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          );
          return;
        }
        // Permission granted; update permission state
        ref.read(permissionDeniedProvider.notifier).state = false;
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
    // Watch the initializer to ensure all settings are loaded
    ref.watch(settingsInitializerProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final fontSize = ref.watch(fontSizeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final isNotificationsEnabled = ref.watch(notificationsEnabledProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = isLandscape ? screenWidth * 0.6 : screenWidth * 0.9;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Container(
                      width: contentWidth,
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
                                    'الإعدادات',
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xfffcead0),
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TextApp.backButton(ref),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          _buildSettingCard(
                            context,
                            label: 'حجم الخط',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Color(0xff977c55)),
                                  onPressed: fontSize > 10.0
                                      ? () => _updateFontSize(fontSize - 1, ref)
                                      : null,
                                ),
                                Text(
                                  fontSize.toStringAsFixed(0),
                                  style: GoogleFonts.cairo(
                                    color: Colors.brown.shade800,
                                    fontSize: screenWidth * 0.045,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Color(0xff977c55)),
                                  onPressed: fontSize < 30.0
                                      ? () => _updateFontSize(fontSize + 1, ref)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          _buildSettingCard(
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

                          _buildSettingCard(
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
                                    _buildClickableSettingCard(
                                      context,
                                      label: 'إضافة حديث',
                                      icon: const Icon(Icons.add, color: Color(0xff977c55), size: 20),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AddHadithScreen()),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    _buildClickableSettingCard(
                                      context,
                                      label: 'حذف حديث',
                                      icon: const Icon(Icons.delete, color: Color(0xff977c55), size: 20),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const RemoveHadithScreen()),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    _buildClickableSettingCard(
                                      context,
                                      label: 'تعديل حديث',
                                      icon: const Icon(Icons.edit, color: Color(0xff977c55), size: 20),
                                      onTap: () {
                                        ref.watch(DataProvider).when(
                                              data: (hadiths) {
                                                if (hadiths.isNotEmpty) {
                                                  ref.read(selectedEditFieldProvider.notifier).state = '';
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
                                    _buildClickableSettingCard(
                                      context,
                                      label: 'تسجيل الخروج',
                                      icon: const Icon(Icons.logout, color: Color(0xff977c55), size: 20),
                                      onTap: () => _showLogoutConfirmationDialog(context, ref),
                                    ),
                                  ],
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stackTrace) => Center(child: Text('خطأ: $error')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(158, 158, 158, 0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.reemKufi(
                color: Colors.brown.shade800,
                fontSize: screenWidth * 0.045,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildClickableSettingCard(
    BuildContext context, {
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildSettingCard(context, label: label, child: icon),
    );
  }
}