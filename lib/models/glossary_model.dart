class GlossaryModel {
  final int? id;
  final int subjectId;
  final String term;
  final String definition;

  GlossaryModel({
    this.id,
    required this.subjectId,
    required this.term,
    required this.definition,
  });

  GlossaryModel copyWith({
    int? id,
    int? subjectId,
    String? term,
    String? definition,
  }) {
    return GlossaryModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      term: term ?? this.term,
      definition: definition ?? this.definition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'term': term,
      'definition': definition,
    };
  }

  factory GlossaryModel.fromMap(Map<String, dynamic> map) {
    return GlossaryModel(
      id: map['id'] as int?,
      subjectId: map['subjectId'] as int,
      term: map['term'] as String,
      definition: map['definition'] as String,
    );
  }
}
