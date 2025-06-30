// === remote_version_fetcher.dart (مُعدّل وآمن) ===
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math';

// --- بداية التعديل ---
const _versionUrl = String.fromEnvironment(
  'VERSION_URL',
  defaultValue: 'URL_NOT_FOUND',
);
// --- نهاية التعديل ---

class RemoteVersionFetcher {
  final Logger _logger = Logger();

  // تم إزالة الرابط من هنا

  String addTimestamp(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return '$url&t=$timestamp$random';
  }

  Future<int> fetchRemoteVersion() async {
    // --- بداية التعديل ---
    if (_versionUrl == 'URL_NOT_FOUND') {
      _logger.e('VERSION_URL not provided. Use --dart-define to provide it.');
      throw Exception('VERSION_URL not provided');
    }
    // --- نهاية التعديل ---

    try {
      final response = await http.get(
        Uri.parse(addTimestamp(_versionUrl)), // استخدام المتغير الآمن
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