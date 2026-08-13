import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordedSessionsScreen extends StatelessWidget {
  const RecordedSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Recorded Sessions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: currentUser == null
          ? const Center(child: Text('Please log in to view recordings.'))
          : StreamBuilder<QuerySnapshot>(
        // صرف ان سیشنز کو لے کر آئے گا جن میں ریکارڈنگ موجود ہو اور جن میں کرنٹ یوزر شامل ہو
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // فلٹر کریں کہ ریکارڈنگ کا لنک موجود ہے یا نہیں
          final recordedSessions = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data.containsKey('recordingUrl') &&
                data['recordingUrl'] != null &&
                data['recordingUrl'].toString().isNotEmpty;
          }).toList();

          if (recordedSessions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: recordedSessions.length,
            itemBuilder: (context, index) {
              final session =
              recordedSessions[index].data() as Map<String, dynamic>;

              final String expertName =
                  session['expertName'] ?? 'Expert';
              final String skill = session['skill'] ?? 'Skill Session';
              final String recordingUrl = session['recordingUrl'] ?? '';
              final Timestamp? timestamp = session['date'] as Timestamp?;
              final String dateStr = timestamp != null
                  ? timestamp.toDate().toString().split(' ')[0]
                  : 'Recent';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.deepPurple,
                      size: 32,
                    ),
                  ),
                  title: Text(
                    '$skill Session',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mentor: $expertName'),
                        const SizedBox(height: 2),
                        Text(
                          'Recorded on: $dateStr',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (recordingUrl.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Opening Recording: $recordingUrl',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // یہاں ویڈیو پلیئر یا سکرین نیویگیشن اوپن کی جا سکتی ہے
                      }
                    },
                    icon: const Icon(
                      Icons.videocam_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Watch',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined,
                size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Recorded Sessions Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a session and turn on recording during your live meeting. Your recorded videos will automatically appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}