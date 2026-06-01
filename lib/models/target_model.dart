class TargetModel {
  final int? id;
  final String courseName;
  final String targetGrade; // e.g. 'A', 'B', 'C'
  final double targetScore; // e.g. 85.0
  final double currentScore; // e.g. 75.0
  final String notes;

  TargetModel({
    this.id,
    required this.courseName,
    required this.targetGrade,
    required this.targetScore,
    required this.currentScore,
    required this.notes,
  });

  TargetModel copyWith({
    int? id,
    String? courseName,
    String? targetGrade,
    double? targetScore,
    double? currentScore,
    String? notes,
  }) {
    return TargetModel(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      targetGrade: targetGrade ?? this.targetGrade,
      targetScore: targetScore ?? this.targetScore,
      currentScore: currentScore ?? this.currentScore,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseName': courseName,
      'targetGrade': targetGrade,
      'targetScore': targetScore,
      'currentScore': currentScore,
      'notes': notes,
    };
  }

  factory TargetModel.fromMap(Map<String, dynamic> map) {
    return TargetModel(
      id: map['id'] as int?,
      courseName: map['courseName'] as String,
      targetGrade: map['targetGrade'] as String,
      targetScore: (map['targetScore'] as num).toDouble(),
      currentScore: (map['currentScore'] as num).toDouble(),
      notes: map['notes'] as String,
    );
  }
}
