// == secure_storage_service.dart ==
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/models/hadith.dart';
import 'package:flutter/services.dart';
class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  final String jsonKey = 'hadith_zakah_data';
  final String versionKey = 'hadith_json_version';

  Future<void> saveHadithList(List<Hadith> hadithList) async {
    final jsonList = hadithList.map((h) => h.toJson()).toList();
    await _storage.write(key: jsonKey, value: json.encode(jsonList));
  }

  Future<List<Hadith>> getHadithList() async {
    try {
      final jsonData = await _storage.read(key: jsonKey);
      if (jsonData == null) return [];
      final List<dynamic> list = json.decode(jsonData);
      return list.map((e) => Hadith.fromJson(e)).toList();
    } on PlatformException catch (e) {
      print("SecureStorage Read Error (getHadithList): $e. Deleting corrupt data.");
      await deleteAllData(); 
      return []; 
    } catch (e) {
      print("General Error (getHadithList): $e. Deleting corrupt data.");
      await deleteAllData();
      return [];
    }
  }

  Future<void> saveHadithJson(String jsonData) async {
    await _storage.write(key: jsonKey, value: jsonData);
  }

  Future<String?> getHadithJson() async {
    try {
      return await _storage.read(key: jsonKey);
    } on PlatformException catch (e) {
      print("SecureStorage Read Error (getHadithJson): $e. Deleting corrupt data.");
      await deleteAllData();
      return null;
    }
  }

  Future<bool> hasHadithJson() async {
    return (await getHadithJson()) != null;
  }

  Future<void> deleteHadithJson() async {
    await _storage.delete(key: jsonKey);
    await _storage.delete(key: versionKey);
  }

  Future<void> setJsonVersion(int version) async {
    await _storage.write(key: versionKey, value: version.toString());
  }

  Future<int> getJsonVersion() async {
    try {
      final versionStr = await _storage.read(key: versionKey);
      if (versionStr == null) return 0;
      return int.tryParse(versionStr) ?? 0;
    } on PlatformException catch (e) {
      print("SecureStorage Read Error (getJsonVersion): $e. Deleting corrupt data.");
      await deleteAllData();
      return 0; 
    }
  }

  Future<void> deleteAllData() async {
    await _storage.deleteAll();
  }
}