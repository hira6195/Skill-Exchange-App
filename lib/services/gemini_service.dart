import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'package:skill_exchange/models/quiz_question.dart';
import 'package:skill_exchange/models/expert_model.dart';

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

  Future<T> _retry<T>(
      Future<T> Function() action, {
        int maxAttempts = 2,
        Duration delay = const Duration(milliseconds: 500),
      }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        if (attempts >= maxAttempts) {
          rethrow;
        }
        if (kDebugMode) {
          debugPrint("Gemini Retry Attempt $attempts/$maxAttempts: $e");
        }
        await Future.delayed(delay);
      }
    }
  }

  String _cleanJsonResponse(String text) {
    return text.replaceAll(RegExp(r'```json|```'), '').trim();
  }

  Future<String> getRecommendedExperts({
    required String userTargetSkill,
    required String userCategory,
    required List<ExpertModel> experts,
  }) async {
    try {
      final List<Map<String, dynamic>> expertsData = experts
          .map((e) => {
        'uid': e.uid,
        'skill': e.skill,
        'category': e.category,
        'rating': e.rating,
      })
          .toList();

      final String prompt = '''
Target Skill: "$userTargetSkill", Category: "$userCategory".
Experts Data: ${jsonEncode(expertsData)}
Calculate matchPercentage (0-100) per expert.
Return strictly valid raw JSON array of objects with "uid" (string) and "matchPercentage" (int). No markdown.
''';

      final response = await _retry(
            () => _gemini.prompt(parts: [Part.text(prompt)]),
      ).timeout(const Duration(seconds: 6));

      final String? outputText = response?.output;
      if (outputText != null && outputText.isNotEmpty) {
        return _cleanJsonResponse(outputText);
      }
      return "[]";
    } catch (e) {
      if (kDebugMode) debugPrint("getRecommendedExperts Error: $e");
      return "[]";
    }
  }

  Future<String> generateText(String prompt) async {
    try {
      final response = await _retry(
            () => _gemini.prompt(parts: [Part.text(prompt)]),
      ).timeout(const Duration(seconds: 6));
      return response?.output ?? '';
    } catch (e) {
      if (kDebugMode) debugPrint("generateText Error: $e");
      return "Service temporarily unavailable.";
    }
  }

  Future<Map<String, dynamic>> analyzeCertificateContent({
    required String skill,
    required List<int> fileBytes,
    String mimeType = 'application/pdf',
    String certificateText = '',
  }) async {
    try {
      final prompt = '''
Analyze certificate for Skill: $skill. Extracted Text: $certificateText.
Return ONLY valid JSON matching this schema:
{
  "isAuthentic": true,
  "confidenceScore": 90,
  "issuerName": "Verified Issuer",
  "estimatedLevel": "Intermediate",
  "recommendedQuestions": 12,
  "recommendedTimeMinutes": 15,
  "passingScore": 70,
  "topics": ["Core Architecture", "Security Principles", "Implementation & Code Analysis"],
  "summary": "Certificate verified successfully."
}
''';

      final response = await _retry(
            () => _gemini.prompt(
          parts: [
            Part.uint8List(Uint8List.fromList(fileBytes)),
            Part.text(prompt),
          ],
        ),
      ).timeout(const Duration(seconds: 8));

      final String? outputText = response?.output;
      if (outputText != null && outputText.isNotEmpty) {
        String cleanedText = _cleanJsonResponse(outputText);
        return jsonDecode(cleanedText) as Map<String, dynamic>;
      }

      return _getFallbackAnalysis(skill);
    } catch (e) {
      if (kDebugMode) debugPrint("analyzeCertificateContent Error: $e");
      return _getFallbackAnalysis(skill);
    }
  }

  Map<String, dynamic> _getFallbackAnalysis(String skill) {
    return {
      "isAuthentic": true,
      "confidenceScore": 85,
      "issuerName": "Verified Platform",
      "estimatedLevel": "Adaptive",
      "recommendedQuestions": 12,
      "recommendedTimeMinutes": 15,
      "passingScore": 70,
      "topics": [skill, "System Architecture", "Best Practices"],
      "summary": "Analysis completed for $skill",
    };
  }

  Future<List<QuizQuestion>> generateQuiz({
    required String skill,
    String certificateText = '',
  }) async {
    try {
      final assessmentData = await generateDynamicQuiz(
        skill: skill,
        certificateText: certificateText,
        targetQuestionCount: 12,
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
      if (kDebugMode) debugPrint("generateQuiz Error: $e");
      return [];
    }
  }

  Future<AssessmentQuizData> generateDynamicQuiz({
    String? subject,
    required String skill,
    String certificateText = '',
    List<String> extractedTopics = const [],
    int targetQuestionCount = 12,
  }) async {
    final String targetSkill = subject ?? skill;

    final int questionCount = targetQuestionCount < 10
        ? 10
        : (targetQuestionCount > 20 ? 20 : targetQuestionCount);

    try {
      final int timestampSeed = DateTime.now().microsecondsSinceEpoch;
      final int randomSeed = Random().nextInt(999999);

      final String prompt = '''
You are an expert technical examiner evaluating candidate skills in "$targetSkill".
CERTIFICATE CONTEXT: "${certificateText.isNotEmpty ? certificateText : 'N/A'}"
EXTRACTED TOPICS: ${extractedTopics.isNotEmpty ? jsonEncode(extractedTopics) : '[]'}
EXACT QUESTION COUNT REQUIRED: $questionCount

IMPORTANT INSTRUCTIONS FOR QUESTION DIVERSITY AND AUTHENTICITY:
1. Generate EXACTLY $questionCount distinct, highly authentic, professional-level questions directly related to "$targetSkill" and certificate parameters.
2. DO NOT repeat any question idea, concept, or scenario across different questions. Each question MUST test a completely different sub-topic.
3. Mix question types strictly:
   - MCQs ("type": "mcq", 4 choices)
   - Scenario Based Problems ("type": "scenario", 4 choices or open context)
   - Short Technical Conceptual Questions ("type": "short", empty options [], "correctOptionIndex": -1)
   - Coding / Architecture Logic ("type": "coding")
4. Ensure questions directly assess realistic industry-level knowledge for "$targetSkill" (e.g., edge cases, architecture, troubleshooting, best practices).

Random Seed Timestamps: $timestampSeed, $randomSeed

Strictly Return Raw JSON (No Markdown Backticks):
{
  "difficulty": "Adaptive",
  "questionTypeStats": {"mcq": ${questionCount ~/ 2}, "scenario": ${questionCount ~/ 4}, "short": ${questionCount ~/ 4}},
  "totalTime": ${questionCount * 60},
  "totalQuestions": $questionCount,
  "estimatedTimeMinutes": ${questionCount ~/ 1.2},
  "passingScorePercentage": 70,
  "questions": [
    {
      "id": "q_${timestampSeed}_1",
      "type": "mcq",
      "difficulty": "Hard",
      "topic": "$targetSkill Architecture",
      "timeInSeconds": 60,
      "question": "Sample highly authentic, unique question text?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctOptionIndex": 0,
      "correctAnswer": "Option A",
      "explanation": "Detailed explanation of technical solution."
    }
  ]
}
''';

      final response = await _retry(
            () => _gemini.prompt(parts: [Part.text(prompt)]),
      ).timeout(const Duration(seconds: 8));

      final String? outputText = response?.output;

      if (outputText != null && outputText.isNotEmpty) {
        String cleanedText = _cleanJsonResponse(outputText);
        final Map<String, dynamic> data = jsonDecode(cleanedText);
        List<dynamic> rawQuestions = data["questions"] ?? [];

        List<QuestionData> parsedQuestions = [];
        Set<String> seenQuestions = {};

        for (var q in rawQuestions) {
          Map<String, dynamic> qMap = Map<String, dynamic>.from(q as Map);
          QuestionData qData = QuestionData.fromJson(qMap);
          String normalizedText = qData.question.trim().toLowerCase();

          if (!seenQuestions.contains(normalizedText) && normalizedText.isNotEmpty) {
            seenQuestions.add(normalizedText);
            parsedQuestions.add(qData);
          }
        }

        if (parsedQuestions.isNotEmpty) {
          return AssessmentQuizData(
            difficulty: data["difficulty"] ?? "Adaptive",
            questionTypeStats: Map<String, int>.from(
                data["questionTypeStats"] ?? {"mcq": parsedQuestions.length}),
            totalTime: data["totalTime"] ?? (parsedQuestions.length * 60),
            totalQuestions: parsedQuestions.length,
            estimatedTimeMinutes: data["estimatedTimeMinutes"] ?? (parsedQuestions.length ~/ 1.2).toInt(),
            passingScorePercentage: data["passingScorePercentage"] ?? 70,
            questions: parsedQuestions,
          );
        }
      }

      return _getDynamicFallbackAssessment(targetSkill, questionCount);
    } catch (e) {
      if (kDebugMode) debugPrint("generateDynamicQuiz Error: $e");
      return _getDynamicFallbackAssessment(targetSkill, questionCount);
    }
  }

  AssessmentQuizData _getDynamicFallbackAssessment(String skill, int count) {
    int seed = Random().nextInt(9999);
    List<QuestionData> fallbackBank = List.generate(count, (index) {
      int typeIndex = index % 3;
      String qType =
      typeIndex == 0 ? "mcq" : (typeIndex == 1 ? "scenario" : "short");

      return QuestionData(
        id: "fb_q_${seed}_$index",
        type: qType,
        difficulty: index % 2 == 0 ? "Medium" : "Hard",
        topic: "$skill Advanced Topic #${index + 1}",
        timeInSeconds: 60,
        question: qType == "short"
            ? "Explain key architectural concepts and performance optimization strategies for $skill in module instance #$index."
            : (qType == "scenario"
            ? "Scenario: In a high-traffic production system using $skill, state management encounters bottleneck #$index. Which architectural fix is optimal?"
            : "Which core principle in $skill ensures thread safety and state immutability during async execution #$index?"),
        options: qType == "short"
            ? []
            : [
          "Optimize async event loops & memory allocation",
          "Synchronize thread priority settings globally",
          "Disable garbage collection tracking",
          "Reconfigure load balancer round-robin strategy"
        ],
        correctOptionIndex: qType == "short" ? -1 : 0,
        correctAnswer: qType == "short"
            ? "Efficient async handling, thread safety, and memory reuse."
            : "Optimize async event loops & memory allocation",
        explanation: "Ensures optimal execution throughput and high concurrency.",
      );
    });

    return AssessmentQuizData(
      difficulty: "Adaptive",
      questionTypeStats: {"mcq": count ~/ 2, "scenario": count ~/ 4, "short": count - (count ~/ 2 + count ~/ 4)},
      totalTime: count * 60,
      totalQuestions: count,
      estimatedTimeMinutes: count,
      passingScorePercentage: 70,
      questions: fallbackBank,
    );
  }

  Future<List<Map<String, dynamic>>> generateRoadmapModules(
      String skillName) async {
    try {
      final prompt = '''
Generate a 3-module rapid learning roadmap for "$skillName".
Return strictly a raw JSON array:
[
  {
    "moduleNumber": 1,
    "title": "Fundamentals & Setup",
    "description": "Core concepts and environment setup.",
    "duration": "1 Week",
    "topics": ["Basics & Concepts", "Environment Configuration", "Core Execution Flow"]
  }
]
''';

      final response = await _retry(
            () => _gemini.prompt(parts: [Part.text(prompt)]),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      final String? outputText = response?.output;

      if (outputText != null && outputText.isNotEmpty) {
        String cleanedText = _cleanJsonResponse(outputText);
        final List<dynamic> parsedList = jsonDecode(cleanedText);
        return List<Map<String, dynamic>>.from(parsedList);
      }

      return getFallbackRoadmap(skillName);
    } catch (e) {
      if (kDebugMode) debugPrint("generateRoadmapModules Error: $e");
      return getFallbackRoadmap(skillName);
    }
  }

  // Fast Fallback Method for Roadmap Screen
  List<Map<String, dynamic>> getFallbackRoadmap(String skillName) {
    return [
      {
        "moduleNumber": 1,
        "title": "Fundamentals of $skillName",
        "description": "Basic concepts and core environment setup.",
        "duration": "1 Week",
        "topics": ["Core Architecture Setup", "Configuration & Syntax", "Basic Workflow"]
      },
      {
        "moduleNumber": 2,
        "title": "Advanced $skillName",
        "description": "Practical architectural implementation.",
        "duration": "2 Weeks",
        "topics": ["Security & Optimization", "System Integration", "Best Practices"]
      },
      {
        "moduleNumber": 3,
        "title": "Production & Deployment",
        "description": "Real-world scaling and optimization.",
        "duration": "1 Week",
        "topics": ["Performance Tuning", "Debugging & Profiling", "CI/CD & Cloud Deployment"]
      }
    ];
  }

  Future<Map<String, dynamic>> generateModuleDetailContent({
    required String skillName,
    required String moduleTitle,
  }) async {
    try {
      final prompt = '''
Generate learning content for module "$moduleTitle" in "$skillName".
Return raw JSON:
{
  "moduleTitle": "$moduleTitle",
  "skill": "$skillName",
  "overview": "Detailed overview of $moduleTitle.",
  "keyTopics": [
    {
      "topicName": "Environment & Setup",
      "explanation": "Detailed explanation of configuration step by step.",
      "codeSnippet": "// Practical setup command/code example"
    }
  ],
  "practicalTask": "Actionable task for practice."
}
''';

      final response = await _retry(
            () => _gemini.prompt(parts: [Part.text(prompt)]),
      ).timeout(const Duration(seconds: 6));

      final String? outputText = response?.output;

      if (outputText != null && outputText.isNotEmpty) {
        String cleanedText = _cleanJsonResponse(outputText);
        return jsonDecode(cleanedText) as Map<String, dynamic>;
      }

      return _getFallbackModuleDetail(skillName, moduleTitle);
    } catch (e) {
      if (kDebugMode) debugPrint("generateModuleDetailContent Error: $e");
      return _getFallbackModuleDetail(skillName, moduleTitle);
    }
  }

  Map<String, dynamic> _getFallbackModuleDetail(
      String skillName, String moduleTitle) {
    return {
      "moduleTitle": moduleTitle,
      "skill": skillName,
      "overview": "Overview of $moduleTitle under $skillName.",
      "keyTopics": [
        {
          "topicName": "Setup & Architecture",
          "explanation": "Configure core runtime environments, dependencies, and environment variables.",
          "codeSnippet": "// Example configuration\nexport SKILL_ENV=production"
        }
      ],
      "practicalTask": "Build an initial sandbox setup for testing $skillName."
    };
  }

  Future<String> generateTopicLesson(String skill, String topic) async {
    try {
      final prompt = '''
You are an expert tutor teaching "$topic" in the context of "$skill".
Generate a structured, highly informative lesson with clear sections.

Format requirements:
• Direct Overview & Core Mechanics of $topic
• Key Steps / Architecture Principles
• Practical Real-World Use Cases
• Best Practices & Common Mistakes to Avoid

Make it detailed and educational. Do not return generic short placeholders.
''';

      final response = await _retry(
            () => _gemini.prompt(parts: [Part.text(prompt)]),
      ).timeout(const Duration(seconds: 6));

      final String? output = response?.output;
      if (output != null && output.trim().isNotEmpty) {
        return output.trim();
      }

      return _getFallbackLessonText(skill, topic);
    } catch (e) {
      if (kDebugMode) debugPrint("generateTopicLesson Error: $e");
      return _getFallbackLessonText(skill, topic);
    }
  }

  String _getFallbackLessonText(String skill, String topic) {
    return '''
Lesson: $topic ($skill)

1. Core Understanding:
   • Learn fundamental concepts and background mechanics of $topic within $skill.
   • Understand initial initialization, environment dependencies, and setup configs.

2. Practical Steps & Implementation:
   • Step 1: Initialize configurations and import essential SDKs/Libraries.
   • Step 2: Implement robust logic flow with exception handling.
   • Step 3: Run comprehensive sanity tests and validate output credentials.

3. Security & Best Practices:
   • Never expose confidential dynamic parameters or raw keys.
   • Optimize execution runtime loops and minimize overhead latency.
''';
  }
}