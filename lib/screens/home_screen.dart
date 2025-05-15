import 'package:ahadith_alzakah/screens/hadith_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import 'abwab_screen.dart';
import '../screens/search_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import '../providers/theme_provider.dart';
import '../core/constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final innerBooksScreenPr = ref.watch(innerBooksScreenProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Screens for navigation with background
    final List<Widget> pages = [
      _buildScreenWithBackground(innerBooksScreenPr ?? BooksScreen()),
      _buildScreenWithBackground(HadithDetails()),
      _buildScreenWithBackground(SearchScreen()),
      _buildScreenWithBackground(SettingsScreen()),
      _buildScreenWithBackground(AboutScreen()),
    ];

    return PopScope(
      canPop: currentIndex != 0 || ref.watch(innerBooksScreenProvider) != null ? false : true,
      onPopInvokedWithResult: (didPop, Object? result) async {
        if (!didPop && currentIndex != 0) {
          navNotifier.changeTab(0);
        } else if (!didPop && currentIndex == 0 && innerBooksScreenPr != null) {
          ref.read(innerBooksScreenProvider.notifier).state = null;
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
          body: Stack(
            children: [
              // Fixed background image for all pages rotated 180 degrees
              Positioned.fill(
                child: Transform.rotate(
                  angle: 3.14159, // 180 degrees in radians
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
              backgroundColor: (isDarkMode && currentIndex == 1)
                  ? const Color(0xff1c1c1c)
                  : const Color.fromRGBO(255, 255, 255, .5),
              onTap: (index) {
                if (index != 0) {
                  ref.read(innerBooksScreenProvider.notifier).state = null;
                }
                navNotifier.changeTab(index);
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

  // Helper function to add background to screens
  Widget _buildScreenWithBackground(Widget child) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: child,
    );
  }
}
