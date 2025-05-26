import 'dart:convert';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/hadith.dart';
import 'providers/data_manager_provider/data_manager/data_manager.dart';

// Provider for storing the selected daily Hadith
final dailyHadithProvider = StateNotifierProvider<DailyHadithNotifier, Hadith?>(
  (ref) => DailyHadithNotifier(),
);

class DailyHadithNotifier extends StateNotifier<Hadith?> {
  DailyHadithNotifier() : super(null);

  void setDailyHadith(Hadith hadith) {
    state = hadith;
  }

  void clearDailyHadith() {
    state = null;
  }
}

class NotificationService {
  final Ref ref;
  final _secureStorage = const FlutterSecureStorage();

  static const String _lastHadithDateKey = 'daily_hadith_last_date';
  static const String _dailyHadithKey = 'daily_hadith_data';
  static const String _hasRequestedPermissionKey = 'has_requested_permission';
  static const String _permissionDeniedKey = 'permission_denied';

  NotificationService(this.ref);

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'daily_hadith_channel',
          channelName: 'Daily Hadith',
          channelDescription: 'Daily Hadith notifications',
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );

    // Load notifications enabled state from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;

    // Check permission status
    final hasRequestedPermission = await _secureStorage.read(key: _hasRequestedPermissionKey);
    final bool permissionDenied = await isPermissionDenied(); // Renamed variable to avoid shadowing

    if (hasRequestedPermission == null && !permissionDenied) {
      // First app launch; don't request permission here, defer to SettingsScreen
      await _secureStorage.write(key: _hasRequestedPermissionKey, value: 'true');
    }

    // Load or generate daily Hadith
    await _loadOrGenerateDailyHadith();

    // Only schedule notifications if enabled in SettingsScreen
    if (notificationsEnabled && !permissionDenied) {
      bool hasPermission = await hasNotificationPermission();
      if (hasPermission) {
        await scheduleDailyHadithNotification();
      } else {
        // If no permission, disable notifications
        await prefs.setBool('notifications_enabled', false);
        await cancelNotifications();
      }
    } else {
      await cancelNotifications();
    }
  }

  Future<void> scheduleDailyHadithNotification() async {
    final hadith = await _getDailyHadith();

    if (hadith != null) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 100,
          channelKey: 'daily_hadith_channel',
          title: 'حديث اليوم',
          body: _formatHadith(hadith),
          notificationLayout: NotificationLayout.BigText,
          bigPicture: null,
          largeIcon: 'resource://drawable/ic_launcher',
        ),
        schedule: NotificationCalendar(
          hour: 12,
          minute: 00,
          second: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    }
  }

  Future<Hadith?> _getDailyHadith() async {
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    try {
      final lastHadithDate = await _secureStorage.read(key: _lastHadithDateKey);

      if (lastHadithDate == today) {
        final savedHadithJson = await _secureStorage.read(key: _dailyHadithKey);
        if (savedHadithJson != null) {
          try {
            final hadithMap = json.decode(savedHadithJson) as Map<String, dynamic>;
            return Hadith.fromJson(hadithMap);
          } catch (e) {
            print('Error decoding saved Hadith: $e');
          }
        }
      }

      return await _generateNewDailyHadith();
    } catch (e) {
      print('Error reading from secure storage: $e');
      return await _generateNewDailyHadith();
    }
  }

  Future<Hadith?> _generateNewDailyHadith() async {
    try {
      final dataManager = ref.read(DataProvider.notifier);
      final hadithAsyncValue = ref.read(DataProvider);

      List<Hadith> allHadiths = [];
      hadithAsyncValue.when(
        data: (hadiths) => allHadiths = hadiths,
        loading: () => allHadiths = [],
        error: (error, stack) => allHadiths = [],
      );
      if (allHadiths.isEmpty) {
        await dataManager.loadHadiths();
        final updatedAsyncValue = ref.read(DataProvider);
        updatedAsyncValue.when(
          data: (hadiths) => allHadiths = hadiths,
          loading: () => allHadiths = [],
          error: (error, stack) => allHadiths = [],
        );
      }

      if (allHadiths.isEmpty) {
        return null;
      }

      final activeHadiths = allHadiths.where((hadith) => hadith.number != 0).toList();

      if (activeHadiths.isEmpty) {
        return null;
      }

      final today = DateTime.now();
      final seed = today.year * 10000 + today.month * 100 + today.day;
      final random = Random(seed);
      final selectedHadith = activeHadiths[random.nextInt(activeHadiths.length)];

      await _saveDailyHadith(selectedHadith);

      ref.read(dailyHadithProvider.notifier).setDailyHadith(selectedHadith);

      return selectedHadith;
    } catch (e) {
      print('Error generating daily hadith: $e');
      return null;
    }
  }

  Future<void> _saveDailyHadith(Hadith hadith) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      await _secureStorage.write(key: _lastHadithDateKey, value: today);

      final hadithJson = json.encode(hadith.toJson());
      await _secureStorage.write(key: _dailyHadithKey, value: hadithJson);
    } catch (e) {
      print('Error saving daily hadith to secure storage: $e');
    }
  }

  Future<void> _loadOrGenerateDailyHadith() async {
    final hadith = await _getDailyHadith();
    if (hadith != null) {
      ref.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
    }
  }

  String _formatHadith(Hadith hadith) {
    String text = hadith.text;

    if (text.length > 200) {
      text = '${text.substring(0, 197)}...';
    }

    return text;
  }

  Future<Hadith?> getDailyHadith() async {
    return await _getDailyHadith();
  }

  Future<Hadith?> forceNewDailyHadith() async {
    try {
      await _secureStorage.delete(key: _lastHadithDateKey);
      await _secureStorage.delete(key: _dailyHadithKey);
      ref.read(dailyHadithProvider.notifier).clearDailyHadith();
      return await _generateNewDailyHadith();
    } catch (e) {
      print('Error forcing new daily hadith: $e');
      return null;
    }
  }

  Future<void> cancelNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<bool> hasNotificationPermission() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  Future<bool> requestNotificationPermission() async {
    final isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    if (!isAllowed) {
      // Mark permission as denied if user rejects
      await _secureStorage.write(key: _permissionDeniedKey, value: 'true');
    } else {
      // Clear denied flag if permission is granted
      await _secureStorage.delete(key: _permissionDeniedKey);
    }
    await _secureStorage.write(key: _hasRequestedPermissionKey, value: 'true');
    return isAllowed;
  }

  Future<bool> isPermissionDenied() async {
    final isDenied = await _secureStorage.read(key: _permissionDeniedKey);
    return isDenied == 'true';
  }

  Future<void> resetPermissionRequest() async {
    await _secureStorage.delete(key: _hasRequestedPermissionKey);
    await _secureStorage.delete(key: _permissionDeniedKey);
  }

  Future<void> sendImmediateNotification() async {
    final hadith = await _getDailyHadith();

    if (hadith != null) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'daily_hadith_channel',
          title: 'حديث اليوم',
          body: _formatHadith(hadith),
          notificationLayout: NotificationLayout.BigText,
        ),
      );
    }
  }

  Future<int> getScheduledNotificationsCount() async {
    final notifications = await AwesomeNotifications().listScheduledNotifications();
    return notifications.length;
  }

  Future<void> clearDailyHadithData() async {
    try {
      await _secureStorage.delete(key: _lastHadithDateKey);
      await _secureStorage.delete(key: _dailyHadithKey);
      ref.read(dailyHadithProvider.notifier).clearDailyHadith();
    } catch (e) {
      print('Error clearing daily hadith data: $e');
    }
  }

  Future<bool> hasTodayHadith() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastHadithDate = await _secureStorage.read(key: _lastHadithDateKey);
      final savedHadithJson = await _secureStorage.read(key: _dailyHadithKey);

      return lastHadithDate == today && savedHadithJson != null;
    } catch (e) {
      print('Error checking today hadith: $e');
      return false;
    }
  }

  Future<String?> getLastHadithDate() async {
    try {
      return await _secureStorage.read(key: _lastHadithDateKey);
    } catch (e) {
      print('Error getting last hadith date: $e');
      return null;
    }
  }

  // Method to check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }
}