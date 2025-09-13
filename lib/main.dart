import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'providers/notification_service_provider.dart';
import 'core/single_instance.dart';
import 'core/secure_supabase_storage.dart';
import 'dart:ui' as ui;
import 'screens/settings_screen.dart';
import 'dart:async';
import 'notification_service.dart';
import 'package:path_provider/path_provider.dart';

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

bool _supabaseInitialized = false;

final initializationProvider = FutureProvider<void>((ref) async {
  await _initializeApp();
  await ref.read(settingsInitializerProvider.future);
});

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
ProviderContainer? _globalContainer;

// دالة لكتابة الأخطاء في ملف
Future<void> _logErrorToFile(String error, String stackTrace) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logFile = File('${directory.path}/notification_error_log.txt');
    final timestamp = DateTime.now().toIso8601String();
    final logContent =
        '[$timestamp]\nError: $error\nStackTrace: $stackTrace\n\n';
    await logFile.writeAsString(logContent, mode: FileMode.append);
  } catch (e) {
    debugPrint("Failed to write to log file: $e");
  }
}

Future<void> _initializeApp() async {
  if (_supabaseInitialized) return;
  try {
    String urlToUse = supabaseUrl;
    String keyToUse = supabaseAnonKey;

    if (urlToUse == 'URL_NOT_FOUND' || urlToUse.isEmpty) {
      urlToUse = fallbackSupabaseUrl;
    }
    if (keyToUse == 'ANON_KEY_NOT_FOUND' || keyToUse.isEmpty) {
      keyToUse = fallbackSupabaseAnonKey;
    }

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
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
    _supabaseInitialized = false;
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  bool showDailyHadith = args.contains('--show-daily-hadith');
  debugPrint('App started with args: $args');

  // --- Start of Single Instance Logic (Corrected Version) ---
  if (!showDailyHadith) {
    bool isPrimary = await SingleInstance.startServer();
    if (!isPrimary) {
      debugPrint('Secondary instance detected. Sending message to primary...');
      bool sent = await SingleInstance.sendMessage(json.encode({'args': ['--show-window']}));
      if (sent) {
        debugPrint('Message sent successfully. Exiting secondary instance.');
        exit(0);
      } else {
        debugPrint('Failed to send message. The primary instance may have crashed. Trying to become the new primary...');
        // The stale lock file should have been deleted by the failed `sendMessage` call.
        // We can now attempt to start this instance as the primary one.
        isPrimary = await SingleInstance.startServer();
        if (!isPrimary) {
          // This should rarely happen, but as a fallback, we exit.
          debugPrint('Could not become the primary instance. Another instance may have just started. Exiting.');
          exit(1);
        }
      }
    }
  }
  debugPrint('This is the primary instance.');
  
  SingleInstance.messages.listen((msg) async {
    final Map<String, dynamic> data = json.decode(msg);
    final List<dynamic> receivedArgs = data['args'];
    if (receivedArgs.contains('--show-window')) {
      await _showMainWindow();
    }
  });
  // --- End of Single Instance Logic ---


  if (showDailyHadith) {
    try {
      debugPrint("Launched by scheduler to show daily hadith.");
      await _initializeApp();
      _globalContainer = ProviderContainer();
      final notificationService =
          _globalContainer!.read(notificationServiceProvider);
      await notificationService.init();
      await notificationService.showImmediateNotification();
      debugPrint("Scheduled notification process completed successfully.");
    } catch (e, st) {
      debugPrint("ERROR during scheduled notification task: $e");
      await _logErrorToFile(e.toString(), st.toString());
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      exit(0);
    }
  } else {
    await _initializeMainApp();
  }
}

Future<void> _initializeMainApp() async {
  debugPrint('Initializing main app');
  
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: ui.Size(800, 900),
    minimumSize: ui.Size(550, 750),
    center: true,
    title: 'موسوعة أحاديث الزكاة',
    alwaysOnTop: false,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    debugPrint('Window is ready to show');
    await _showMainWindow();
  });

  windowManager.setPreventClose(true);

  await _initializeApp();
  if (!_supabaseInitialized) {
    debugPrint('Failed to initialize Supabase. App might not function correctly.');
  }

  _globalContainer = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: _globalContainer!,
      child: const MyApp(),
    ),
  );
}

Future<void> _showMainWindow() async {
  try {
    debugPrint('Attempting to show main window...');
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setAlwaysOnTop(true);
    
    Future.delayed(const Duration(seconds: 1), () {
      windowManager.setAlwaysOnTop(false);
    });
    
    debugPrint('Main window shown successfully');
  } catch (e) {
    debugPrint('Error showing main window: $e');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp>
    with WindowListener, TrayListener {
  bool _isAppReady = false;

  @override
  void initState() {
    super.initState();
    debugPrint('MyApp initState called');
    
    windowManager.addListener(this);
    trayManager.addListener(this);
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _initializeComponents();
    });
  }

  Future<void> _initializeComponents() async {
    try {
      debugPrint('Initializing app components...');
      
      await _initTray();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(notificationServiceProvider).init();
        }
      });
      
      setState(() {
        _isAppReady = true;
      });
      
      debugPrint('App components initialized successfully');
    } catch (e) {
      debugPrint('Error initializing app components: $e');
    }
  }

  Future<void> _initTray() async {
    try {
      debugPrint('Initializing system tray...');
      
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
      
      debugPrint('System tray initialized successfully');
    } catch (e) {
      debugPrint('Error initializing system tray: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('MyApp dispose called');
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    SingleInstance.stopServer(); // Cleanly stop the server and delete the lock file.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp build called, isAppReady: $_isAppReady');
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'موسوعة أحاديث الزكاة',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: _isAppReady ? const SplashScreen() : const _LoadingScreen(),
    );
  }

  @override
  void onWindowClose() {
    debugPrint('Window close event received - hiding to tray');
    windowManager.hide();
    windowManager.setSkipTaskbar(true);
  }

  @override
  void onTrayIconMouseDown() {
    _showMainWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    debugPrint('Tray menu item clicked: ${menuItem.key}');
    
    if (menuItem.key == 'show_window') {
      _showMainWindow();
    } else if (menuItem.key == 'exit_app') {
      debugPrint('Exit app from tray menu');
      windowManager.destroy();
    }
  }
}

// شاشة تحميل مؤقتة
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل التطبيق...'),
          ],
        ),
      ),
    );
  }
}