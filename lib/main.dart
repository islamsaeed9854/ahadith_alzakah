// lib/main.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';
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
import 'dart:ui' as ui;
import 'screens/settings_screen.dart';
import 'dart:async';

// Hardcoded Supabase credentials for MSIX build fallback
const String fallbackSupabaseUrl = 'https://iccvwmacddhakaypawvn.supabase.co';
const String fallbackSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImljY3Z3bWFjZGRoYWtheXBhd3ZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyODYzMzUsImV4cCI6MjA2Njg2MjMzNX0.ucpKV7V0Z57VdvDAdUVEvIC4X4F9NTjtiEa4NZev-nQ';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: fallbackSupabaseUrl,
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: fallbackSupabaseAnonKey,
);

// Global flag to track Supabase initialization
bool _supabaseInitialized = false;

final initializationProvider = FutureProvider<void>((ref) async {
  await _initializeApp();
  await ref.read(settingsInitializerProvider.future);
});

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// StreamController for handling notification actions
final StreamController<ReceivedAction> receivedActionStream =
    StreamController<ReceivedAction>.broadcast();

class NotificationController {
  
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('onNotificationCreatedMethod: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('onNotificationDisplayedMethod: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('onDismissActionReceivedMethod: ${receivedAction.id}');
  }
  
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification action received at ${DateTime.now()}');
    debugPrint('Action type: ${receivedAction.actionType}');
    debugPrint('Payload: ${receivedAction.payload}');
    
    // Add the action to the stream for the app to handle
    receivedActionStream.add(receivedAction);

    // Handle platform-specific actions
    if (Platform.isWindows) {
      await _handleWindowsNotificationAction(receivedAction);
    } else {
      await _handleMobileNotificationAction(receivedAction);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _handleWindowsNotificationAction(ReceivedAction receivedAction) async {
    try {
      // Send message to show window if another instance is handling it
      final message = json.encode({
        'args': ['--show-window-from-notification'],
        'action': receivedAction.toMap(),
      });
      
      await SingleInstance.sendMessage(message);
      
      // Also try to show window directly if this is the main instance
      if (Platform.isWindows) {
        await windowManager.show();
        await windowManager.setSkipTaskbar(false);
        await windowManager.focus();
      }
    } catch (e) {
      debugPrint('Error handling Windows notification action: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _handleMobileNotificationAction(ReceivedAction receivedAction) async {
    // Mobile platforms handle this through the stream listener in the main app
    debugPrint('Mobile notification action will be handled by stream listener');
  }
}

Future<void> _initializeApp() async {
  if (_supabaseInitialized) {
    debugPrint('Supabase already initialized, skipping...');
    return;
  }

  try {
    debugPrint('Starting Supabase initialization...');

    String urlToUse = supabaseUrl;
    String keyToUse = supabaseAnonKey;

    if (urlToUse == 'URL_NOT_FOUND' || urlToUse.isEmpty) {
      debugPrint('Using fallback Supabase URL');
      urlToUse = fallbackSupabaseUrl;
    }

    if (keyToUse == 'ANON_KEY_NOT_FOUND' || keyToUse.isEmpty) {
      debugPrint('Using fallback Supabase Key');
      keyToUse = fallbackSupabaseAnonKey;
    }

    debugPrint('Supabase URL: ${urlToUse.substring(0, 20)}...');
    debugPrint('Supabase Key: ${keyToUse.substring(0, 10)}...');

    await Supabase.initialize(
      url: urlToUse,
      anonKey: keyToUse,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSupabaseStorage(),
        autoRefreshToken: true,
      ),
    );

    _supabaseInitialized = true;
    debugPrint('Supabase initialized successfully');

  } catch (e, stackTrace) {
    debugPrint('Error initializing Supabase: $e');
    debugPrint('Stack trace: $stackTrace');
    _supabaseInitialized = false;
  }
}

ReceivedAction? _initialAction;
ProviderContainer? _globalContainer;

void main(List<String> args) async {
  debugPrint('main: Application started with args: $args');

  WidgetsFlutterBinding.ensureInitialized();

  bool hideOnStartup = args.contains('--startup');
  bool showDailyHadith = args.contains('--show-daily-hadith-scheduler');
  bool showWindowFromNotification = args.contains('--show-window-from-notification');

  debugPrint('main: hideOnStartup: $hideOnStartup, showDailyHadith: $showDailyHadith, showWindowFromNotification: $showWindowFromNotification');

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

    // Enhanced message listener to handle notification actions
    SingleInstance.messages.listen((msg) async {
      try {
        final Map<String, dynamic> data = json.decode(msg) as Map<String, dynamic>;
        
        if (data.containsKey('args')) {
          final List<dynamic> receivedArgs = data['args'] as List<dynamic>;

          if (receivedArgs.isEmpty || receivedArgs.contains('--show-window-from-notification')) {
            debugPrint('main: Received command to show window from another instance');
            await windowManager.show();
            await windowManager.setSkipTaskbar(false);
            await windowManager.focus();
            
            // If there's an action payload, handle it
            if (data.containsKey('action')) {
              final actionData = data['action'] as Map<String, dynamic>;
              final ReceivedAction R = new ReceivedAction();
              final receivedAction = R.fromMap(actionData);
              receivedActionStream.add(receivedAction);
            }
          }
        }
      } catch (e) {
        debugPrint('main: Error decoding message: $e');
      }
    });
  }

  if (Platform.isWindows) {
    try {
      debugPrint('main: Initializing window manager');
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = WindowOptions(
        size: const ui.Size(800, 900),
        minimumSize: const ui.Size(550, 750),
        center: true,
        title: 'موسوعة أحاديث الزكاة',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        debugPrint('main: Window ready to show, hideOnStartup is $hideOnStartup');

        if (!hideOnStartup && !showDailyHadith) {
          await windowManager.show();
          await windowManager.focus();
        } else {
          await windowManager.hide();
          await windowManager.setSkipTaskbar(true);
        }
      });

      windowManager.setPreventClose(true);
      debugPrint('main: Window manager initialized and preventClose set');

      debugPrint('main: Setting up local notifier');
      await localNotifier.setup(
        appName: 'أحاديث الزكاة',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );

    } catch (e) {
      debugPrint('main: Error initializing Windows components: $e');
    }
  }

