import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddNewSkillScreen extends StatefulWidget {
  const AddNewSkillScreen({super.key});

  @override
  State<AddNewSkillScreen> createState() => _AddNewSkillScreenState();
}

class _AddNewSkillScreenState extends State<AddNewSkillScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController _skillNameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedCategory = "Design"; // Default value matching image
  String? _selectedLevel = "Beginner";   // Default value placeholder

  bool _isSaving = false;

  final List<String> _categories = ["Design", "Development", "Marketing", "Business"];
  final List<String> _levels = ["Beginner", "Intermediate", "Advanced"];

  Future<void> _saveSkillToFirestore() async {
    final user = _auth.currentUser;
    if (user == null || _skillNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a skill name")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Image design ke mutabiq decide karenge ke kis array me save krna hai.
      // Default hum teachSkills ya learnSkills manage kr skte hain base on category choose.
      String dbField = _selectedCategory == "Design" ? "teachSkills" : "learnSkills";

      await _firestore.collection("users").doc(user.uid).update({
        dbField: FieldValue.arrayUnion([_skillNameController.text.trim()])
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Skill added successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Wapis profile update screen pe bheje ga
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add New Skill",
          style: TextStyle(color: Color(0xff6A1B9A), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill Name
            _buildLabel("Skill Name"),
            TextField(
              controller: _skillNameController,
              decoration: _buildInputDecoration(),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            _buildLabel("Category"),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: _buildInputDecoration(),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            // Level Dropdown
            _buildLabel("Level"),
            DropdownButtonFormField<String>(
              initialValue: _selectedLevel,
              decoration: _buildInputDecoration(),
              items: _levels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
              onChanged: (val) => setState(() => _selectedLevel = val),
            ),
            const SizedBox(height: 20),

            // Description Field
            _buildLabel("Description"),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: _buildInputDecoration(),
            ),
            const SizedBox(height: 40),

            // Save Skill Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSkillToFirestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6A1B9A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Skill",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff6A1B9A), width: 1.5),
      ),
    );
  }
}