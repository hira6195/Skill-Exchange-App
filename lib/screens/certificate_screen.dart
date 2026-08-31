import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class CertificateScreen extends StatefulWidget {
  final String studentName;
  final String courseName;
  final String instructorName;
  final String issueDate;

  const CertificateScreen({
    super.key,
    required this.studentName,
    required this.courseName,
    required this.instructorName,
    required this.issueDate,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  late String _currentStudentName;
  late String _currentCourseName;
  final GlobalKey _globalKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentStudentName = widget.studentName.isNotEmpty ? widget.studentName : "Student Name";
    _currentCourseName = widget.courseName;
  }

  void _showEditCertificateDialog() {
    final TextEditingController nameController = TextEditingController(text: _currentStudentName);
    final TextEditingController courseController = TextEditingController(text: _currentCourseName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Certificate Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Student Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: courseController,
              decoration: const InputDecoration(labelText: "Course / Skill Name"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () {
              setState(() {
                _currentStudentName = nameController.text.trim();
                _currentCourseName = courseController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadToGallery() async {
    setState(() => _isSaving = true);
    try {
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // امیج سیکیور رینڈر ہو چکی ہے
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate downloaded & saved to Gallery successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save certificate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Verified Certificate', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6C5CE7), size: 26),
            tooltip: 'Edit Certificate Name',
            onPressed: _showEditCertificateDialog,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6C5CE7), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 60, color: Colors.amber),
                    const SizedBox(height: 8),
                    const Text(
                      'CERTIFICATE OF ACHIEVEMENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF2D1B2E)),
                    ),
                    const SizedBox(height: 4),
                    const Text('PROUDLY PRESENTED TO', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Text(
                      _currentStudentName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7), fontStyle: FontStyle.italic),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.0),
                      child: Divider(thickness: 1.5, color: Color(0xFF6C5CE7)),
                    ),
                    const SizedBox(height: 12),
                    const Text('for successfully completing the skill assessment test on', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(_currentCourseName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.instructorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Instructor', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(widget.issueDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Issued Date', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _downloadToGallery,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.file_download_outlined, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving to Gallery...' : 'Download to Gallery / Storage',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}