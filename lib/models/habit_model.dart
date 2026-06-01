class HabitModel {
  final int? id;
  final String name;
  final String frequency; // 'Daily', 'Weekly'
  final int streak;
  final DateTime? lastCompleted;

  HabitModel({
    this.id,
    required this.name,
    required this.frequency,
    this.streak = 0,
    this.lastCompleted,
  });

  HabitModel copyWith({
    int? id,
    String? name,
    String? frequency,
    int? streak,
    DateTime? lastCompleted,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      streak: streak ?? this.streak,
      lastCompleted: lastCompleted ?? this.lastCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'streak': streak,
      'lastCompleted': lastCompleted?.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      frequency: map['frequency'] as String,
      streak: map['streak'] as int,
      lastCompleted: map['lastCompleted'] != null
          ? DateTime.parse(map['lastCompleted'] as String)
          : null,
    );
  }

  bool get isCompletedToday {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    return lastCompleted!.year == now.year &&
        lastCompleted!.month == now.month &&
        lastCompleted!.day == now.day;
  }
}
