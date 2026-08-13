/// Legacy Quiz Question Model
class QuizQuestion {
  final String id;
  final String type;
  final String difficulty;
  final String topic;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.topic,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = List<String>.from(json['options'] ?? []);

    // Extract raw index with fallback keys
    int rawIndex = (json['correctOptionIndex'] ??
        json['correct_option_index'] ??
        0) as int;

    // Safe Index Normalization: Convert 1-based index (1, 2, 3, 4) to 0-based index
    if (parsedOptions.isNotEmpty) {
      if (rawIndex >= parsedOptions.length && rawIndex > 0) {
        rawIndex = rawIndex - 1;
      }
      // Out of bounds safety guard
      if (rawIndex < 0 || rawIndex >= parsedOptions.length) {
        rawIndex = 0;
      }
    } else {
      rawIndex = 0;
    }

    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'MCQ',
      difficulty: json['difficulty']?.toString() ?? 'Medium',
      topic: json['topic']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: parsedOptions,
      correctOptionIndex: rawIndex,
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'difficulty': difficulty,
      'topic': topic,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }
}

/// Unified Question Data model used by Quiz Assessment screens
class QuestionData {
  final String id;
  final String type;
  final String difficulty;
  final String topic;
  final int timeInSeconds;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String correctAnswer;
  final String explanation;

  QuestionData({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.topic,
    required this.timeInSeconds,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = List<String>.from(json['options'] ?? []);

    // Extract raw index with fallback keys
    int rawIndex = (json['correctOptionIndex'] ??
        json['correct_option_index'] ??
        0) as int;

    // Safe Index Normalization
    if (parsedOptions.isNotEmpty) {
      if (rawIndex >= parsedOptions.length && rawIndex > 0) {
        rawIndex = rawIndex - 1;
      }
      if (rawIndex < 0 || rawIndex >= parsedOptions.length) {
        rawIndex = 0;
      }
    } else {
      rawIndex = -1;
    }

    String answerText = json['correctAnswer']?.toString() ?? '';
    if (answerText.isEmpty &&
        rawIndex >= 0 &&
        rawIndex < parsedOptions.length) {
      answerText = parsedOptions[rawIndex];
    }

    return QuestionData(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'MCQ',
      difficulty: json['difficulty']?.toString() ?? 'Medium',
      topic: json['topic']?.toString() ?? '',
      timeInSeconds:
      (json['timeInSeconds'] ?? json['time_in_seconds'] ?? 60) as int,
      question: json['question']?.toString() ?? '',
      options: parsedOptions,
      correctOptionIndex: rawIndex,
      correctAnswer: answerText,
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'difficulty': difficulty,
      'topic': topic,
      'timeInSeconds': timeInSeconds,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }
}

/// Complete Assessment Quiz Data Model
class AssessmentQuizData {
  final String difficulty;
  final Map<String, int> questionTypeStats;
  final int totalTime;
  final int totalQuestions;
  final int estimatedTimeMinutes;
  final int passingScorePercentage;
  final List<QuestionData> questions;

  AssessmentQuizData({
    required this.difficulty,
    required this.questionTypeStats,
    required this.totalTime,
    required this.totalQuestions,
    required this.estimatedTimeMinutes,
    required this.passingScorePercentage,
    required this.questions,
  });

  factory AssessmentQuizData.fromJson(Map<String, dynamic> json) {
    return AssessmentQuizData(
      difficulty: json['difficulty']?.toString() ?? 'Adaptive',
      questionTypeStats: Map<String, int>.from(
        (json['questionTypeStats'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
        ) ??
            {},
      ),
      totalTime: json['totalTime'] as int? ?? 600,
      totalQuestions: json['totalQuestions'] as int? ?? 10,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int? ?? 10,
      passingScorePercentage: json['passingScorePercentage'] as int? ?? 75,
      questions: (json['questions'] as List?)
          ?.map((q) =>
          QuestionData.fromJson(Map<String, dynamic>.from(q as Map)))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'difficulty': difficulty,
      'questionTypeStats': questionTypeStats,
      'totalTime': totalTime,
      'totalQuestions': totalQuestions,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'passingScorePercentage': passingScorePercentage,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}