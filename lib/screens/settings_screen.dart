import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart'; // تأكد من أن المسار صحيح

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleFontBoxTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTapTime = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = ref.watch(fontSizeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/opening-screen02.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextApp.backButton(ref),
                      Text(
                        'الإعدادات',
                        style: TextStyle(
                          color: const Color(0xfffcead0),
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  GestureDetector(
                    onTap: _handleFontBoxTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.8),
                        borderRadius: BorderRadius.circular(12),
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
                          Text(
                            'حجم الخط',
                            style: TextStyle(
                              color: Colors.brown.shade800,
                              fontSize: screenWidth * 0.045,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove,
                                    color: Color(0xff977c55)),
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
                                icon: const Icon(Icons.add,
                                    color: Color(0xff977c55)),
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
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.8),
                      borderRadius: BorderRadius.circular(12),
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
                        Text(
                          'القراءة الليلية',
                          style: TextStyle(
                            color: Colors.brown.shade800,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                        Switch(
                          value: isDarkMode,
                          onChanged: (value) {
                            ref.read(isDarkModeProvider.notifier).state = value;
                          },
                          activeColor: const Color(0xff977c55),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(158, 158, 158,0.2),
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
                        Text(
                          'إضافة حديث',
                          style: TextStyle(
                            color: Colors.brown.shade800,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                        const Icon(
                          Icons.add,
                          color: Color(0xff977c55),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.8),
                      borderRadius: BorderRadius.circular(12),
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
                        Text(
                          "حذف حديث",
                          style: TextStyle(
                            color: Colors.brown.shade800,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                        const Icon(
                          Icons.delete,
                          color: Color(0xff977c55),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  Center(child: TextApp.drSamyKhalilName),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
