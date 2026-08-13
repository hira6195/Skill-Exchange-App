import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/models/assessment_result.dart';
import 'package:skill_exchange/models/quiz_question.dart';
import 'package:skill_exchange/services/gemini_service.dart' hide AssessmentQuizData;
import 'package:skill_exchange/services/firestore_service.dart';
import 'package:skill_exchange/screens/learning_roadmap_screen.dart';
import 'package:skill_exchange/screens/assessment/quiz_screen.dart';
import 'package:skill_exchange/screens/my_home_screen.dart';

class AssessmentResultScreen extends StatefulWidget {
  final AssessmentResult result;

  const AssessmentResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<AssessmentResultScreen> createState() => _AssessmentResultScreenState();
}

class _AssessmentResultScreenState extends State<AssessmentResultScreen> {
  bool _isGeneratingNewQuiz = false;

  @override
  void initState() {
    super.initState();
    // Update test result & badge status in Firebase Firestore upon screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveUserSkillStatus();
    });
  }

  // Null-safe dynamic score calculation
  double get calculatedPercentage {
    int total = widget.result.correctAnswers + widget.result.wrongAnswers;
    if (total == 0) return widget.result.percentage; // Fallback
    return ((widget.result.correctAnswers / total) * 100);
  }

  bool get isPassed => calculatedPercentage >= 60; // 60% Passing mark

  String get currentLevel {
    double score = calculatedPercentage;
    if (score >= 80) return "EXPERT";
    if (score >= 60) return "INTERMEDIATE";
    return "BEGINNER";
  }

  /// Saves user test completion status and skill level to Firestore
  Future<void> _saveUserSkillStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          'isTestPassed': isPassed,
          'skillLevel': currentLevel,
          'lastAssessedSkill': widget.result.skillName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving user skill status: $e");
    }
  }

  Future<void> _handleRetakeAssessment() async {
    setState(() {
      _isGeneratingNewQuiz = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? widget.result.userId;
      final skillName = widget.result.skillName;

      final AssessmentQuizData quizData = await GeminiService.instance.generateDynamicQuiz(
        subject: skillName,
        skill: skillName,
        certificateText: "Retake assessment request",
        targetQuestionCount: 15,
      );

      final newSessionId = await FirestoreService().createAssessmentSession(
        userId: userId,
        skillName: skillName,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            sessionId: newSessionId,
            userId: userId,
            skillName: skillName,
            quizData: quizData,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating new quiz: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingNewQuiz = false;
        });
      }
    }
  }

  // Navigate directly to MyHomeScreen
  void _navigateToHomeScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MyHomeScreen(
          onSearchTap: () {},
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double percentage = calculatedPercentage;
    final int correct = widget.result.correctAnswers;
    final int incorrect = widget.result.wrongAnswers;
    final int total = correct + incorrect > 0 ? (correct + incorrect) : 10;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              "AI Assessment Result",
              style: TextStyle(
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Here is your AI assessment score and skill level.",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LearningRoadmapScreen(
                      skillName: widget.result.skillName,
                      subject: '',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Color(0xFF6C5CE7),
              ),
              label: const Text(
                "Enhance Skill",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.home_rounded,
              color: Color(0xFF6C5CE7),
              size: 26,
            ),
            tooltip: "Go to Home",
            onPressed: _navigateToHomeScreen,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isGeneratingNewQuiz
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            SizedBox(height: 16),
            Text(
              "Generating a new AI Assessment...",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C5CE7),
              ),
            )
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 95,
                      width: 95,
                      child: CircularProgressIndicator(
                        value: (percentage / 100).clamp(0.0, 1.0),
                        strokeWidth: 9,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPassed ? Colors.green : const Color(0xFF6C5CE7),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${percentage.toInt()}%",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isPassed ? Colors.green : const Color(0xFF6C5CE7),
                          ),
                        ),
                        const Text(
                          "Your Score",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isPassed ? "Great Job! " : "Keep Trying! ",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isPassed ? "🎉" : "💪",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You have completed the AI Skill Assessment for ${widget.result.skillName}.",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn("$correct", "Correct Answers", Colors.green),
                  Container(height: 35, width: 1, color: Colors.grey.shade300),
                  _buildStatColumn("$incorrect", "Incorrect Answers", Colors.red),
                  Container(height: 35, width: 1, color: Colors.grey.shade300),
                  _buildStatColumn("$total", "Total Questions", Colors.black),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "YOUR SKILL LEVEL",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Your score places you in the following category",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildLevelTile(
                    title: "EXPERT LEVEL",
                    subtitle: "Excellent! Your skills are at a high level.",
                    range: "80% - 100%",
                    color: Colors.green,
                    isSelected: currentLevel == 'EXPERT',
                    icon: Icons.star_rounded,
                  ),
                  const Divider(height: 16),
                  _buildLevelTile(
                    title: "INTERMEDIATE LEVEL",
                    subtitle: "Good! Your skills are average.",
                    range: "60% - 79%",
                    color: Colors.amber.shade700,
                    isSelected: currentLevel == 'INTERMEDIATE',
                    icon: Icons.stars_rounded,
                  ),
                  const Divider(height: 16),
                  _buildLevelTile(
                    title: "BEGINNER LEVEL",
                    subtitle: "You need more practice to reach required level.",
                    range: "Below 60%",
                    color: Colors.redAccent,
                    isSelected: currentLevel == 'BEGINNER',
                    icon: Icons.cancel_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _handleRetakeAssessment,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Retake Assessment",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: _navigateToHomeScreen,
              child: const Text(
                "Go to Dashboard",
                style: TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color == Colors.black ? Colors.grey : color,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelTile({
    required String title,
    required String subtitle,
    required String range,
    required Color color,
    required bool isSelected,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}