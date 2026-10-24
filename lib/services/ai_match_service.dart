import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:skill_exchange/models/expert_model.dart';
import 'package:skill_exchange/services/firestore_service.dart';
import 'package:skill_exchange/services/gemini_service.dart';

class AIMatchService {
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService.instance;

  Future<List<ExpertModel>> fetchAndMatchExperts({
    required String userTargetSkill,
    required String userCategory,
    String? userCanTeachSkill,
  }) async {
    try {
      if (userTargetSkill.trim().isEmpty && (userCanTeachSkill == null || userCanTeachSkill.trim().isEmpty)) {
        return [];
      }

      // Step 1: Fetch experts
      List<ExpertModel> rawExperts = await _firestoreService.getExperts();
      if (rawExperts.isEmpty) return [];

      // Step 2: Safe Pre-filtering (Fixing null errors for skills)
      final targetLower = userTargetSkill.toLowerCase().trim();
      final categoryLower = userCategory.toLowerCase().trim();

      List<ExpertModel> candidateExperts = rawExperts.where((expert) {
        final categoryMatch = expert.category.toLowerCase().contains(categoryLower);

        // FIX 1: Safely handle nullable skills list using ?.any()
        final skillMatch = expert.skills?.any((s) => s.toLowerCase().contains(targetLower)) ?? false;
        final nameMatch = expert.name.toLowerCase().contains(targetLower);

        return categoryMatch || skillMatch || nameMatch;
      }).toList();

      // Fallback limit for fast AI response
      if (candidateExperts.isEmpty) {
        candidateExperts = rawExperts.take(12).toList();
      } else if (candidateExperts.length > 10) {
        candidateExperts = candidateExperts.take(10).toList();
      }

      // Step 3: Fast Local Scoring Engine
      Map<String, int> matchScores = {};
      for (var expert in candidateExperts) {
        int score = 50; // Base Score

        // FIX 2 & 3: Safely check skills list with fallback ?? []
        final expertSkills = expert.skills ?? [];

        if (expertSkills.any((s) => s.toLowerCase() == targetLower)) {
          score += 35;
        } else if (expertSkills.any((s) => s.toLowerCase().contains(targetLower))) {
          score += 25;
        }

        // Direct Category Matching
        if (expert.category.toLowerCase() == categoryLower) {
          score += 10;
        }

        matchScores[expert.uid] = score.clamp(0, 99);
      }

      // Step 4: AI Optimization Call
      try {
        String aiResponseJson = await _geminiService
            .getRecommendedExperts(
          userTargetSkill: userTargetSkill,
          userCategory: userCategory,
          experts: candidateExperts,
        )
            .timeout(const Duration(seconds: 4));

        String sanitizedJson = aiResponseJson
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();

        List<dynamic> parsedList = jsonDecode(sanitizedJson);
        for (var item in parsedList) {
          if (item is Map && item['uid'] != null && item['matchPercentage'] != null) {
            matchScores[item['uid'].toString()] = (item['matchPercentage'] as num).toInt();
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint("AI Timeout/JSON Error (Using Local Matching): $e");
      }

      // Step 5: Map Final Results & Sort
      List<ExpertModel> matchedExperts = candidateExperts.map((expert) {
        int score = matchScores[expert.uid] ?? 60;
        return expert.copyWith(matchPercentage: score);
      }).toList();

      matchedExperts.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
      return matchedExperts;

    } catch (e) {
      if (kDebugMode) debugPrint("AIMatchService Error: $e");
      return [];
    }
  }
}