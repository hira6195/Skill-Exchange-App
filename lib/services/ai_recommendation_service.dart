import '../models/expert_model.dart';

class AIRecommendationService {
  /// Dynamic AI Ranking & 2-Way Swap Engine
  List<ExpertModel> getAIRecommendedExperts({
    required List<ExpertModel> allExperts,
    required String userTargetSkill, // What logged-in user wants to learn
    String? userCanTeachSkill,        // What logged-in user can teach / verified skill
  }) {
    if (allExperts.isEmpty) return [];

    bool isUserSkillEmpty = (userTargetSkill.trim().isEmpty || userTargetSkill.toLowerCase() == 'not set') &&
        (userCanTeachSkill == null || userCanTeachSkill.trim().isEmpty || userCanTeachSkill.toLowerCase() == 'not set');

    if (isUserSkillEmpty) {
      return [];
    }

    List<ExpertModel> rankedExperts = [];

    for (var expert in allExperts) {
      int matchScore = 0;

      // 1. Check: Expert teaches what user wants to learn
      bool teachesWhatILearn = _isSkillMatching(expert.skill, userTargetSkill) ||
          _isSkillMatching(expert.category, userTargetSkill);

      // 2. Check: User teaches what Expert wants to learn
      bool wantsWhatITeach = userCanTeachSkill != null &&
          userCanTeachSkill.isNotEmpty &&
          userCanTeachSkill.toLowerCase() != 'not set' &&
          _isSkillMatching(expert.wantsToLearn, userCanTeachSkill);

      // --- MATCH SCORE CALCULATION ---
      if (teachesWhatILearn && wantsWhatITeach) {
        matchScore = 95; // Perfect 2-Way Swap
      } else if (teachesWhatILearn) {
        matchScore = 80; // 1-Way Teacher Match
      } else if (wantsWhatITeach) {
        matchScore = 65; // 1-Way Learner Match
      } else {
        matchScore = 0;
      }

      if (matchScore > 0) {
        double ratingBonus = (expert.rating / 5.0) * 4;
        matchScore = (matchScore + ratingBonus.round()).clamp(0, 100);
        rankedExperts.add(expert.copyWith(matchPercentage: matchScore));
      }
    }

    rankedExperts.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return rankedExperts;
  }

  bool _isSkillMatching(String skillA, String skillB) {
    if (skillA.isEmpty || skillB.isEmpty) return false;

    String cleanA = skillA.toLowerCase();
    String cleanB = skillB.toLowerCase();

    if (cleanA.contains(cleanB) || cleanB.contains(cleanA)) {
      return true;
    }

    final wordsA = cleanA.split(RegExp(r'[,/ ]+'));
    final wordsB = cleanB.split(RegExp(r'[,/ ]+'));

    for (var wordA in wordsA) {
      if (wordA.length < 2) continue;
      for (var wordB in wordsB) {
        if (wordB.length < 2) continue;
        if (wordA.contains(wordB) || wordB.contains(wordA)) {
          return true;
        }
      }
    }
    return false;
  }
}