import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math';

class RemoteVersionFetcher {
  final Logger _logger = Logger();

  // الرابط المضمن مباشرة في الكود
  static const String _versionUrl = 'https://iccvwmacddhakaypawvn.supabase.co/storage/v1/object/sign/compreesed.files/ahadith_alzakah_data/version.json?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9mYWM2OGIxNC02ZjE0LTQwMDAtOGIyOS1mNjUxMzYwZTcxYTIiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJjb21wcmVlc2VkLmZpbGVzL2FoYWRpdGhfYWx6YWthaF9kYXRhL3ZlcnNpb24uanNvbiIsImlhdCI6MTc1NDc0MzUzNiwiZXhwIjo5NjAwMTc1NDczMzkzNn0.p0S7FWlEQ7dwq48Uo9spvs3AfglToqVWKFMnrjM2ZXQ';

  Uri _buildSafeUriWithTimestamp(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final newQueryParameters = Map<String, dynamic>.from(uri.queryParameters);
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    newQueryParameters['cache_buster'] = '$timestamp$random';

    return uri.replace(queryParameters: newQueryParameters);
  }

  Future<int> fetchRemoteVersion() async {
    try {
      final safeUri = _buildSafeUriWithTimestamp(_versionUrl);
      
      final response = await http.get(
        safeUri,
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final version = data['version'];
        
        if (version is int) return version;
        if (version is String) return int.parse(version);
        
        _logger.e('صيغة الإصدار غير متوقعة: $version');
        return 0;
      } else {
        _logger.e('فشل في تحميل الإصدار: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      _logger.e('خطأ في جلب الإصدار: $e');
      rethrow;
    }
  }
}