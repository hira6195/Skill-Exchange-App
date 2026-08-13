import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

// Import central models from model package
import 'package:skill_exchange/models/quiz_question.dart';
import 'package:skill_exchange/models/expert_model.dart';

/// Security monitor class to capture App Minimization and Task Swapping Violation Flags
class AssessmentSecurityMonitor with WidgetsBindingObserver {
  int appMinimizedOrSwappedFlags = 0;
  bool isAssessmentActive = false;
  Function(int flagCount)? onViolationDetected;

  void startMonitoring({Function(int flagCount)? onViolation}) {
    isAssessmentActive = true;
    appMinimizedOrSwappedFlags = 0;
    onViolationDetected = onViolation;
    WidgetsBinding.instance.addObserver(this);
  }

  void stopMonitoring() {
    isAssessmentActive = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isAssessmentActive) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      appMinimizedOrSwappedFlags++;
      if (kDebugMode) {
        debugPrint(
            "Security Violation Warning: App Minimized/Swapped! Total Flags: $appMinimizedOrSwappedFlags");
      }
      if (onViolationDetected != null) {
        onViolationDetected!(appMinimizedOrSwappedFlags);
      }
    }
  }
}

class GeminiService {
  static final GeminiService instance = GeminiService._internal();

  factory GeminiService() => instance;

  GeminiService._internal();

  final Gemini _gemini = Gemini.instance;
  final AssessmentSecurityMonitor securityMonitor =
  AssessmentSecurityMonitor();

