import 'package:ahadith_alzakah/notification_service.dart';
import 'package:ahadith_alzakah/providers/notification_service_provider.dart';
import 'package:ahadith_alzakah/screens/chapters_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import 'abwab_screen.dart';
import '../screens/search_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import '../providers/theme_provider.dart';
import '../core/constants.dart';
import 'hadith_details.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool showHadithDetails;
  const HomeScreen({super.key, this.showHadithDetails = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialized = false;

  void _setStatusBarForNonHadithScreens() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ));
  }

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen initState - showHadithDetails: ${widget.showHadithDetails}');
  }

  Future<void> _handleDailyHadithNavigation() async {
    if (_isInitialized || !widget.showHadithDetails) return;
    
    debugPrint('Handling daily hadith navigation...');
    
    // Wait for data to be loaded
    final dataState = ref.read(DataProvider);
    if (dataState.isLoading) {
      debugPrint('Data is still loading, waiting...');
      return;
    }
    
    if (dataState.hasError || dataState.valueOrNull?.isEmpty == true) {
      debugPrint('No hadiths available, staying on main screen');
      return;
    }

    // Try to get daily hadith
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final dailyHadith = await notificationService.getDailyHadith();
      
      if (dailyHadith != null) {
        debugPrint('Daily hadith found, navigating to details');
        ref.read(dailyHadithProvider.notifier).setDailyHadith(dailyHadith);
        ref.read(showDailyHadithProvider.notifier).state = true;
        ref.read(selectedHadithProvider.notifier).state = null;
        ref.read(innerBooksScreenProvider.notifier).state = null;
        ref.read(navigationProvider.notifier).changeTab(1);
        _isInitialized = true;
      } else {
        debugPrint('No daily hadith available');
      }
    } catch (e) {
      debugPrint('Error getting daily hadith: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final innerBooksScreenPr = ref.watch(innerBooksScreenProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final dataState = ref.watch(DataProvider);

    debugPrint('HomeScreen rendered with currentIndex: $currentIndex, innerBooksScreenPr: $innerBooksScreenPr');
    debugPrint('Screen size: ${MediaQuery.of(context).size.width}w x ${MediaQuery.of(context).size.height}h');
   
    // Handle daily hadith navigation after data is loaded
    if (widget.showHadithDetails && !dataState.isLoading && !_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDailyHadithNavigation();
      });
    }

    if (currentIndex != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setStatusBarForNonHadithScreens();
      });
    }

    final List<Widget> pages = [
      _buildScreenWithBackground(innerBooksScreenPr ?? BooksScreen()),
      _buildScreenWithBackground(const HadithDetails()),
      _buildScreenWithBackground(SearchScreen()),
      _buildScreenWithBackground(SettingsScreen()),
      _buildScreenWithBackground(AboutScreen()),
    ];

    return PopScope(
      canPop: currentIndex == 0 && innerBooksScreenPr == null,
      onPopInvokedWithResult: (didPop, Object? result) async {
        if (!didPop && currentIndex != 0) {
          navNotifier.changeTab(0);
          ref.read(innerBooksScreenProvider.notifier).state = null;
          
          _setStatusBarForNonHadithScreens();
          debugPrint('Pop invoked: Switched to tab 0 and reset innerBooksScreenProvider');
        } else if (!didPop && currentIndex == 0 && innerBooksScreenPr != null) {
          ref.read(innerBooksScreenProvider.notifier).state = null;
          debugPrint('Pop invoked: Reset innerBooksScreenProvider');
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              TextApp.appBackgroundWidget,
              pages[currentIndex],
            ],
          ),
          bottomNavigationBar: Opacity(
            opacity: (isDarkMode && currentIndex == 1) ? 1 : 1,
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              backgroundColor: (isDarkMode && currentIndex == 1)
                  ? const Color(0xff1c1c1c)
                  : const Color(0xfffcf3e8),
              onTap: (index) {
                if (index != 0) {
                  ref.read(innerBooksScreenProvider.notifier).state = null;
                }
                if (index != 1) { 
                  ref.read(showDailyHadithProvider.notifier).state = false;
                  _setStatusBarForNonHadithScreens();
                }
                navNotifier.changeTab(index);
                debugPrint('BottomNavigationBar tapped: Switched to tab $index');
              },
              selectedItemColor: const Color.fromARGB(255, 192, 144, 76),
              unselectedItemColor: (isDarkMode && currentIndex == 1)
                  ? const Color(0xfffcead0)
                  : const Color.fromARGB(255, 26, 23, 23),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "الرئيسية",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: "ألاحاديث",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: "البحث",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: "الاعدادات",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: "عن الموسوعة",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenWithBackground(Widget child) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: child,
    );
  }
}