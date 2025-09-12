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
      await _cleanupOldStartupEntries();
    }

    if (!kIsWeb && Platform.isWindows) {
      try {
        await _createWindowsStartupTask();
        await _createWindowsScheduledTask(12, 0); // Default to 12:00 if not set
      } catch (e) {
        if (e.toString().contains('Access is denied')) {
          _showAdminPermissionDialog();
        }
      }
    } else {
      await AwesomeNotifications().initialize('resource://drawable/ic_launcher', [
        NotificationChannel(
          channelKey: 'daily_hadith_channel',
          channelName: 'Daily Hadith',
          channelDescription: 'Daily Hadith notifications',
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          channelShowBadge: false,
          locked: true, 
          defaultRingtoneType: DefaultRingtoneType.Notification,
          enableLights: true,
          ledColor: Colors.green,
        ),
      ], debug: true);

      // Set notification listeners with improved handling
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceivedMethod,
        onNotificationCreatedMethod: _onNotificationCreatedMethod,
        onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final hasShownDialog = prefs.getBool('has_shown_permission_dialog') ?? false;

    if (!hasShownDialog) {
      final bool hasPermission = await requestNotificationPermission();
      await prefs.setBool('has_shown_permission_dialog', true);

      if (hasPermission) {
        await prefs.setBool('notifications_enabled', true);
        await scheduleDailyHadithNotification();
      } else {
        await prefs.setBool('notifications_enabled', false);
      }
    } else {
      bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      final bool hasPermission = await hasNotificationPermission();

      if (notificationsEnabled && hasPermission) {
        await scheduleDailyHadithNotification();
      } else {
        await cancelNotifications();
      }
    }

    await _loadOrGenerateDailyHadith();
  }

  // Improved notification action handlers
  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed: ${receivedAction.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.actionType}');
    debugPrint('Payload: ${receivedAction.payload}');
    
    try {
      // Extract hadith data from payload
      if (receivedAction.payload != null && 
          receivedAction.payload!.containsKey('hadith')) {
        final hadithJson = receivedAction.payload!['hadith']!;
        final hadithData = json.decode(hadithJson) as Map<String, dynamic>;
        final hadith = Hadith.fromJson(hadithData);
        
        // Handle the navigation based on platform
        if (Platform.isWindows) {
          await _handleWindowsNotificationClick(hadith);
        } else {
          await _handleMobileNotificationClick(hadith);
        }
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  // Windows-specific notification click handler
  static Future<void> _handleWindowsNotificationClick(Hadith hadith) async {
    try {
      // Ensure window is visible and focused
      await windowManager.show();
      await windowManager.setSkipTaskbar(false);
      await windowManager.focus();
      
      // Wait for window to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to the hadith
      await _navigateToHadith(hadith);
    } catch (e) {
      debugPrint('Error handling Windows notification click: $e');
    }
  }

  // Mobile-specific notification click handler
  static Future<void> _handleMobileNotificationClick(Hadith hadith) async {
    try {
      await _navigateToHadith(hadith);
    } catch (e) {
      debugPrint('Error handling mobile notification click: $e');
    }
  }

  // Unified navigation handler
  static Future<void> _navigateToHadith(Hadith hadith) async {
    try {
      if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
        final container = ProviderScope.containerOf(navigatorKey.currentContext!);
        
        // Set the hadith data in providers
        container.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
        container.read(showDailyHadithProvider.notifier).state = true;
        container.read(selectedHadithProvider.notifier).state = null;
        container.read(innerBooksScreenProvider.notifier).state = null;
        container.read(navigationProvider.notifier).changeTab(1);

        // Navigate to home screen with hadith details
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(showHadithDetails: true),
          ),
          (Route<dynamic> route) => false,
        );

        debugPrint('Successfully navigated to hadith details');
      } else {
        debugPrint('Navigator not ready for navigation');
      }
    } catch (e) {
      debugPrint('Error navigating to hadith: $e');
    }
  }

  Future<void> _cleanupOldStartupEntries() async {
    try {
      debugPrint('Cleaning up old startup entries...');
      
      final String startupDir = await _getStartupDirectory();
      final String shortcutPath = '$startupDir\\AhadithAlZakah.lnk';
      final file = File(shortcutPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted old startup shortcut: $shortcutPath');
      }
      
      await _deleteWindowsScheduledTask('AhadithAlZakah_Startup');
      await _deleteWindowsScheduledTask('AhadithAlZakah_DailyHadith');
      
      await _cleanupRegistryEntries();
      
    } catch (e) {
      debugPrint('Error cleaning up old startup entries: $e');
    }
  }

  Future<void> _cleanupRegistryEntries() async {
    try {
      await Process.run('reg', [
        'delete',
        'HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
        '/v',
        'AhadithAlZakah',
        '/f'
      ]);
      
      await Process.run('reg', [
        'delete',
        'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
        '/v',
        'AhadithAlZakah',
        '/f'
      ]);
      
      debugPrint('Cleaned up registry entries');
    } catch (e) {
      debugPrint('Registry cleanup error (may be expected): $e');
    }
  }

  Future<void> _deleteWindowsScheduledTask(String taskName) async {
    try {
      final result = await Process.run('schtasks', [
        '/Query',
        '/TN',
        taskName,
        '/FO',
        'LIST'
      ]);
      
      if (result.exitCode == 0) {
        await Process.run('schtasks', ['/Delete', '/TN', taskName, '/F']);
        debugPrint('Deleted scheduled task: $taskName');
      }
    } catch (e) {
      debugPrint('Scheduled task deletion error (may be expected): $e');
    }
  }

  Future<void> scheduleDailyHadithNotification() async {
    await cancelNotifications();

    final hadith = await _getDailyHadith();

    if (hadith != null) {
      final hadithJson = json.encode(hadith.toJson());
      if (kIsWeb) return;
      
      if (Platform.isWindows) {
        final prefs = await SharedPreferences.getInstance();
        final hour = prefs.getInt('daily_notification_hour') ?? 12;
        final minute = prefs.getInt('daily_notification_minute') ?? 0;
        await _scheduleWindowsDailyNotification(hadith, hour, minute);
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
            payload: {'hadith': hadithJson},
            // Settings to make notification persistent and clickable
            criticalAlert: true,
            locked: false, // Allow user to dismiss but make it clickable
            autoDismissible: true, // Allow auto dismiss after click
            displayOnForeground: true,
            displayOnBackground: true,
            wakeUpScreen: true, // Wake up screen on notification
            fullScreenIntent: false, // Don't force full screen
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
      try {
        final String startupDir = await _getStartupDirectory();
        final String exePath = Platform.resolvedExecutable;
        final String shortcutPath = '$startupDir\\AhadithAlZakah.lnk';

        final result = await Process.run('powershell', [
          '-Command',
          '''
          \$WshShell = New-Object -comObject WScript.Shell;
          \$Shortcut = \$WshShell.CreateShortcut("$shortcutPath");
          \$Shortcut.TargetPath = "$exePath";
          \$Shortcut.Arguments = "--startup --background";
          \$Shortcut.WorkingDirectory = "${Directory.current.path}";
          \$Shortcut.Description = "موسوعة أحاديث الزكاة";
          \$Shortcut.WindowStyle = 7;
          \$Shortcut.Save();
          '''
        ]);

        if (result.exitCode == 0) {
          debugPrint('Startup shortcut created successfully in user startup folder');
          return;
        }
      } catch (e) {
        debugPrint('Error creating startup shortcut: $e');
      }

      final taskName = 'AhadithAlZakah_Startup';
      final exe = Platform.resolvedExecutable;
      final tr = '"$exe" --startup --background';
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
        if (result.stderr.toString().contains('Access is denied')) {
          _showAdminPermissionDialog();
        }
        throw Exception('Task creation failed: ${result.stderr}');
      }
    } catch (e) {
      debugPrint('Error creating startup task: $e');
    }
  }

  Future<String> _getStartupDirectory() async {
    final ProcessResult result = await Process.run('powershell', [
      '-Command',
      '[Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)'
    ]);
    return result.stdout.toString().trim();
  }

  Future<void> _createWindowsScheduledTask(int hour, int minute) async {
    try {
      final taskName = 'AhadithAlZakah_DailyHadith';
      final exe = Platform.resolvedExecutable;
      final tr = '"$exe" --show-daily-hadith-scheduler';
      final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      debugPrint('Creating daily task with command: $tr at $time');

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
        if (result.stderr.toString().contains('Access is denied')) {
          _showAdminPermissionDialog();
        }
        
        debugPrint('Falling back to internal timer for daily notifications');
        final hadith = await _getDailyHadith();
        if (hadith != null) {
          await _scheduleWindowsDailyNotification(hadith, hour, minute);
        }
      }
    } catch (e) {
      debugPrint('Error creating daily hadith task: $e');
      
      final hadith = await _getDailyHadith();
      if (hadith != null) {
        await _scheduleWindowsDailyNotification(hadith, hour, minute);
      }
    }
  }

  Future<void> _scheduleWindowsDailyNotification(Hadith hadith, int hour, int minute) async {
    _windowsTimer?.cancel();
    _windowsDailyTimer?.cancel();

    final hadithJson = json.encode(hadith.toJson());

    final enabled = await areNotificationsEnabled();
    final hasPermission = await hasNotificationPermission();
    if (!enabled || !hasPermission) return;

    DateTime next = _nextOccurrence(hour, minute);
    final now = DateTime.now();
    final initialDelay = next.difference(now);

    _windowsTimer = Timer(initialDelay, () async {
      try {
        await _showLocalNotification(hadith);
      } catch (e) {
        debugPrint('Error showing scheduled notification: $e');
      }

      _windowsDailyTimer = Timer.periodic(const Duration(days: 1), (t) async {
        try {
          final freshHadith = await _getDailyHadith();
          if (freshHadith != null) {
            await _showLocalNotification(freshHadith);
          }
        } catch (e) {
          debugPrint('Error showing periodic notification: $e');
        }
      });
    });
  }

  // Improved local notification with better click handling
  Future<void> _showLocalNotification(Hadith hadith) async {
    try {
      LocalNotification notification = LocalNotification(
        title: 'حديث اليوم',
        body: _formatHadith(hadith),
      );
      
      notification.onClick = () async {
        debugPrint('Local notification clicked');
        try {
          await windowManager.show();
          await windowManager.setSkipTaskbar(false);
          await windowManager.focus();

          await Future.delayed(const Duration(milliseconds: 500));
          await _navigateToHadith(hadith);
        } catch (e) {
          debugPrint('Error handling local notification click: $e');
        }
      };

      notification.show();
      debugPrint('Local notification shown successfully');
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
            final hadithMap = json.decode(savedHadithJson) as Map<String, dynamic>;
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
    String text = hadith.text.replaceAll(RegExp(r'[A-Z]'), '');
    if (text.length > 200) {
      text = '${text.substring(0, 197)}...';
    }
    return text;
  }

  // Public methods
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
      _windowsTimer?.cancel();
      _windowsDailyTimer?.cancel();
      await _deleteWindowsScheduledTask('AhadithAlZakah_DailyHadith');
    } else {
      await AwesomeNotifications().cancelAll();
    }
  }

  Future<void> handleLaunchFromScheduler([String? hadithData]) async {
    debugPrint('Scheduler launched app. Handling notification...');

    final hadith = await _getDailyHadith();

    if (hadith != null) {
      await windowManager.show();
      await windowManager.focus();
      await _showLocalNotification(hadith);
      _handleHadithNavigation(hadith);
    }
  }

  Future<bool> hasNotificationPermission() async {
    if (kIsWeb) return false;
    if (Platform.isWindows) {
      return true;
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
      final isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      return isAllowed;
    }
  }

  Future<void> sendImmediateNotification() async {
    await sendImmediateNotificationInternal();
  }

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
          payload: {'hadith': json.encode(hadith.toJson())},
          criticalAlert: true,
          locked: false, // Allow dismissal but make clickable
          autoDismissible: true,
          displayOnForeground: true,
          displayOnBackground: true,
          wakeUpScreen: true,
        ),
      );
    }
  }

  Future<void> sendImmediateNotificationTest() async {
    await sendImmediateNotificationInternal(requirePrefAndTime: false);
  }

  Future<int> getScheduledNotificationsCount() async {
    if (kIsWeb || Platform.isWindows) return 0;
    final notifications = await AwesomeNotifications().listScheduledNotifications();
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

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  Future<bool> _requestAdminPrivileges() async {
    if (!Platform.isWindows) return true;
    try {
      final result = await Process.run('net', ['session']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint("Error checking for admin privileges: $e");
      return false;
    }
  }

  void _showAdminPermissionDialog() {
    if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('إذن إداري مطلوب'),
          content: const Text(
            'لتمكين التشغيل التلقائي وإشعارات الحديث اليومي، يرجى تشغيل التطبيق كمسؤول (Administrator) مرة واحدة على الأقل.\n\n'
            'انقر بزر الفأرة الأيمن على التطبيق واختر "Run as Administrator"، ثم افتح الإعدادات وحفظها مرة أخرى.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('حسنًا'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openSettings();
              },
              child: const Text('فتح الإعدادات'),
            ),
          ],
        ),
      );
    }
  }

  void _openSettings() {
    try {
      if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
        final container = ProviderScope.containerOf(navigatorKey.currentContext!);
        container.read(navigationProvider.notifier).changeTab(2);
      }
    } catch (e) {
      debugPrint('Error opening settings: $e');
    }
  }

  Future<bool> _checkBackgroundService() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', ['/FI', 'IMAGENAME eq ahadith_alzakah.exe', '/FO', 'CSV']);
        final output = result.stdout.toString();
        return output.contains('ahadith_alzakah.exe');
      }
      return false;
    } catch (e) {
      debugPrint('Error checking background service: $e');
      return false;
    }
  }
}