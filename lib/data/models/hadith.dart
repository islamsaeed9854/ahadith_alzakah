class Hadith {
  final int id;
  final int number;
  final bool deleted;
  final String text;
  final String reference;
  final String analysis;
  final String summary;
  final int bab;
  final int fasl;
  final String chapter_title;
  final String section_title;

  Hadith({
    required this.id,
    required this.number,
    required this.deleted,
    required this.text,
    required this.reference,
    required this.analysis,
    required this.summary,
    required this.bab,
    required this.fasl,
    required this.chapter_title,
    required this.section_title,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      deleted: json['deleted'] as bool? ?? false,
      text: json['text'].replaceAll('P','ﷺ') as String? ?? '',
      reference: json['reference'].replaceAll('P','ﷺ') as String? ?? '',
      analysis: json['analysis'].replaceAll('P','ﷺ') as String? ?? '',
      summary: json['summary'].replaceAll('P','ﷺ') as String? ?? '',
      bab: json['bab'] as int? ?? 0,
      fasl: json['fasl'] as int? ?? 0,
      chapter_title: json['chapter_title'].replaceAll('  P ','') as String? ?? '',
      section_title: json['section_title'].replaceAll('  P ','') as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'deleted': deleted,
      'text': text,
      'reference': reference,
      'analysis': analysis,
      'summary': summary,
      'chapter_title': chapter_title,
      'section_title': section_title,
      'bab': bab,
      'fasl': fasl,
    };
  }

  Hadith copyWith({
    int? id,
    int? number,
    bool? deleted,
    String? text,
    String? reference,
    String? analysis,
    String? summary,
    String? chapter_title,
    String? section_title,
    int? bab,
    int? fasl,
  }) {
    return Hadith(
      id: id ?? this.id,
      number: number ?? this.number,
      deleted: deleted ?? this.deleted,
      text: text ?? this.text,
      reference: reference ?? this.reference,
      analysis: analysis ?? this.analysis,
      summary: summary ?? this.summary,
      bab: bab ?? this.bab,
      fasl: fasl ?? this.fasl,
      chapter_title: chapter_title ?? this.chapter_title,
      section_title: section_title ?? this.section_title,
    );
  }

  factory Hadith.empty() {
    return Hadith(
      id: 0,
      number: 0,
      deleted: false,
      text: '',
      reference: '',
      analysis: '',
      summary: '',
      bab: 0,
      fasl: 0,
      chapter_title: '',
      section_title: '',
    );
  }
}
