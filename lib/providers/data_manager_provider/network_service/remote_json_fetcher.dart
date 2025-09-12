import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math';
import 'package:archive/archive.dart';

class RemoteJsonFetcher {
  final Logger _logger = Logger();

  // الروابط المضمنة مباشرة في الكود
  static const String _dataZipUrl = 'https://iccvwmacddhakaypawvn.supabase.co/storage/v1/object/sign/compreesed.files/ahadith_alzakah_data/ahadith_zakah.zip?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9mYWM2OGIxNC02ZjE0LTQwMDAtOGIyOS1mNjUxMzYwZTcxYTIiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJjb21wcmVlc2VkLmZpbGVzL2FoYWRpdGhfYWx6YWthaF9kYXRhL2FoYWRpdGhfemFrYWguemlwIiwiaWF0IjoxNzU0NzQwNzI2LCJleHAiOjk2MDE3NTQ3MzExMjZ9.L_-WGzw50zhU-JOuKAKyEclU59r3VhPqOjOFguYuAV8';

  Uri _buildSafeUriWithTimestamp(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final newQueryParameters = Map<String, dynamic>.from(uri.queryParameters);
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    newQueryParameters['cache_buster'] = '$timestamp$random';

    return uri.replace(queryParameters: newQueryParameters);
  }

  Future<Map<String, dynamic>?> fetchRemoteJson() async {
    try {
      final safeUri = _buildSafeUriWithTimestamp(_dataZipUrl);
      
      final response = await http.get(
        safeUri,
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('تم تحميل الملف المضغوط بنجاح (${response.bodyBytes.length} بايت).');
        
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);
        
        // البحث عن ملف JSON في الأرشيف
        for (final file in archive.files) {
          if (file.isFile && file.name.endsWith('.json')) {
            final decompressedBytes = file.content as List<int>;
            final jsonString = utf8.decode(decompressedBytes);
            _logger.i('تم فك ضغط الملف بنجاح: ${file.name}');
            return json.decode(jsonString) as Map<String, dynamic>;
          }
        }
        
        _logger.e('لم يتم العثور على ملف JSON في الأرشيف');
        return null;
      } else {
        _logger.e('فشل في تحميل الملف: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('خطأ في فك ضغط الملفات: $e');
      rethrow;
    }
  }
}