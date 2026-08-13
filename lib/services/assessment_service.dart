import 'dart:convert';
import '../models/assessment_result.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';

/// AssessmentService: Advanced AI evaluation aur performance breakdown handler.
class AssessmentService {
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _firestoreService = FirestoreService();

  static const double _passingThreshold = 60.0; // Standard 60% passing mark

  Future<AssessmentResult> evaluateAssessment({
    required String sessionId,
    required String userId,
    required String skillName,
    required List<Map<String, dynamic>> questionsWithUserAnswers,
  }) async {
    try {
      await _firestoreService.saveAssessmentAnswers(
        sessionId: sessionId,
        answers: questionsWithUserAnswers,
      );

      Map<String, Map<String, int>> performanceBreakdown =
      _calculatePerformanceMetrics(questionsWithUserAnswers);

      int totalQuestions = questionsWithUserAnswers.length;
      int correctAnswersCount = performanceBreakdown["overall"]!["correct"]!;
      int wrongAnswersCount = totalQuestions - correctAnswersCount;

      double percentage = totalQuestions > 0
          ? (correctAnswersCount / totalQuestions) * 100
          : 0.0;
      bool isPassed = percentage >= _passingThreshold;

      final Map<String, dynamic> aiFeedback = await _getAIEvaluationFeedback(
        skillName: skillName,
        scorePercentage: percentage,
        isPassed: isPassed,
        questionsWithAnswers: questionsWithUserAnswers,
        performanceBreakdown: performanceBreakdown,
      );

      final result = AssessmentResult(
        sessionId: sessionId,
        userId: userId,
        skillName: skillName,
        score: percentage,
        percentage: percentage,
        correctAnswers: correctAnswersCount,
        wrongAnswers: wrongAnswersCount,
        isPassed: isPassed,
        skillLevel:
        aiFeedback['skillLevel'] ?? _determineFallbackLevel(percentage),
        feedback: aiFeedback['feedback'] ?? 'Assessment complete.',
        completedAt: DateTime.now(),
        userAnswers: questionsWithUserAnswers,
      );

      await _firestoreService.saveAssessmentResult(result);

      if (isPassed) {
        await _firestoreService.addVerifiedSkill(
          userId: userId,
          skillName: skillName,
          skillLevel: result.skillLevel,
          score: result.percentage,
          resultId: sessionId,
        );
      }

      return result;
    } catch (e) {
      throw Exception('AssessmentService Error (evaluateAssessment): $e');
    }
  }

  Map<String, Map<String, int>> _calculatePerformanceMetrics(
      List<Map<String, dynamic>> questions) {
    Map<String, Map<String, int>> stats = {
      "overall": {"correct": 0, "total": questions.length},
      "easy": {"correct": 0, "total": 0},
      "medium": {"correct": 0, "total": 0},
      "hard": {"correct": 0, "total": 0},
      "mcq": {"correct": 0, "total": 0},
      "scenario": {"correct": 0, "total": 0},
      "short": {"correct": 0, "total": 0},
      "debugging": {"correct": 0, "total": 0},
    };

    for (var q in questions) {
      String difficulty = (q['difficulty'] ?? 'Easy').toString().toLowerCase();
      String type = (q['type'] ?? 'MCQ').toString().toLowerCase();

      int? selectedIndex = q['selectedOptionIndex'] as int?;
      int correctIndex = q['correctOptionIndex'] as int? ?? -1;

      String userText =
      (q['selectedOptionText'] ?? "").toString().trim().toLowerCase();
      String correctText =
      (q['correctAnswerText'] ?? "").toString().trim().toLowerCase();

      bool isCorrect = false;

      // 1. First Priority: String Text Match (Bypasses AI 1-based/0-based index bugs)
      if (userText.isNotEmpty && correctText.isNotEmpty) {
        if (userText == correctText) {
          isCorrect = true;
        }
      }

      // 2. Second Priority: Index-based Fallbacks
      if (!isCorrect && selectedIndex != null) {
        // Direct index match
        if (selectedIndex == correctIndex) {
          isCorrect = true;
        }
        // 1-based shift match (AI raw index - 1)
        else if (selectedIndex == (correctIndex - 1)) {
          isCorrect = true;
        }
      }

      // Fallback for short answers / open text questions
      if (!isCorrect && type != 'mcq' && type != 'scenario') {
        String shortText = (q['shortAnswerText'] ?? '').toString().trim();
        if (shortText.length > 15) {
          isCorrect = true;
        }
      }

      // Record Stats
      if (isCorrect) {
        stats["overall"]!["correct"] = stats["overall"]!["correct"]! + 1;
      }

      if (stats.containsKey(difficulty)) {
        stats[difficulty]!["total"] = stats[difficulty]!["total"]! + 1;
        if (isCorrect) {
          stats[difficulty]!["correct"] = stats[difficulty]!["correct"]! + 1;
        }
      }

      if (stats.containsKey(type)) {
        stats[type]!["total"] = stats[type]!["total"]! + 1;
        if (isCorrect) {
          stats[type]!["correct"] = stats[type]!["correct"]! + 1;
        }
      }
    }

    return stats;
  }

  Future<Map<String, dynamic>> _getAIEvaluationFeedback({
    required String skillName,
    required double scorePercentage,
    required bool isPassed,
    required List<Map<String, dynamic>> questionsWithAnswers,
    required Map<String, Map<String, int>> performanceBreakdown,
  }) async {
    final String prompt = '''
You are an expert AI Technical Auditor evaluating a comprehensive candidate skill assessment for "$skillName".

SCORE OVERVIEW:
- Total Percentage: ${scorePercentage.toStringAsFixed(1)}\% - Status:${isPassed ? "PASSED" : "FAILED"}

PERFORMANCE BREAKDOWN DATA:
${jsonEncode(performanceBreakdown)}

RAW QUESTION RESPONSE LOGS:
${jsonEncode(questionsWithAnswers)}

EVALUATION CRITERIA FOR SKILL LEVEL:
- "Expert": Strong performance across Hard, Debugging, and Scenario questions (Score >= 80%).
- "Intermediate": Solid performance in Easy/Medium, moderate score in Hard/Debugging (Score >= 60% and < 80%).
- "Beginner": Lower performance across Medium/Hard questions or Failed assessment (Score < 60%).

Return ONLY a raw JSON object strictly matching this format without markdown code blocks:
{
  "skillLevel": "Beginner | Intermediate | Expert",
  "feedback": "A concise 3-sentence technical analysis highlighting performance in Easy, Medium, Hard questions and specific strengths in Debugging or Scenarios."
}
''';

    try {
      final String aiRawResponse = await _geminiService.generateText(prompt);

      String cleanJson = aiRawResponse.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson =
            cleanJson.replaceAll('```json', '').replaceAll('```', '').trim();
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll('```', '').trim();
      }

      final Map<String, dynamic> decoded = jsonDecode(cleanJson);
      return decoded;
    } catch (e) {
      return {
        'skillLevel': _determineFallbackLevel(scorePercentage),
        'feedback': isPassed
            ? 'Great performance across fundamental and complex scenarios! You have verified your skills in $skillName.'
            : 'You demonstrated foundational understanding. Practice more debugging and scenario-based tasks before retrying.',
      };
    }
  }

  String _determineFallbackLevel(double percentage) {
    if (percentage >= 80.0) return "Expert";
    if (percentage >= 60.0) return "Intermediate";
    return "Beginner";
  }
}