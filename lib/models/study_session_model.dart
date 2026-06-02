class StudySessionModel {
  final int? id;
  final int? taskId;
  final String subject;
  final DateTime date;
  final int durationSeconds; // Saved as elapsed seconds
  final String notes;

  StudySessionModel({
    this.id,
    this.taskId,
    required this.subject,
    required this.date,
    required this.durationSeconds,
    required this.notes,
  });

  StudySessionModel copyWith({
    int? id,
    int? taskId,
    String? subject,
    DateTime? date,
    int? durationSeconds,
    String? notes,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'subject': subject,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'notes': notes,
    };
  }

  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: map['id'] as int?,
      taskId: map['taskId'] as int?,
      subject: map['subject'] as String,
      date: DateTime.parse(map['date'] as String),
      durationSeconds: map['durationSeconds'] as int,
      notes: map['notes'] as String,
    );
  }
}
