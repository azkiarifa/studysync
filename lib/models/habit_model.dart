class HabitModel {
  final int? id;
  final String name;
  final int color;
  final int targetDaysPerWeek;
  final DateTime createdAt;

  HabitModel({
    this.id,
    required this.name,
    this.color = 0xFF6366F1,
    this.targetDaysPerWeek = 7,
    required this.createdAt,
  });

  HabitModel copyWith({
    int? id,
    String? name,
    int? color,
    int? targetDaysPerWeek,
    DateTime? createdAt,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      targetDaysPerWeek: targetDaysPerWeek ?? this.targetDaysPerWeek,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'targetDaysPerWeek': targetDaysPerWeek,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int? ?? 0xFF6366F1,
      targetDaysPerWeek: map['targetDaysPerWeek'] as int? ?? 7,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class HabitLogModel {
  final int? id;
  final int habitId;
  final DateTime dateCompleted;

  HabitLogModel({
    this.id,
    required this.habitId,
    required this.dateCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'dateCompleted': dateCompleted.toIso8601String(),
    };
  }

  factory HabitLogModel.fromMap(Map<String, dynamic> map) {
    return HabitLogModel(
      id: map['id'] as int?,
      habitId: map['habitId'] as int,
      dateCompleted: DateTime.parse(map['dateCompleted'] as String),
    );
  }
}
