import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class RemoteJsonFetcher {
  final Logger _logger = Logger();
  final _supabase = Supabase.instance.client;

  final String _bucketName = 'ahadith.alzakah.app';
  final String _dataFilePath = 'ahadith_alzakah_data/ahadith_zakah.json';

  Future<Map<String, dynamic>?> fetchRemoteJson() async {
    try {
      final responseBytes = await _supabase.storage
          .from(_bucketName)
          .download(_dataFilePath);

    
      final jsonString = utf8.decode(responseBytes);
      
      return json.decode(jsonString) as Map<String, dynamic>;

    } on StorageException catch (e) {
      _logger.e('Supabase Storage Error (JSON Fetch): ${e.message}');
      return null;
    } catch (e) {
      _logger.e('General error fetching remote JSON: $e');
      rethrow;
    }
  }
}