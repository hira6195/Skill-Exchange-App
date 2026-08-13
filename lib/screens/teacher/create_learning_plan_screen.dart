import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateLearningPlanScreen extends StatefulWidget {
  const CreateLearningPlanScreen({Key? key}) : super(key: key);

  @override
  State<CreateLearningPlanScreen> createState() => _CreateLearningPlanScreenState();
}

class _CreateLearningPlanScreenState extends State<CreateLearningPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _skillController = TextEditingController(text: 'Flutter');
  final TextEditingController _durationController = TextEditingController(text: '3 Months');

  // Dynamic Modules Controllers List
  final List<TextEditingController> _moduleControllers = [
    TextEditingController(text: 'Module 1: Basics & Fundamentals'),
    TextEditingController(text: 'Module 2: Advanced Concepts'),
  ];

  bool _isLoading = false;

  // Add Module Field dynamically
  void _addModuleField() {
    setState(() {
      _moduleControllers.add(TextEditingController());
    });
  }

  // Remove Module Field
  void _removeModuleField(int index) {
    if (_moduleControllers.length > 1) {
      setState(() {
        _moduleControllers[index].dispose();
        _moduleControllers.removeAt(index);
      });
    }
  }

  // Save Plan to Firestore
  Future<void> _saveLearningPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Convert controllers list to String list
    List<String> modulesList = _moduleControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    try {
      await FirebaseFirestore.instance.collection('learning_plans').add({
        'teacherId': teacherId,
        'skill': _skillController.text.trim(),
        'duration': _durationController.text.trim(),
        'modules': modulesList,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Learning Plan Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    _durationController.dispose();
    for (var controller in _moduleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Learning Plan'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skill Input Field
              const Text('Skill Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _skillController,
                decoration: InputDecoration(
                  hintText: 'e.g. Flutter, React, Python',
                  prefixIcon: const Icon(Icons.code),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter skill name' : null,
              ),
              const SizedBox(height: 20),

              // Duration Input Field
              const Text('Estimated Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  hintText: 'e.g. 3 Months, 6 Weeks',
                  prefixIcon: const Icon(Icons.timer_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter estimated duration' : null,
              ),
              const SizedBox(height: 24),

              // Modules List Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Modules Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: _addModuleField,
                    icon: const Icon(Icons.add, color: Colors.deepPurple),
                    label: const Text('Add Module', style: TextStyle(color: Colors.deepPurple)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dynamic List of Module Fields
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _moduleControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _moduleControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Module ${index + 1}',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Module cannot be empty' : null,
                          ),
                        ),
                        if (_moduleControllers.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeModuleField(index),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLearningPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Save Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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