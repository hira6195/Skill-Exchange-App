import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class RecordedSessionsScreen extends StatefulWidget {
  const RecordedSessionsScreen({super.key});

  @override
  State<RecordedSessionsScreen> createState() => _RecordedSessionsScreenState();
}

class _RecordedSessionsScreenState extends State<RecordedSessionsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // Gallery se Video pick karke Upload karne ka Function
  Future<void> _pickAndUploadVideo(BuildContext context) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final TextEditingController titleController = TextEditingController();

    // Video ka Title lene ke liye Dialog
    if (!mounted) return;
    final bool? shouldUpload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Recorded Session'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Session / Skill Title',
            hintText: 'e.g. Flutter Advanced Live Class',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Upload', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldUpload != true) return;

    setState(() => _isUploading = true);

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('recorded_sessions/${currentUser.uid}/$fileName');

      // Firebase Storage me upload
      final UploadTask uploadTask = storageRef.putFile(File(video.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore me document save karna
      await _firestore.collection('bookings').add({
        'userId': currentUser.uid,
        'expertId': currentUser.uid,
        'userName': currentUser.displayName ?? 'User',
        'expertName': 'Self Uploaded',
        'skill': titleController.text.trim().isNotEmpty
            ? titleController.text.trim()
            : 'Custom Recording',
        'recordingUrl': downloadUrl,
        'date': FieldValue.serverTimestamp(),
        'isGalleryUpload': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploaded & saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Record Delete karne ka function
  Future<void> _deleteRecording(String docId) async {
    try {
      await _firestore.collection('bookings').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

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
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.video_call_rounded, color: Colors.deepPurple, size: 28),
              tooltip: 'Upload Video from Gallery',
              onPressed: _isUploading ? null : () => _pickAndUploadVideo(context),
            ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('Please log in to view recordings.'))
          : Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('bookings').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final recordedSessions = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bool isUserInvolved = data['userId'] == currentUser.uid ||
                    data['expertId'] == currentUser.uid;
                final bool hasRecording = data.containsKey('recordingUrl') &&
                    data['recordingUrl'] != null &&
                    data['recordingUrl'].toString().trim().isNotEmpty;

                return isUserInvolved && hasRecording;
              }).toList();

              if (recordedSessions.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: recordedSessions.length,
                itemBuilder: (context, index) {
                  final doc = recordedSessions[index];
                  final session = doc.data() as Map<String, dynamic>;

                  final String expertName = session['expertName'] ?? 'Expert';
                  final String userName = session['userName'] ?? 'User';
                  final String skill = session['skill'] ?? 'Skill Session';
                  final String recordingUrl = session['recordingUrl'] ?? '';
                  final Timestamp? timestamp = session['date'] as Timestamp?;
                  final String dateStr = timestamp != null
                      ? timestamp.toDate().toString().split(' ')[0]
                      : 'Recent';

                  final bool isCurrentUserExpert = session['expertId'] == currentUser.uid;
                  final String partnerName = isCurrentUserExpert ? userName : expertName;
                  final String roleLabel = isCurrentUserExpert ? 'Learner' : 'Mentor';
                  final bool isGalleryUpload = session['isGalleryUpload'] == true;

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
                        child: Icon(
                          isGalleryUpload ? Icons.file_upload_outlined : Icons.play_circle_fill_rounded,
                          color: Colors.deepPurple,
                          size: 30,
                        ),
                      ),
                      title: Text(
                        '$skill Session',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isGalleryUpload ? 'Type: Custom Upload' : '$roleLabel: $partnerName'),
                            const SizedBox(height: 2),
                            Text(
                              'Recorded on: $dateStr',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _showVideoPreviewDialog(
                                context,
                                skill: skill,
                                partnerName: partnerName,
                                recordingUrl: recordingUrl,
                                date: dateStr,
                              );
                            },
                            icon: const Icon(Icons.videocam_rounded, size: 16, color: Colors.white),
                            label: const Text('Watch', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                            onPressed: () => _deleteRecording(doc.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.deepPurple),
                        SizedBox(height: 12),
                        Text('Uploading Video to Account...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showVideoPreviewDialog(
      BuildContext context, {
        required String skill,
        required String partnerName,
        required String recordingUrl,
        required String date,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$skill - Recording',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 56),
                    const SizedBox(height: 8),
                    Text('Ready to Stream Recording', style: TextStyle(color: Colors.grey.shade300)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Participant / Detail: $partnerName'),
              Text('Date: $date'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Streaming from: $recordingUrl'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Start Playback', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Recorded Sessions Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Recorded meeting sessions or videos uploaded from your gallery will appear here persistently.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              onPressed: () => _pickAndUploadVideo(context),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Upload Video from Gallery', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}