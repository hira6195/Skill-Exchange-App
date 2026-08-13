import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skill_exchange/models/quiz_question.dart';
import 'package:skill_exchange/models/assessment_result.dart';
import 'package:skill_exchange/services/assessment_service.dart';
import 'package:skill_exchange/screens/assessment/assessment_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String skillName;
  final AssessmentQuizData quizData;

  const QuizScreen({
    super.key,
    required this.sessionId,
    required this.userId,
    required this.skillName,
    required this.quizData,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _remainingTime = 90;
  Timer? _timer;

  final List<Map<String, dynamic>> _userAnswers = [];
  int? _selectedOption;
  final TextEditingController _textAnswerController = TextEditingController();

  late List<QuestionData> _parsedQuestions;

  // ================= Anti-Cheating Tracker =================
  int _warningCount = 0;
  final int _maxAllowedWarnings = 3;
  bool _isTerminated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Deduplicate Questions locally to avoid repeated questions on UI
    final Set<String> seenQuestions = {};
    _parsedQuestions = widget.quizData.questions.where((q) {
      final normalized = q.question.trim().toLowerCase();
      if (seenQuestions.contains(normalized)) {
        return false;
      }
      seenQuestions.add(normalized);
      return true;
    }).toList();

    _startQuestionTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _textAnswerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isTerminated) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _registerCheatingFlag("App minimized or screen swapped!");
    }
  }

  void _registerCheatingFlag(String reason) {
    setState(() {
      _warningCount++;
    });

    if (kDebugMode) {
      debugPrint("FLAG GENERATED: $reason (Count: $_warningCount/$_maxAllowedWarnings)");
    }

    if (_warningCount >= _maxAllowedWarnings) {
      _terminateQuizDueToCheating();
    } else {
      _showWarningDialog(reason);
    }
  }

  void _showWarningDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text("Cheating Warning!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "$reason\n\nWarning $_warningCount of $_maxAllowedWarnings. If you swap screen or minimize app again, your quiz will be terminated automatically!",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: const Text("I Understand", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _terminateQuizDueToCheating() {
    _timer?.cancel();
    _isTerminated = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Text("Quiz Terminated!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Multiple screen swapping or app minimization attempts were detected. Your assessment has been auto-terminated due to suspicious activity.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit Quiz", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    if (_parsedQuestions.isNotEmpty && _currentIndex < _parsedQuestions.length) {
      _remainingTime = _parsedQuestions[_currentIndex].timeInSeconds > 0
          ? _parsedQuestions[_currentIndex].timeInSeconds
          : 60;
    } else {
      _remainingTime = 60;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        if (mounted) {
          setState(() {
            _remainingTime--;
          });
        }
      } else {
        _nextQuestion(isAutoSubmit: true);
      }
    });
  }

  void _nextQuestion({bool isAutoSubmit = false}) {
    if (_parsedQuestions.isEmpty || _isTerminated) return;

    final QuestionData currentQ = _parsedQuestions[_currentIndex];
    final bool isWrittenType = currentQ.type.toLowerCase() == 'short' || currentQ.options.isEmpty;

    if (!isAutoSubmit) {
      if (isWrittenType && _textAnswerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please write your answer!"), backgroundColor: Colors.orange),
        );
        return;
      } else if (!isWrittenType && _selectedOption == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an answer to continue!"), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    String selectedText = "";
    if (isWrittenType) {
      selectedText = _textAnswerController.text.trim();
    } else if (_selectedOption != null && _selectedOption! >= 0 && _selectedOption! < currentQ.options.length) {
      selectedText = currentQ.options[_selectedOption!];
    }

    String correctText = "";
    if (currentQ.correctOptionIndex >= 0 && currentQ.correctOptionIndex < currentQ.options.length) {
      correctText = currentQ.options[currentQ.correctOptionIndex];
    }

    _userAnswers.add({
      'id': currentQ.id,
      'question': currentQ.question,
      'type': currentQ.type,
      'topic': currentQ.topic,
      'difficulty': currentQ.difficulty,
      'options': currentQ.options,
      'correctOptionIndex': currentQ.correctOptionIndex,
      'selectedOptionIndex': _selectedOption,
      'selectedOptionText': selectedText,
      'correctAnswerText': correctText,
      'explanation': currentQ.explanation,
    });

    _selectedOption = null;
    _textAnswerController.clear();

    if (_currentIndex < _parsedQuestions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startQuestionTimer();
    } else {
      _timer?.cancel();
      _submitAssessment();
    }
  }

  Future<void> _submitAssessment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
    );

    try {
      int correctAnswersCount = 0;
      int totalQuestions = _userAnswers.length;

      for (var qa in _userAnswers) {
        int? selectedIdx = qa['selectedOptionIndex'] as int?;
        int correctIdx = qa['correctOptionIndex'] as int? ?? -1;
        String selectedStr = (qa['selectedOptionText'] ?? "").toString().trim().toLowerCase();
        String correctStr = (qa['correctAnswerText'] ?? "").toString().trim().toLowerCase();

        bool isCorrect = false;
        if (selectedIdx != null && selectedIdx == correctIdx) {
          isCorrect = true;
        } else if (selectedStr.isNotEmpty && correctStr.isNotEmpty && selectedStr == correctStr) {
          isCorrect = true;
        }

        if (isCorrect) correctAnswersCount++;
      }

      int wrongAnswersCount = totalQuestions - correctAnswersCount;
      double percentage = totalQuestions > 0 ? (correctAnswersCount / totalQuestions) * 100 : 0.0;

      AssessmentResult result;
      try {
        result = await AssessmentService().evaluateAssessment(
          sessionId: widget.sessionId,
          userId: widget.userId,
          skillName: widget.skillName,
          questionsWithUserAnswers: _userAnswers,
        );
      } catch (e) {
        result = AssessmentResult(
          sessionId: widget.sessionId,
          userId: widget.userId,
          skillName: widget.skillName,
          correctAnswers: correctAnswersCount,
          wrongAnswers: wrongAnswersCount,
          percentage: percentage,
          score: correctAnswersCount.toDouble(),
          isPassed: percentage >= 60.0,
          skillLevel: percentage >= 80 ? 'EXPERT' : (percentage >= 60 ? 'INTERMEDIATE' : 'BEGINNER'),
          feedback: 'Assessment completed. Total Warnings: $_warningCount',
          completedAt: DateTime.now(),
          userAnswers: _userAnswers,
        );
      }

      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => AssessmentResultScreen(result: result)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Widget _buildTypeBadge(String type) {
    Color badgeColor = Colors.purple;
    String label = "MCQ";

    if (type.toLowerCase() == 'scenario') {
      badgeColor = Colors.orange.shade700;
      label = "Scenario";
    } else if (type.toLowerCase() == 'short') {
      badgeColor = Colors.blue.shade700;
      label = "Short Answer";
    } else if (type.toLowerCase() == 'conceptual') {
      badgeColor = Colors.teal.shade700;
      label = "Conceptual";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalQuestions = _parsedQuestions.length;

    if (totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF6C5CE7)),
        body: const Center(child: Text("No questions generated.")),
      );
    }

    final QuestionData currentQ = _parsedQuestions[_currentIndex];
    final bool isWrittenType = currentQ.type.toLowerCase() == 'short' || currentQ.options.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.skillName} (${_currentIndex + 1}/$totalQuestions)"),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _warningCount > 0 ? Colors.red : Colors.green.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Flags: $_warningCount/$_maxAllowedWarnings",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / totalQuestions,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF6C5CE7),
              minHeight: 6,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildTypeBadge(currentQ.type),
                    const SizedBox(width: 8),
                    Text(
                      "Difficulty: ${currentQ.difficulty}",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      "${_remainingTime}s",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Q${_currentIndex + 1}. ${currentQ.question}",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isWrittenType
                  ? TextField(
                controller: _textAnswerController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Type your conceptual/short answer here...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6C5CE7), width: 2),
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: currentQ.options.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedOption == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedOption = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.08) : Colors.white,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentQ.options[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _nextQuestion(isAutoSubmit: false),
              child: Text(
                _currentIndex == totalQuestions - 1 ? "Finish Assessment" : "Next Question",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}