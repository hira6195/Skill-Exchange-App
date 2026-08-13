import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentResult {
  final String sessionId;
  final String userId;
  final String skillName;
  final double score;
  final double percentage;
  final int correctAnswers;
  final int wrongAnswers;
  final bool isPassed;
  final String skillLevel;
  final String feedback;
  final DateTime completedAt;
  final List<Map<String, dynamic>> userAnswers;

  AssessmentResult({
    required this.sessionId,
    required this.userId,
    required this.skillName,
    required this.score,
    required this.percentage,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.isPassed,
    required this.skillLevel,
    required this.feedback,
    required this.completedAt,
    required this.userAnswers,
  });

  /// Map representation for Firestore saving
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'skillName': skillName,
      'score': score,
      'percentage': percentage,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'isPassed': isPassed,
      'skillLevel': skillLevel,
      'feedback': feedback,
      'completedAt': Timestamp.fromDate(completedAt),
      'userAnswers': userAnswers,
    };
  }

  /// Construct object from Firestore Document Map
  factory AssessmentResult.fromMap(Map<String, dynamic> map) {
    return AssessmentResult(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      skillName: map['skillName'] ?? '',
      score: (map['score'] ?? 0).toDouble(),
      percentage: (map['percentage'] ?? 0).toDouble(),
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      isPassed: map['isPassed'] ?? false,
      skillLevel: map['skillLevel'] ?? 'Beginner',
      feedback: map['feedback'] ?? '',
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : DateTime.parse(map['completedAt'].toString()))
          : DateTime.now(),
      userAnswers: List<Map<String, dynamic>>.from(map['userAnswers'] ?? []),
    );
  }
}