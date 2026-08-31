import 'package:flutter/material.dart';
import 'package:skill_exchange/services/gemini_service.dart';

class LearningRoadmapScreen extends StatefulWidget {
  final String skillName;

  const LearningRoadmapScreen({
    super.key,
    required this.skillName,
    required String subject,
  });

  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen> {
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _modules = [];

  int _targetDays = 14;
  String _userFocus = '';
  final Set<String> _completedTopics = {};

  @override
  void initState() {
    super.initState();
    _fetchRoadmapData();
  }

  Future<void> _fetchRoadmapData() async {
    setState(() => _isLoading = true);
    try {
      final String fullQuery = _userFocus.isNotEmpty ? "${widget.skillName} with focus on $_userFocus" : widget.skillName;
      final data = await _geminiService.generateRoadmapModules(fullQuery);
      if (mounted) {
        setState(() {
          _modules = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAITeacherDialog(String topicName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (context, scrollController) {
            return FutureBuilder<String>(
              future: _geminiService.generateTopicLesson(widget.skillName, topicName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
                }

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Text("AI Lesson: $topicName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      Text(snapshot.data ?? "Lesson content unavailable.", style: const TextStyle(fontSize: 14, height: 1.5)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B894)),
                        onPressed: () {
                          setState(() => _completedTopics.add(topicName));
                          Navigator.pop(context);
                        },
                        child: const Text("Mark as Completed", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("${widget.skillName} AI Roadmap"),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _modules.length,
        itemBuilder: (context, index) {
          final module = _modules[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ExpansionTile(
              title: Text(module['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(module['description'] ?? ''),
              children: ((module['topics'] as List<dynamic>?) ?? []).map((t) {
                final topicStr = t.toString();
                final isDone = _completedTopics.contains(topicStr);
                return ListTile(
                  title: Text(topicStr, style: TextStyle(decoration: isDone ? TextDecoration.lineThrough : null)),
                  trailing: IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Color(0xFF6C5CE7)),
                    onPressed: () => _openAITeacherDialog(topicStr),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}