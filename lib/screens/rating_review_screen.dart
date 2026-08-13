import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'certificate_screen.dart';

class RatingReviewScreen extends StatefulWidget {
  final String teacherName;
  final String teacherId;
  final String bookingId;

  const RatingReviewScreen({
    super.key,
    required this.teacherName,
    required this.teacherId,
    required this.bookingId,
  });

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a short review comment.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch student & skill info from learning_progress or booking
      final progressDoc = await firestore
          .collection('learning_progress')
          .doc(widget.bookingId)
          .get();

      final String studentId = progressDoc.data()?['studentId'] ?? '';
      final String skill = progressDoc.data()?['skill'] ?? 'Course';

      // 2. Fetch student name
      String studentName = 'Student';
      if (studentId.isNotEmpty) {
        final studentDoc = await firestore.collection('users').doc(studentId).get();
        if (studentDoc.exists) {
          studentName = studentDoc.data()?['name'] ?? 'Student';
        }
      }

      // 3. Save review to Firestore
      await firestore.collection('reviews').add({
        'bookingId': widget.bookingId,
        'teacherId': widget.teacherId,
        'studentId': studentId,
        'studentName': studentName,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating & Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // 4. Navigate directly to Certificate Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CertificateScreen(
            studentName: studentName,
            courseName: skill,
            instructorName: widget.teacherName,
            issueDate: DateTime.now().toString().split(' ')[0],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rating & Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'How was your learning session with ${widget.teacherName}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Star Rating Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Review Input Field
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your feedback here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit & Claim Certificate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}