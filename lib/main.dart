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

void main(List<String> args) async {
  debugPrint('main: Application started with args: $args');

  WidgetsFlutterBinding.ensureInitialized();

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
        size: const ui.Size(800, 900),
        minimumSize: const ui.Size(550, 750),
        center: true,
        title: 'موسوعة أحاديث الزكاة',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (!args.contains('--startup')) {
          await windowManager.show();
          await windowManager.focus();
        } else {
          await windowManager.hide();
        }
      });
      windowManager.setPreventClose(true);
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
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

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
      Menu menu = Menu(
        items: [
          MenuItem(key: 'show_window', label: 'فتح التطبيق'),
          MenuItem.separator(),
          MenuItem(key: 'exit_app', label: 'خروج'),
        ],
      );
      await trayManager.setContextMenu(menu);
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
      home: const SplashScreen(),
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
     if (Platform.isWindows) {
      trayManager.popUpContextMenu();
    }
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

final supabaseConnectionProvider = StateProvider<bool>((ref) {
  return _supabaseInitialized;
});