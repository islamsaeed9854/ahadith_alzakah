import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();

    // Set HadithDetails tab if showHadithDetails is true
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

    // Screens for navigation with background
    final List<Widget> pages = [
      _buildScreenWithBackground(innerBooksScreenPr ?? BooksScreen()),
      _buildScreenWithBackground(const HadithDetails()), // Tab 1: HadithDetails
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
              // Fixed background image
              Positioned.fill(
                child: Transform.rotate(
                  angle: 3.14159,
                  child: Image(
                    image: TextApp.appBackgroundImage,
                    fit: BoxFit.cover,
                    color: Colors.black26,
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
              // Current page content
              pages[currentIndex],
            ],
          ),
          bottomNavigationBar: Opacity(
            opacity: (isDarkMode && currentIndex == 1) ? 1 : .8,
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              backgroundColor:
                  (isDarkMode && currentIndex == 1)
                      ? const Color(0xff1c1c1c)
                      : const Color.fromRGBO(252, 243, 232, 0.9),
              onTap: (index) {
                if (index != 0) {
                  ref.read(innerBooksScreenProvider.notifier).state = null;
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