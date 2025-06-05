import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/home_screen.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/splash_screen.dart';
import 'providers/notification_service_provider.dart';

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
      
      // Reset innerBooksScreenProvider to ensure BooksScreen is not active
      container.read(innerBooksScreenProvider.notifier).state = null;
      
      // Set navigation to HadithDetails tab (index 1)
      container.read(navigationProvider.notifier).changeTab(1);

      debugPrint('Set navigationProvider to index 1');
      debugPrint(
        'innerBooksScreenProvider reset to: ${container.read(innerBooksScreenProvider)}',
      );

      // Clear all previous routes and navigate to HomeScreen
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showHadithDetails: true),
        ),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
      debugPrint('Navigated to HomeScreen with showHadithDetails: true');
    } else {
      debugPrint('Navigator state or context is null');
    }
  }
}

Future<void> _initializeApp() async {
  await Supabase.initialize(
    url: 'https://oqjnppmlqqehnqktejfl.supabase.co',
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xam5wcG1scXFlaG5xa3RlamZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5OTg0NzgsImV4cCI6MjA2MzU3NDQ3OH0.ponVTjJnEhFJsjO5Ol25PJt5d2zrYToJxxHXDsbcLLE",
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();
  final initialNotification =
      await AwesomeNotifications().getInitialNotificationAction();
  if (initialNotification != null) {
    debugPrint(
      'App opened from initial notification: ${initialNotification.toString()}',
    );
    await NotificationController.onActionReceivedMethod(initialNotification);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize notifications via NotificationService
    ref.read(notificationServiceProvider).init();

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Azkar & Hadith App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}