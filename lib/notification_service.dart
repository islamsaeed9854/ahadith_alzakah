import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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

  static const MethodChannel _windowsToastChannel = MethodChannel('ahadith_alzakah/windows_toast');

  Future<void> init() async {
    if (!kIsWeb && Platform.isWindows) {
      // Windows initialization is handled in main.dart
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
        await _scheduleWindowsDailyNotification(hadith, hour, minute);
        // Create a Windows Scheduled Task so the OS will launch the app at the time
        await _createWindowsScheduledTask(hour, minute);
      } else {
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
            hour: 12,
            minute: 0,
            second: 0,
            repeats: true,
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );
      }
    }
  }

  Future<void> _createWindowsScheduledTask(int hour, int minute) async {
    try {
      final taskName = 'AhadithAlZakah_DailyHadith';
      final exe = Platform.resolvedExecutable;
      // Use resolved executable and pass a flag so the app knows to show hadith
      final tr = '"$exe" --show-daily-hadith';
      final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      await Process.run('schtasks', [
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
    } catch (e) {
      // ignore; creation may fail in debug or without permission
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

  Future<void> _scheduleWindowsDailyNotification(Hadith hadith, int hour, int minute) async {
    // Cancel existing timers
    _windowsTimer?.cancel();
    _windowsDailyTimer?.cancel();

    // Precompute JSON for the hadith so timer callbacks can reference it
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
        // Prefer native Windows Toast with activation args so clicking it
        // launches the app with arguments.
        final launchArgs = '--show-daily-hadith --hadith=' + Uri.encodeComponent(hadithJson);
        try {
          await _windowsToastChannel.invokeMethod('showToast', {
            'title': 'حديث اليوم',
            'body': _formatHadith(hadith),
            'launch': launchArgs,
          });
        } catch (e) {
          // Fallback to local notification if native toast fails
          await _showLocalNotification(hadith);
        }
      } catch (e) {
        // ignore errors to avoid crashing the app
      }

      // schedule daily repeating timer (every 24 hours) after the first firing
      _windowsDailyTimer = Timer.periodic(const Duration(days: 1), (t) async {
        try {
          final freshHadith = await _getDailyHadith();
          if (freshHadith != null) {
            final freshJson = json.encode(freshHadith.toJson());
            final launchArgs = '--show-daily-hadith --hadith=' + Uri.encodeComponent(freshJson);
            try {
              await _windowsToastChannel.invokeMethod('showToast', {
                'title': 'حديث اليوم',
                'body': _formatHadith(freshHadith),
                'launch': launchArgs,
              });
            } catch (e) {
              await _showLocalNotification(freshHadith);
            }
          }
        } catch (e) {
          // ignore
        }
      });
    });
  }

  // دالة منفصلة لعرض الإشعار المحلي مع تحسين onClick handler
  Future<void> _showLocalNotification(Hadith hadith) async {
    try {
      LocalNotification notification = LocalNotification(
        title: 'حديث اليوم',
        body: _formatHadith(hadith),
      );
      
      notification.onClick = () async {
        // فتح النافذة ثم الانتظار لثانية قصيرة قبل التنقل
        await windowManager.show();
        await windowManager.focus();

        // تأخير قصير لضمان أن واجهة Flutter جاهزة لاستقبال التنقل
        await Future.delayed(const Duration(milliseconds: 500));

        // استدعاء التنقل إلى الحديث
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
            print('Error decoding saved Hadith: $e');
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
      print('Error forcing new daily hadith: $e');
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

  /// Called when the app is launched by the OS scheduled task with the
  /// --show-daily-hadith argument.
  Future<void> handleLaunchFromScheduler([String? hadithData]) async {
    debugPrint('handleLaunchFromScheduler called with data: ${hadithData != null ? 'yes' : 'no'}');
    
    Hadith? hadith;
    
    // جرب استخدام الـ hadith data من الـ launch arguments الأول
    if (hadithData != null) {
      try {
        final hadithMap = json.decode(hadithData) as Map<String, dynamic>;
        hadith = Hadith.fromJson(hadithMap);
        debugPrint('Successfully parsed hadith from launch args');
      } catch (e) {
        debugPrint('Error parsing hadith from launch args: $e');
      }
    }
    
    // إذا فشل، استخدم الحديث اليومي المحفوظ
    // If no hadithData provided, try to parse from Platform.executableArguments
    if (hadith == null && hadithData == null && !kIsWeb && Platform.isWindows) {
      try {
        final args = Platform.executableArguments;
        for (final a in args) {
          if (a.startsWith('--hadith=')) {
            final decoded = Uri.decodeComponent(a.substring(9));
            final hadithMap = json.decode(decoded) as Map<String, dynamic>;
            hadith = Hadith.fromJson(hadithMap);
            debugPrint('Parsed hadith from Platform.executableArguments');
            break;
          }
        }
      } catch (e) {
        debugPrint('Error parsing hadith from executableArguments: $e');
      }
    }

    if (hadith == null) {
      hadith = await _getDailyHadith();
      debugPrint('Using stored daily hadith');
    }
    
    if (hadith != null) {
      // انتظار وقت كافي للتأكد من أن التطبيق جاهز
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // التأكد من أن Navigator جاهز
      int retryCount = 0;
      while (retryCount < 10) {
        if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
          _handleHadithNavigation(hadith);
          break;
        }
        await Future.delayed(const Duration(milliseconds: 300));
        retryCount++;
        debugPrint('Waiting for navigator... retry $retryCount');
      }
      
      if (retryCount >= 10) {
        debugPrint('Navigator not ready after maximum retries');
      }
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

    if (requirePrefAndTime) {
      // By default require that notifications are enabled and it's the scheduled time (hour:12 minute:0)
      if (!enabled || !hasPermission || !(now.hour == 12 && now.minute == 0)) return;
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