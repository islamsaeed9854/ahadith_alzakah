// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Hadith {
  int hadithBook;
  int hadithFasl;
  int hadithNumber;
  String nameHadith;
  String textHadith;
  String explanationHadith;
  String translateNarrator;
  String ta5reegHadith;

  Hadith({
    required this.hadithBook,
    required this.hadithFasl,
    required this.hadithNumber,
    required this.nameHadith,
    required this.textHadith,
    required this.explanationHadith,
    required this.translateNarrator,
    required this.ta5reegHadith,
  });

  

 

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hadithBook': hadithBook,
      'hadithFasl': hadithFasl,
      'hadithNumber': hadithNumber,
      'nameHadith': nameHadith,
      'textHadith': textHadith,
      'explanationHadith': explanationHadith,
      'translateNarrator': translateNarrator,
      'ta5reegHadith': ta5reegHadith,
    };
  }

  factory Hadith.fromMap(Map<String, dynamic> map) {
    return Hadith(
      hadithBook: map['hadithBook'] as int,
      hadithFasl: map['hadithFasl'] as int,
      hadithNumber: map['hadithNumber'] as int,
      nameHadith: map['nameHadith'] as String,
      textHadith: map['textHadith'] as String,
      explanationHadith: map['explanationHadith'] as String,
      translateNarrator: map['translateNarrator'] as String,
      ta5reegHadith: map['ta5reegHadith'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Hadith.fromJson(String source) => Hadith.fromMap(json.decode(source) as Map<String, dynamic>);
}
