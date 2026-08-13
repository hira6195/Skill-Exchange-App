import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class UpcomingSessionsScreen extends StatelessWidget {
  const UpcomingSessionsScreen({super.key});

  // Direct Meeting URL Launch Logic
  Future<void> _launchMeetingUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);

    try {
      final canLaunch = await canLaunchUrl(url);
      if (!context.mounted) return;

      if (canLaunch) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackBar(context, 'Could not open link: $urlString');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Invalid meeting link or error opening app.');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLearnerId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Sessions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch sessions where status is 'Accepted' for logged in learner
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('learnerId', isEqualTo: currentLearnerId)
            .where('status', isEqualTo: 'Accepted')
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
                'No upcoming sessions scheduled.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final sessions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final doc = sessions[index];
              final data = doc.data() as Map<String, dynamic>;

              final String teacherName = data['teacherName'] ?? 'Teacher';
              final String skill = data['skill'] ?? 'Flutter';
              final String date = data['date'] ?? 'N/A';
              final String time = data['time'] ?? 'N/A';
              final String status = data['status'] ?? 'Accepted';
              final String meetingPlatform = data['meetingPlatform'] ?? 'Google Meet';
              final String? meetingUrl = data['meetingUrl'];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Teacher Name & Status Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
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
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  backgroundColor: Colors.purple.shade50,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Schedule Details
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(date, style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 20),
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Platform Badge
                      Row(
                        children: [
                          const Icon(Icons.video_call, size: 18, color: Colors.deepPurple),
                          const SizedBox(width: 6),
                          Text(
                            'Platform: $meetingPlatform',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Direct Join Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (meetingUrl != null && meetingUrl.isNotEmpty) {
                              _launchMeetingUrl(context, meetingUrl);
                            } else {
                              _showErrorSnackBar(
                                context,
                                'Meeting link has not been updated by the teacher yet.',
                              );
                            }
                          },
                          icon: const Icon(Icons.video_call_rounded, color: Colors.white),
                          label: const Text(
                            'Join Meeting',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
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
}