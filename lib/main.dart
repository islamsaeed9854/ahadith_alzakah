// lib/main.dart

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
import 'screens/settings_screen.dart';
import 'dart:async';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'URL_NOT_FOUND',
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'ANON_KEY_NOT_FOUND',
);

final initializationProvider = FutureProvider<void>((ref) async {
  await _initializeApp();
  await ref.read(settingsInitializerProvider.future);
});

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final StreamController<ReceivedAction> receivedActionStream =
    StreamController<ReceivedAction>.broadcast();

class NotificationController {
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('Notification action received at ${DateTime.now()}');
    receivedActionStream.add(receivedAction);

    if (Platform.isWindows) {
      final message = json.encode({
        'args': ['--show-window-from-notification']
      });
      await SingleInstance.sendMessage(message);
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

  bool hideOnStartup = args.contains('--startup');
  
  bool showDailyHadith = args.contains('--show-daily-hadith');

  debugPrint(
      'main: hideOnStartup: $hideOnStartup, showDailyHadith: $showDailyHadith');

  if (Platform.isWindows) {
    debugPrint('main: Initializing SingleInstance server');
    final becamePrimary = await SingleInstance.startServer();
    if (!becamePrimary) {
      debugPrint(
          'main: Another instance is primary, sending message and exiting');
      final message = json.encode({'args': args});
      await SingleInstance.sendMessage(message);
      return;
    }
    debugPrint('main: Became primary instance, setting up message listener');
    
    SingleInstance.messages.listen((msg) async {
      try {
        final Map<String, dynamic> data =
            json.decode(msg) as Map<String, dynamic>;
        if (data.containsKey('args')) {
          final List<dynamic> receivedArgs = data['args'] as List<dynamic>;
         
          if (receivedArgs.isEmpty ||
              receivedArgs.contains('--show-window-from-notification')) {
            debugPrint(
                'main: Received command to show window from another instance');
            await windowManager.show();
            await windowManager
                .setSkipTaskbar(false); 
            await windowManager.focus();
          }
        }
      } catch (_) {
        debugPrint('main: Error decoding message');
      }
    });
  }

  if (Platform.isWindows) {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      if (!await _requestAdminPrivileges()) {
        debugPrint('main: Admin privileges denied, exiting');
        exit(0);
      }
      await prefs.setBool('isFirstRun', false);
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
      
      if (!hideOnStartup && !showDailyHadith) {
        await windowManager.show();
        await windowManager.focus();
      } else {
        await windowManager.hide();
        await windowManager.setSkipTaskbar(true);
      }
    });
    await windowManager.ensureInitialized();
    windowManager.setPreventClose(true);
    debugPrint('main: Window manager initialized and preventClose set');
  }

  await _initializeApp();
  debugPrint('main: Supabase initialized');

  if (!Platform.isWindows) {
    _initialAction = await AwesomeNotifications().getInitialNotificationAction(
      removeFromActionEvents: false,
    );
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final container = ProviderContainer();

 
  if (showDailyHadith && Platform.isWindows) {
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notificationService = container.read(notificationServiceProvider);
      await notificationService.init();
     
      await Future.delayed(const Duration(seconds: 1));
      final hadith = await notificationService.getDailyHadith();
      if (hadith != null) {
        await notificationService.sendImmediateNotificationTest();
      }
    });
  }

  runApp(ProviderScope(parent: container, child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp>
    with WindowListener, TrayListener {
  late StreamSubscription<ReceivedAction> _actionStreamSubscription;

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

    _actionStreamSubscription =
        receivedActionStream.stream.listen((receivedAction) {
      _handleNotificationNavigation(receivedAction);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialAction != null) {
        _handleNotificationNavigation(_initialAction!);
        _initialAction = null;
      }
    });
  }

  void _handleNotificationNavigation(ReceivedAction receivedAction) {
    if (mounted &&
        receivedAction.payload != null &&
        receivedAction.payload!.containsKey('hadith')) {
      try {
        final hadithJson = receivedAction.payload!['hadith']!;
        final hadithMap = json.decode(hadithJson) as Map<String, dynamic>;
        final hadith = Hadith.fromJson(hadithMap);

      
        windowManager.show();
        windowManager.focus();

        ref.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
        ref.read(showDailyHadithProvider.notifier).state = true;
        ref.read(selectedHadithProvider.notifier).state = null;
        ref.read(innerBooksScreenProvider.notifier).state = null;
        ref.read(navigationProvider.notifier).changeTab(1);

        debugPrint(
            'Successfully handled notification navigation to Hadith Details.');
      } catch (e) {
        debugPrint('Error parsing hadith payload during navigation: $e');
      }
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
    _actionStreamSubscription.cancel();
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
  if (!Platform.isWindows) return true;

  final isElevated = await Process.run('net', ['session']).then((result) {
    return result.exitCode == 0;
  }).catchError((_) => false);

  if (isElevated) return true;

  final exePath = Platform.resolvedExecutable;
  final result = ShellExecute(
    0,
    TEXT('runas'),
    TEXT(exePath),
    TEXT(''),
    nullptr,
    SW_SHOWNORMAL,
  );

  if (result <= 32) {
    debugPrint('Failed to request admin privileges. Error code: $result');
    return false;
  }

  return true;
}
