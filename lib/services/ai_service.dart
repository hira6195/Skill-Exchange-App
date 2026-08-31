import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:skill_exchange/api_key.dart';

class AIService {
  static final GenerativeModel _fastModel = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: ApiKey.geminiApiKey,
    generationConfig: GenerationConfig(
      temperature: 0.4,
      maxOutputTokens: 2048,
      responseMimeType: 'application/json',
    ),
  );

  static final GenerativeModel _textModel = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: ApiKey.geminiApiKey,
    generationConfig: GenerationConfig(
      temperature: 0.7,
      maxOutputTokens: 1500,
    ),
  );

  /// 1. ULTRA-FAST UNIQUE ASSESSMENT GENERATOR
  static Future<List<Map<String, dynamic>>> generateAssessmentQuestions({
    required String skill,
    required String userLevel,
  }) async {
    final int seed = DateTime.now().millisecondsSinceEpoch;
    final prompt = '''
    Generate a highly diverse, unique skill assessment test for skill "$skill" (User Level: $userLevel).
    Randomization Seed: $seed.
    
    STRICT REQUIREMENTS:
    - Absolutely NO duplicate or similar questions.
    - Provide exactly 10 items in this exact distribution:
      * 4 MCQs (1 Easy, 2 Medium, 1 Hard)
      * 3 Short Answer Technical Questions
      * 3 Real-World Scenario-based Problem Solving Questions
    
    RETURN ONLY A VALID JSON ARRAY with this exact structure for each item:
    [
      {
        "id": 1,
        "type": "mcq", // "mcq", "short", or "scenario"
        "difficulty": "Medium",
        "question": "Clear distinct question string",
        "options": ["Option A", "Option B", "Option C", "Option D"], // null if type is short or scenario
        "correctAnswer": "Option A or model answer key"
      }
    ]
    ''';

    try {
      final response = await _fastModel.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        final List<dynamic> parsed = jsonDecode(response.text!);
        return List<Map<String, dynamic>>.from(parsed);
      }
    } catch (e) {
      debugPrint("Error generating assessment: $e");
    }
    return [];
  }

  /// 2. LIGHTWEIGHT AI MATCHMAKING ENGINE
  static Future<List<Map<String, dynamic>>> getSkillMatches({
    required Map<String, dynamic> currentUser,
    required List<Map<String, dynamic>> targetCandidates,
  }) async {
    if (targetCandidates.isEmpty) return [];

    final prompt = '''
    Target User: ${jsonEncode(currentUser)}
    Candidate Pool: ${jsonEncode(targetCandidates)}
    
    Analyze mutual exchange value (User A teaches what User B wants to learn, and User B teaches what User A wants to learn).
    
    RETURN ONLY A VALID JSON ARRAY of top matches:
    [
      {
        "candidateUid": "uid_here",
        "matchPercentage": 95,
        "reason": "Clear 1-sentence explanation why this skill swap is mutually beneficial."
      }
    ]
    ''';

    try {
      final response = await _fastModel.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        final List<dynamic> parsed = jsonDecode(response.text!);
        return List<Map<String, dynamic>>.from(parsed);
      }
    } catch (e) {
      debugPrint("Error generating matches: $e");
    }
    return [];
  }

  /// 3. INSTANT AI ROADMAP & CONCEPT EXPLORER
  static Future<Map<String, dynamic>> generateSkillRoadmap(String skill) async {
    final prompt = '''
    Create a step-by-step masterclass roadmap for learning: "$skill".
    
    RETURN ONLY VALID JSON:
    {
      "skill": "$skill",
      "estimatedDuration": "4 Weeks",
      "modules": [
        {
          "phase": "Phase 1: Foundations",
          "topics": ["Topic A", "Topic B"],
          "miniProject": "Build a small demo"
        }
      ]
    }
    ''';

    try {
      final response = await _fastModel.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        return Map<String, dynamic>.from(jsonDecode(response.text!));
      }
    } catch (e) {
      debugPrint("Error generating roadmap: $e");
    }
    return {};
  }
}