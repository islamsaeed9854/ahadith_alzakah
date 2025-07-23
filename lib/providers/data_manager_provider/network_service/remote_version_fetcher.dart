// === remote_version_fetcher.dart (الحل الجذري باستخدام Supabase API) ===
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class RemoteVersionFetcher {
  final Logger _logger = Logger();
  final _supabase = Supabase.instance.client;

  
  final String _bucketName = 'ahadith.alzakah.app';
  
  
  final String _versionFilePath = 'ahadith_alzakah_data/version.json';

  Future<int> fetchRemoteVersion() async {
    try {
      
      final responseBytes = await _supabase.storage
          .from(_bucketName)
          .download(_versionFilePath);

      
      final jsonString = utf8.decode(responseBytes);
      final versionData = json.decode(jsonString);

      final version = versionData['version'];
      if (version is int) return version;
      if (version is String) return int.parse(version);
      
      return 0;

    } on StorageException catch (e) {
      _logger.e('Supabase Storage Error (Version Fetch): ${e.message}');
    
      return 0; 
    } catch (e) {
      _logger.e('General error fetching remote version: $e');
      rethrow; 
    }
  }
}