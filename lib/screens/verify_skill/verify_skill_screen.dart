import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skill_exchange/screens/assessment/assessment_intro_screen.dart';
import 'package:skill_exchange/services/certificate_service.dart';
import 'package:skill_exchange/services/gemini_service.dart';

class VerifySkillScreen extends StatefulWidget {
  const VerifySkillScreen({super.key});

  @override
  State<VerifySkillScreen> createState() => _VerifySkillScreenState();
}

class _VerifySkillScreenState extends State<VerifySkillScreen> {
  final CertificateService _certificateService = CertificateService();
  final TextEditingController _skillController = TextEditingController();

  File? _selectedCertificate;
  bool _isLoading = false;

  /// Helper method to extract file name
  String _getFileName(String filePath) {
    return filePath.split(Platform.pathSeparator).last;
  }

  /// Helper method to check if the selected file is PDF or Word
  bool _isValidDocument(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return extension == 'pdf' || extension == 'doc' || extension == 'docx';
  }

  Future<void> _pickCertificate() async {
    try {
      File? file = await _certificateService.pickCertificate();
      if (file != null) {
        // Validate file extension for PDF / Word only
        if (_isValidDocument(file.path)) {
          setState(() {
            _selectedCertificate = file;
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Only PDF and Word documents (.pdf, .doc, .docx) are allowed!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: ${e.toString()}")),
      );
    }
  }

  Future<void> _uploadCertificate() async {
    final skillName = _skillController.text.trim();

    if (skillName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter skill name")),
      );
      return;
    }

    if (_selectedCertificate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a certificate")),
      );
      return;
    }

    // Double check file validation before upload
    if (!_isValidDocument(_selectedCertificate!.path)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a valid PDF or Word document"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload Certificate to Firebase / Storage
      await _certificateService.uploadCertificate(
        skillName: skillName,
        certificate: _selectedCertificate!,
      );

      // 2. Pre-fetch / Validate AI Dynamic Quiz
      await GeminiService().generateDynamicQuiz(
        skill: skillName,
        certificateText: "Certificate for $skillName",
        targetQuestionCount: 5,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Certificate uploaded & Quiz generated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // 3. Navigate to Assessment Intro Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentIntroScreen(
            skillName: skillName,
            certificateText: "Certificate for $skillName",
          ),
        ),
      );

      // Reset Form State
      _skillController.clear();
      setState(() {
        _selectedCertificate = null;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text(
                        "Verify Your Skill",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff4A148C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Upload a PDF or Word certificate to verify your skill.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                GestureDetector(
                  onTap: _pickCertificate,
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xffFCE4EC).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xffF8BBD0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded, // File Icon
                          size: 60,
                          color: Color(0xff6A1B9A),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _selectedCertificate != null
                                ? _getFileName(_selectedCertificate!.path)
                                : "Upload PDF or Word Document",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: const TextSpan(
                            text: "Supports ",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            children: [
                              TextSpan(
                                text: ".pdf, .doc, .docx",
                                style: TextStyle(
                                  color: Color(0xff6A1B9A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                const Text(
                  "Skill Name",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _skillController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "UI/UX design",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xff6A1B9A), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _uploadCertificate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6A1B9A),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      "Upload Certificate",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}