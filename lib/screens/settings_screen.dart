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
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = ref.watch(fontSizeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Background Image
            Image(
              image: TextApp.appBackgroundImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              color: Colors.black26,
              colorBlendMode: BlendMode.darken,
            ),
            // Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
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
                                TextApp.backButton(ref), // Back button on the right
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.04),

                            /// حجم الخط
                            _buildSettingCard(
                              screenWidth,
                              screenHeight,
                              label: 'حجم الخط',
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Color(0xff977c55),
                                    ),
                                    onPressed: () {
                                      if (fontSize > 10) {
                                        ref
                                            .read(fontSizeProvider.notifier)
                                            .state--;
                                      }
                                    },
                                  ),
                                  Text(
                                    fontSize.toString(),
                                    style: TextStyle(
                                      color: Colors.brown.shade800,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Color(0xff977c55),
                                    ),
                                    onPressed: () {
                                      if (fontSize < 30) {
                                        ref
                                            .read(fontSizeProvider.notifier)
                                            .state++;
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            /// القراءة الليلية
                            _buildSettingCard(
                              screenWidth,
                              screenHeight,
                              label: 'القراءة الليلية',
                              child: Switch(
                                value: isDarkMode,
                                onChanged: (value) {
                                  ref.read(isDarkModeProvider.notifier).state =
                                      value;
                                },
                                activeColor: const Color(0xff977c55),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            /// إضافة حديث
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AddHadithScreen(),
                                  ),
                                );
                              },
                              child: _buildSettingCard(
                                screenWidth,
                                screenHeight,
                                label: 'إضافة حديث',
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xff977c55),
                                  size: 20,
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            /// حذف حديث
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RemoveHadithScreen(),
                                  ),
                                );
                              },
                              child: _buildSettingCard(
                                screenWidth,
                                screenHeight,
                                label: 'حذف حديث',
                                child: const Icon(
                                  Icons.delete,
                                  color: Color(0xff977c55),
                                  size: 20,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    double screenWidth,
    double screenHeight, {
    required String label,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(158, 158, 158, 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
}