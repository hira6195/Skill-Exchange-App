import 'dart:convert';
import 'dart:math';
import '../models/assessment_result.dart';
import '../models/quiz_question.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';

class AssessmentService {
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _firestoreService = FirestoreService();

  static const double _passingThreshold = 70.0;

  Future<AssessmentQuizData> generateAssessmentQuiz(String skillName) async {
    final int seed = DateTime.now().microsecondsSinceEpoch;
    final int questionCount = Random().nextInt(3) + 6; // 6 to 8 questions

    final String prompt = '''
You are a Senior Technical Examiner crafting an assessment exam for "$skillName".
Randomization Seed: $seed.
Generate $questionCount HIGH-QUALITY, DIVERSE, REAL-WORLD questions.

STRICT GENERATION RULES:
1. QUESTION COUNT: Exactly $questionCount questions.
2. MIX OF TYPES: Ensure a balanced mix of "mcq", "scenario", "short", and "coding".
3. UNIQUE OPTIONS: For "mcq" and "scenario" types, every option in the "options" array MUST BE ENTIRELY UNIQUE and non-repeating. Never provide identical options!
4. CODING QUESTIONS: If "$skillName" involves programming, software, or tech, include at least 1-2 "coding" questions. Always provide a clear "codeSnippet" (code block string) showing code syntax, bugs, or logic.
5. FOR "short" TYPE: "options" MUST be empty [] and "correctOptionIndex" MUST be -1. Provide a clear "correctAnswer" model answer.
6. EXPLANATION: Max 15 words.
7. Return ONLY raw valid JSON (no markdown formatting, no ```json tags).

JSON Schema:
{
  "difficulty": "Adaptive",
  "questionTypeStats": {"mcq": 2, "scenario": 2, "short": 1, "coding": 2},
  "totalTime": 900,
  "totalQuestions": $questionCount,
  "estimatedTimeMinutes": 15,
  "passingScorePercentage": 70,
  "questions": [
    {
      "id": "q_${seed}_1",
      "type": "coding",
      "difficulty": "Hard",
      "topic": "Syntax & Logic",
      "timeInSeconds": 60,
      "question": "What is the output or error in the following code snippet?",
      "codeSnippet": "void main() {\\n  var list = [1, 2, 3];\\n  print(list[5]);\\n}",
      "options": ["RangeError (Index out of range)", "Prints null", "Prints 5", "Compilation Error"],
      "correctOptionIndex": 0,
      "correctAnswer": "RangeError (Index out of range)",
      "explanation": "Accessing index 5 on a 3-element array throws a RangeError."
    }
  ]
}
''';

    try {
      final String rawJson = await _geminiService.generateText(prompt).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('AI quiz generation timed out'),
      );

      String cleanJson = rawJson.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.replaceAll('```json', '').replaceAll('```', '').trim();
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll('```', '').trim();
      }

      final Map<String, dynamic> decoded = jsonDecode(cleanJson);
      return AssessmentQuizData.fromJson(decoded);
    } catch (e) {
      return await _geminiService.generateDynamicQuiz(
        skill: skillName,
        targetQuestionCount: min(questionCount, 6),
      );
    }
  }

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
      "conceptual": {"correct": 0, "total": 0},
      "short": {"correct": 0, "total": 0},
      "coding": {"correct": 0, "total": 0},
    };

    for (var q in questions) {
      String difficulty = (q['difficulty'] ?? 'Easy').toString().toLowerCase();
      String type = (q['type'] ?? 'mcq').toString().toLowerCase();

      int? selectedIndex = q['selectedOptionIndex'] as int?;
      int correctIndex = q['correctOptionIndex'] as int? ?? -1;

      String userText =
      (q['selectedOptionText'] ?? q['shortAnswerText'] ?? "").toString().trim().toLowerCase();
      String correctText =
      (q['correctAnswerText'] ?? q['correctAnswer'] ?? "").toString().trim().toLowerCase();

      bool isCorrect = false;

      if (type == 'short') {
        // Fair evaluation for written answers: match key words or meaningful response length
        if (userText.length >= 10) {
          List<String> correctKeywords = correctText.split(' ').where((w) => w.length > 3).toList();
          int matchedCount = correctKeywords.where((kw) => userText.contains(kw)).length;
          if (correctKeywords.isEmpty || matchedCount > 0 || userText.length > 25) {
            isCorrect = true;
          }
        }
      } else {
        if (selectedIndex != null && correctIndex >= 0 && selectedIndex == correctIndex) {
          isCorrect = true;
        } else if (userText.isNotEmpty && correctText.isNotEmpty && userText == correctText) {
          isCorrect = true;
        }
      }

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
You are an expert AI Technical Auditor evaluating a candidate for "$skillName".

SCORE OVERVIEW:
- Total Percentage: ${scorePercentage.toStringAsFixed(1)}\% - Status:${isPassed ? "PASSED" : "FAILED"}
PERFORMANCE BREAKDOWN: ${jsonEncode(performanceBreakdown)}

Return ONLY raw JSON object:
{
  "skillLevel": "Beginner | Intermediate | Expert",
  "feedback": "Concise technical feedback regarding overall evaluation (max 2 sentences)."
}
''';

    try {
      final String aiRawResponse = await _geminiService.generateText(prompt).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('AI feedback timed out'),
      );

      String cleanJson = aiRawResponse.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.replaceAll('```json', '').replaceAll('```', '').trim();
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll('```', '').trim();
      }

      return jsonDecode(cleanJson);
    } catch (e) {
      return {
        'skillLevel': _determineFallbackLevel(scorePercentage),
        'feedback': 'Assessment completed successfully for $skillName.',
      };
    }
  }

  String _determineFallbackLevel(double percentage) {
    if (percentage >= 80.0) return "Expert";
    if (percentage >= 70.0) return "Intermediate";
    return "Beginner";
  }
}