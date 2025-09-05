import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:win32/win32.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/chapters_screen.dart';
import 'providers/notification_service_provider.dart';
import 'data/models/hadith.dart';
import 'notification_service.dart';
import 'core/single_instance.dart';
import 'core/secure_supabase_storage.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui; // Add prefix for dart:ui

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'URL_NOT_FOUND',
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'ANON_KEY_NOT_FOUND',
);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Standalone entry point for scheduler tasks.
/// This runs a minimal app instance to show a notification and then exits.
@pragma('vm:entry-point')
void notificationMain() async {
  // Required initialization for background tasks.
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('notificationMain: Starting background task initialization');
  
  // Setup local notifications for Windows.
  if (Platform.isWindows) {
    debugPrint('notificationMain: Setting up local notifier for Windows');
    await localNotifier.setup(
      appName: 'أحاديث الزكاة',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }
  
  // Initialize providers in a new, separate scope.
  final container = ProviderContainer();
  debugPrint('notificationMain: Initializing Supabase');
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSupabaseStorage(),
    ),
  );
  
  final notificationService = container.read(notificationServiceProvider);
  debugPrint('notificationMain: Handling launch from scheduler');
  await notificationService.handleLaunchFromScheduler();
  
  // Instead of exiting, keep the app running in the background on Windows
  if (Platform.isWindows) {
    debugPrint('notificationMain: Keeping app running in background');
    await windowManager.hide(); // Hide the window instead of exiting
    await windowManager.setSkipTaskbar(true); // Remove from taskbar
  } else {
    debugPrint('notificationMain: Exiting after scheduler task');
    exit(0); // Exit only on non-Windows platforms
  }
}

class NotificationController {
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('Notification action received at ${DateTime.now()}');

    // When a notification is clicked, bring the main app to the front.
    if (Platform.isWindows) {
      final message = json.encode({'args': ['--show-window-from-notification']});
      await SingleInstance.sendMessage(message);
    }

    // A delay to allow the main instance to respond.
    await Future.delayed(const Duration(milliseconds: 500));

    if (navigatorKey.currentState != null &&
        navigatorKey.currentContext != null) {
      final container = ProviderScope.containerOf(navigatorKey.currentContext!);
      if (receivedAction.payload?.containsKey('hadith') == true) {
        try {
          final hadithJson = receivedAction.payload!['hadith']!;
          final hadithMap = json.decode(hadithJson) as Map<String, dynamic>;
          final hadith = Hadith.fromJson(hadithMap);
          container.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
          container.read(showDailyHadithProvider.notifier).state = true;
          container.read(selectedHadithProvider.notifier).state = null;
          debugPrint('Set daily hadith from notification payload');
        } catch (e) {
          debugPrint('Error parsing hadith from notification: $e');
        }
      }
      container.read(innerBooksScreenProvider.notifier).state = null;
      container.read(navigationProvider.notifier).changeTab(1);
      debugPrint('Set navigationProvider to index 1');

      await Future.delayed(const Duration(milliseconds: 200));

      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showHadithDetails: true),
        ),
        (Route<dynamic> route) => false,
      );
      debugPrint('Navigated to HomeScreen with showHadithDetails: true');
    }
  }
}

Future<void> _initializeApp() async {
  if (supabaseUrl == 'URL_NOT_FOUND' ||
      supabaseAnonKey == 'ANON_KEY_NOT_FOUND') {
    throw Exception(
        'Supabase URL/Key not provided. Use --dart-define to provide them.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSupabaseStorage(),
    ),
  );
}

ReceivedAction? _initialAction;

