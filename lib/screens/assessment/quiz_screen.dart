import 'dart:async';
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
  int _remainingTime = 60;
  Timer? _timer;

  final List<Map<String, dynamic>> _userAnswers = [];
  int? _selectedOption;
  final TextEditingController _textAnswerController = TextEditingController();

  late List<QuestionData> _parsedQuestions;
  int _warningCount = 0;
  final int _maxAllowedWarnings = 3;
  bool _isTerminated = false;

  // Modern Professional Dark Theme Palette
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color darkBackground = Color(0xFF0B0E14);
  static const Color cardColor = Color(0xFF151921);
  static const Color cardBorderColor = Color(0xFF232936);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final Set<String> seen = {};
    _parsedQuestions = widget.quizData.questions.where((q) {
      final normalized = q.question.trim().toLowerCase();
      if (seen.contains(normalized)) return false;
      seen.add(normalized);
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
      _registerCheatingFlag("App switch or loss of focus detected!");
    }
  }

  void _registerCheatingFlag(String reason) {
    setState(() => _warningCount++);
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
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorderColor),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 26),
            SizedBox(width: 8),
            Text("Proctor Alert", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          "$reason\n\nWarning $_warningCount of $_maxAllowedWarnings. Further focus losses will invalidate your exam.",
          style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            onPressed: () => Navigator.pop(context),
            child: const Text("I Understand", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent),
        ),
        title: const Text("Assessment Invalidated", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("Multiple security focus violations registered.", style: TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit Exam", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    if (_parsedQuestions.isNotEmpty && _currentIndex < _parsedQuestions.length) {
      _remainingTime = _parsedQuestions[_currentIndex].timeInSeconds > 0 ? _parsedQuestions[_currentIndex].timeInSeconds : 60;
    } else {
      _remainingTime = 60;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        if (mounted) setState(() => _remainingTime--);
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
          SnackBar(content: const Text("Please enter a response before continuing."), backgroundColor: Colors.orange.shade800),
        );
        return;
      } else if (!isWrittenType && _selectedOption == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Please select an answer choice."), backgroundColor: Colors.orange.shade800),
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

    String correctText = currentQ.correctAnswer;
    if (correctText.isEmpty && currentQ.correctOptionIndex >= 0 && currentQ.correctOptionIndex < currentQ.options.length) {
      correctText = currentQ.options[currentQ.correctOptionIndex];
    }

    _userAnswers.add({
      'id': currentQ.id,
      'question': currentQ.question,
      'codeSnippet': currentQ.codeSnippet,
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
      setState(() => _currentIndex++);
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
      builder: (_) => const Center(child: CircularProgressIndicator(color: primaryPurple)),
    );

    try {
      AssessmentResult result = await AssessmentService().evaluateAssessment(
        sessionId: widget.sessionId,
        userId: widget.userId,
        skillName: widget.skillName,
        questionsWithUserAnswers: _userAnswers,
      );

      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => AssessmentResultScreen(result: result)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Widget _buildTypeBadge(String type) {
    Color badgeColor = primaryPurple;
    String label = "MCQ";

    if (type.toLowerCase() == 'scenario') {
      badgeColor = const Color(0xFFFFB74D);
      label = "Scenario Problem";
    } else if (type.toLowerCase() == 'short') {
      badgeColor = const Color(0xFF64B5F6);
      label = "Conceptual Written";
    } else if (type.toLowerCase() == 'coding') {
      badgeColor = const Color(0xFF00E676);
      label = "Code Logic & Syntax";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07090E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryPurple.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFF80D8FF),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalQuestions = _parsedQuestions.length;
    if (totalQuestions == 0) {
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: Text("No questions generated.", style: TextStyle(color: Colors.white))),
      );
    }

    final QuestionData currentQ = _parsedQuestions[_currentIndex];
    final bool isWrittenType = currentQ.type.toLowerCase() == 'short' || currentQ.options.isEmpty;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text("${widget.skillName} Verification", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _warningCount > 0 ? Colors.redAccent.withValues(alpha: 0.2) : Colors.greenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _warningCount > 0 ? Colors.redAccent.withValues(alpha: 0.5) : Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: _warningCount > 0 ? Colors.redAccent : Colors.greenAccent, size: 14),
                const SizedBox(width: 4),
                Text("Security: $_warningCount/$_maxAllowedWarnings", style: TextStyle(color: _warningCount > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / totalQuestions,
                  backgroundColor: cardBorderColor,
                  color: primaryPurple,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildTypeBadge(currentQ.type),
                      const SizedBox(width: 8),
                      Text("Q${_currentIndex + 1} of $totalQuestions", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _remainingTime <= 15 ? Colors.redAccent.withValues(alpha: 0.2) : primaryPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _remainingTime <= 15 ? Colors.redAccent.withValues(alpha: 0.4) : primaryPurple.withValues(alpha: 0.3)),
                    ),
                    child: Text("${_remainingTime}s", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _remainingTime <= 15 ? Colors.redAccent : const Color(0xFFD1C4E9))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currentQ.question,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 14),

              if (currentQ.codeSnippet != null && currentQ.codeSnippet!.isNotEmpty)
                _buildCodeBlock(currentQ.codeSnippet!),

              Expanded(
                child: isWrittenType
                    ? TextField(
                  controller: _textAnswerController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Type conceptual solution or reasoning here...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: cardBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: cardBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryPurple, width: 1.5),
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: currentQ.options.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedOption == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedOption = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryPurple.withValues(alpha: 0.2) : cardColor,
                          border: Border.all(
                            color: isSelected ? primaryPurple : cardBorderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? primaryPurple : Colors.transparent,
                                border: Border.all(color: isSelected ? primaryPurple : Colors.white38, width: 2),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                currentQ.options[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _nextQuestion(isAutoSubmit: false),
                  child: Text(
                    _currentIndex == totalQuestions - 1 ? "Submit Assessment" : "Next Question",
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}