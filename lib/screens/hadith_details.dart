import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart'; // Assuming providers are in this file
import '../providers/navigation_provider.dart';
class HadithDetails extends ConsumerWidget {
  const HadithDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = ref.watch(themeProvider);
    final fontSize = ref.watch(fontSizeProvider);
final navNotifier = ref.read(navigationProvider.notifier);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: theme,
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textTheme.titleLarge?.color),
                onPressed: () => navNotifier.changeTab(0),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الباب الأول: فرض الزكاة وفضلها',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    'الفصل الأول: وجوب الزكاة | حديث رقم: 1',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Hadith text section
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'عن أبي هريرة رضي الله عنه قال: قال رسول الله صلى الله عليه وسلم: '
                      'ما نقصت صدقة من مال، وما زاد الله عبداً بعفو إلا عزاً، وما تواضع '
                      'أحد لله إلا رفعه الله. (رواه مسلم)',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: fontSize.toDouble(), // Dynamic font size from provider
                        height: 1.8,
                      ),
                    ),
                  ),
                  // Tabs (TabBar)
                  TabBar(
                    indicatorColor: const Color(0xFFE6A345),
                    labelColor: theme.textTheme.titleLarge?.color,
                    unselectedLabelColor: const Color(0xff977c55),
                    labelStyle: TextStyle(
                      fontSize: fontSize.toDouble() * 0.8, // Slightly smaller for tabs
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: fontSize.toDouble() * 0.8,
                    ),
                    tabs: const [
                      Tab(text: 'الخلاصة'),
                      Tab(text: 'التخريج'),
                      Tab(text: 'الدراسة'),
                    ],
                  ),
                  // Tabbed content (TabBarView)
                  Container(
                    height: screenHeight * 0.5,
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: TabBarView(
                      children: [
                        TabContent(text: 'الخلاصة: هذا الحديث يبين وجوب الزكاة وأهميتها في الإسلام...'),
                        TabContent(text: 'التخريج: أخرجه أبو داود في سننه برقم 1561، وصححه الألباني.'),
                        TabContent(text: 'الدراسة: الحديث يدل على عدالة توزيع المال...'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TabContent extends ConsumerWidget {
  final String text;
  const TabContent({super.key, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Text(
          text,
          textAlign: TextAlign.justify,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: fontSize.toDouble(), // Dynamic font size from provider
            height: 1.8,
          ),
        ),
      ),
    );
  }
}