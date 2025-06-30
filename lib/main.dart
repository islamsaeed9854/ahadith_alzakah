// === main.dart (مُعدّل وآمن) ===
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
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
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showHadithDetails: true),
        ),
        (Route<dynamic> route) => false,
      );
      debugPrint('Navigated to HomeScreen with showHadithDetails: true');
    } else {
      debugPrint('Navigator state or context is null. The app is likely starting fresh.');
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();
  _initialAction = await AwesomeNotifications().getInitialNotificationAction(
    removeFromActionEvents: false
  );
  if (_initialAction != null) {
      debugPrint('App was launched by a notification action.');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(notificationServiceProvider).init();
    if (_initialAction != null) {
      Future.delayed(Duration.zero, () {
        debugPrint('Handling initial notification action after the first frame.');
        NotificationController.onActionReceivedMethod(_initialAction!);
        _initialAction = null;
      });
    }
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
        ); // Get your custom font size
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0), // Lock scaling to 100%
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
}