import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../../core/utils.dart';

class DataUploader {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();

  Future<void> uploadData(Map<String, dynamic> jsonMap, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('جارٍ إرسال التحديثات إلى السيرفر...'), duration: Duration(days: 1)),
      );
      final response = await _supabase.functions.invoke(
        'compress-and-update-both',
        body: jsonMap,
      );
      scaffoldMessenger.hideCurrentSnackBar();
      if (response.status != 200) {
        final errorBody = response.data as Map<String, dynamic>?;
        final errorMessage = errorBody?['error'] ?? 'فشل غير معروف';
        throw Exception('faild to update files : $errorMessage');
      }

      if (context.mounted) {
        showSingleSnackBar(context, message: 'تم تحديث البيانات بنجاح', backgroundColor: Colors.green);
      }
    } catch (e) {
      _logger.e('Data upload error: $e');
      scaffoldMessenger.hideCurrentSnackBar();
      rethrow;
    }
  }
}