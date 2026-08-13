import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressDetailScreen extends StatelessWidget {
  final String planId; // Document ID of the learning_plan in Firestore

  const ProgressDetailScreen({Key? key, required this.planId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Progress Detail'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('learning_plans')
            .doc(planId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Fallback Dummy Data View for UI Testing / Preview
            return _buildWeeklyList(_getDummyWeeklyData());
          }

          final planData = snapshot.data!.data() as Map<String, dynamic>;

          // Expecting 'weeklyProgress' list from Firestore
          // Structure: [{'week': 'Week 1', 'status': 'Completed'}, ...]
          final List<dynamic> weeklyData = planData['weeklyProgress'] ?? _getDummyWeeklyData();

          return _buildWeeklyList(weeklyData);
        },
      ),
    );
  }

  // Build Week List UI
  Widget _buildWeeklyList(List<dynamic> weeklyData) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: weeklyData.length,
      itemBuilder: (context, index) {
        final item = weeklyData[index] as Map<String, dynamic>;
        final String weekName = item['week'] ?? 'Week ${index + 1}';
        final String status = item['status'] ?? 'Pending';
        final bool isCompleted = status.toLowerCase() == 'completed';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: CircleAvatar(
              backgroundColor: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.hourglass_top_rounded,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(
              weekName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              item['topic'] ?? 'Module topics and practice sessions',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isCompleted ? Colors.green.shade800 : Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Dummy fallback data matching the requested UI structure
  List<Map<String, dynamic>> _getDummyWeeklyData() {
    return [
      {'week': 'Week 1', 'status': 'Completed', 'topic': 'Setup & Dart Basics'},
      {'week': 'Week 2', 'status': 'Completed', 'topic': 'Widgets & Layouts'},
      {'week': 'Week 3', 'status': 'Pending', 'topic': 'State Management (Bloc/Provider)'},
      {'week': 'Week 4', 'status': 'Pending', 'topic': 'API Integration & Capstone'},
    ];
  }
}