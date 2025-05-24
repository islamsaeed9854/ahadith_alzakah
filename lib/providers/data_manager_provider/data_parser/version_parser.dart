import 'package:logger/logger.dart';

class VersionParser {
  final Logger _logger = Logger();

  int parseVersion(dynamic version) {
    try {
      if (version is int) return version;
      if (version is String) return int.parse(version);
      return 0;
    } catch (e) {
      _logger.e('Version parse error: $e');
      return 0;
    }
  }
}