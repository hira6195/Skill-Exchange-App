import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rating_review_screen.dart';

class LearningProgressScreen extends StatelessWidget {
  final String bookingId;

  const LearningProgressScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Progress', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('learning_progress').doc(bookingId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No active learning progress found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int overallProgress = data['progress'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Top Cards (Overview)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['skill'] ?? 'Skill Course',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '$overallProgress%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: overallProgress / 100,
                        backgroundColor: Colors.purple.shade100,
                        color: Colors.deepPurple,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Realtime Subcollection: Modules List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('learning_progress')
                        .doc(bookingId)
                        .collection('modules')
                        .snapshots(),
                    builder: (context, modSnapshot) {
                      if (!modSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final modules = modSnapshot.data!.docs;

                      return ListView.builder(
                        itemCount: modules.length,
                        itemBuilder: (context, index) {
                          final mod = modules[index].data() as Map<String, dynamic>;
                          final String status = mod['status'] ?? 'Locked';

                          Color badgeColor = Colors.grey;
                          if (status == 'Completed') badgeColor = Colors.green;
                          if (status == 'In Progress') badgeColor = Colors.orange;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: badgeColor.withValues(alpha: 0.15),
                                child: Text('${index + 1}', style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(mod['title'] ?? 'Module', style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Chip(
                                label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                                backgroundColor: badgeColor,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // STEP 8: Rate & Review Unlock Logic (If 100% Complete)
                if (overallProgress == 100)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RatingReviewScreen(
                              teacherName: data['teacherName'] ?? 'Teacher',
                              teacherId: data['teacherId'] ?? '',
                              bookingId: bookingId, // Fixed: Added missing bookingId parameter
                            ),
                          ),
                        );
                      },
                      child: const Text('Leave Rating & Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}