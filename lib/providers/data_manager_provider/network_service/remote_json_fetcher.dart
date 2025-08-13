import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:math';
import 'package:archive/archive.dart';


const _dataUrl = String.fromEnvironment(
  'DATA_ZIP_URL',
  defaultValue: 'URL_NOT_FOUND',
);

class RemoteJsonFetcher {
  final Logger _logger = Logger();

 
  Uri _buildSafeUriWithTimestamp(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final newQueryParameters = Map<String, dynamic>.from(uri.queryParameters);
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100000);
    newQueryParameters['cache_buster'] = '$timestamp$random';

    return uri.replace(queryParameters: newQueryParameters);
  }

  Future<Map<String, dynamic>?> fetchRemoteJson() async {
    if (_dataUrl == 'URL_NOT_FOUND') {
      _logger.e('DATA_ZIP_URL not provided. Use --dart-define to provide it.');
      throw Exception('DATA_ZIP_URL not provided');
    }

    try {
      final safeUri = _buildSafeUriWithTimestamp(_dataUrl);
      
    
      final response = await http.get(
        safeUri,
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _logger.i('compressed file was gittin succesfully (${response.bodyBytes.length} byte).');
        
      
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);
        final jsonFile = archive.first;

        if (jsonFile.isFile) {
          final decompressedBytes = jsonFile.content as List<int>;
          final jsonString = utf8.decode(decompressedBytes);
          _logger.i('file was decompressed succesfully');
          return json.decode(jsonString) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      _logger.e('error in decompressing the compressed files : $e');
      rethrow;
    }
  }
}