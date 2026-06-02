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
    bool clearLastCompleted = false,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      streak: streak ?? this.streak,
      lastCompleted: clearLastCompleted
          ? null
          : lastCompleted ?? this.lastCompleted,
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
