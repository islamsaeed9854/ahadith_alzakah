import 'package:ahadith_alzakah/notification_service.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  final bool showHadithDetails;
  const HomeScreen({super.key, this.showHadithDetails = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

 
    if (widget.showHadithDetails) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).changeTab(1);
        ref.read(innerBooksScreenProvider.notifier).state = null;
        debugPrint('Set navigation to HadithDetails tab (index 1)');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final innerBooksScreenPr = ref.watch(innerBooksScreenProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    debugPrint(
      'HomeScreen rendered with currentIndex: $currentIndex, innerBooksScreenPr: $innerBooksScreenPr',
    );

   
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
          debugPrint(
            'Pop invoked: Switched to tab 0 and reset innerBooksScreenProvider',
          );
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
              backgroundColor:
                  (isDarkMode && currentIndex == 1)
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
                debugPrint(
                  'BottomNavigationBar tapped: Switched to tab $index',
                );
              },
              selectedItemColor: const Color.fromARGB(255, 192, 144, 76),
              unselectedItemColor:
                  (isDarkMode && currentIndex == 1)
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
         // Test button for immediate notification
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () {
          //     ref.read(notificationServiceProvider).sendImmediateNotification();
          //     debugPrint('Triggered immediate notification');
          //   },
          //   child: const Icon(Icons.notification_add),
          // ),
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