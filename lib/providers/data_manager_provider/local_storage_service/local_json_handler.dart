import 'dart:convert';
import 'package:logger/logger.dart';
import 'secure_storage_service.dart';

class LocalJsonHandler {
  final SecureStorageService _storage;
  final Logger _logger = Logger();

  LocalJsonHandler() : _storage = SecureStorageService();

  Future<void> saveHadithJson(Map<String, dynamic> jsonData) async {
    try {
      await _storage.saveHadithJson(json.encode(jsonData));
    } catch (e) {
      _logger.e('Local JSON save error: $e');
      rethrow;
    }
  }

  Future<String?> getLocalHadithJson() async {
    return await _storage.getHadithJson();
  }
}