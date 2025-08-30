import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'screens/home_screen.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/chapters_screen.dart';
import 'providers/notification_service_provider.dart';
import 'data/models/hadith.dart';
import 'notification_service.dart';
import 'core/secure_supabase_storage.dart';
import 'package:flutter/services.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'URL_NOT_FOUND',
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'ANON_KEY_NOT_FOUND',
);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationController {
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('Notification action received at ${DateTime.now()}');

    // إضافة delay للتأكد من أن التطبيق جاهز
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
      
      // استخدام delay إضافي قبل التنقل
      await Future.delayed(const Duration(milliseconds: 200));
      
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showHadithDetails: true),
        ),
        (Route<dynamic> route) => false,
      );
      debugPrint('Navigated to HomeScreen with showHadithDetails: true');
    } else {
      debugPrint('Navigator state or context is null. Retrying in 1 second...');
      // إعادة المحاولة بعد ثانية واحدة
      await Future.delayed(const Duration(seconds: 1));
      if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
        await onActionReceivedMethod(receivedAction);
      } else {
        debugPrint('Navigator still not ready. The app may need more time to initialize.');
      }
    }
  }
}

Future<void> _initializeApp() async {
  if (supabaseUrl == 'URL_NOT_FOUND' || supabaseAnonKey == 'ANON_KEY_NOT_FOUND') {
    throw Exception('Supabase URL/Key not provided. Use --dart-define to provide them.');
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
bool _launchedForDailyHadith = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows) {
    await localNotifier.setup(
      appName: 'أحاديث الزكاة',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    await windowManager.ensureInitialized();
    windowManager.setPreventClose(true);
  }
  
  // Detect scheduler launch flag and extract hadith data
  if (Platform.isWindows) {
    final args = Platform.executableArguments;
    if (args.contains('--show-daily-hadith')) {
  _launchedForDailyHadith = true;
    }
  }
  
  await _initializeApp();
  
  if (!Platform.isWindows) {
    _initialAction = await AwesomeNotifications().getInitialNotificationAction(
      removeFromActionEvents: false
    );
  }
  
  if (_initialAction != null) {
    debugPrint('App was launched by a notification action.');
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

class _MyAppState extends ConsumerState<MyApp> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      trayManager.addListener(this);
      windowManager.addListener(this);
      _initTray();
    }
    ref.read(notificationServiceProvider).init();
    
    if (_launchedForDailyHadith) {
      // Call the handler after a longer delay so providers are ready
      Future.delayed(const Duration(milliseconds: 800), () {
        ref.read(notificationServiceProvider).handleLaunchFromScheduler();
        _launchedForDailyHadith = false;
      
      });
    }
    
    if (_initialAction != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('Handling initial notification action after the first frame.');
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