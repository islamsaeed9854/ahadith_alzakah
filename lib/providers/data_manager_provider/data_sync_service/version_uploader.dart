import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

class VersionUploader {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final String _bucket = 'ahadith.alzakah.app';
  final String _versionPath = 'ahadith_alzakah_data/version.json';
  final RetryOptions _retryOptions = const RetryOptions(
    maxAttempts: 2,
    delayFactor: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 2),
  );

  Future<void> uploadVersion(int version, BuildContext context, String successMessage) async {
    try {
      final versionJson = json.encode({'version': version});
      final versionBytes = Uint8List.fromList(utf8.encode(versionJson));
      await _retryOptions.retry(() async {
        await _supabase.storage
            .from(_bucket)
            .uploadBinary(
              _versionPath,
              versionBytes,
              fileOptions: const FileOptions(
                contentType: 'application/json',
                upsert: true,
                cacheControl: '0',
              ),
            )
            .timeout(const Duration(seconds: 100));
      }, onRetry: (e) => _logger.w('Retrying version upload: $e'));
      if (context.mounted) {
        // showSingleSnackBar(
        //   context,
        //   message: successMessage,
        //   backgroundColor: Colors.green, 
        //   duration: const Duration(seconds: 3), 
        // );
      }
    } catch (e) {
      _logger.e('Version upload error: $e');
      rethrow;
    }
  }
}