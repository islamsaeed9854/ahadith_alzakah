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
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// This class handles the logic for what happens when a notification is tapped.
class NotificationController {
  /// This method is the entry point for notification actions.
  /// It's a static method that can be called from a background isolate.
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('Notification action received at ${DateTime.now()}');

    // This is the crucial check. If the app is running (even in the background),
    // the navigatorKey will have a state and context, and we can navigate.
    // If the app was terminated, this will be false, and the logic to handle
    // the initial notification in main.dart and MyApp will take over.
    if (navigatorKey.currentState != null &&
        navigatorKey.currentContext != null) {
      // Access the Riverpod container safely using the navigator's context.
      final container = ProviderScope.containerOf(navigatorKey.currentContext!);

      // Parse the hadith from the notification payload
      if (receivedAction.payload?.containsKey('hadith') == true) {
        try {
          final hadithJson = receivedAction.payload!['hadith']!;
          final hadithMap = json.decode(hadithJson) as Map<String, dynamic>;
          final hadith = Hadith.fromJson(hadithMap);

          // Update the providers to show the correct daily hadith.
          container.read(dailyHadithProvider.notifier).setDailyHadith(hadith);
          container.read(showDailyHadithProvider.notifier).state = true;
          // Clear any selected hadith to ensure the daily hadith is shown.
          container.read(selectedHadithProvider.notifier).state = null;
          debugPrint('Set daily hadith from notification payload');
        } catch (e) {
          debugPrint('Error parsing hadith from notification: $e');
        }
      }

      // Reset any inner screen navigation to ensure a clean state.
      container.read(innerBooksScreenProvider.notifier).state = null;

      // Set the bottom navigation bar to the HadithDetails tab (index 1).
      container.read(navigationProvider.notifier).changeTab(1);
      debugPrint('Set navigationProvider to index 1');

      // Navigate to the HomeScreen, ensuring it shows the HadithDetails page.
      // This removes all previous routes, which is important for consistency.
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showHadithDetails: true),
        ),
        (Route<dynamic> route) => false,
      );
      debugPrint('Navigated to HomeScreen with showHadithDetails: true');
    } else {
      // This case is handled by the initial notification logic in main.dart.
      debugPrint('Navigator state or context is null. The app is likely starting fresh.');
    }
  }
}

/// Initializes Supabase.
Future<void> _initializeApp() async {
  await Supabase.initialize(
    url: 'https://oqjnppmlqqehnqktejfl.supabase.co',
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xam5wcG1scXFlaG5xa3RlamZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5OTg0NzgsImV4cCI6MjA2MzU3NDQ3OH0.ponVTjJnEhFJsjO5Ol25PJt5d2zrYToJxxHXDsbcLLE",
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSupabaseStorage(),
    ),
  );
}

// A global variable to hold the notification that launched the app.
// This is a key part of the fix to avoid race conditions.
ReceivedAction? _initialAction;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();

  // Get the notification action that launched the app, if any.
  // This is the correct way to handle notifications when the app is terminated.
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
    // Initialize the notification service, which sets up listeners for when the app is running.
    ref.read(notificationServiceProvider).init();

    // FIX: This is the core of the fix for the black screen issue.
    // If the app was launched by a notification (_initialAction is not null),
    // we wait until the first frame is rendered, and then handle the action.
    // This ensures that the Navigator and Riverpod providers are ready.
    if (_initialAction != null) {
      Future.delayed(Duration.zero, () {
        debugPrint('Handling initial notification action after the first frame.');
        NotificationController.onActionReceivedMethod(_initialAction!);
        // Clear the action so it's not processed again on rebuilds.
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
              fontSize: fontSize.toDouble(), // Apply your custom size
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