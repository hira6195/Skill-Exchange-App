import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// IMPORTANT: Centralized model import
import 'package:skill_exchange/models/quiz_question.dart';
import 'package:skill_exchange/screens/assessment/quiz_screen.dart';
import 'package:skill_exchange/services/firestore_service.dart';
// Hide duplicate AssessmentQuizData from service import to eliminate collision
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
      // Minimum 10 questions requested
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
        setState(() {
          _isLoading = false;
        });
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "AI Assessment",
          style: TextStyle(
            color: primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryPurple),
            SizedBox(height: 16),
            Text(
              "AI is generating tailored questions & duration...",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                height: 160,
                width: 200,
                child: Image.asset(
                  'assets/ai robot.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.smart_toy_outlined,
                      size: 100,
                      color: primaryPurple,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              "AI Skill Assessment",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Based on your uploaded certificate, our AI will evaluate your practical knowledge through an adaptive assessment",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    iconPath: Icons.bar_chart_rounded,
                    iconColor: Colors.orangeAccent,
                    bgColor: const Color(0xFFFFF4E5),
                    label: "Difficulty",
                    value: _quizData?.difficulty ?? "Adaptive (Easy → Hard)",
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    iconPath: Icons.help_outline_rounded,
                    iconColor: Colors.purpleAccent,
                    bgColor: const Color(0xFFF2E9FC),
                    label: "Total Questions",
                    value: "${_quizData?.questions.length ?? 10} Questions",
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    iconPath: Icons.access_time_rounded,
                    iconColor: Colors.blueAccent,
                    bgColor: const Color(0xFFE8F1FF),
                    label: "Duration",
                    value: "${(_quizData?.questions.length ?? 10) * 1} Minutes",
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    iconPath: Icons.assignment_turned_in_outlined,
                    iconColor: primaryPurple,
                    bgColor: const Color(0xFFEEEBFF),
                    label: "Passing Score",
                    value: "60%",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                if (_quizData == null) return;

                try {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please login again."),
                      ),
                    );
                    return;
                  }

                  final String sessionId =
                  await FirestoreService().createAssessmentSession(
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
                    SnackBar(
                      content: Text("Failed to start assessment.\n$e"),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Start Assessment",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData iconPath,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(iconPath, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}