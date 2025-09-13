import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
// استيراد مكتبة إشعارات ويندوز الجديدة
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

import '../data/models/hadith.dart';
import 'providers/data_manager_provider/data_manager/data_manager.dart';
import '../main.dart';
import '../screens/chapters_screen.dart';
import '../providers/navigation_provider.dart';
import '../screens/home_screen.dart';

// Providers for storing the selected daily Hadith
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
  late FlutterSecureStorage _secureStorage;
  
  // Add fallback to SharedPreferences when secure storage fails
  static const String _lastHadithDateKey = 'daily_hadith_last_date';
  static const String _dailyHadithKey = 'daily_hadith_data';
  static const String _taskName = 'AhadithAlZakah_DailyHadith';
  
  // Flag to track if we should use fallback storage
  bool _useSecureStorage = true;

  late final WindowsNotification _winNotifyPlugin;

  NotificationService(this.ref) {
    // Initialize secure storage with Windows-specific options
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      wOptions: WindowsOptions(
        // Use a different path to avoid conflicts
    //    path: 'ahadith_alzakah_secure',
      ),
    );
    
    _winNotifyPlugin = WindowsNotification(
      applicationId: "com.example.ahadith_alzakah_windows",
    );
  }

  Future<void> init() async {
    try {
      // Test secure storage and clear if corrupted
      await _testAndFixSecureStorage();
      
      // تفعيل الاستماع للأحداث عند ضغط المستخدم على الإشعار
      _winNotifyPlugin.initNotificationCallBack((event) {
        debugPrint('Notification action received: ${event.toString()}');
        _handleNotificationClick(event);
      });

      await _loadOrGenerateDailyHadith();
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      // Continue with fallback storage
      _useSecureStorage = false;
      await _loadOrGenerateDailyHadith();
    }
  }

  // Test secure storage and fix corruption issues
  Future<void> _testAndFixSecureStorage() async {
    try {
      // Try to read a test value
      await _secureStorage.read(key: 'test_key');
      _useSecureStorage = true;
    } catch (e) {
      debugPrint('Secure storage corrupted, attempting to fix: $e');
      
      try {
        // Try to delete all data and reset
        await _secureStorage.deleteAll();
        // Write a test value to ensure it's working
        await _secureStorage.write(key: 'test_key', value: 'test');
        await _secureStorage.delete(key: 'test_key');
        _useSecureStorage = true;
        debugPrint('Secure storage fixed successfully');
      } catch (resetError) {
        debugPrint('Cannot fix secure storage, using SharedPreferences fallback: $resetError');
        _useSecureStorage = false;
        
        // Try to delete the corrupted file directly (Windows specific)
        if (Platform.isWindows) {
          await _deleteCorruptedSecureStorageFile();
        }
      }
    }
  }

  // Delete corrupted secure storage file on Windows
  Future<void> _deleteCorruptedSecureStorageFile() async {
    try {
      final appDataPath = Platform.environment['APPDATA'];
      if (appDataPath != null) {
        final secureStorageFile = File('$appDataPath\\com.example\\ahadith_alzakah\\flutter_secure_storage.dat');
        if (await secureStorageFile.exists()) {
          await secureStorageFile.delete();
          debugPrint('Deleted corrupted secure storage file');
        }
        
        // Also try to delete the new path
        final newSecureStorageFile = File('$appDataPath\\com.example\\ahadith_alzakah\\ahadith_alzakah_secure.dat');
        if (await newSecureStorageFile.exists()) {
          await newSecureStorageFile.delete();
          debugPrint('Deleted new corrupted secure storage file');
        }
      }
    } catch (e) {
      debugPrint('Could not delete corrupted file: $e');
    }
  }

  // Storage helper methods with fallback
  Future<String?> _readFromStorage(String key) async {
    try {
      if (_useSecureStorage) {
        return await _secureStorage.read(key: key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
    } catch (e) {
      debugPrint('Error reading from storage, using fallback: $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  Future<void> _writeToStorage(String key, String value) async {
    try {
      if (_useSecureStorage) {
        await _secureStorage.write(key: key, value: value);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Error writing to storage, using fallback: $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  Future<void> _deleteFromStorage(String key) async {
    try {
      if (_useSecureStorage) {
        await _secureStorage.delete(key: key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error deleting from storage, using fallback: $e');
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  Future<void> _handleNotificationClick(dynamic event) async {
    try {
      debugPrint('Handling notification click event');
      
      // إحضار التطبيق إلى المقدمة
      await _bringAppToForeground();
      
      // الحصول على الحديث اليومي الحالي
      final currentHadith = await getDailyHadith();
      if (currentHadith != null) {
        _navigateToHadith(currentHadith);
      } else {
        debugPrint('No daily hadith available for navigation');
      }
    } catch (e) {
      debugPrint('Error handling notification click: $e');
    }
  }

  Future<void> _bringAppToForeground() async {
    try {
      // إظهار النافذة وإحضارها للمقدمة
      await windowManager.show();
      await windowManager.setSkipTaskbar(false);
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(true);
      
      // إزالة الـ always on top بعد ثانية واحدة
      Future.delayed(const Duration(seconds: 1), () {
        windowManager.setAlwaysOnTop(false);
      });
      
      debugPrint('App brought to foreground successfully');
    } catch (e) {
      debugPrint('Error bringing app to foreground: $e');
    }
  }

  void _navigateToHadith(Hadith hadith) {
    try {
      if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
        final container = ProviderScope.containerOf(navigatorKey.currentContext!);
        
        // تأخير صغير للتأكد من أن النافذة ظهرت
        Future.delayed(const Duration(milliseconds: 300), () {
          try {
            container.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
            container.read(showDailyHadithProvider.notifier).state = true;
            container.read(selectedHadithProvider.notifier).state = null;
            container.read(innerBooksScreenProvider.notifier).state = null;
            container.read(navigationProvider.notifier).changeTab(1);

            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen(showHadithDetails: true)),
              (Route<dynamic> route) => false,
            );
            debugPrint('Successfully navigated to hadith details from notification');
          } catch (navigationError) {
            debugPrint('Error during navigation: $navigationError');
          }
        });
      } else {
        debugPrint('Navigator not ready for navigation');
      }
    } catch (e) {
      debugPrint('Error in hadith navigation: $e');
    }
  }

  Future<void> scheduleDailyHadithNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('daily_notification_hour') ?? 12;
      final minute = prefs.getInt('daily_notification_minute') ?? 0;
      
      debugPrint('Scheduling daily hadith notification for $hour:${minute.toString().padLeft(2, '0')}');
      
      // إزالة المهمة القديمة أولاً
      await _deleteScheduledTask();
      
      // إنشاء مهمة جديدة
      await _createWindowsScheduledTask(hour, minute);
      
      debugPrint('Daily hadith notification scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling daily hadith notification: $e');
    }
  }

  Future<void> _createWindowsScheduledTask(int hour, int minute) async {
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      final taskRun = 'cmd /c "cd /d \\"$exeDir\\" && \\"$exePath\\" --show-daily-hadith"';

      debugPrint('Creating daily task: $_taskName');
      debugPrint('Executable Path: $exePath');
      debugPrint('Executable Directory: $exeDir');
      debugPrint('Task run command: $taskRun');
      debugPrint('Time: $time');

      final result = await Process.run('schtasks', [
        '/Create',
        '/SC',
        'DAILY',
        '/TN',
        _taskName,
        '/TR',
        taskRun,
        '/ST',
        time,
        '/F', 
        '/RL',
        'HIGHEST',
      ]);

      if (result.exitCode == 0) {
        debugPrint('Daily hadith task created successfully: $_taskName at $time');
        debugPrint('Task creation output: ${result.stdout}');
      } else {
        debugPrint('!!!!!!!!!! FAILED TO CREATE SCHEDULED TASK !!!!!!!!!!');
        debugPrint('This is likely a PERMISSIONS issue.');
        debugPrint('Try running your IDE or the final .exe file "as Administrator".');
        debugPrint('Exit code: ${result.exitCode}');
        debugPrint('Stdout: ${result.stdout}');
        debugPrint('Stderr: ${result.stderr}');
      }
    } catch (e, st) {
      debugPrint('Error creating daily hadith task: $e');
      debugPrint(st.toString());
    }
  }

  Future<void> _deleteScheduledTask() async {
    try {
      final result = await Process.run('schtasks', ['/Delete', '/TN', _taskName, '/F']);
      if (result.exitCode == 0) {
        debugPrint('Scheduled task $_taskName deleted successfully.');
      } else {
        // Don't print an error if the task just doesn't exist, but do print if it's access denied.
        final stderr = result.stderr as String;
        if (!stderr.contains('The specified task name does not exist')) {
            debugPrint('Could not delete scheduled task (this might be a permissions issue): ${result.stderr}');
        }
      }
    } catch (e) {
      debugPrint('Could not delete scheduled task $_taskName: $e');
    }
  }
  
  // هذه الدالة يتم استدعاؤها عند تشغيل التطبيق مع الوسيط --show-daily-hadith
  Future<void> handleScheduledNotification() async {
    try {
      debugPrint('Handling scheduled notification...');
      
      final hadith = await getDailyHadith();
      if (hadith != null) {
        _showWindowsNotification(hadith);
        debugPrint('Scheduled notification sent successfully');
      } else {
        debugPrint('No hadith available for scheduled notification');
      }
    } catch (e) {
      debugPrint('Error handling scheduled notification: $e');
    }
  }
  
  Future<void> showImmediateNotification() async {
    try {
      final hadith = await getDailyHadith();
      if (hadith != null) {
        _showWindowsNotification(hadith);
      }
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }

  void _showWindowsNotification(Hadith hadith) {
    try {
      // إنشاء ID فريد للإشعار
      final notificationId = "daily_hadith_${DateTime.now().millisecondsSinceEpoch}";
      
      // إنشاء الإشعار
      final message = NotificationMessage.fromPluginTemplate(
        notificationId,
        "حديث اليوم",
        _formatHadith(hadith),
      );
      
      // إظهار الإشعار
      _winNotifyPlugin.showNotificationPluginTemplate(message);
      debugPrint('Windows notification shown with ID: $notificationId');
      
    } catch (e) {
      debugPrint('Error showing Windows notification: $e');
    }
  }

  Future<void> cancelNotifications() async {
    try {
      await _deleteScheduledTask();
      debugPrint('All notifications canceled successfully');
    } catch (e) {
      debugPrint('Error canceling notifications: $e');
    }
  }

  Future<void> sendImmediateNotificationTest() async {
    try {
      final hadith = await getDailyHadith();
      if (hadith != null) {
        _showWindowsNotification(hadith);
        debugPrint('Test notification sent successfully');
      } else {
        debugPrint("Could not get a hadith for the test notification.");
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
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
    final today = DateTime.now().toIso8601String().split('T')[0];
    try {
      final lastHadithDate = await _readFromStorage(_lastHadithDateKey);
      if (lastHadithDate == today) {
        final savedHadithJson = await _readFromStorage(_dailyHadithKey);
        if (savedHadithJson != null) {
          try {
            return Hadith.fromJson(json.decode(savedHadithJson));
          } catch (e) {
            debugPrint('Error parsing saved hadith: $e');
            return await _generateNewDailyHadith();
          }
        }
      }
      return await _generateNewDailyHadith();
    } catch (e) {
      debugPrint('Error getting daily hadith: $e');
      return await _generateNewDailyHadith();
    }
  }

  Future<Hadith?> _generateNewDailyHadith() async {
    try {
      final hadithAsyncValue = ref.read(DataProvider);
      List<Hadith> allHadiths = hadithAsyncValue.valueOrNull ?? [];
      
      if (allHadiths.isEmpty) {
        await ref.read(DataProvider.notifier).loadHadiths();
        allHadiths = ref.read(DataProvider).valueOrNull ?? [];
      }

      if (allHadiths.isEmpty) {
        debugPrint('No hadiths available to generate daily hadith');
        return null;
      }

      final activeHadiths = allHadiths.where((h) => !h.deleted).toList();
      if (activeHadiths.isEmpty) {
        debugPrint('No active hadiths available');
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
      debugPrint('Error generating daily hadith: $e');
      return null;
    }
  }

  Future<void> _saveDailyHadith(Hadith hadith) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _writeToStorage(_lastHadithDateKey, today);
      await _writeToStorage(_dailyHadithKey, json.encode(hadith.toJson()));
    } catch (e) {
      debugPrint('Error saving daily hadith: $e');
    }
  }

  Future<void> _loadOrGenerateDailyHadith() async {
    try {
      final hadith = await getDailyHadith();
      if (hadith != null) {
        ref.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
      }
    } catch (e) {
      debugPrint('Error loading or generating daily hadith: $e');
    }
  }
  
  Future<void> forceNewDailyHadith() async {
    try {
      await _deleteFromStorage(_lastHadithDateKey);
      await _deleteFromStorage(_dailyHadithKey);
      ref.read(dailyHadithProvider.notifier).clearDailyHadith();
      await _generateNewDailyHadith();
    } catch (e) {
      debugPrint('Error forcing new daily hadith: $e');
    }
  }

  Future<void> clearDailyHadithData() async {
    try {
      await _deleteFromStorage(_lastHadithDateKey);
      await _deleteFromStorage(_dailyHadithKey);
      ref.read(dailyHadithProvider.notifier).clearDailyHadith();
    } catch (e) {
      debugPrint('Error clearing daily hadith data: $e');
    }
  }
  
  Future<bool> hasNotificationPermission() async {
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_enabled') ?? false;
    } catch (e) {
      debugPrint('Error checking notifications enabled status: $e');
      return false;
    }
  }

  // دالة للتحقق من حالة المهمة المجدولة
  Future<bool> isTaskScheduled() async {
    try {
      final result = await Process.run('schtasks', ['/Query', '/TN', _taskName]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error checking task status: $e');
      return false;
    }
  }
  
  // Reset secure storage completely (call this if issues persist)
  Future<void> resetSecureStorage() async {
    try {
      debugPrint('Attempting to reset secure storage...');
      
      // Try to delete all data
      try {
        await _secureStorage.deleteAll();
      } catch (e) {
        debugPrint('Error deleting all from secure storage: $e');
      }
      
      // Delete the physical file on Windows
      if (Platform.isWindows) {
        await _deleteCorruptedSecureStorageFile();
      }
      
      // Switch to SharedPreferences
      _useSecureStorage = false;
      
      // Clear any existing data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastHadithDateKey);
      await prefs.remove(_dailyHadithKey);
      
      debugPrint('Storage reset complete, using SharedPreferences');
    } catch (e) {
      debugPrint('Error resetting storage: $e');
    }
  }
}