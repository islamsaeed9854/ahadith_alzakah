import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';
import '../../../core/utils.dart';
class DataUploader {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final String _bucket = 'ahadith.alzakah.app';
  final String _dataPath = 'ahadith_alzakah_data/ahadith_zakah.json';
  final RetryOptions _retryOptions = const RetryOptions(    maxAttempts: 3, // Increase attempts to handle slow internet
    delayFactor: Duration(seconds: 1), // Longer delay between attempts
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
      final fileBytes = Uint8List.fromList(utf8.encode(jsonData));      // Show loading indicator
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
          duration: Duration(days: 1), // Very long duration to keep SnackBar visible until upload completes
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
      scaffoldMessenger.hideCurrentSnackBar();
      if (context.mounted) {
        showSingleSnackBar(
              context,
              message: 'تم رفع البيانات بنجاح',
              backgroundColor:   Colors.green  ,
              duration: const Duration(seconds: 3),
            );
      }
    } catch (e) {
      _logger.e('Data upload error: $e');  
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      rethrow;
    }
  }
}