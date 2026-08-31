import 'package:flutter/material.dart';
import 'package:skill_exchange/services/gemini_service.dart';

class TopicLessonScreen extends StatefulWidget {
  final String skillName;
  final String topicName;
  final String category;

  const TopicLessonScreen({
    super.key,
    required this.skillName,
    required this.topicName,
    required this.category,
  });

  @override
  State<TopicLessonScreen> createState() => _TopicLessonScreenState();
}

class _TopicLessonScreenState extends State<TopicLessonScreen> {
  bool _isLoading = true;
  String _lessonText = "";
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAITopicLesson();
  }

  Future<void> _loadAITopicLesson() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lessonContent = await GeminiService.instance.generateTopicLesson(
        widget.skillName,
        widget.topicName,
      );
      if (mounted) {
        setState(() {
          _lessonText = lessonContent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AI Personal Tutor",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Topic Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff6A1B9A), Color(0xff8E24AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "${widget.category} • ${widget.skillName}",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.topicName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lesson Body
            Expanded(
              child: _isLoading
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xff6A1B9A)),
                    SizedBox(height: 16),
                    Text(
                      "AI Tutor is preparing your lesson...",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : _errorMessage != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      SelectableText(
                        "Error: $_errorMessage",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff6A1B9A),
                        ),
                        onPressed: _loadAITopicLesson,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text("Try Again",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: SelectableText(
                      _lessonText,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}