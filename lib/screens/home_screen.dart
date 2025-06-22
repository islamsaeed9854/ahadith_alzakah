import 'package:ahadith_alzakah/notification_service.dart';
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

  Widget _buildCustomBottomNavBar({
    required int currentIndex,
    required bool isDarkMode,
    required Function(int) onTap,
  }) {
   
    final Color backgroundColor = (isDarkMode && currentIndex == 1)
        ? const Color(0xff1c1c1c)
        : const Color(0xfffcf3e8);

    final navItems = [
      {'icon': Icons.home, 'label': 'الرئيسية'},
      {'icon': Icons.book, 'label': 'ألاحاديث'},
      {'icon': Icons.search, 'label': 'البحث'},
      {'icon': Icons.settings, 'label': 'الاعدادات'},
      {'icon': Icons.info, 'label': 'عن الموسوعة'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
       
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.1),
        //     spreadRadius: 0,
        //     blurRadius: 10,
        //   ),
        // ],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final bool isSelected = currentIndex == index;

      
          final Color selectedColor = const Color.fromARGB(255, 192, 144, 76);
          final Color unselectedColor = (isDarkMode && currentIndex == 1)
              ? const Color(0xfffcead0)
              : const Color.fromARGB(255, 26, 23, 23);
          final Color itemColor = isSelected ? selectedColor : unselectedColor;

       
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item['icon'] as IconData, color: itemColor),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: itemColor,
                        fontSize: 12, 
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
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
        } else if (!didPop && currentIndex == 0 && innerBooksScreenPr != null) {
          ref.read(innerBooksScreenProvider.notifier).state = null;
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
 
          bottomNavigationBar: _buildCustomBottomNavBar(
            currentIndex: currentIndex,
            isDarkMode: isDarkMode,
            onTap: (index) {
              if (index != 0) {
                ref.read(innerBooksScreenProvider.notifier).state = null;
              }
              if (index != 1) {
                ref.read(showDailyHadithProvider.notifier).state = false;
              }
              navNotifier.changeTab(index);
              debugPrint('Custom Nav Bar tapped: Switched to tab $index');
            },
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