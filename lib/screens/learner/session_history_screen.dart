import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rating_review_screen.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch sessions where status is either 'Completed' or 'Rejected'
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('learnerId', isEqualTo: currentUserId)
            .where('status', whereIn: ['Completed', 'Rejected'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No past session history found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final sessions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final data = sessions[index].data() as Map<String, dynamic>;

              final String teacherId = data['teacherId'] ?? '';
              final String teacherName = data['teacherName'] ?? 'Teacher';
              final String skill = data['skill'] ?? 'Skill Course';
              final String date = data['date'] ?? 'N/A';
              final String time = data['time'] ?? 'N/A';
              final String status = data['status'] ?? 'Completed';
              final bool isCompleted = status == 'Completed';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Teacher Name & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacherName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(
                                  skill,
                                  style: const TextStyle(fontSize: 11, color: Colors.deepPurple),
                                ),
                                backgroundColor: Colors.purple.shade50,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const Divider(height: 20),

                      // Session Timing Info
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(date, style: const TextStyle(color: Colors.black87)),
                          const SizedBox(width: 20),
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(time, style: const TextStyle(color: Colors.black87)),
                        ],
                      ),

                      // Rate & Review Option (Only for Completed Sessions)
                      if (isCompleted) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RatingReviewScreen(
                                    teacherId: teacherId,
                                    teacherName: teacherName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.star_outline, color: Colors.amber),
                            label: const Text(
                              'Rate & Review Session',
                              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.deepPurple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper Widget for Status Display
  Widget _buildStatusBadge(String status) {
    final bool isCompleted = status == 'Completed';
    final Color color = isCompleted ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}