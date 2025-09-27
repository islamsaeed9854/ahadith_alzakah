import 'dart:convert';
import 'dart:math';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

import '../data/models/hadith.dart';
import 'providers/data_manager_provider/data_manager/data_manager.dart';
import '../main.dart';
import '../screens/chapters_screen.dart';
import '../providers/navigation_provider.dart';
import '../screens/home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


// Providers
final dailyHadithProvider = StateNotifierProvider<DailyHadithNotifier, Hadith?>(
  (ref) => DailyHadithNotifier(),
);
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
  final _secureStorage = const FlutterSecureStorage(wOptions: WindowsOptions());
  static const String _lastHadithDateKey = 'daily_hadith_last_date';
  static const String _dailyHadithKey = 'daily_hadith_data';
  static const String _notificationLaunchArg = 'ahadith-alzakah://notification-clicked';
  bool _useSecureStorage = true;
  late final WindowsNotification _winNotifyPlugin;
  final Cron _cron = Cron();
  ScheduledTask? _scheduledTask;

  NotificationService(this.ref) {
    _winNotifyPlugin = WindowsNotification(
      applicationId: null
    );
  }
  
  /// Initializes the notification service and schedules notifications if enabled.
  Future<void> init() async {
    try {
      // The callback receives an object of type NotificationCallBackDetails
      _winNotifyPlugin.initNotificationCallBack((event) {
        debugPrint('Notification action received from callback: ${event.toString()}');
        
        // FIX: Check the 'argrument' property (with the typo) of the event object.
        if (event.argrument == _notificationLaunchArg) {
          handleNotificationClick();
        }
      });
      await _checkAndScheduleNotifications();
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Checks preferences and schedules/cancels the daily notification cron job.
  Future<void> _checkAndScheduleNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

      if (notificationsEnabled) {
        await scheduleDailyHadithNotification();
        debugPrint('Notifications enabled and scheduled.');
      } else {
        await cancelNotifications();
        debugPrint('Notifications are disabled.');
      }
    } catch (e) {
      debugPrint('Error in _checkAndScheduleNotifications: $e');
    }
  }

  /// Schedules the daily hadith notification using a cron job.
  Future<void> scheduleDailyHadithNotification() async {
    await _scheduledTask?.cancel(); // Cancel any existing task before rescheduling

    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('daily_notification_hour') ?? 12;
    final minute = prefs.getInt('daily_notification_minute') ?? 0;

    debugPrint('Scheduling daily hadith notification for $hour:$minute');
    _scheduledTask = _cron.schedule(Schedule(hours: hour, minutes: minute), () async {
      debugPrint('Cron job triggered at ${DateTime.now()}');
      final hadith = await getDailyHadith();
      if (hadith != null) {
        _showWindowsNotification(hadith);
      }
    });
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelNotifications() async {
    await _scheduledTask?.cancel();
    _scheduledTask = null;
    debugPrint('All scheduled notifications cancelled.');
  }

  /// Handles the click event on a notification.
  Future<void> handleNotificationClick() async {
    try {
      debugPrint('Handling notification click...');
      await _bringAppToForeground();
      
      // Get or generate daily hadith
      final currentHadith = await getDailyHadith();
      if (currentHadith != null) {
        _navigateToHadith(currentHadith);
      } else {
        debugPrint('No daily hadith available for notification click');
      }
    } catch (e) {
      debugPrint('Error handling notification click: $e');
    }
  }

  /// Brings the application window to the foreground forcefully and reliably.
  Future<void> _bringAppToForeground() async {
    try {
      debugPrint('Attempting to bring app to foreground...');
      
      await windowManager.show();
      await windowManager.setSkipTaskbar(false); 

      if (await windowManager.isMinimized()) {
          await windowManager.restore();
      }

      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 100));
      await windowManager.setAlwaysOnTop(false);

      debugPrint('App should now be in the foreground.');
    } catch (e) {
      debugPrint('Error bringing app to foreground: $e');
    }
  }

  /// Navigates to the details screen for the given hadith using a direct delay.
  void _navigateToHadith(Hadith hadith) {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
        final container = ProviderScope.containerOf(navigatorKey.currentContext!);
        
        // Set up daily hadith navigation
        container.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
        container.read(showDailyHadithProvider.notifier).state = true;
        container.read(selectedHadithProvider.notifier).state = null;
        container.read(innerBooksScreenProvider.notifier).state = null;
        container.read(navigationProvider.notifier).changeTab(1);
        
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen(showHadithDetails: true)),
          (Route<dynamic> route) => false,
        );
        debugPrint('Successfully navigated to hadith details from notification.');
      } else {
        debugPrint('Navigator was not ready for navigation.');
      }
    });
  }

  /// Shows a notification on Windows.
  void _showWindowsNotification(Hadith hadith) {
    try {
      final id = "daily_hadith_${DateTime.now().millisecondsSinceEpoch}";
      
      // FIX: Use the 'fromPluginTemplate' constructor and pass 'launch' as a named argument.
      final message = NotificationMessage.fromPluginTemplate(
        id,
        "حديث اليوم",
        _formatHadithForNotification(hadith),
        launch: _notificationLaunchArg, // Pass launch argument here
      );

      _winNotifyPlugin.showNotificationPluginTemplate(message);
      debugPrint('✓ Notification ID $id sent with launch arg: "${message.launch}"');
    } catch (e) {
      debugPrint('✗ Notification error: $e');
    }
  }

  /// Formats the hadith text for the notification.
  String _formatHadithForNotification(Hadith hadith) {
    String text = hadith.text
        .replaceAll(RegExp(r'[A-Z]'), '')
        .replaceAll('P', 'ﷺ');
    if (text.length > 200) text = '${text.substring(0, 197)}...';
    return text;
  }

  /// Retrieves the daily hadith, generating a new one if necessary.
  Future<Hadith?> getDailyHadith() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = await _readFromStorage(_lastHadithDateKey);

    debugPrint('Getting daily hadith - Today: $today, Last date: $lastDate');

    if (lastDate == today) {
      final json = await _readFromStorage(_dailyHadithKey);
      if (json != null) {
        try {
          final hadith = Hadith.fromJson(jsonDecode(json));
          debugPrint('Found stored daily hadith: ${hadith.number}');
          return hadith;
        } catch (e) {
          debugPrint('Error parsing stored hadith: $e');
        }
      }
    }

    // Generate new daily hadith
    final newHadith = await _generateNewDailyHadith();
    if (newHadith != null) {
      debugPrint('Generated new daily hadith: ${newHadith.number}');
    } else {
      debugPrint('Failed to generate new daily hadith');
    }
    return newHadith;
  }

  /// Generates and saves a new daily hadith.
  Future<Hadith?> _generateNewDailyHadith() async {
    try {
      // Ensure hadiths are loaded
      final dataManager = ref.read(DataProvider.notifier);
      final currentState = ref.read(DataProvider);
      
      if (currentState.valueOrNull == null) {
        debugPrint('Loading hadiths for daily hadith generation...');
        await dataManager.loadHadiths();
      }
      
      final hadiths = ref.read(DataProvider).value ?? [];
      debugPrint('Available hadiths for daily selection: ${hadiths.length}');
      
      if (hadiths.isEmpty) {
        debugPrint('No hadiths available for daily selection');
        return null;
      }

      final activeHadiths = hadiths.where((h) => !h.deleted).toList();
      debugPrint('Active (non-deleted) hadiths: ${activeHadiths.length}');
      
      if (activeHadiths.isEmpty) {
        debugPrint('No active hadiths available for daily selection');
        return null;
      }

      // Use a seed based on the current date to ensure the same hadith for the whole day
      final today = DateTime.now();
      final seed = today.year * 10000 + today.month * 100 + today.day;
      final random = Random(seed);
      final selectedHadith = activeHadiths[random.nextInt(activeHadiths.length)];
      
      debugPrint('Selected daily hadith: Bab ${selectedHadith.bab}, Fasl ${selectedHadith.fasl}, Number ${selectedHadith.number}');
      
      await _saveDailyHadith(selectedHadith);
      return selectedHadith;
    } catch (e) {
      debugPrint('Error generating new daily hadith: $e');
      return null;
    }
  }

  /// Saves the daily hadith to secure storage.
  Future<void> _saveDailyHadith(Hadith hadith) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _writeToStorage(_lastHadithDateKey, today);
      await _writeToStorage(_dailyHadithKey, jsonEncode(hadith.toJson()));
      debugPrint('Saved daily hadith to storage');
    } catch (e) {
      debugPrint('Error saving daily hadith: $e');
    }
  }

  /// Clears the stored daily hadith (useful for testing or manual refresh)
  Future<void> clearDailyHadith() async {
    try {
      await _deleteFromStorage(_lastHadithDateKey);
      await _deleteFromStorage(_dailyHadithKey);
      ref.read(dailyHadithProvider.notifier).clearDailyHadith();
      debugPrint('Cleared daily hadith from storage');
    } catch (e) {
      debugPrint('Error clearing daily hadith: $e');
    }
  }

  // --- Storage Helper Methods ---
  Future<String?> _readFromStorage(String key) async {
    if (_useSecureStorage) {
      try {
        return await _secureStorage.read(key: key);
      } catch(e) {
         debugPrint('SecureStorage read failed, falling back to SharedPreferences: $e');
         _useSecureStorage = false;
         final prefs = await SharedPreferences.getInstance();
         return prefs.getString(key);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _writeToStorage(String key, String value) async {
     if (_useSecureStorage) {
      try {
        await _secureStorage.write(key: key, value: value);
      } catch(e) {
         debugPrint('SecureStorage write failed, falling back to SharedPreferences: $e');
         _useSecureStorage = false;
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString(key, value);
      }
    } else {
       final prefs = await SharedPreferences.getInstance();
       await prefs.setString(key, value);
    }
  }

  Future<void> _deleteFromStorage(String key) async {
    if (_useSecureStorage) {
      try {
        await _secureStorage.delete(key: key);
      } catch(e) {
         debugPrint('SecureStorage delete failed, falling back to SharedPreferences: $e');
         _useSecureStorage = false;
         final prefs = await SharedPreferences.getInstance();
         await prefs.remove(key);
      }
    } else {
       final prefs = await SharedPreferences.getInstance();
       await prefs.remove(key);
    }
  }

  // --- Test Method ---
  Future<void> sendImmediateNotificationTest() async {
    final hadith = await getDailyHadith();
    if (hadith != null) {
      _showWindowsNotification(hadith);
    } else {
      debugPrint('No hadith available for immediate test notification.');
    }
  }
}