  // Initialize Supabase with retry mechanism
  int retryCount = 0;
  const maxRetries = 3;

  while (!_supabaseInitialized && retryCount < maxRetries) {
    try {
      await _initializeApp();
      if (_supabaseInitialized) {
        debugPrint('main: Supabase initialized successfully on attempt ${retryCount + 1}');
        break;
      }
    } catch (e) {
      debugPrint('main: Supabase initialization attempt ${retryCount + 1} failed: $e');
    }
    retryCount++;
    if (retryCount < maxRetries) {
      await Future.delayed(Duration(seconds: retryCount * 2));
    }
  }

  if (!_supabaseInitialized) {
    debugPrint('main: Failed to initialize Supabase after $maxRetries attempts');
  }

  // Get initial notification action for non-Windows platforms
  if (!Platform.isWindows) {
    try {
      _initialAction = await AwesomeNotifications().getInitialNotificationAction(
        removeFromActionEvents: false,
      );
      debugPrint('main: Initial action received: ${_initialAction?.toMap()}');
    } catch (e) {
      debugPrint('main: Error getting initial notification action: $e');
    }
  }

  _globalContainer = ProviderContainer();

  // Handle daily hadith scheduler launch
  if (showDailyHadith && Platform.isWindows && _globalContainer != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        debugPrint('main: Handling daily hadith scheduler launch');
        final notificationService = _globalContainer!.read(notificationServiceProvider);
        await notificationService.init();

        await Future.delayed(const Duration(seconds: 1));
        await notificationService.handleLaunchFromScheduler();
      } catch (e) {
        debugPrint('main: Error handling daily hadith scheduler: $e');
      }
    });
  }
   
  runApp(ProviderScope(
    parent: _globalContainer,
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener, TrayListener {
  late StreamSubscription<ReceivedAction> _actionStreamSubscription;

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows) {
      trayManager.addListener(this);
      windowManager.addListener(this);
      _initTray();
    }

    // Initialize notification service after a delay
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1));
      try {
        await ref.read(notificationServiceProvider).init();
        debugPrint('MyAppState: Notification service initialized');
      } catch (e) {
        debugPrint('MyAppState: Error initializing notification service: $e');
      }
    });

    // Enhanced notification action stream listener
    _actionStreamSubscription = receivedActionStream.stream.listen((receivedAction) {
      debugPrint('MyAppState: Received notification action from stream: ${receivedAction.toMap()}');
      _handleNotificationNavigation(receivedAction);
    });

    // Handle initial action if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialAction != null) {
        debugPrint('MyAppState: Handling initial notification action');
        _handleNotificationNavigation(_initialAction!);
        _initialAction = null;
      }
    });
  }

  void _handleNotificationNavigation(ReceivedAction receivedAction) {
    debugPrint('MyAppState: Starting notification navigation handler');
    
    if (!mounted) {
      debugPrint('MyAppState: Widget not mounted, skipping navigation');
      return;
    }

    if (receivedAction.payload == null || !receivedAction.payload!.containsKey('hadith')) {
      debugPrint('MyAppState: No hadith payload found in notification');
      return;
    }

    try {
      final hadithJson = receivedAction.payload!['hadith']!;
      final hadithMap = json.decode(hadithJson) as Map<String, dynamic>;
      final hadith = Hadith.fromJson(hadithMap);

      debugPrint('MyAppState: Successfully parsed hadith from payload');

      // Show window if on Windows
      if (Platform.isWindows) {
        windowManager.show();
        windowManager.setSkipTaskbar(false);
        windowManager.focus();
      }

      // Wait for window to be ready then navigate
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          try {
            // Set the hadith data in providers
            ref.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
            ref.read(showDailyHadithProvider.notifier).state = true;
            ref.read(selectedHadithProvider.notifier).state = null;
            ref.read(innerBooksScreenProvider.notifier).state = null;
            ref.read(navigationProvider.notifier).changeTab(1);

            // Navigate to home screen with hadith details
            if (navigatorKey.currentState != null) {
              navigatorKey.currentState!.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(showHadithDetails: true),
                ),
                (Route<dynamic> route) => false,
              );
              debugPrint('MyAppState: Successfully navigated to HomeScreen with hadith details');
            } else {
              debugPrint('MyAppState: NavigatorState is null');
            }
          } catch (e) {
            debugPrint('MyAppState: Error during navigation: $e');
          }
        } else {
          debugPrint('MyAppState: Widget not mounted during delayed navigation');
        }
      });

    } catch (e) {
      debugPrint('MyAppState: Error parsing hadith payload during navigation: $e');
    }
  }

  void _initTray() async {
    try {
      await trayManager.setIcon('assets/app_icon.ico');
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
    } catch (e) {
      debugPrint('MyAppState: Error initializing tray: $e');
    }
  }

  @override
  void dispose() {
    _actionStreamSubscription.cancel();
    if (Platform.isWindows) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSupabaseConnected = ref.watch(supabaseConnectionProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'موسوعة أحاديث الزكاة',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (!isSupabaseConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        bottom: 8,
                        left: 8,
                        right: 8),
                    color: Colors.red.withOpacity(0.9),
                    child: const Text(
                      'لا يوجد اتصال بقاعدة البيانات. بعض الميزات قد لا تعمل.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      home: const SplashScreen(),
    );
  }

  @override
  void onWindowClose() {
    if (Platform.isWindows) {
      windowManager.hide();
      windowManager.setSkipTaskbar(true);
    }
  }

  @override
  void onTrayIconMouseDown() {
    if(Platform.isWindows) {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.setSkipTaskbar(false);
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }
}

// Provider to track Supabase connection state
final supabaseConnectionProvider = StateProvider<bool>((ref) {
  return _supabaseInitialized;
});

// Function to check admin privileges
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