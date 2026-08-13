import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'learning_progress_screen.dart';

class JoinSessionScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const JoinSessionScreen({super.key, required this.bookingData});

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  bool _isLoading = false;

  Future<void> _endSessionAndUnlockProgress() async {
    setState(() => _isLoading = true);

    final String bookingId = widget.bookingData['bookingId'] ?? '';
    final String studentId = widget.bookingData['studentId'] ?? '';
    final String teacherId = widget.bookingData['teacherId'] ?? '';
    final String skill = widget.bookingData['skill'] ?? '';

    try {
      final firestore = FirebaseFirestore.instance;
      String targetDocId = bookingId;

      // 1. Search document by interior field 'bookingId' if direct lookup fails
      final querySnapshot = await firestore
          .collection('bookings')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Found document via query (Fixes auto-generated doc ID issue)
        targetDocId = querySnapshot.docs.first.id;
      } else {
        // Fallback check direct doc
        final directDoc = await firestore.collection('bookings').doc(bookingId).get();
        if (!directDoc.exists) {
          throw Exception("No booking document found for ID '$bookingId'");
        }
      }

      // 2. Safely update booking status using actual document ID
      await firestore.collection('bookings').doc(targetDocId).update({
        'status': 'Completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 3. Initialize Learning Progress entry
      final progressRef = firestore.collection('learning_progress').doc(bookingId);

      await progressRef.set({
        'bookingId': bookingId,
        'studentId': studentId,
        'teacherId': teacherId,
        'skill': skill,
        'teacherName': widget.bookingData['teacherName'] ?? '',
        'progress': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Initialize default subcollection modules
      final modulesRef = progressRef.collection('modules');
      final modulesSnapshot = await modulesRef.get();

      if (modulesSnapshot.docs.isEmpty) {
        final List<Map<String, String>> defaultModules = [
          {'title': 'Module 1: Basics & Introduction', 'status': 'In Progress'},
          {'title': 'Module 2: Core Concepts', 'status': 'Locked'},
          {'title': 'Module 3: Advanced Topics', 'status': 'Locked'},
          {'title': 'Module 4: Final Practical Assessment', 'status': 'Locked'},
        ];

        for (int i = 0; i < defaultModules.length; i++) {
          await modulesRef.doc('module_${i + 1}').set({
            ...defaultModules[i],
            'order': i + 1,
          });
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Navigate to Learning Progress Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LearningProgressScreen(bookingId: bookingId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String teacherName = widget.bookingData['teacherName'] ?? 'Teacher';
    final String skill = widget.bookingData['skill'] ?? 'Skill Course';
    final String sessionDate = widget.bookingData['sessionDate'] ?? '2026-10-30';
    final String sessionTime = widget.bookingData['sessionTime'] ?? '11:00 AM';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Join Session', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Teacher & Session Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    teacherName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skill,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoTile(Icons.calendar_month_outlined, sessionDate),
                      _buildInfoTile(Icons.access_time_outlined, sessionTime),
                      _buildInfoTile(Icons.timer_outlined, '60 Mins'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Countdown / Timer Card
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: const [
                  Text(
                    'Session Starts In',
                    style: TextStyle(fontSize: 14, color: Colors.deepPurple, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '00:14:40',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joining Video Session...')),
                  );
                },
                icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                label: const Text('Join Meeting Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // End Session & Unlock Progress Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _endSessionAndUnlockProgress,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                )
                    : const Icon(Icons.check_circle_outline_rounded, color: Colors.red),
                label: const Text(
                  'End Session & Unlock Progress',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}