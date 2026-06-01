class ReminderModel {
  final int? id;
  final String title;
  final DateTime dateTime;
  final bool isCompleted;
  final String repeatType; // 'None', 'Daily', 'Weekly'

  ReminderModel({
    this.id,
    required this.title,
    required this.dateTime,
    this.isCompleted = false,
    required this.repeatType,
  });

  ReminderModel copyWith({
    int? id,
    String? title,
    DateTime? dateTime,
    bool? isCompleted,
    String? repeatType,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      repeatType: repeatType ?? this.repeatType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'repeatType': repeatType,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      isCompleted: (map['isCompleted'] as int) == 1,
      repeatType: map['repeatType'] as String,
    );
  }
}
