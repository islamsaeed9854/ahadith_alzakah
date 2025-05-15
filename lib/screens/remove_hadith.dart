import 'package:ahadith_alzakah/core/constants.dart';
import 'package:ahadith_alzakah/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class RemoveHadithScreen extends ConsumerWidget {
  const RemoveHadithScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom; // Get keyboard height

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevent Scaffold from resizing with keyboard
        body: Stack(
          fit: StackFit.expand, // Ensure Stack fills the entire screen
          children: [
            // Background
            SizedBox.expand(child: TextApp.appBackgroundWidget),

            // Overlay
            Container(color: const Color.fromRGBO(0, 0, 0, 0.3)),

            // Main content
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: screenSize.height * 0.04, // Space for title and back button
                    bottom: keyboardHeight > 0 ? keyboardHeight + 30 : 30, // Adjust for keyboard
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - keyboardHeight, // Adjust minHeight based on keyboard
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'حذف حديث',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenSize.width * 0.09,
                                  color: const Color(0xfffcead0),
                                  shadows: [
                                    Shadow(
                                      blurRadius: screenSize.width * 0.03,
                                      color: const Color(0xfffcead0),
                                    ),
                                  ],
                                ),
                              ),
                              TextApp.backButtonLoginAddRemovePages(context),
                            ],
                          ),
                          SizedBox(height: screenSize.height * 0.04),
                          Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLabeledInputField('رقم الباب'),
                                const SizedBox(height: 20),
                                _buildLabeledInputField('رقم الفصل'),
                                const SizedBox(height: 20),
                                _buildLabeledInputField('رقم الحديث'),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff912929),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    _showConfirmationDialog(context);
                                  },
                                  child: Text(
                                    'حذف الحديث',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20), // Additional bottom padding
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledInputField(String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.cairo(
              color: AppTheme.primaryColor,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: TextFormField(
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xfffcead0),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xffe6a345),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xffe6a345),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Color(0xffe6a345),
                  width: 2,
                ),
              ),
            ),
            cursorColor: const Color(0xff6f4f2d),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFFFDF5EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(
              color: Color(0xff912929),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('هل أنت متأكد من حذف هذا الحديث؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.brown),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الحديث بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}