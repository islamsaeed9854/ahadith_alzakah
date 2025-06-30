// === remote_json_fetcher.dart (مُعدّل وآمن) ===
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math';

// --- بداية التعديل ---
const _dataUrl = String.fromEnvironment(
  'DATA_URL',
  defaultValue: 'URL_NOT_FOUND',
);
// --- نهاية التعديل ---

class RemoteJsonFetcher {
  final Logger _logger = Logger();
  
  // تم إزالة الرابط من هنا

  String addTimestamp(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return '$url&t=$timestamp$random';
  }

  Future<Map<String, dynamic>?> fetchRemoteJson() async {
    // --- بداية التعديل ---
    if (_dataUrl == 'URL_NOT_FOUND') {
      _logger.e('DATA_URL not provided. Use --dart-define to provide it.');
      throw Exception('DATA_URL not provided');
    }
    // --- نهاية التعديل ---

    try {
      final response = await http.get(
        Uri.parse(addTimestamp(_dataUrl)), // استخدام المتغير الآمن
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