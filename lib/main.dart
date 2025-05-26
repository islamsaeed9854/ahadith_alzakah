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

late ProviderContainer globalProviderContainer;

class NotificationController {
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification action received!');

    if (navigatorKey.currentState != null) {
      globalProviderContainer.read(navigationProvider.notifier).changeTab(1);

      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }
}

final appInitializationProvider = FutureProvider<void>((ref) async {
  try {
    await ref.read(notificationInitProvider.future);

    // Set notification action listener
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );

    final pending = await AwesomeNotifications().listScheduledNotifications();
    debugPrint('Pending notifications: ${pending.length}');
  } catch (e) {
    debugPrint('Error during app initialization: $e');
  }
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://oqjnppmlqqehnqktejfl.supabase.co',
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xam5wcG1scXFlaG5xa3RlamZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5OTg0NzgsImV4cCI6MjA2MzU3NDQ3OH0.ponVTjJnEhFJsjO5Ol25PJt5d2zrYToJxxHXDsbcLLE",
  );

  globalProviderContainer = ProviderContainer();

  runApp(UncontrolledProviderScope(
    container: globalProviderContainer,
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Azkar & Hadith App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationAsync = ref.watch(appInitializationProvider);

    return initializationAsync.when(
      data: (_) {
        // After initialization, go to SplashScreen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        });
        return const _LoadingScreen();
      },
      loading: () => const _LoadingScreen(),
      error: (error, stackTrace) {
        debugPrint('Initialization error: $error');
        // On error, still go to SplashScreen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        });
        return const _LoadingScreen();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SplashScreen(),
    );
  }
}