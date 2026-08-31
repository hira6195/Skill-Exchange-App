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
  bool _isLoading = true;
  bool _isUploading = false;
  bool _hasAlreadyVerified = false;
  String _verificationStatus = ''; // 'pending', 'approved', 'rejected'
  String _existingSkillName = '';

  @override
  void initState() {
    super.initState();
    _checkExistingVerification();
  }

  /// Check Firestore for existing verification status
  Future<void> _checkExistingVerification() async {
    setState(() => _isLoading = true);
    try {
      final certData = await _certificateService.getUserVerificationStatus();
      if (certData != null) {
        setState(() {
          _hasAlreadyVerified = true;
          _verificationStatus = certData['status'] ?? 'pending';
          _existingSkillName = certData['skillName'] ?? '';
          _skillController.text = _existingSkillName;
        });
      }
    } catch (e) {
      debugPrint("Error checking verification status: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
    if (_hasAlreadyVerified && _verificationStatus != 'rejected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Free Tier Limit: You have already submitted a certificate for verification."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      File? file = await _certificateService.pickCertificate();
      if (file != null) {
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
      _isUploading = true;
    });

    try {
      // 1. Upload Certificate & save to Firestore
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
        _isUploading = false;
        _hasAlreadyVerified = true;
        _verificationStatus = 'pending';
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

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusBanner() {
    Color bannerColor = Colors.orange;
    IconData icon = Icons.hourglass_top;
    String message = "Your certificate is under review.";

    if (_verificationStatus == 'approved') {
      bannerColor = Colors.green;
      icon = Icons.check_circle_outline;
      message = "Skill verified successfully!";
    } else if (_verificationStatus == 'rejected') {
      bannerColor = Colors.red;
      icon = Icons.error_outline;
      message = "Certificate rejected. Please re-upload a valid document.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        border: Border.all(color: bannerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: bannerColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff6A1B9A)),
        ),
      );
    }

    final bool isFormDisabled = _hasAlreadyVerified && _verificationStatus != 'rejected';

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
                const SizedBox(height: 25),

                if (_hasAlreadyVerified) _buildStatusBanner(),

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
                          Icons.picture_as_pdf_rounded,
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
                  enabled: !isFormDisabled,
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
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xff6A1B9A), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (isFormDisabled) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Free Plan Limit: You can only verify 1 skill in the free plan. Upgrade to Premium to verify more skills.",
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (isFormDisabled || _isUploading) ? null : _uploadCertificate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6A1B9A),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      isFormDisabled ? "Already Submitted" : "Upload Certificate",
                      style: TextStyle(
                        color: isFormDisabled ? Colors.grey.shade600 : Colors.white,
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