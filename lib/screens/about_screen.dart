import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/theme.dart';


class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back Button
                          TextApp.backButton(ref),
                          SizedBox(height: screenHeight * 0.02),
                          // About Us Title
                          Text(
                            'عن التطبيق',
                            style: TextStyle(
                              color: AppTheme.secodaryColor,
                              fontSize:
                                  screenWidth * 0.08, // Responsive font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          // About Us Content
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.015,
                            ),
                            child: Text(
                              'معلومات عنا\n\n'
                              'هذا التطبيق مخصص لتقديم معلومات ونتائج بحث دقيقة حول مواضيع متنوعة. '
                              'نحن نهدف إلى توفير تجربة مستخدم سلسة ومفيدة من خلال واجهة سهلة الاستخدام '
                              'ومحتوى غني. يمكنك البحث عن المعلومات، ضبط الإعدادات مثل حجم الخط، '
                              'والاستمتاع بتصميم يدعم اللغة العربية بشكل كامل.',
                              style: TextStyle(
                                color: Colors.brown.shade800,
                                fontSize: screenWidth * 0.045,
                                height: 1.6,
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          // Contact Us Title
                          Text(
                            'تواصل معنا',
                            style: TextStyle(
                              color: AppTheme.secodaryColor,
                              fontSize:
                                  screenWidth * 0.08, // Responsive font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          // Contact Us Content
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.015,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'البريد الإلكتروني: support@appname.com',
                                  style: TextStyle(
                                    color: Colors.brown.shade800,
                                    fontSize: screenWidth * 0.045,
                                    height: 1.6,
                                  ),
                                ),
                                Text(
                                  'رقم الهاتف: +123 456 7890',
                                  style: TextStyle(
                                    color: Colors.brown.shade800,
                                    fontSize: screenWidth * 0.045,
                                    height: 1.6,
                                  ),
                                ),
                                Text(
                                  'العنوان: شارع التقدم، مدينة المعرفة',
                                  style: TextStyle(
                                    color: Colors.brown.shade800,
                                    fontSize: screenWidth * 0.045,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 25,),
                          Center(child: TextApp.drSamyKhalilName),
                        ],
                      ),
                      
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
