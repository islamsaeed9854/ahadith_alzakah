import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/hadith.dart';
import '../data_sync_service/auth_checker.dart';
import '../data_sync_service/data_uploader.dart';
import '../data_sync_service/version_uploader.dart';
import '../local_storage_service/local_json_handler.dart';
import '../local_storage_service/local_version_handler.dart';
import 'data_grouper.dart';

class DataAdder {
  final AuthChecker _authChecker;
  final DataUploader _dataUploader;
  final VersionUploader _versionUploader;
  final LocalJsonHandler _jsonHandler;
  final LocalVersionHandler _versionHandler;
  final HadithGrouper _grouper;

  DataAdder()
      : _authChecker = AuthChecker(),
        _dataUploader = DataUploader(),
        _versionUploader = VersionUploader(),
        _jsonHandler = LocalJsonHandler(),
        _versionHandler = LocalVersionHandler(),
        _grouper = HadithGrouper();

  Future<void> addHadith(
    Hadith newHadith,
    int flag,
    BuildContext context,
    List<Hadith> current,
    AsyncValue<List<Hadith>> Function(List<Hadith>) updateState,
  ) async {
    if (newHadith.bab <= 0 || newHadith.fasl <= 0 || newHadith.number <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بيانات الحديث غير صالحة')),
        );
      }
      return;
    }

    final existingIndex = current.indexWhere((h) => h.bab == newHadith.bab && h.fasl == newHadith.fasl && h.number == newHadith.number);
    if (!_authChecker.isUserAuthenticated()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ لم يتم تسجيل الدخول، يرجى تسجيل الدخول أولاً')),
        );
      }
      return;
    }

    try {
      List<Hadith> stagedHadiths = List.from(current);
      switch (flag) {
        case 4:
          if (existingIndex != -1) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الحديث موجود مسبقاً')),
              );
            }
            return;
          }
          stagedHadiths.add(newHadith);
          break;
        case 3:
          if (existingIndex == -1) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الحديث غير موجود')),
              );
            }
            return;
          }
          stagedHadiths[existingIndex] = stagedHadiths[existingIndex].copyWith(text: newHadith.text);
          break;
        case 2:
          if (existingIndex == -1) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الحديث غير موجود')),
              );
            }
            return;
          }
          stagedHadiths[existingIndex] = stagedHadiths[existingIndex].copyWith(reference: newHadith.reference);
          break;
        case 1:
          if (existingIndex == -1) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الحديث غير موجود')),
              );
            }
            return;
          }
          stagedHadiths[existingIndex] = stagedHadiths[existingIndex].copyWith(analysis: newHadith.analysis);
          break;
        case 0:
          if (existingIndex == -1) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الحديث غير موجود')),
              );
            }
            return;
          }
          stagedHadiths[existingIndex] = stagedHadiths[existingIndex].copyWith(summary: newHadith.summary);
          break;
        case 5:
          if (existingIndex == -1) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الحديث غير موجود، لا يمكن التعديل')),
              );
            }
            return;
          }
          // تعديل جميع الحقول (text, summary, reference, analysis)
          stagedHadiths[existingIndex] = stagedHadiths[existingIndex].copyWith(
            text: newHadith.text,
            summary: newHadith.summary,
            reference: newHadith.reference,
            analysis: newHadith.analysis,
          );
          break;
        default:
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('عملية غير صالحة')),
            );
          }
          return;
      }

      stagedHadiths.sort((a, b) {
        final babCompare = a.bab.compareTo(b.bab);
        if (babCompare != 0) return babCompare;
        final faslCompare = a.fasl.compareTo(b.fasl);
        if (faslCompare != 0) return faslCompare;
        return a.number.compareTo(b.number);
      });

      final version = DateTime.now().millisecondsSinceEpoch;
      final grouped = _grouper.groupHadithsByStructure(stagedHadiths);
      final jsonMap = {'version': version, 'chapters': grouped};

      // رفع البيانات
      await _dataUploader.uploadData(jsonMap, context);
      await _versionUploader.uploadVersion(version, context, ''); // نرفع النسخة بدون رسالة نجاح مباشرة

      // حفظ البيانات محليًا
      await _jsonHandler.saveHadithJson(jsonMap);
      await _versionHandler.setLocalVersion(version);

      // تحديث الحالة
      updateState(stagedHadiths);

      // عرض رسالة النجاح فقط بعد التأكد من النجاح
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التعديل بنجاح!'), // تم تعديل الرسالة لتعكس التعديل
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // معالجة الأخطاء بطريقة مفهومة
      String errorMessage;
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorMessage = 'فشل الاتصال بالخادم، يرجى التحقق من الإنترنت وإعادة المحاولة';
      } else if (e.toString().contains('permission') || e.toString().contains('unauthorized')) {
        errorMessage = 'لا يوجد إذن كافٍ لإضافة الحديث، يرجى التحقق من الصلاحيات';
      } else if (e.toString().contains('storage') || e.toString().contains('io')) {
        errorMessage = 'مشكلة في التخزين المحلي، يرجى التأكد من المساحة المتاحة';
      } else {
        errorMessage = 'حدث خطأ أثناء الحفظ، يرجى المحاولة لاحقًا';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// مزود لـ DataAdder
final dataAdderProvider = Provider<DataAdder>((ref) {
  return DataAdder();
});