class DeckModel {
  final int? id;
  final String title;
  final String description;
  final int color;

  DeckModel({
    this.id,
    required this.title,
    required this.description,
    required this.color,
  });

  DeckModel copyWith({
    int? id,
    String? title,
    String? description,
    int? color,
  }) {
    return DeckModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color,
    };
  }

  factory DeckModel.fromMap(Map<String, dynamic> map) {
    return DeckModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      color: map['color'] as int,
    );
  }
}
