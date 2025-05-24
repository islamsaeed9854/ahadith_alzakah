import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

class DataUploader {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final String _bucket = 'ahadith.alzakah.app';
  final String _dataPath = 'ahadith_alzakah_data/ahadith_zakah.json';
  final RetryOptions _retryOptions = const RetryOptions(
    maxAttempts: 3, // زيادة عدد المحاولات للتعامل مع الإنترنت البطيء
    delayFactor: Duration(seconds: 1), // تأخير أطول بين المحاولات
    maxDelay: Duration(seconds: 5),
  );

  Future<void> uploadData(Map<String, dynamic> jsonMap, BuildContext context) async {
    try {
      // التحقق من صحة البيانات
      if (jsonMap.isEmpty) {
        _logger.w('JSON data is empty');
        throw Exception('البيانات المراد رفعها فارغة');
      }

      final jsonData = json.encode(jsonMap);
      final fileBytes = Uint8List.fromList(utf8.encode(jsonData));

      // عرض مؤشر التحميل
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جارٍ المزامنة مع السيرفر...'),
            ],
          ),
          duration: Duration(days: 1), // مدة طويلة جدًا لضمان بقاء الـ SnackBar حتى انتهاء الرفع
        ),
      );

      // رفع الملف مع إعادة المحاولة
      await _retryOptions.retry(
        () async {
          await _supabase.storage.from(_bucket).uploadBinary(
            _dataPath,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'application/json',
              upsert: true,
              cacheControl: '0',
            ),
          );
        },
        onRetry: (e) => _logger.w('Retrying upload: $e'),
      );

      // إغلاق مؤشر التحميل وعرض رسالة النجاح
      scaffoldMessenger.hideCurrentSnackBar();
      // if (context.mounted) {
      //   scaffoldMessenger.showSnackBar(
      //     const SnackBar(
      //       content: Text('تم الرفع بنجاح'),
      //       backgroundColor: Colors.green,
      //       duration: Duration(seconds: 3),
      //     ),
      //   );
      // }
    } catch (e) {
      _logger.e('Data upload error: $e');
      // إغلاق مؤشر التحميل في حالة حدوث خطأ
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // رمي الاستثناء ليتم التعامل معه في الطبقة الأعلى (مثل DataAdder)
      rethrow;
    }
  }
}