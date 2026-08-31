import 'package:flutter/material.dart';
import '../../services/assessment_service.dart';

class AssessmentResult {
  final double score;
  final String skillLevel;
  final bool isPassed;
  final String feedback;

  AssessmentResult({
    required this.score,
    required this.skillLevel,
    required this.isPassed,
    required this.feedback,
  });
}

class AiEvaluationScreen extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String skillName;
  final List<Map<String, dynamic>> questionsWithUserAnswers;

  const AiEvaluationScreen({
    super.key,
    required this.sessionId,
    required this.userId,
    required this.skillName,
    required this.questionsWithUserAnswers,
  });

  @override
  State<AiEvaluationScreen> createState() => _AiEvaluationScreenState();
}

class _AiEvaluationScreenState extends State<AiEvaluationScreen> {
  static const primaryPurple = Color(0xFF6C5CE7);

  bool _isEvaluating = true;
  AssessmentResult? _result;
  String _errorMessage = "";

  final List<String> _strongTopics = [];
  final List<String> _weakTopics = [];

  @override
  void initState() {
    super.initState();
    _runEvaluation();
  }

  Future<void> _runEvaluation() async {
    try {
      final AssessmentService service = AssessmentService();

      _extractTopicsAnalysis();

      final result = await service.evaluateAssessment(
        sessionId: widget.sessionId,
        userId: widget.userId,
        skillName: widget.skillName,
        questionsWithUserAnswers: widget.questionsWithUserAnswers,
      );

      if (mounted) {
        setState(() {
          if (result is AssessmentResult) {
            _result = result as AssessmentResult?;
          } else {
            double calcScore = _calculateScore();
            _result = AssessmentResult(
              score: calcScore,
              skillLevel: _getSkillLevel(calcScore),
              isPassed: calcScore >= 70,
              feedback: calcScore >= 70
                  ? "Great performance! You demonstrated good technical competence across dynamic problem-solving."
                  : "Needs improvement. Please review weak conceptual and scenario-based areas.",
            );
          }
          _isEvaluating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        double calcScore = _calculateScore();
        setState(() {
          _result = AssessmentResult(
            score: calcScore,
            skillLevel: _getSkillLevel(calcScore),
            isPassed: calcScore >= 70,
            feedback: "Performance analysis generated based on answer accuracy.",
          );
          _isEvaluating = false;
        });
      }
    }
  }

  double _calculateScore() {
    if (widget.questionsWithUserAnswers.isEmpty) return 0.0;
    int correct = 0;
    for (var q in widget.questionsWithUserAnswers) {
      String type = (q['type'] ?? 'mcq').toString().toLowerCase();
      if (type == 'mcq') {
        if (q['selectedOptionIndex'] != null &&
            q['selectedOptionIndex'] == q['correctOptionIndex']) {
          correct++;
        }
      } else {
        String ans = (q['shortAnswerText'] ?? q['selectedOptionText'] ?? '').toString().trim();
        if (ans.length > 15) correct++;
      }
    }
    return (correct / widget.questionsWithUserAnswers.length) * 100;
  }

  String _getSkillLevel(double score) {
    if (score >= 80) return 'Expert';
    if (score >= 70) return 'Intermediate';
    return 'Beginner';
  }

  void _extractTopicsAnalysis() {
    Map<String, int> totalPerTopic = {};
    Map<String, int> correctPerTopic = {};

    for (var q in widget.questionsWithUserAnswers) {
      String topic = q['topic'] ?? 'General Mechanics';
      totalPerTopic[topic] = (totalPerTopic[topic] ?? 0) + 1;

      bool isCorrect = false;
      String type = (q['type'] ?? 'mcq').toString().toLowerCase();
      if (type == 'mcq') {
        isCorrect = q['selectedOptionIndex'] != null &&
            q['selectedOptionIndex'] == q['correctOptionIndex'];
      } else {
        String ans = (q['shortAnswerText'] ?? q['selectedOptionText'] ?? '').toString().trim();
        isCorrect = ans.length > 15;
      }

      if (isCorrect) {
        correctPerTopic[topic] = (correctPerTopic[topic] ?? 0) + 1;
      }
    }

    _strongTopics.clear();
    _weakTopics.clear();

    totalPerTopic.forEach((topic, total) {
      int correct = correctPerTopic[topic] ?? 0;
      double ratio = correct / total;
      if (ratio >= 0.70) {
        _strongTopics.add(topic);
      } else {
        _weakTopics.add(topic);
      }
    });

    if (_strongTopics.isEmpty) _strongTopics.add("Core Fundamentals");
    if (_weakTopics.isEmpty) _weakTopics.add("Advanced Scenarios");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Assessment Result",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isEvaluating
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryPurple),
            const SizedBox(height: 20),
            const Text("AI is evaluating performance across topics...",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Analyzing MCQs, Scenarios, & Short Code Answers",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(child: Text("Error during evaluation:\n$_errorMessage", textAlign: TextAlign.center))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildMetricTile("Score", "${_result!.score.toStringAsFixed(1)}%", Icons.stars_rounded, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricTile("Total Qs", "${widget.questionsWithUserAnswers.length}", Icons.quiz_rounded, Colors.purple)),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Skill Matrix Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildTopicChipSection("Strong Topics", _strongTopics, Colors.green),
                  const SizedBox(height: 12),
                  _buildTopicChipSection("Weak Topics (Needs Practice)", _weakTopics, Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryPurple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: primaryPurple, size: 20),
                      SizedBox(width: 8),
                      Text("AI Technical Feedback", style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _result!.feedback,
                    style: const TextStyle(height: 1.4, color: Colors.black87, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result!.isPassed ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _result!.isPassed ? Colors.green.shade300 : Colors.amber.shade400),
              ),
              child: Row(
                children: [
                  Icon(
                    _result!.isPassed ? Icons.verified_user : Icons.warning_amber_rounded,
                    color: _result!.isPassed ? Colors.green.shade800 : Colors.amber.shade900,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _result!.isPassed ? "Certificate Eligible!" : "Retake Required",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _result!.isPassed ? Colors.green.shade900 : Colors.amber.shade900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _result!.isPassed
                              ? "Congratulations! Your skill badge has been verified."
                              : "You didn't reach the 70% threshold. Review weak topics and retry.",
                          style: TextStyle(
                            fontSize: 12,
                            color: _result!.isPassed ? Colors.green.shade800 : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Column(
              children: [
                if (!_result!.isPassed) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text("Retry Assessment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    _result!.isPassed ? "Done & Go to Dashboard" : "Back to Dashboard",
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(
            _result!.isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
            size: 60,
            color: _result!.isPassed ? Colors.amber : Colors.redAccent,
          ),
          const SizedBox(height: 10),
          Text(
            widget.skillName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Level: ${_result!.skillLevel}",
              style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicChipSection(String title, List<String> topics, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: topics
              .map((t) => Chip(
            label: Text(t, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            backgroundColor: color.withValues(alpha: 0.08),
            side: BorderSide(color: color.withValues(alpha: 0.2)),
          ))
              .toList(),
        ),
      ],
    );
  }
}