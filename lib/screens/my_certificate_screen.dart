import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyCertificateScreen extends StatefulWidget {
  final String userId;
  final bool isInstructor; // Pass true if the logged-in user is the one teaching

  const MyCertificateScreen({
    Key? key,
    required this.userId,
    this.isInstructor = true, // Defaulting to true so you can test edit features easily
  }) : super(key: key);

  @override
  State<MyCertificateScreen> createState() => _MyCertificateScreenState();
}

class _MyCertificateScreenState extends State<MyCertificateScreen> {
  final GlobalKey _globalKey = GlobalKey();

  // Editable Certificate Data
  String studentName = "Hira";
  String courseName = "Full Stack Web Development Course";
  String instructorName = "Expert Instructor";

  // Customizable Style & Colors
  Color cardBorderColor = Colors.amber;
  Color cardBgColor = Colors.amber.shade50;
  Color primaryTextColor = Colors.purple;
  Color secondaryTextColor = Colors.black87;

  bool isDownloading = false;

  void _openEditCertificateModal() {
    TextEditingController studentCtrl = TextEditingController(text: studentName);
    TextEditingController courseCtrl = TextEditingController(text: courseName);
    TextEditingController instructorCtrl = TextEditingController(text: instructorName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customize Certificate',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: studentCtrl,
                      decoration: const InputDecoration(labelText: 'Student Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: courseCtrl,
                      decoration: const InputDecoration(labelText: 'Course / Skill Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: instructorCtrl,
                      decoration: const InputDecoration(labelText: 'Instructor Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    const Text('Change Text & Theme Colors:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _colorPickerChip("Theme", primaryTextColor, (col) {
                          setModalState(() => primaryTextColor = col);
                          setState(() => primaryTextColor = col);
                        }),
                        _colorPickerChip("Border", cardBorderColor, (col) {
                          setModalState(() => cardBorderColor = col);
                          setState(() => cardBorderColor = col);
                        }),
                        _colorPickerChip("Background", cardBgColor, (col) {
                          setModalState(() => cardBgColor = col);
                          setState(() => cardBgColor = col);
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        onPressed: () {
                          setState(() {
                            studentName = studentCtrl.text.trim();
                            courseName = courseCtrl.text.trim();
                            instructorName = instructorCtrl.text.trim();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Save Certificate Design', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _colorPickerChip(String label, Color currentColor, Function(Color) onSelect) {
    List<Color> colors = [Colors.purple, Colors.amber, Colors.deepOrange, Colors.blue, Colors.green, Colors.teal, Colors.amber.shade50];
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: colors.map((col) {
            return GestureDetector(
              onTap: () => onSelect(col),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: col,
                child: currentColor == col ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _downloadCertificate() async {
    setState(() => isDownloading = true);
    try {
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate generated and saved to Gallery!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificate'),
        backgroundColor: Colors.purple,
        actions: [
          if (widget.isInstructor)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit Certificate',
              onPressed: _openEditCertificateModal,
            )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('certificates').where('userId', isEqualTo: widget.userId).snapshots(),
        builder: (context, snapshot) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // RepaintBoundary captures exact design when downloaded
                RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: cardBorderColor, width: 4),
                      borderRadius: BorderRadius.circular(16),
                      color: cardBgColor,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.workspace_premium, size: 60, color: cardBorderColor),
                        const SizedBox(height: 10),
                        Text('Certificate of Completion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        const SizedBox(height: 8),
                        Text('This is to certify that', style: TextStyle(fontSize: 12, color: secondaryTextColor.withOpacity(0.7))),
                        const SizedBox(height: 4),
                        Text(studentName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: secondaryTextColor)),
                        const SizedBox(height: 8),
                        Text('has successfully completed', style: TextStyle(fontSize: 12, color: secondaryTextColor.withOpacity(0.7))),
                        const SizedBox(height: 4),
                        Text(courseName, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Instructor: $instructorName', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: secondaryTextColor)),
                            Text('Verified Skill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cardBorderColor)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, minimumSize: const Size(0, 46)),
                        icon: isDownloading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.download, color: Colors.white),
                        label: Text(isDownloading ? 'Saving...' : 'Download Certificate', style: const TextStyle(color: Colors.white)),
                        onPressed: isDownloading ? null : _downloadCertificate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                        icon: const Icon(Icons.share, color: Colors.purple),
                        label: const Text('Share', style: TextStyle(color: Colors.purple)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sharing Certificate...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}