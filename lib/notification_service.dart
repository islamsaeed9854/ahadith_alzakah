import 'dart:convert';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/hadith.dart';
import 'providers/data_manager_provider/data_manager/data_manager.dart';
import '../main.dart';

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

  NotificationService(this.ref);

  Future<void> init() async {
    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize('resource://drawable/ic_launcher', [
      NotificationChannel(
        channelKey: 'daily_hadith_channel',
        channelName: 'Daily Hadith',
        channelDescription: 'Daily Hadith notifications',
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
      ),
    ], debug: true);

    // Set notification listeners
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );

    final prefs = await SharedPreferences.getInstance();
    final hasShownDialog =
        prefs.getBool('has_shown_permission_dialog') ?? false;

    if (!hasShownDialog) {
      // First-time user: Request permission immediately
      final bool hasPermission = await requestNotificationPermission();
      await prefs.setBool('has_shown_permission_dialog', true);

      // If permission granted, enable notifications by default
      if (hasPermission) {
        await prefs.setBool('notifications_enabled', true);
        await scheduleDailyHadithNotification();
      } else {
        await prefs.setBool('notifications_enabled', false);
      }
    } else {
      // User has already seen the dialog, load their preference
      bool notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? false;
      final bool hasPermission = await hasNotificationPermission();

      if (notificationsEnabled && hasPermission) {
        await scheduleDailyHadithNotification();
      } else {
        await cancelNotifications();
      }
    }

    // Load or generate daily Hadith regardless of notification status
    await _loadOrGenerateDailyHadith();
  }

  Future<void> scheduleDailyHadithNotification() async {
    await cancelNotifications();

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
          actionType: ActionType.Default, // Ensure action triggers
        ),
        schedule: NotificationCalendar(
          hour: 12,
          minute: 0,
          second: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } else {}
  }

  Future<Hadith?> _getDailyHadith() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      final lastHadithDate = await _secureStorage.read(key: _lastHadithDateKey);

      if (lastHadithDate == today) {
        final savedHadithJson = await _secureStorage.read(key: _dailyHadithKey);
        if (savedHadithJson != null) {
          try {
            final hadithMap =
                json.decode(savedHadithJson) as Map<String, dynamic>;
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
        error: (error, stack) => allHadiths = [],
        loading: () => allHadiths = [],
      );
      if (allHadiths.isEmpty) {
        await dataManager.loadHadiths();
        final updatedAsyncValue = ref.read(DataProvider);
        updatedAsyncValue.when(
          data: (hadiths) => allHadiths = hadiths,
          error: (error, stack) => allHadiths = [],
          loading: () => allHadiths = [],
        );
      }

      if (allHadiths.isEmpty) {
        return null;
      }

      final activeHadiths =
          allHadiths.where((hadith) => hadith.number != 0).toList();

      if (activeHadiths.isEmpty) {
        return null;
      }

      final today = DateTime.now();
      final seed = today.year * 10000 + today.month * 100 + today.day;
      final random = Random(seed);
      final selectedHadith =
          activeHadiths[random.nextInt(activeHadiths.length)];

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
    } else {}
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
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();

    return isAllowed;
  }

  Future<bool> requestNotificationPermission() async {
    final isAllowed =
        await AwesomeNotifications().requestPermissionToSendNotifications();

    return isAllowed;
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
          actionType: ActionType.Default,
        ),
      );
    } else {}
  }

  Future<int> getScheduledNotificationsCount() async {
    final notifications =
        await AwesomeNotifications().listScheduledNotifications();

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

      final hasHadith = lastHadithDate == today && savedHadithJson != null;

      return hasHadith;
    } catch (e) {
      print('Error checking today hadith: $e');
      return false;
    }
  }

  Future<String?> getLastHadithDate() async {
    try {
      final date = await _secureStorage.read(key: _lastHadithDateKey);

      return date;
    } catch (e) {
      print('Error getting last hadith date: $e');
      return null;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;

    return enabled;
  }
}

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
