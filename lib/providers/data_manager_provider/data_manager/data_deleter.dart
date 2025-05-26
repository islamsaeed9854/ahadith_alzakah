import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/hadith.dart';
import '../data_sync_service/auth_checker.dart';
import '../data_sync_service/data_uploader.dart';
import '../data_sync_service/version_uploader.dart';
import '../local_storage_service/local_json_handler.dart';
import '../local_storage_service/local_version_handler.dart';
import 'data_grouper.dart';

class DataDeleter {
  final AuthChecker _authChecker;
  final DataUploader _dataUploader;
  final VersionUploader _versionUploader;
  final LocalJsonHandler _jsonHandler;
  final LocalVersionHandler _versionHandler;
  final HadithGrouper _grouper;

  DataDeleter()
      : _authChecker = AuthChecker(),
        _dataUploader = DataUploader(),
        _versionUploader = VersionUploader(),
        _jsonHandler = LocalJsonHandler(),
        _versionHandler = LocalVersionHandler(),
        _grouper = HadithGrouper();

  Future<void> deleteHadith(
    int bab,
    int fasl,
    int number,
    BuildContext context,
    List<Hadith> current,
    AsyncValue<List<Hadith>> Function(List<Hadith>) updateState,
  ) async {
    if (bab <= 0 || fasl <= 0 || number <= 0) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بيانات الحديث غير صالحة')));
      return;
    }

    final exists = current.any((h) => h.bab == bab && h.fasl == fasl && h.number == number);
    if (!exists) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحديث غير موجود')));
      return;
    }

    if (!_authChecker.isUserAuthenticated()) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ لم يتم تسجيل الدخول، يرجى تسجيل الدخول أولاً')));
      return;
    }

    try {
      final stagedHadiths = current.where((h) => !(h.bab == bab && h.fasl == fasl && h.number == number)).toList();
      final version = DateTime.now().millisecondsSinceEpoch;
      final grouped = _grouper.groupHadithsByStructure(stagedHadiths);
      final jsonMap = {'version': version, 'chapters': grouped};

      await _dataUploader.uploadData(jsonMap, context);
      await _versionUploader.uploadVersion(version, context, '🗑️ تم الحذف بنجاح');
      updateState(stagedHadiths);
      await _jsonHandler.saveHadithJson(jsonMap);
      await _versionHandler.setLocalVersion(version);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحذف: ${e.toString()}')));
    }
  }
}