void main(List<String> args) async {
  debugPrint('main: Application started with args: $args');
  WidgetsFlutterBinding.ensureInitialized();
  
  bool hideOnStartup = Platform.isWindows && args.contains('--startup');
  debugPrint('main: hideOnStartup set to $hideOnStartup');

  if (Platform.isWindows && args.contains('--show-daily-hadith-scheduler')) {
    debugPrint('main: Detected scheduler launch, running notificationMain');
    notificationMain();
    return;
  }

  if (Platform.isWindows) {
    debugPrint('main: Initializing SingleInstance server');
    final becamePrimary = await SingleInstance.startServer();
    if (!becamePrimary) {
      debugPrint('main: Another instance is primary, sending message and exiting');
      final message = json.encode({'args': args});
      await SingleInstance.sendMessage(message);
      return;
    }
    debugPrint('main: Became primary instance, setting up message listener');
    SingleInstance.messages.listen((msg) async {
      try {
        final Map<String, dynamic> data = json.decode(msg) as Map<String, dynamic>;
        if (data.containsKey('args')) {
          final List<dynamic> receivedArgs = data['args'] as List<dynamic>;
          if (receivedArgs.contains('--show-window-from-notification')) {
            debugPrint('main: Received show-window-from-notification command');
            await windowManager.show();
            await windowManager.focus();
          }
        }
      } catch (_) {
        debugPrint('main: Error decoding message');
      }
    });
  }

  // Check if this is the first run and request admin privileges
  if (Platform.isWindows) {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      if (!await _requestAdminPrivileges()) {
        debugPrint('main: Admin privileges denied, exiting');
        exit(0); // Exit if admin privileges are not granted
      }
      await prefs.setBool('isFirstRun', false); // Mark as not first run after success
    }
  }

  if (Platform.isWindows) {
    debugPrint('main: Setting up local notifier');
    await localNotifier.setup(
      appName: 'أحاديث الزكاة',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    debugPrint('main: Initializing window manager');
    WindowOptions windowOptions = WindowOptions(
      size: const ui.Size(800, 900),
      minimumSize: const ui.Size(550, 750),
      center: true,
      title: 'موسوعة أحاديث الزكاة',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      debugPrint('main: Window ready to show, hideOnStartup is $hideOnStartup');
      if (!hideOnStartup) {
        await windowManager.show();
        await windowManager.focus();
      } else {
        await windowManager.hide(); // Hide on startup
        await windowManager.setSkipTaskbar(true); // Remove from taskbar
      }
    });
    await windowManager.ensureInitialized();
    windowManager.setPreventClose(true);
    debugPrint('main: Window manager initialized and preventClose set');
  }

  await _initializeApp();
  debugPrint('main: Supabase initialized');

  if (!Platform.isWindows) {
    _initialAction =
        await AwesomeNotifications().getInitialNotificationAction(
      removeFromActionEvents: false,
    );
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp>
    with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      trayManager.addListener(this);
      windowManager.addListener(this);
      _initTray();
    }
    ref.read(notificationServiceProvider).init();
    debugPrint('MyAppState: Notification service initialized');

    if (_initialAction != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        NotificationController.onActionReceivedMethod(_initialAction!);
        _initialAction = null;
      });
    }
  }

  void _initTray() async {
    await trayManager.setIcon(
      'assets/app_icon.ico',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'فتح التطبيق',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'خروج',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    await trayManager.setToolTip('موسوعة أحاديث الزكاة');
    debugPrint('MyAppState: Tray initialized');
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Azkar & Hadith App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final fontSize = ref.read(
          fontSizeProvider,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: DefaultTextStyle(
            style: DefaultTextStyle.of(context).style.copyWith(
                  fontSize: fontSize.toDouble(),
                  fontFamily: 'Roboto',
                ),
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }
}

Future<bool> _requestAdminPrivileges() async {
  if (!Platform.isWindows) return true; // No need for non-Windows platforms

  // Check if already running as admin
  final isElevated = await Process.run('net', ['session']).then((result) {
    return result.exitCode == 0;
  }).catchError((_) => false);

  if (isElevated) return true;

  // Request elevation using ShellExecute
  final exePath = Platform.resolvedExecutable;
  final result = ShellExecute(
    0, // Use 0 instead of nullptr
    TEXT('runas'), // Request elevation
    TEXT(exePath),
    TEXT(''), // No additional arguments
    nullptr, // Use 0 instead of nullptr
    SW_SHOWNORMAL,
  );

  if (result <= 32) {
    debugPrint('Failed to request admin privileges. Error code: $result');
    return false; // User declined or error occurred
  }

  // If successful, the app will restart with admin rights
  return true;
}