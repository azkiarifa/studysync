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
<<<<<<< HEAD
    String? frequency,
    int? streak,
    DateTime? lastCompleted,
    bool clearLastCompleted = false,
=======
    int? color,
    int? targetDaysPerWeek,
    DateTime? createdAt,
>>>>>>> 0adf14d3e21ec2ab8c2d5bc896a36b1a7417d553
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
<<<<<<< HEAD
      frequency: frequency ?? this.frequency,
      streak: streak ?? this.streak,
      lastCompleted: clearLastCompleted
          ? null
          : lastCompleted ?? this.lastCompleted,
=======
      color: color ?? this.color,
      targetDaysPerWeek: targetDaysPerWeek ?? this.targetDaysPerWeek,
      createdAt: createdAt ?? this.createdAt,
>>>>>>> 0adf14d3e21ec2ab8c2d5bc896a36b1a7417d553
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

  bool get isCompletedThisWeek {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    return _startOfWeek(lastCompleted!).isAtSameMomentAs(_startOfWeek(now));
  }

  bool get isCompletedForCurrentPeriod {
    if (frequency == 'Weekly') return isCompletedThisWeek;
    return isCompletedToday;
  }

  bool get wasCompletedInPreviousPeriod {
    if (lastCompleted == null) return false;
    final now = DateTime.now();

    if (frequency == 'Weekly') {
      final currentWeek = _startOfWeek(now);
      final previousWeek = currentWeek.subtract(const Duration(days: 7));
      return _startOfWeek(lastCompleted!).isAtSameMomentAs(previousWeek);
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final completedDay = DateTime(
      lastCompleted!.year,
      lastCompleted!.month,
      lastCompleted!.day,
    );
    return completedDay.isAtSameMomentAs(yesterday);
  }

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
