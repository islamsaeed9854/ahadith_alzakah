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
import 'screens/hadith_details.dart';

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
      // Reset innerBooksScreenProvider to prevent BooksScreen
      container.read(innerBooksScreenProvider.notifier).state = null;
      // Set navigation to HadithDetails tab (index 1)
      container.read(navigationProvider.notifier).changeTab(1);

      debugPrint('Set navigationProvider to index 1');
      debugPrint(
        'innerBooksScreenProvider reset to: ${container.read(innerBooksScreenProvider)}',
      );

      // Wait for state to propagate
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to HomeScreen with HadithDetails tab
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showHadithDetails: true),
        ),
        (route) => false,
      );
      debugPrint('Navigated to HomeScreen with showHadithDetails: true');
    } else {
      debugPrint('Navigator state or context is null');
      // Fallback: Directly push HadithDetails
      if (navigatorKey.currentState != null) {
        await Future.delayed(const Duration(milliseconds: 300));
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HadithDetails()),
          (route) => false,
        );
        debugPrint('Fallback: Navigated directly to HadithDetails');
      } else {
        debugPrint('Cannot navigate: Navigator state is null');
      }
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

  // Check for initial notification (e.g., app opened from notification)
  final initialNotification =
      await AwesomeNotifications().getInitialNotificationAction();
  if (initialNotification != null) {
    debugPrint(
      'App opened from initial notification: ${initialNotification.toString()}',
    );
    await NotificationController.onActionReceivedMethod(initialNotification);
  }

  runApp(ProviderScope(child: const MyApp()));
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
