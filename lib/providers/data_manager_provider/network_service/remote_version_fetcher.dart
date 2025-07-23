import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math';

const _versionUrl = String.fromEnvironment(
  'VERSION_URL',
  defaultValue: 'URL_NOT_FOUND',
);

class RemoteVersionFetcher {
  final Logger _logger = Logger();

  String addTimestamp(String url) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    return '$url&t=$timestamp$random';
  }

  Future<int> fetchRemoteVersion() async {
    if (_versionUrl == 'URL_NOT_FOUND') {
      _logger.e('VERSION_URL not provided. Use --dart-define to provide it.');
     
      throw Exception('VERSION_URL not provided');
    }

   

    _logger.i('Attempting to fetch version from: $_versionUrl');

    final response = await http.get(
      Uri.parse(addTimestamp(_versionUrl)),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      _logger.i('Version fetch successful. Status 200.');
      final version = json.decode(response.body)['version'];
      if (version is int) return version;
      if (version is String) return int.parse(version);
      return 0;
    } else {
    
      _logger.e('Version fetch failed with status code: ${response.statusCode}');
      throw Exception('Failed to fetch remote version. Status code: ${response.statusCode}');
    }
  }
}