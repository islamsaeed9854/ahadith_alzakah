import 'package:logger/logger.dart';
import 'secure_storage_service.dart';

class LocalVersionHandler {
  final SecureStorageService _storage;
  final Logger _logger = Logger();

  LocalVersionHandler() : _storage = SecureStorageService();

  Future<int> getLocalVersion() async {
    return await _storage.getJsonVersion();
  }

  Future<void> setLocalVersion(int version) async {
    try {
      await _storage.setJsonVersion(version);
    } catch (e) {
      _logger.e('Local version update error: $e');
      rethrow;
    }
  }
}