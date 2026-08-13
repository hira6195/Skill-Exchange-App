import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_exchange/models/assessment_result.dart';
import 'package:skill_exchange/models/expert_model.dart'; // Import added

/// FirestoreService: Handles all Firebase Firestore database operations.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _sessionsRef => _db.collection('assessment_sessions');
  CollectionReference get _resultsRef => _db.collection('assessment_results');
  CollectionReference get _verifiedSkillsRef => _db.collection('verified_skills');
  CollectionReference get _generatedQuestionsRef => _db.collection('generated_questions');
  CollectionReference get _usersRef => _db.collection('users');

  /// 0. Get Recommended Experts
  /// Fetches verified teachers from the users collection for AI matching.
  Future<List<ExpertModel>> getExperts() async {
    try {
      final QuerySnapshot query = await _usersRef
          .where('role', isEqualTo: 'teacher')
          .where('verified', isEqualTo: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExpertModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('FirestoreService Error (getExperts): $e');
    }
  }

  /// 1. Create Assessment Session
  /// Creates a new assessment session record when user starts the test.
  Future<String> createAssessmentSession({
    required String userId,
    required String skillName,
  }) async {
    try {
      final docRef = await _sessionsRef.add({
        'userId': userId,
        'skillName': skillName,
        'status': 'in_progress', // Statuses: in_progress, submitted, completed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('FirestoreService Error (createAssessmentSession): $e');
    }
  }

  /// 2. Save User Answers
  /// Stores selected user answers upon quiz completion using set(merge: true) to avoid NOT_FOUND error.
  Future<void> saveAssessmentAnswers({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      await _sessionsRef.doc(sessionId).set({
        'userAnswers': answers,
        'status': 'submitted',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('FirestoreService Error (saveAssessmentAnswers): $e');
    }
  }

  /// 3. Save Result
  /// Stores final AI evaluation outcome in assessment_results collection.
  Future<void> saveAssessmentResult(AssessmentResult result) async {
    try {
      await _resultsRef.doc(result.sessionId).set(
        result.toMap(),
        SetOptions(merge: true),
      );

      // Mark assessment session as completed
      await _sessionsRef.doc(result.sessionId).set({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('FirestoreService Error (saveAssessmentResult): $e');
    }
  }

  /// 4. Add Verified Skill
  /// Creates or updates verified skill record when user passes.
  Future<void> addVerifiedSkill({
    required String userId,
    required String skillName,
    required String skillLevel,
    required double score,
    required String resultId,
  }) async {
    try {
      // Unique document ID prevents duplicate badges for the same user
      final String skillDocId = '${userId}_${skillName.replaceAll(' ', '_').toLowerCase()}';

      await _verifiedSkillsRef.doc(skillDocId).set({
        'userId': userId,
        'skillName': skillName,
        'skillLevel': skillLevel,
        'score': score,
        'resultId': resultId,
        'verifiedAt': FieldValue.serverTimestamp(),
        'isVerified': true,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('FirestoreService Error (addVerifiedSkill): $e');
    }
  }

  /// 5. Get Result
  /// Fetches saved AssessmentResult model by session ID.
  Future<AssessmentResult?> getAssessmentResult(String sessionId) async {
    try {
      final DocumentSnapshot doc = await _resultsRef.doc(sessionId).get();

      if (doc.exists && doc.data() != null) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return AssessmentResult.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('FirestoreService Error (getAssessmentResult): $e');
    }
  }

  /// 6. Get Previous Questions
  /// Fetches all previously asked questions for a user and skill to ensure zero repetition.
  Future<List<String>> getPreviousQuestions({
    required String userId,
    required String skillName,
  }) async {
    try {
      final QuerySnapshot query = await _generatedQuestionsRef
          .where('userId', isEqualTo: userId)
          .where('skillName', isEqualTo: skillName)
          .get();

      List<String> previousQuestions = [];
      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['questions'] != null && data['questions'] is List) {
          final List questionsList = data['questions'];
          for (var q in questionsList) {
            if (q is Map && q['question'] != null) {
              previousQuestions.add(q['question'].toString().trim());
            }
          }
        }
      }
      return previousQuestions;
    } catch (e) {
      return [];
    }
  }

  /// 7. Save Generated Questions
  /// Stores newly generated AI question set for session history and deduplication.
  Future<void> saveGeneratedQuestions({
    required String sessionId,
    required String userId,
    required String skillName,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      await _generatedQuestionsRef.doc(sessionId).set({
        'sessionId': sessionId,
        'userId': userId,
        'skillName': skillName,
        'questions': questions,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('FirestoreService Error (saveGeneratedQuestions): $e');
    }
  }
}