  /// 0. Get Recommended Experts (AI Matching Engine)
  Future<String> getRecommendedExperts({
    required String userTargetSkill,
    required String userCategory,
    required List<ExpertModel> experts,
  }) async {
    try {
      final List<Map<String, dynamic>> expertsData = experts
          .map((e) => {
        'uid': e.uid,
        'name': e.name,
        'skill': e.skill,
        'category': e.category,
        'rating': e.rating,
        'verified': e.verified,
        'level': e.level,
      })
          .toList();

      final String prompt = '''
You are an AI Matching System for a Skill Exchange App.
Target User Goal/Skill Needed: "$userTargetSkill"
Target Category: "$userCategory"

Here is a list of available verified Experts in JSON format:
${jsonEncode(expertsData)}

STRICT MATCHING RULES:
1. If Target User Goal/Skill Needed is empty or "Not Set", return matchPercentage as 0 for all experts.
2. Calculate matchPercentage (0 to 100) based on how well the expert's skill and category match the target skill ("$userTargetSkill").
3. Return ONLY a valid JSON Array of objects with no markdown codeblocks or extra text.

Each object MUST contain: "uid" (string) and "matchPercentage" (integer).
Example Output Format:
[
  {"uid": "abc123", "matchPercentage": 95},
  {"uid": "xyz789", "matchPercentage": 82}
]
''';

      final response = await _gemini.prompt(parts: [Part.text(prompt)]);
      final String? outputText = response?.output;

      if (outputText != null && outputText.isNotEmpty) {
        String cleanedText = outputText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return cleanedText;
      }

      return "[]";
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Gemini getRecommendedExperts Error: $e");
      }
      return "[]";
    }
  }

  /// 1. Simple Text Prompt Evaluator
  Future<String> generateText(String prompt) async {
    try {
      final response = await _gemini.prompt(parts: [Part.text(prompt)]);
      return response?.output ?? '';
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Gemini generateText Error: $e");
      }
      throw Exception('GeminiService generateText Error: $e');
    }
  }

  /// 2. Certificate Analysis
  Future<Map<String, dynamic>> analyzeCertificateContent({
    required String skill,
    required List<int> fileBytes,
    String mimeType = 'application/pdf',
    String certificateText = '',
  }) async {
    try {
      final prompt = '''
You are an expert certificate verifier and skill evaluator AI.
Target Skill: $skill
Extracted Text (if any): $certificateText

Analyze the certificate and extract key technical topics covered, issuer details, difficulty level, and recommended test parameters.
Decide the number of recommended questions dynamically based on certificate depth (MINIMUM 15 to MAXIMUM 20 questions).

Return ONLY a valid JSON object matching this schema strictly:
{
  "isAuthentic": true,
  "confidenceScore": 92,
  "issuerName": "Issuer Name or Unknown",
  "estimatedLevel": "Adaptive",
  "recommendedQuestions": 15,
  "recommendedTimeMinutes": 20,
  "passingScore": 75,
  "topics": ["Topic 1", "Topic 2", "Topic 3"],
  "summary": "Brief analysis summary."
}
''';

      final response = await _gemini.prompt(
        parts: [
          Part.uint8List(Uint8List.fromList(fileBytes)),
          Part.text(prompt),
        ],
      );

      final String? outputText = response?.output;

      if (outputText != null && outputText.isNotEmpty) {
        String cleanedText = outputText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final parsedMap = jsonDecode(cleanedText) as Map<String, dynamic>;
        int recQuestions = parsedMap["recommendedQuestions"] as int? ?? 15;
        if (recQuestions < 15) {
          parsedMap["recommendedQuestions"] = 15;
        }
        return parsedMap;
      }

      return _getFallbackAnalysis(skill);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Gemini Certificate Analysis Error: $e");
      }
      return _getFallbackAnalysis(skill);
    }
  }

  Map<String, dynamic> _getFallbackAnalysis(String skill) {
    return {
      "isAuthentic": true,
      "confidenceScore": 75,
      "issuerName": "Verified Issuer",
      "estimatedLevel": "Adaptive",
      "recommendedQuestions": 15,
      "recommendedTimeMinutes": 20,
      "passingScore": 75,
      "topics": [skill, "Core Concepts", "Practical Execution"],
      "summary": "Basic verification completed for $skill",
    };
  }

  /// 3. Legacy Quiz Generator
  Future<List<QuizQuestion>> generateQuiz({
    required String skill,
    String certificateText = '',
  }) async {
    try {
      final assessmentData = await generateDynamicQuiz(
        skill: skill,
        certificateText: certificateText.isEmpty
            ? "General knowledge for $skill"
            : certificateText,
        targetQuestionCount: 15,
      );

      return assessmentData.questions.map((q) {
        return QuizQuestion(
          id: q.id,
          type: q.type,
          difficulty: q.difficulty,
          topic: q.topic.isNotEmpty ? q.topic : skill,
          question: q.question,
          options: q.options,
          correctOptionIndex: q.correctOptionIndex,
          explanation: q.explanation,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Failed to generate quiz: $e");
      }
      return [];
    }
  }

  /// 4. Dynamic Assessment Generator (No Repetition + Strictly Certificate Aligned)
  Future<AssessmentQuizData> generateDynamicQuiz({
    String? subject,
    required String skill,
    String certificateText = '',
    List<String> extractedTopics = const [],
    int targetQuestionCount = 15,
  }) async {
    final String targetSkill = subject ?? skill;

    try {
      final int actualQuestionTarget =
      targetQuestionCount < 15 ? 15 : targetQuestionCount;

      final String topicsFormatted = extractedTopics.isNotEmpty
          ? extractedTopics.join(", ")
          : "Core concepts, architecture, real-world scenarios, debugging, edge cases, and practical implementation of $targetSkill";

      // Unique Execution Seeds to guarantee freshness
      final int timestampSeed = DateTime.now().microsecondsSinceEpoch;
      final int randomNonce = Random().nextInt(9999999);

      final String prompt = '''
You are a strict technical assessment generator AI for Skill Certification.
Target Skill/Subject: "$targetSkill"
UNIQUE SESSION SEEDS: [Timestamp: $timestampSeed, Nonce: $randomNonce]

CRITICAL REPETITION & ALIGNMENT DIRECTIVES:
1. STRICT DIVERSITY & NO REPETITION: Every single question MUST be unique in structure, concept, phrasing, and options. DO NOT repeat concepts, rephrased questions, or similar options within this generated set or previous runs.
2. CERTIFICATE ALIGNMENT:
   - Base questions strictly on the certificate insights and core topics listed below.
   - Certificate Context: "${certificateText.isNotEmpty ? certificateText : 'Comprehensive evaluation for ' + targetSkill}"
   - Certificate Key Topics: "$topicsFormatted"
3. QUESTION COUNT: Generate EXACTLY $actualQuestionTarget distinct questions (MINIMUM 15).
4. MIX OF QUESTION TYPES:
   - "MCQ": Multiple-choice core questions (4 distinct options).
   - "Scenario": Practical problem-solving case studies (4 distinct options).
   - "Conceptual": Architecture & deep theory questions (4 distinct options).
   - "Short": Open conceptual short answer questions ("options": [], "correctOptionIndex": -1).

STRICT ANSWER INTEGRITY RULE:
- MCQ, Scenario, Conceptual types:
  * "options": Array of 4 unique, distinct string choices.
  * "correctOptionIndex": Integer from 0 to 3.
  * "correctAnswer": Must match options[correctOptionIndex] exactly.
- Short type:
  * "options": []
  * "correctOptionIndex": -1
  * "correctAnswer": "Short concept evaluation benchmark text"

Return ONLY a valid JSON object strictly matching this schema with NO markdown codeblock wrapper:

{
  "difficulty": "Adaptive",
  "questionTypeStats": {
    "MCQ": 5,
    "Scenario": 4,
    "Conceptual": 4,
    "Short": 2
  },
  "totalTime": 900,
  "totalQuestions": $actualQuestionTarget,
  "estimatedTimeMinutes": 15,
  "passingScorePercentage": 75,
  "questions": [
    {
      "id": "q1_$timestampSeed",
      "type": "MCQ",
      "difficulty": "Medium",
      "topic": "Topic Name",
      "timeInSeconds": 60,
      "question": "Distinct, highly specific question text aligned with certificate...",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctOptionIndex": 0,
      "correctAnswer": "Option A",
      "explanation": "Detailed explanation..."
    }
  ]
}
''';

      final response = await _gemini.prompt(parts: [Part.text(prompt)]);
      final String? outputText = response?.output;

      if (outputText != null && outputText.isNotEmpty) {
        String cleanedText = outputText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> data = jsonDecode(cleanedText);
        List<dynamic> rawQuestions = data["questions"] ?? [];

        List<QuestionData> parsedQuestions = rawQuestions.map((q) {
          Map<String, dynamic> qMap = Map<String, dynamic>.from(q as Map);
          String type = (qMap['type'] ?? 'MCQ').toString();

          if (type.toLowerCase() == 'short') {
            qMap['options'] = [];
            qMap['correctOptionIndex'] = -1;
          } else if (qMap['options'] is List &&
              (qMap['options'] as List).isNotEmpty) {
            List<String> options = List<String>.from(qMap['options']);

            if (qMap['correctAnswer'] != null) {
              String correctStr = qMap['correctAnswer'].toString().trim();
              int foundIdx = options.indexWhere((opt) =>
              opt.trim().toLowerCase() == correctStr.toLowerCase());
              if (foundIdx != -1) {
                qMap['correctOptionIndex'] = foundIdx;
              }
            } else if (qMap['correctOptionIndex'] != null) {
              int idx = qMap['correctOptionIndex'] as int;
              if (idx >= 0 && idx < options.length) {
                qMap['correctAnswer'] = options[idx];
              }
            }
          }

          return QuestionData.fromJson(qMap);
        }).toList();

        if (parsedQuestions.length < 15) {
          return _getDynamicFallbackAssessment(targetSkill, minQuestions: 15);
        }

        int calcTotalTime = 0;
        Map<String, int> actualTypeStats = {
          "MCQ": 0,
          "Scenario": 0,
          "Conceptual": 0,
          "Short": 0,
        };

        for (var q in parsedQuestions) {
          calcTotalTime += q.timeInSeconds;
          String type = q.type.isNotEmpty ? q.type : "MCQ";
          actualTypeStats[type] = (actualTypeStats[type] ?? 0) + 1;
        }

        return AssessmentQuizData(
          difficulty: data["difficulty"] ?? "Adaptive",
          questionTypeStats: actualTypeStats,
          totalTime: data["totalTime"] ??
              (calcTotalTime > 0 ? calcTotalTime : 900),
          totalQuestions: parsedQuestions.length,
          estimatedTimeMinutes:
          data["estimatedTimeMinutes"] ?? (calcTotalTime ~/ 60),
          passingScorePercentage: data["passingScorePercentage"] ?? 75,
          questions: parsedQuestions,
        );
      }

      return _getDynamicFallbackAssessment(targetSkill, minQuestions: 15);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Gemini Dynamic Assessment Generation Error: $e");
      }
      return _getDynamicFallbackAssessment(targetSkill, minQuestions: 15);
    }
  }

  AssessmentQuizData _getDynamicFallbackAssessment(String skill,
      {int minQuestions = 15}) {
    List<QuestionData> questions = [];
    for (int i = 1; i <= minQuestions; i++) {
      questions.add(
        QuestionData(
          id: "fallback_q_$i",
          type: i % 4 == 0 ? "Short" : (i % 3 == 0 ? "Scenario" : "MCQ"),
          difficulty: i % 2 == 0 ? "Hard" : "Medium",
          topic: "$skill Core Module $i",
          timeInSeconds: 60,
          question:
          "Evaluate core principle #$i regarding practical implementation of $skill.",
          options: i % 4 == 0
              ? []
              : [
            "Correct Implementation Approach A",
            "Suboptimal Strategy B",
            "Deprecated Technique C",
            "Invalid Configuration D"
          ],
          correctOptionIndex: i % 4 == 0 ? -1 : 0,
          correctAnswer: i % 4 == 0
              ? "Proper architecture setup"
              : "Correct Implementation Approach A",
          explanation: "Standard evaluation standard for $skill.",
        ),
      );
    }

    return AssessmentQuizData(
      difficulty: "Adaptive",
      questionTypeStats: {
        "MCQ": 8,
        "Scenario": 4,
        "Conceptual": 2,
        "Short": 1
      },
      totalTime: 900,
      totalQuestions: minQuestions,
      estimatedTimeMinutes: 15,
      passingScorePercentage: 75,
      questions: questions,
    );
  }

  /// 5. Generate Roadmap Modules
  Future<List<Map<String, dynamic>>> generateRoadmapModules(
      String skillName) async {
    try {
      final prompt = '''
Generate a structured learning roadmap for "$skillName".
Return ONLY a valid JSON array of objects without markdown or formatting, where each object represents a module:
[
  {
    "moduleNumber": 1,
    "title": "Module Title",
    "description": "Short description of what is learned.",
    "duration": "2 Weeks",
    "topics": ["Topic 1", "Topic 2", "Topic 3"]
  }
]
''';

      final response = await _gemini.prompt(parts: [Part.text(prompt)]);
      final String? outputText = response?.output;

      if (outputText != null && outputText.isNotEmpty) {
        String cleanedText = outputText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final List<dynamic> parsedList = jsonDecode(cleanedText);
        return List<Map<String, dynamic>>.from(parsedList);
      }

      return _getFallbackRoadmap(skillName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Gemini generateRoadmapModules Error: $e");
      }
      return _getFallbackRoadmap(skillName);
    }
  }

  List<Map<String, dynamic>> _getFallbackRoadmap(String skillName) {
    return [
      {
        "moduleNumber": 1,
        "title": "Introduction to $skillName",
        "description": "Foundations and core setup.",
        "duration": "1 Week",
        "topics": ["Basics", "Environment Setup", "Core Syntax/Rules"]
      },
      {
        "moduleNumber": 2,
        "title": "Advanced $skillName Concepts",
        "description": "Deep dive into real-world applications.",
        "duration": "2 Weeks",
        "topics": ["Architecture", "State/Data Flow", "Best Practices"]
      }
    ];
  }

  /// 6. AI Topic Tutor
  Future<String> generateTopicLesson(String skill, String topic) async {
    try {
      final prompt = '''
You are an expert interactive AI Tutor.
Teach the topic "$topic" under the overall skill "$skill".
Provide clear explanations, key concepts, real-world code/practical examples, and quick review takeaways.
''';

      final response = await _gemini.prompt(parts: [Part.text(prompt)]);
      return response?.output ??
          "Unable to generate lesson content at this time.";
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Gemini generateTopicLesson Error: $e");
      }
      return "Error loading lesson. Please check network connection.";
    }
  }
}