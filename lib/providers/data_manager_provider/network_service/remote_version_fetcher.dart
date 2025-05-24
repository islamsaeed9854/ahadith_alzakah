import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math';

class RemoteVersionFetcher {
  final Logger _logger = Logger();
  final String versionUrl =
      'https://oqjnppmlqqehnqktejfl.supabase.co/storage/v1/object/sign/ahadith.alzakah.app/ahadith_alzakah_data/version.json?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InN0b3JhZ2UtdXJsLXNpZ25pbmcta2V5XzQ5ZTFkMTFmLWIzMDMtNGFjZi04NDY3LTc5Yjk0YzAwMWQ4YyJ9.eyJ1cmwiOiJhaGFkaXRoLmFsemFrYWguYXBwL2FoYWRpdGhfYWx6YWthaF9kYXRhL3ZlcnNpb24uanNvbiIsImlhdCI6MTc0ODA4NTUyMywiZXhwIjo4NjQwMDAwMDAwMDE3NDgxMDAwMDB9.bNnG8MGc7hwT4-Drbc8Xx1XJIXZVD5F9_qEKdRYjRW8';

  String addTimestamp(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return '$url&t=$timestamp$random';
  }

  Future<int> fetchRemoteVersion() async {
    try {
      final response = await http.get(
        Uri.parse(addTimestamp(versionUrl)),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final version = json.decode(response.body)['version'];
        if (version is int) return version;
        if (version is String) return int.parse(version);
        return 0;
      }
      return 0;
    } catch (e) {
      _logger.e('Version fetch error: $e');
      rethrow;
    }
  }
}