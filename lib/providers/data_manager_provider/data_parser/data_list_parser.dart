import 'package:logger/logger.dart';
import '../../../data/models/hadith.dart';

class HadithListParser {
  final Logger _logger = Logger();

  List<Hadith> parseHadithList(dynamic jsonData) {
    final List<Hadith> hadiths = [];
    try {
      if (jsonData is! Map<String, dynamic> || jsonData['chapters'] is! List) {
        _logger.e('Invalid JSON structure');
        return hadiths;
      }
      for (final chapter in jsonData['chapters']) {
        final chapterNumber = chapter['chapter_number'] as int? ?? 0;
        final chapterTitle = chapter['chapter_title'] as String? ?? 'بدون عنوان باب'; 
        if (chapter['sections'] is! List) continue;
        for (final section in chapter['sections']) {
          final sectionNumber = section['section_number'] as int? ?? 0;
          final sectionTitle = section['section_title'] as String? ?? 'بدون عنوان قسم'; 
          if (section['ahadith'] is! List) continue;
          for (final h in section['ahadith']) {
            try {
              hadiths.add(Hadith.fromJson({
                ...h,
                'bab': chapterNumber,
                'fasl': sectionNumber,
                'chapter_title': chapterTitle, 
                'section_title': sectionTitle,
              }));
            } catch (e) {
              _logger.e('Hadith parse error: $e');
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Hadith list parse error: $e');
    }
    return hadiths;
  }
}