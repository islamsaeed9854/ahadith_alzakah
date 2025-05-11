import 'package:flutter/foundation.dart';
import '../data/models/hadith.dart';

class HadithProvider with ChangeNotifier {
  List<Hadith> _hadiths = [];

  // Get all hadiths
  List<Hadith> get hadiths => _hadiths;

  // Get hadith by ID
  Hadith? getHadithById(int hadithNumber) {
    try {
      return _hadiths.firstWhere((hadith) => hadith.hadithNumber == hadithNumber);
    } catch (e) {
      return null;
    }
  }

  // Get hadiths by book
  List<Hadith> getHadithsByBook(int hadithBook) {
    return _hadiths.where((hadith) => hadith.hadithBook == hadithBook).toList();
  }

  // Get hadiths by chapter (fasl)
  List<Hadith> getHadithsByChapter(int hadithFasl) {
    return _hadiths.where((hadith) => hadith.hadithFasl == hadithFasl).toList();
  }

  // Add a new hadith
  void addHadith(Hadith newHadith) {
    _hadiths.add(newHadith);
    notifyListeners();
  }

  // Update an existing hadith
  void updateHadith(Hadith updatedHadith) {
    final index = _hadiths.indexWhere(
        (h) => h.hadithNumber == updatedHadith.hadithNumber);
    if (index != -1) {
      _hadiths[index] = updatedHadith;
      notifyListeners();
    }
  }

  // Remove a hadith
  void removeHadith(int hadithNumber) {
    _hadiths.removeWhere((hadith) => hadith.hadithNumber == hadithNumber);
    notifyListeners();
  }

  // Load hadiths from JSON
  void loadHadithsFromJson(List<dynamic> jsonList) {
    _hadiths = jsonList.map((json) => Hadith.fromJson(json)).toList();
    notifyListeners();
  }

  // Clear all hadiths
  void clearHadiths() {
    _hadiths.clear();
    notifyListeners();
  }

  // Get total count
  int get count => _hadiths.length;

  // Search hadiths by text
  List<Hadith> searchHadiths(String query) {
    return _hadiths.where((hadith) =>
        hadith.textHadith.toLowerCase().contains(query.toLowerCase()) ||
        hadith.nameHadith.toLowerCase().contains(query.toLowerCase()) ||
        hadith.explanationHadith.toLowerCase().contains(query.toLowerCase())).toList();
  }
}