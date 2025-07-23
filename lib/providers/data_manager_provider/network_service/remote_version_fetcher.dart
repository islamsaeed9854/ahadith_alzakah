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

  
  Uri _buildSafeUri(String baseUrl) {
    
    final uri = Uri.parse(baseUrl);

    
    final newQueryParameters = Map<String, dynamic>.from(uri.queryParameters);
    
 
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    newQueryParameters['t'] = '$timestamp$random';

  
    return uri.replace(queryParameters: newQueryParameters);
  }


  Future<int> fetchRemoteVersion() async {
    if (_versionUrl == 'URL_NOT_FOUND') {
      _logger.e('VERSION_URL not provided. Use --dart-define to provide it.');
      throw Exception('VERSION_URL not provided');
    }

    try {
      final safeUri = _buildSafeUri(_versionUrl); 
      
      final response = await http.get(
        safeUri, 
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