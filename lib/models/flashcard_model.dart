class FlashcardModel {
  final int? id;
  final int deckId;
  final String question;
  final String answer;
  final bool isLearned;

  FlashcardModel({
    this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    this.isLearned = false,
  });

  FlashcardModel copyWith({
    int? id,
    int? deckId,
    String? question,
    String? answer,
    bool? isLearned,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      isLearned: isLearned ?? this.isLearned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'isLearned': isLearned ? 1 : 0,
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as int?,
      deckId: map['deckId'] as int,
      question: map['question'] as String,
      answer: map['answer'] as String,
      isLearned: (map['isLearned'] as int) == 1,
    );
  }
}
