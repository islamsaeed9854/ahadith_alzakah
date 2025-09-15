import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'providers/notification_service_provider.dart';
import 'core/single_instance.dart';
import 'core/secure_supabase_storage.dart';
import 'dart:ui' as ui;
import 'screens/settings_screen.dart';
import 'dart:async';
import 'core/startup_manager.dart';
import 'core/startup_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

ProviderContainer? _globalContainer;
const String _notificationLaunchArg = 'ahadith-alzakah://notification-clicked';

void main(List<String> args) async {
  debugPrint('main: Application started with args: $args');

  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if launched with startup argument
  bool isStartupLaunch = args.contains('--startup') || args.contains('--silent-start');
  bool showHadithOnLaunch = args.contains(_notificationLaunchArg);
  
  if (isStartupLaunch) {
    debugPrint('App launched on system startup - starting in background mode');
  }
  
  if (showHadithOnLaunch) {
    debugPrint('App launched from a notification click.');
  }

  // Single Instance Logic
  if (Platform.isWindows) {
    final becamePrimary = await SingleInstance.startServer((message) async {
      debugPrint('Received message from secondary instance: $message');
      await windowManager.show();
      await windowManager.setSkipTaskbar(false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
      await Future.delayed(const Duration(seconds: 2));
      await windowManager.setAlwaysOnTop(false);

      // Handle notification click from secondary instance
      try {
        final decodedMessage = json.decode(message);
        final messageArgs = (decodedMessage['args'] as List?)?.cast<String>() ?? [];
        if (messageArgs.contains(_notificationLaunchArg)) {
          debugPrint('Secondary instance passed notification click. Handling navigation.');
          _globalContainer?.read(notificationServiceProvider).handleNotificationClick();
        }
      } catch (e) {
        debugPrint('Error processing message from secondary instance: $e');
      }
    });

    if (!becamePrimary) {
      debugPrint('Another instance is primary, sending message and exiting');
      await SingleInstance.sendMessage(json.encode({'args': args}));
      exit(0);
    }
  }

  // Window Manager Initialization
  if (Platform.isWindows) {
    try {
      debugPrint('main: Initializing window manager');
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = WindowOptions(
  size: const ui.Size(800, 700),
  minimumSize: const ui.Size(550, 750),
  center: true,
  title: 'موسوعة أحاديث الزكاة',
  skipTaskbar: isStartupLaunch, 
  titleBarStyle: TitleBarStyle.normal, 
  backgroundColor: Colors.white, 
  alwaysOnTop: false,
  fullScreen: false,

);

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
  if (isStartupLaunch) {
    // Start hidden for system startup
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
    debugPrint('App started in background mode');
  } else if (!showHadithOnLaunch) {
    // Normal launch - show window
    await windowManager.show();
    await windowManager.setSkipTaskbar(false); 
    await windowManager.focus();
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
  } else {
    // Notification launch - will be handled by notification service
    await windowManager.hide();
  }
});
      windowManager.setPreventClose(true);
      
      // Enable auto-startup only on first installation
      if (!isStartupLaunch) {
        await _enableAutoStartupFirstTime();
      }
    } catch (e) {
      debugPrint('main: Error initializing Windows components: $e');
    }
  }

  // Supabase Initialization with retries
  int retryCount = 0;
  const maxRetries = 3;
  while (!_supabaseInitialized && retryCount < maxRetries) {
    await _initializeApp();
    if (_supabaseInitialized) break;
    retryCount++;
    await Future.delayed(Duration(seconds: retryCount * 2));
  }
  if (!_supabaseInitialized) {
    debugPrint('main: Failed to initialize Supabase after $maxRetries attempts');
  }

  _globalContainer = ProviderContainer();

  runApp(ProviderScope(
    parent: _globalContainer,
    child: MyApp(
      showHadithOnLaunch: showHadithOnLaunch,
      isStartupLaunch: isStartupLaunch,
    ),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  final bool showHadithOnLaunch;
  final bool isStartupLaunch;
  
  const MyApp({
    super.key, 
    this.showHadithOnLaunch = false,
    this.isStartupLaunch = false,
  });

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _initTray();
    }
    // Initialize notification service
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       await ref.read(notificationServiceProvider).init();
    });
  }

  void _initTray() async {
    try {
      await trayManager.setIcon('assets/app_icon.ico');
      await trayManager.setToolTip('موسوعة أحاديث الزكاة');
    } catch (e) {
      debugPrint('MyAppState: Error initializing tray: $e');
    }
  }


  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
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
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      home: SplashScreen(
        showHadithOnLaunch: widget.showHadithOnLaunch,
        isStartupLaunch: widget.isStartupLaunch,
      ),
    );
  }

  @override
  void onWindowClose() {
    if (Platform.isWindows) {
      windowManager.hide();
    }
  }
  
  @override
  void onTrayIconMouseDown() {
    debugPrint('Tray icon clicked!');
    if (Platform.isWindows) {
      _showWindow();
    }
  }
  
  @override
  void onTrayIconRightMouseDown() {
    debugPrint('Tray icon right clicked!');
    if (Platform.isWindows) {
      _showWindow();
    }
  }
  
  Future<void> _showWindow() async {
  try {
    await windowManager.show();
    await windowManager.setSkipTaskbar(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.focus();
    debugPrint('Window shown successfully');
  } catch (e) {
    debugPrint('Error showing window: $e');
  }
}
}

final supabaseConnectionProvider = StateProvider<bool>((ref) {
  return _supabaseInitialized;
});


Future<void> _enableAutoStartupFirstTime() async {
  if (!Platform.isWindows) return;
  
  try {
    final prefs = await SharedPreferences.getInstance();
    const String firstRunKey = 'app_first_run_completed';
    
    bool isFirstRun = !(prefs.getBool(firstRunKey) ?? false);
    
    if (isFirstRun) {
      debugPrint('First run detected - enabling auto-startup');
      bool success = await StartupManager.enableAutoStartup();
      
      if (success) {
        debugPrint('Auto-startup enabled successfully on first run');
        await prefs.setBool('auto_startup_enabled', true);
      } else {
        debugPrint('Failed to enable auto-startup on first run');
        await prefs.setBool('auto_startup_enabled', false);
      }
      
      await prefs.setBool(firstRunKey, true);
    } else {
      debugPrint('Not first run - respecting user auto-startup preference');
    }
  } catch (e) {
    debugPrint('Error in _enableAutoStartupFirstTime: $e');
  }
}