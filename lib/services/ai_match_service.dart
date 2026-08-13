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

      List<ExpertModel> rawExperts = await _firestoreService.getExperts();

      if (rawExperts.isEmpty) return [];

      // Gemini AI Prompting for Real Swap Evaluation
      String aiResponseJson = await _geminiService.getRecommendedExperts(
        userTargetSkill: userTargetSkill,
        userCategory: userCategory,
        experts: rawExperts,
      );

      String sanitizedJson = aiResponseJson
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      Map<String, int> matchScores = {};
      try {
        List<dynamic> parsedList = jsonDecode(sanitizedJson);
        for (var item in parsedList) {
          if (item is Map && item['uid'] != null && item['matchPercentage'] != null) {
            matchScores[item['uid'].toString()] = (item['matchPercentage'] as num).toInt();
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint("JSON Parse Error: $e");
      }

      List<ExpertModel> matchedExperts = rawExperts.map((expert) {
        int score = matchScores[expert.uid] ?? 0;
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