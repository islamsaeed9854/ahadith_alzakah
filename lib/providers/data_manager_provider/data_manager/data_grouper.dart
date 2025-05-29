import '../../../data/models/hadith.dart';

class HadithGrouper {
  List<Map<String, dynamic>> groupHadithsByStructure(List<Hadith> hadiths) {
    final Map<int, Map<int, List<Hadith>>> grouped = {};
    

    for (final hadith in hadiths) {
      grouped
          .putIfAbsent(hadith.bab, () => {})
          .putIfAbsent(hadith.fasl, () => [])
          .add(hadith);
    }

    return grouped.entries.map((babEntry) {
  
      final chapterTitle = babEntry.value.isNotEmpty && 
                         babEntry.value.values.first.isNotEmpty
          ? babEntry.value.values.first.first.chapter_title
          : 'باب رقم ${babEntry.key}';

      final sections = babEntry.value.entries.map((faslEntry) {

        final sectionTitle = faslEntry.value.isNotEmpty
            ? faslEntry.value.first.section_title
            : 'قسم رقم ${faslEntry.key}';

        return {
          'section_number': faslEntry.key,
          'section_title': sectionTitle,
          'ahadith': faslEntry.value.map((h) => {
            'id': h.id,
            'number': h.number,
            'deleted': h.deleted,
            'text': h.text,
            'reference': h.reference,
            'analysis': h.analysis,
            'summary': h.summary,
          
          }).toList(),
        };
      }).toList()
        ..sort((a, b) => (a['section_number'] as int).compareTo(b['section_number'] as int));

      return {
        'chapter_number': babEntry.key,
        'chapter_title': chapterTitle,
        'sections': sections,
      };
    }).toList()
      ..sort((a, b) => (a['chapter_number'] as int).compareTo(b['chapter_number'] as int));
  }
}