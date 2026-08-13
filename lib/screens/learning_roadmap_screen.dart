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

  // User Custom Preferences
  int _targetDays = 14;
  String _userFocus = '';
  final Set<String> _completedTopics = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUserPreferenceDialog();
    });
  }

  void _showUserPreferenceDialog() {
    final TextEditingController daysController =
    TextEditingController(text: '14');
    final TextEditingController focusController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Color(0xFF6C5CE7)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Customize AI Plan for ${widget.skillName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select completion timeline and specific focus areas:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Completion Days (e.g., 7, 14, 30)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: focusController,
              decoration: InputDecoration(
                labelText: 'Specific Focus Areas (Optional)',
                hintText: 'e.g., Basics, Real Projects, UI/UX',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.center_focus_strong),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _targetDays = int.tryParse(daysController.text) ?? 14;
                _userFocus = focusController.text.trim();
              });
              Navigator.pop(context);
              _fetchRoadmapData();
            },
            child: const Text('Generate Custom Plan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchRoadmapData() async {
    setState(() => _isLoading = true);
    try {
      // Send skillName along with user focus if available
      final String fullQuery = _userFocus.isNotEmpty
          ? "${widget.skillName} with focus on $_userFocus"
          : widget.skillName;

      final data = await _geminiService.generateRoadmapModules(fullQuery);
      setState(() {
        _modules = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showModuleDetailsSheet(Map<String, dynamic> module) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final List<String> topics = List<String>.from(module['topics'] ?? []);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      module['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      module['description'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: Color(0xFF6C5CE7), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          "Pacing Goal: ~${(_targetDays / (_modules.isEmpty ? 1 : _modules.length)).toStringAsFixed(0)} Days for this module",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text(
                      "Topics Checklist (Tap magic icon to learn):",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...topics.map((topic) {
                      final isChecked = _completedTopics.contains(topic);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: isChecked,
                            activeColor: const Color(0xFF00B894),
                            onChanged: (bool? val) {
                              setModalState(() {
                                setState(() {
                                  if (val == true) {
                                    _completedTopics.add(topic);
                                  } else {
                                    _completedTopics.remove(topic);
                                  }
                                });
                              });
                            },
                          ),
                          title: Text(
                            topic,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.auto_awesome,
                                color: Color(0xFF6C5CE7)),
                            tooltip: 'Teach me this topic with AI',
                            onPressed: () {
                              _openAITeacherDialog(topic);
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Save Progress & Close",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAITeacherDialog(String topicName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return FutureBuilder<String>(
              future: _geminiService.generateTopicLesson(
                  widget.skillName, topicName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                        SizedBox(height: 16),
                        Text("AI is preparing your personalized lesson..."),
                      ],
                    ),
                  );
                }

                final lessonText = snapshot.data ??
                    "AI Tutor content is unavailable right now.";

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF6C5CE7),
                            child: Icon(Icons.school, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "AI Lesson: $topicName",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        lessonText,
                        style: const TextStyle(
                            fontSize: 15, height: 1.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("I Understood This Topic",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B894),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          setState(() {
                            _completedTopics.add(topicName);
                          });
                          Navigator.pop(context);
                        },
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
        title: Text("${widget.skillName} Roadmap"),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Change Plan Goals',
            onPressed: _showUserPreferenceDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            SizedBox(height: 16),
            Text("AI is crafting your customized roadmap..."),
          ],
        ),
      )
          : Column(
        children: [
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Target: $_targetDays Days Plan",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C5CE7)),
                ),
                Text(
                  "Completed Topics: ${_completedTopics.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B894)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final module = _modules[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showModuleDetailsSheet(module),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF6C5CE7)
                                .withValues(alpha: 0.1),
                            child: Text(
                              "${module['moduleNumber'] ?? index + 1}",
                              style: const TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  module['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}