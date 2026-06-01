class PomodoroModel {
  final int? id;
  final int durationMinutes;
  final DateTime dateTime;
  final String category; // 'Belajar', 'Tugas', 'Projek', 'Lainnya'

  PomodoroModel({
    this.id,
    required this.durationMinutes,
    required this.dateTime,
    required this.category,
  });

  PomodoroModel copyWith({
    int? id,
    int? durationMinutes,
    DateTime? dateTime,
    String? category,
  }) {
    return PomodoroModel(
      id: id ?? this.id,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'durationMinutes': durationMinutes,
      'dateTime': dateTime.toIso8601String(),
      'category': category,
    };
  }

  factory PomodoroModel.fromMap(Map<String, dynamic> map) {
    return PomodoroModel(
      id: map['id'] as int?,
      durationMinutes: map['durationMinutes'] as int,
      dateTime: DateTime.parse(map['dateTime'] as String),
      category: map['category'] as String,
    );
  }
}
