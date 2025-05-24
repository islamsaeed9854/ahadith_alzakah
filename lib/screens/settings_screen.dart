import 'package:ahadith_alzakah/screens/login_screen.dart';
import 'package:ahadith_alzakah/screens/remove_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../providers/theme_provider.dart';
import '../screens/add_hadith.dart';
import '../providers/navigation_provider.dart';
import 'edit_options_secreen.dart';
import '../providers/data_manager_provider/data_manager/data_manager.dart';
import '../data/models/hadith.dart';

final authStateProvider = StreamProvider<bool>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) {
    return supabase.auth.currentUser != null;
  });
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _handleTitleTap(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final lastTapTime = ref.read(lastTapTimeProvider);
    final tapCount = ref.read(tapCountProvider.notifier);

    if (lastTapTime == null || now.difference(lastTapTime) > const Duration(seconds: 2)) {
      tapCount.state = 1;
    } else {
      tapCount.state++;
    }

    ref.read(lastTapTimeProvider.notifier).state = now;

    if (tapCount.state >= 5) {
      tapCount.state = 0;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'تأكيد تسجيل الخروج',
              style: GoogleFonts.cairo(
                color: Colors.brown.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              'هل أنت متأكد أنك تريد تسجيل الخروج؟',
              style: GoogleFonts.reemKufi(
                color: Colors.brown.shade600,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(
                    color: Colors.brown.shade400,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _logout(context, ref);
                },
                child: Text(
                  'تسجيل الخروج',
                  style: GoogleFonts.cairo(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final supabase = ref.watch(supabaseProvider);
    try {
      await supabase.auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تسجيل الخروج بنجاح!',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      ref.read(navigationProvider.notifier).changeTab(0);
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('network')
                ? 'فشل الاتصال بالإنترنت، يرجى التحقق من الشبكة'
                : 'حدث خطأ أثناء تسجيل الخروج: $e',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final fontSize = ref.watch(fontSizeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final authState = ref.watch(authStateProvider);
    final currentHadiths = ref.watch(DataProvider).value ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = isLandscape ? screenWidth * 0.6 : screenWidth * 0.9;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Container(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => _handleTitleTap(context, ref),
                                  child: Text(
                                    'الإعدادات',
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xfffcead0),
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TextApp.backButton(ref),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          _buildSettingCard(
                            context,
                            label: 'حجم الخط',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Color(0xff977c55)),
                                  onPressed: fontSize > 10
                                      ? () => ref.read(fontSizeProvider.notifier).state--
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
                                  icon: const Icon(Icons.add, color: Color(0xff977c55)),
                                  onPressed: fontSize < 30
                                      ? () => ref.read(fontSizeProvider.notifier).state++
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          _buildSettingCard(
                            context,
                            label: 'القراءة الليلية',
                            child: Switch.adaptive(
                              value: isDarkMode,
                              onChanged: (value) =>
                                  ref.read(isDarkModeProvider.notifier).state = value,
                              activeColor: const Color(0xff977c55),
                            ),
                          ),

                          authState.when(
                            data: (isAuthenticated) {
                              if (isAuthenticated) {
                                return Column(
                                  children: [
                                    SizedBox(height: screenHeight * 0.02),
                                    _buildClickableSettingCard(
                                      context,
                                      label: 'إضافة حديث',
                                      icon: const Icon(Icons.add, color: Color(0xff977c55), size: 20),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AddHadithScreen()),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    _buildClickableSettingCard(
                                      context,
                                      label: 'حذف حديث',
                                      icon:
                                          const Icon(Icons.delete, color: Color(0xff977c55), size: 20),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const RemoveHadithScreen()),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    _buildClickableSettingCard(
                                      context,
                                      label: 'تعديل حديث',
                                      icon: const Icon(Icons.edit, color: Color(0xff977c55), size: 20),
                                      onTap: () {
                                        if (currentHadiths.isNotEmpty) {
                                          ref.read(selectedEditFieldProvider.notifier).state = '';
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const EditOptionsScreen(),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('لا يوجد أحاديث للتعديل'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    _buildClickableSettingCard(
                                      context,
                                      label: 'تسجيل الخروج',
                                      icon: const Icon(Icons.logout, color: Color(0xff977c55), size: 20),
                                      onTap: () => _showLogoutConfirmationDialog(context, ref),
                                    ),
                                  ],
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stackTrace) => Center(child: Text('خطأ: $error')),
                          ),
                        ],
                      ),
                    ),
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
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.reemKufi(
                color: Colors.brown.shade800,
                fontSize: screenWidth * 0.045,
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
