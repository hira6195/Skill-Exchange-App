import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/learning_progress_screen.dart';

class LearnerProgressDashboardCard extends StatelessWidget {
  const LearnerProgressDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      // STEP 4 Condition: studentId == currentUser AND status == Completed
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('studentId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Locked / Hidden if no completed meeting exists
          return const SizedBox.shrink();
        }

        // Active Completed Booking exists -> Get First Active
        final bookingData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final String bookingId = snapshot.data!.docs.first.id;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('learning_progress')
              .doc(bookingId)
              .snapshots(),
          builder: (context, progressSnapshot) {
            if (!progressSnapshot.hasData || !progressSnapshot.data!.exists) {
              return const SizedBox.shrink();
            }

            final progressData = progressSnapshot.data!.data() as Map<String, dynamic>;
            final int progress = progressData['progress'] ?? 0;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  'Learning Progress: ${progressData['skill']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.purple.shade100,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 6),
                    Text('$progress% Completed', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.deepPurple),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LearningProgressScreen(bookingId: bookingId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}