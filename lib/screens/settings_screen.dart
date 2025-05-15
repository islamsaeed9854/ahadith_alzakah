import 'package:ahadith_alzakah/screens/login_screen.dart';
import 'package:ahadith_alzakah/screens/remove_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/theme_provider.dart';
import '../screens/add_hadith.dart';
import '../providers/navigation_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _handleTitleTap(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final lastTapTime = ref.read(lastTapTimeProvider);
    final tapCount = ref.read(tapCountProvider.notifier);

    if (lastTapTime == null ||
        now.difference(lastTapTime) > const Duration(seconds: 2)) {
      tapCount.state = 1;
    } else {
      tapCount.state++;
    }

    ref.read(lastTapTimeProvider.notifier).state = now;

    if (tapCount.state >= 5) {
      tapCount.state = 0;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = ref.watch(fontSizeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _handleTitleTap(context, ref),
                            child: Text(
                              'الإعدادات',
                              style: GoogleFonts.cairo(
                                color: const Color(0xfffcead0),
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextApp.backButton(ref),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Font Size Setting
                      _buildSettingCard(
                        context,
                        label: 'حجم الخط',
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove,
                                color: Color(0xff977c55),
                              ),
                              onPressed:
                                  fontSize > 10
                                      ? () =>
                                          ref
                                              .read(fontSizeProvider.notifier)
                                              .state--
                                      : null,
                            ),
                            Text(
                              fontSize.toString(),
                              style: GoogleFonts.cairo(
                                color: Colors.brown.shade800,
                                fontSize: screenWidth * 0.045,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xff977c55),
                              ),
                              onPressed:
                                  fontSize < 30
                                      ? () =>
                                          ref
                                              .read(fontSizeProvider.notifier)
                                              .state++
                                      : null,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Dark Mode Setting
                      _buildSettingCard(
                        context,
                        label: 'القراءة الليلية',
                        child: Switch.adaptive(
                          value: isDarkMode,
                          onChanged:
                              (value) =>
                                  ref.read(isDarkModeProvider.notifier).state =
                                      value,
                          activeColor: const Color(0xff977c55),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Add Hadith Button
                      _buildClickableSettingCard(
                        context,
                        label: 'إضافة حديث',
                        icon: const Icon(
                          Icons.add,
                          color: Color(0xff977c55),
                          size: 20,
                        ),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddHadithScreen(),
                              ),
                            ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Remove Hadith Button
                      _buildClickableSettingCard(
                        context,
                        label: 'حذف حديث',
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xff977c55),
                          size: 20,
                        ),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RemoveHadithScreen(),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(158, 158, 158, 0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.brown.shade800,
                fontSize: screenWidth * 0.05,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildClickableSettingCard(
    BuildContext context, {
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildSettingCard(context, label: label, child: icon),
    );
  }
}
