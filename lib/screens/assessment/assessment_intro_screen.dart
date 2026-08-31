import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:skill_exchange/models/quiz_question.dart';
import 'package:skill_exchange/screens/assessment/quiz_screen.dart';
import 'package:skill_exchange/services/firestore_service.dart';
import 'package:skill_exchange/services/gemini_service.dart' hide AssessmentQuizData;

class AssessmentIntroScreen extends StatefulWidget {
  final String skillName;
  final String certificateText;

  const AssessmentIntroScreen({
    super.key,
    required this.skillName,
    required this.certificateText,
  });

  @override
  State<AssessmentIntroScreen> createState() => _AssessmentIntroScreenState();
}

class _AssessmentIntroScreenState extends State<AssessmentIntroScreen> {
  bool _isLoading = true;
  AssessmentQuizData? _quizData;

  @override
  void initState() {
    super.initState();
    _loadAssessmentFromAI();
  }

  Future<void> _loadAssessmentFromAI() async {
    try {
      final quizData = await GeminiService().generateDynamicQuiz(
        skill: widget.skillName,
        certificateText: widget.certificateText,
        targetQuestionCount: 10,
      );

      if (mounted) {
        setState(() {
          _quizData = quizData as AssessmentQuizData?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating assessment: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6C5CE7);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FE),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "AI Skills Certification",
          style: TextStyle(
            color: Color(0xFF1E1B29),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(color: primaryPurple, strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            const Text(
              "Generating Ultra-Adaptive Assessment...",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B29)),
            ),
            const SizedBox(height: 6),
            const Text(
              "Analyzing uploaded certificate credentials with AI",
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, size: 80, color: primaryPurple),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Adaptive Knowledge Test",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B29),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "This test dynamically measures practical skill depth, architectural concepts, and scenario problems based on your verified background.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.bar_chart_rounded,
                    iconColor: Colors.orangeAccent,
                    bgColor: const Color(0xFFFFF4E5),
                    label: "Difficulty Level",
                    value: _quizData?.difficulty ?? "Multi-Tiered Adaptive",
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.quiz_outlined,
                    iconColor: Colors.purpleAccent,
                    bgColor: const Color(0xFFF2E9FC),
                    label: "Question Breakdown",
                    value: "${_quizData?.questions.length ?? 10} Dynamic Questions",
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.timer_outlined,
                    iconColor: Colors.blueAccent,
                    bgColor: const Color(0xFFE8F1FF),
                    label: "Estimated Duration",
                    value: "${(_quizData?.questions.length ?? 10) * 1} Minutes",
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    icon: Icons.verified_outlined,
                    iconColor: primaryPurple,
                    bgColor: const Color(0xFFEEEBFF),
                    label: "Passing Score Required",
                    value: "60%",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  if (_quizData == null) return;
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login again.")),
                      );
                      return;
                    }

                    final String sessionId = await FirestoreService().createAssessmentSession(
                      userId: user.uid,
                      skillName: widget.skillName,
                    );

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          quizData: _quizData!,
                          skillName: widget.skillName,
                          sessionId: sessionId,
                          userId: user.uid,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to start assessment: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Begin Assessment Now", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }
}