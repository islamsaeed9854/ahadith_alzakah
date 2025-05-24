import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math';

class RemoteJsonFetcher {
  final Logger _logger = Logger();
  final String dataUrl =
      'https://oqjnppmlqqehnqktejfl.supabase.co/storage/v1/object/sign/ahadith.alzakah.app/ahadith_alzakah_data/ahadith_zakah.json?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InN0b3JhZ2UtdXJsLXNpZ25pbmcta2V5XzQ5ZTFkMTFmLWIzMDMtNGFjZi04NDY3LTc5Yjk0YzAwMWQ4YyJ9.eyJ1cmwiOiJhaGFkaXRoLmFsemFrYWguYXBwL2FoYWRpdGhfYWx6YWthaF9kYXRhL2FoYWRpdGhfemFrYWguanNvbiIsImlhdCI6MTc0ODA4NTU1MiwiZXhwIjo4LjY0MDAwMDAwMDAwMDE3NGUrMjJ9.geUIxS5-SWXlXBg8R2acGU45cTIndlWVFJfJA-X5DNc';

  String addTimestamp(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return '$url&t=$timestamp$random';
  }

  Future<Map<String, dynamic>?> fetchRemoteJson() async {
    try {
     
      final response = await http.get(
        Uri.parse(addTimestamp(dataUrl)),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.e('JSON fetch error: $e');
      rethrow;
    }
  }
}