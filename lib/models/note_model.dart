class NoteModel {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int color;
  final bool isPinned;

  NoteModel({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.color,
    this.isPinned = false,
  });

  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    int? color,
    bool? isPinned,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      color: map['color'] as int,
      isPinned: (map['isPinned'] as int) == 1,
    );
  }
}
