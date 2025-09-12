import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notification_service.dart';
import '../screens/settings_screen.dart';

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
  final notificationsEnabled = ref.watch(notificationsEnabledProvider);
  
  if (notificationsEnabled) {
    bool hasPermission = await notificationService.hasNotificationPermission();
    if (hasPermission) {
      await notificationService.scheduleDailyHadithNotification();
    }
  } else {
    await notificationService.cancelNotifications();
  }
});

// Provider for checking notification status
final notificationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  
  try {
    final dailyHadith = await notificationService.getDailyHadith();
    final hasPermission = await notificationService.hasNotificationPermission();
    final notificationsEnabled = await notificationService.areNotificationsEnabled();
    final scheduledCount = await notificationService.getScheduledNotificationsCount();
    final hasTodayHadith = await notificationService.hasTodayHadith();
    final lastHadithDate = await notificationService.getLastHadithDate();

    return {
      'hasPermission': hasPermission,
      'dailyHadith': dailyHadith,
      'isInitialized': true,
      'notificationsEnabled': notificationsEnabled,
      'scheduledCount': scheduledCount,
      'hasTodayHadith': hasTodayHadith,
      'lastHadithDate': lastHadithDate,
      'error': null,
    };
  } catch (e) {
    return {
      'hasPermission': false,
      'dailyHadith': null,
      'isInitialized': false,
      'notificationsEnabled': false,
      'scheduledCount': 0,
      'hasTodayHadith': false,
      'lastHadithDate': null,
      'error': e.toString(),
    };
  }
});

// Provider for daily hadith management
final dailyHadithManagementProvider = Provider<DailyHadithManager>((ref) {
  return DailyHadithManager(ref);
});

class DailyHadithManager {
  final Ref ref;
  
  DailyHadithManager(this.ref);
  
  Future<void> refreshDailyHadith() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.forceNewDailyHadith();
    
    // Trigger a refresh of the notification status
    ref.invalidate(notificationStatusProvider);
  }
  
  Future<void> sendTestNotification() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.sendImmediateNotificationTest();
  }
  
  Future<void> clearDailyHadithData() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.clearDailyHadithData();
    
    // Trigger a refresh of the notification status
    ref.invalidate(notificationStatusProvider);
  }
  
  Future<void> rescheduleNotifications() async {
    final notificationService = ref.read(notificationServiceProvider);
    final notificationsEnabled = await notificationService.areNotificationsEnabled();
    
    if (notificationsEnabled) {
      await notificationService.scheduleDailyHadithNotification();
    } else {
      await notificationService.cancelNotifications();
    }
    
    // Trigger a refresh of the notification status
    ref.invalidate(notificationStatusProvider);
  }
}