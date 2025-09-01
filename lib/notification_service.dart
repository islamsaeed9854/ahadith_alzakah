import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../data/models/hadith.dart';
import 'providers/data_manager_provider/data_manager/data_manager.dart';
import '../main.dart';
import '../screens/chapters_screen.dart';
import '../providers/navigation_provider.dart';
import '../screens/home_screen.dart';

// Provider for storing the selected daily Hadith
final dailyHadithProvider = StateNotifierProvider<DailyHadithNotifier, Hadith?>(
  (ref) => DailyHadithNotifier(),
);

// Provider to track whether we should show daily hadith
final showDailyHadithProvider = StateProvider<bool>((ref) => false);

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
  Timer? _windowsTimer;
  Timer? _windowsDailyTimer;

  static const String _lastHadithDateKey = 'daily_hadith_last_date';
  static const String _dailyHadithKey = 'daily_hadith_data';

  NotificationService(this.ref);

  Future<void> init() async {
    if (!kIsWeb && Platform.isWindows) {
      // Windows initialization is handled in main.dart
      await _createWindowsStartupTask();
    } else {
      // Initialize Awesome Notifications
      await AwesomeNotifications().initialize('resource://drawable/ic_launcher', [
        NotificationChannel(
          channelKey: 'daily_hadith_channel',
          channelName: 'Daily Hadith',
          channelDescription: 'Daily Hadith notifications',
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          channelShowBadge: false,
        ),
      ], debug: true);

      // Set notification listeners
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      );
    }

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
      final hadithJson = json.encode(hadith.toJson());
      if (kIsWeb) return;
      if (Platform.isWindows) {
        // Schedule Windows notifications using an in-app timer.
        // Read scheduled hour/minute from prefs (defaults to 12:00).
        final prefs = await SharedPreferences.getInstance();
        final hour = prefs.getInt('daily_notification_hour') ?? 12;
        final minute = prefs.getInt('daily_notification_minute') ?? 0;
        // Use in-app timer and Dart-based notifications only (no native runner or scheduled task).
        await _scheduleWindowsDailyNotification(hadith, hour, minute);
        // Also create a Windows Scheduled Task so the OS can launch the app at the scheduled time
        // (useful when the app is closed). This is best-effort and may fail in environments
        // without sufficient privileges.
        await _createWindowsScheduledTask(hour, minute);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final hour = prefs.getInt('daily_notification_hour') ?? 12;
        final minute = prefs.getInt('daily_notification_minute') ?? 0;
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 100,
            channelKey: 'daily_hadith_channel',
            title: 'حديث اليوم',
            body: _formatHadith(hadith),
            notificationLayout: NotificationLayout.BigText,
            bigPicture: null,
            largeIcon: 'resource://drawable/ic_launcher',
            actionType: ActionType.Default,
            payload: {'hadith': hadithJson}, // Add hadith data to payload
          ),
          schedule: NotificationCalendar(
            hour: hour,
            minute: minute,
            second: 0,
            repeats: true,
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );
      }
    }
  }

  Future<void> _createWindowsStartupTask() async {
    try {
      final taskName = 'AhadithAlZakah_Startup';
      final exe = Platform.resolvedExecutable;
      final tr = '"$exe" --startup';
      debugPrint('Creating startup task with command: $tr');

      final result = await Process.run('schtasks', [
        '/Create',
        '/SC',
        'ONLOGON',
        '/TN',
        taskName,
        '/TR',
        tr,
        '/F',
      ]);

      if (result.exitCode == 0) {
        debugPrint('Startup task created successfully for $taskName');
      } else {
        debugPrint('Failed to create startup task. Exit code: ${result.exitCode}, Output: ${result.stdout}, Error: ${result.stderr}');
        throw Exception('Task creation failed: ${result.stderr}');
      }
    } catch (e) {
      debugPrint('Error creating startup task: $e');
      if (e.toString().contains('Access is denied')) {
        debugPrint('Access denied, please run as Administrator or create task manually with: schtasks /create /sc onlogon /tn AhadithAlZakah_Startup /tr "$e --startup" /f');
      }
    }
  }

  Future<void> _deleteWindowsScheduledTask() async {
    try {
      final taskName = 'AhadithAlZakah_DailyHadith';
      await Process.run('schtasks', ['/Delete', '/TN', taskName, '/F']);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _createWindowsScheduledTask(int hour, int minute) async {
    try {
      final taskName = 'AhadithAlZakah_DailyHadith';
      final exe = Platform.resolvedExecutable;
      // Use resolved executable and pass a scheduler-only flag so native runner
      // can create a Windows toast (without opening UI). The toast's launch
      // argument will use the "activate" flag which opens the app when clicked.
      final tr = '"$exe" --show-daily-hadith-scheduler';
      final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      final result = await Process.run('schtasks', [
        '/Create',
        '/SC',
        'DAILY',
        '/TN',
        taskName,
        '/TR',
        tr,
        '/ST',
        time,
        '/F',
      ]);

      if (result.exitCode == 0) {
        debugPrint('Daily hadith task created successfully for $taskName at $time');
      } else {
        debugPrint('Failed to create daily hadith task. Exit code: ${result.exitCode}, Output: ${result.stdout}, Error: ${result.stderr}');
        throw Exception('Task creation failed: ${result.stderr}');
      }
    } catch (e) {
      debugPrint('Error creating daily hadith task: $e');
      // ignore; creation may fail in debug or without permission
    }
  }

  Future<void> _scheduleWindowsDailyNotification(Hadith hadith, int hour, int minute) async {
    // Cancel existing timers
    _windowsTimer?.cancel();
    _windowsDailyTimer?.cancel();

    // Precompute JSON for the hadith so timer callbacks can reference it (not used for native launch args)
    final hadithJson = json.encode(hadith.toJson());

    final enabled = await areNotificationsEnabled();
    final hasPermission = await hasNotificationPermission();
    if (!enabled || !hasPermission) return;

    DateTime next = _nextOccurrence(hour, minute);
    final now = DateTime.now();
    final initialDelay = next.difference(now);

    // One-shot timer to show first notification at the next occurrence
    _windowsTimer = Timer(initialDelay, () async {
      try {
        // Show Dart-based local notification for Windows.
        await _showLocalNotification(hadith);
      } catch (e, s) {
        debugPrint('Failed to show initial scheduled Windows notification: $e\n$s');
      }

      // schedule daily repeating timer (every 24 hours) after the first firing
      _windowsDailyTimer = Timer.periodic(const Duration(days: 1), (t) async {
        try {
          final freshHadith = await _getDailyHadith();
          if (freshHadith != null) {
            // Show Dart-based local notification for Windows.
            await _showLocalNotification(freshHadith);
          }
        } catch (e, s) {
          debugPrint('Failed to show periodic Windows notification: $e\n$s');
        }
      });
    });
  }

  // Separate function to show a local notification with an improved onClick handler
  Future<void> _showLocalNotification(Hadith hadith) async {
    try {
      LocalNotification notification = LocalNotification(
        title: 'حديث اليوم',
        body: _formatHadith(hadith),
      );

      notification.onClick = () async {
        // Show the window then wait briefly before navigating
        await windowManager.show();
        await windowManager.focus();

        // A short delay to ensure the Flutter UI is ready to receive navigation
        await Future.delayed(const Duration(milliseconds: 500));

        // Call the navigation handler for the hadith
        _handleHadithNavigation(hadith);
      };

      notification.show();
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  DateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _handleHadithNavigation(Hadith hadith) {
    try {
      if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
        final container = ProviderScope.containerOf(navigatorKey.currentContext!);
        container.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
        container.read(showDailyHadithProvider.notifier).state = true;
        container.read(selectedHadithProvider.notifier).state = null;
        container.read(innerBooksScreenProvider.notifier).state = null;
        container.read(navigationProvider.notifier).changeTab(1);

        debugPrint('Navigating to HomeScreen with hadith details');

        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(showHadithDetails: true),
          ),
          (Route<dynamic> route) => false,
        );

        debugPrint('Navigation completed successfully');
      } else {
        debugPrint('Navigator not ready for navigation');
      }
    } catch (e) {
      debugPrint('Error in hadith navigation: $e');
    }
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
            debugPrint('Error decoding saved Hadith: $e');
          }
        }
      }

      return await _generateNewDailyHadith();
    } catch (e) {
      return await _generateNewDailyHadith();
    }
  }

  Future<Hadith?> _generateNewDailyHadith() async {
    try {
      final dataManager = ref.read(DataProvider.notifier);
      var hadithAsyncValue = ref.read(DataProvider);

      // If data is not yet available or is empty, trigger loading and get the new state.
      if (!hadithAsyncValue.hasValue || (hadithAsyncValue.asData?.value.isEmpty ?? true)) {
        await dataManager.loadHadiths();
        hadithAsyncValue = ref.read(DataProvider);
      }

      // Safely extract the data, providing an empty list as a fallback.
      final allHadiths = hadithAsyncValue.asData?.value ?? [];

      if (allHadiths.isEmpty) {
        debugPrint('Could not generate daily hadith because no hadiths are available.');
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
      debugPrint('Error generating daily hadith: $e');
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
      debugPrint('Error saving daily hadith to secure storage: $e');
    }
  }

  Future<void> _loadOrGenerateDailyHadith() async {
    final hadith = await _getDailyHadith();
    if (hadith != null) {
      ref.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
    }
  }

  String _formatHadith(Hadith hadith) {
    String text = hadith.text.replaceAll(RegExp(r'[A-Z]'), '');
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
      debugPrint('Error forcing new daily hadith: $e');
      return null;
    }
  }

  Future<void> cancelNotifications() async {
    if (kIsWeb) return;
    if (Platform.isWindows) {
      // Cancel in-app Windows timers
      _windowsTimer?.cancel();
      _windowsDailyTimer?.cancel();
      // Remove scheduled task
      await _deleteWindowsScheduledTask();
    } else {
      await AwesomeNotifications().cancelAll();
    }
  }

  /// Called when the app is launched by the OS scheduled task.
  Future<void> handleLaunchFromScheduler([String? hadithData]) async {
    debugPrint('Scheduler launched app. Handling notification...');

    final hadith = await _getDailyHadith();

    if (hadith != null) {
      // THE FIX: Bring the window to the foreground to ensure notifications work.
      await windowManager.show();
      await windowManager.focus();

      // Show the notification now that the app is active.
      await _showLocalNotification(hadith);
      
      // Navigate to the hadith details screen inside the app.
      _handleHadithNavigation(hadith);
    }
  }

  Future<bool> hasNotificationPermission() async {
    if (kIsWeb) return false;
    if (Platform.isWindows) {
      return true; // on Windows, permission is granted by default
    } else {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      return isAllowed;
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    if (Platform.isWindows) {
      return true;
    } else {
      final isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
      return isAllowed;
    }
  }

  Future<void> sendImmediateNotification() async {
    await sendImmediateNotificationInternal();
  }

  /// Internal immediate notification sender. By default honors prefs/permission
  /// but test callers can call [sendImmediateNotificationTest] to bypass time/pref guard.
  Future<void> sendImmediateNotificationInternal({bool requirePrefAndTime = true}) async {
    final hadith = await _getDailyHadith();

    if (hadith == null) return;

    if (kIsWeb) return;

    final enabled = await areNotificationsEnabled();
    final hasPermission = await hasNotificationPermission();
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('daily_notification_hour') ?? 12;
    final minute = prefs.getInt('daily_notification_minute') ?? 0;

    if (requirePrefAndTime) {
      // By default require that notifications are enabled and it's the scheduled time
      if (!enabled || !hasPermission || !(now.hour == hour && now.minute == minute)) return;
    } else {
      if (!hasPermission) return;
    }

    if (Platform.isWindows) {
      await _showLocalNotification(hadith);
    } else {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'daily_hadith_channel',
          title: 'حديث اليوم',
          body: _formatHadith(hadith),
          notificationLayout: NotificationLayout.BigText,
          actionType: ActionType.Default,
          payload: {'hadith': json.encode(hadith.toJson())}, // Add hadith data to payload
        ),
      );
    }
  }

  /// Send a test immediate notification bypassing the default time/pref guard
  Future<void> sendImmediateNotificationTest() async {
    await sendImmediateNotificationInternal(requirePrefAndTime: false);
  }

  Future<int> getScheduledNotificationsCount() async {
    if (kIsWeb || Platform.isWindows) return 0;
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
      debugPrint('Error clearing daily hadith data: $e');
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
      debugPrint('Error checking today hadith: $e');
      return false;
    }
  }

  Future<String?> getLastHadithDate() async {
    try {
      final date = await _secureStorage.read(key: _lastHadithDateKey);
      return date;
    } catch (e) {
      debugPrint('Error getting last hadith date: $e');
      return null;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;
    return enabled;
  }
}