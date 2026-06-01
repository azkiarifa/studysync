class ScheduleModel {
  final int? id;
  final String title;
  final String location;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int color; // Hex color value representation
  final String lecturer;

  ScheduleModel({
    this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.lecturer,
  });

  ScheduleModel copyWith({
    int? id,
    String? title,
    String? location,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? color,
    String? lecturer,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      lecturer: lecturer ?? this.lecturer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'lecturer': lecturer,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      location: map['location'] as String,
      date: DateTime.parse(map['date'] as String),
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      color: map['color'] as int,
      lecturer: map['lecturer'] as String,
    );
  }
}
