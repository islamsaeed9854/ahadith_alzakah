import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notification_service.dart';
import '../screens/settings_screen.dart'; // Import to access notificationsEnabledProvider

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

// Provider for initializing notifications
final notificationInitProvider = FutureProvider<void>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.init();
});

// Provider for scheduling daily notifications
final scheduleNotificationProvider = FutureProvider<void>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  final notificationsEnabled = ref.read(notificationsEnabledProvider);
  if (notificationsEnabled) {
    bool hasPermission = await notificationService.hasNotificationPermission();
    if (hasPermission) {
      await notificationService.scheduleDailyHadithNotification();
    }
  }
});

// Provider for checking notification status
final notificationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  final dailyHadith = await notificationService.getDailyHadith();

  return {
    'hasPermission': await notificationService.hasNotificationPermission(),
    'dailyHadith': dailyHadith,
    'isInitialized': true,
    'notificationsEnabled': await notificationService.areNotificationsEnabled(),
  };
});