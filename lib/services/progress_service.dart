import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> endSessionAndInitializeProgress({
    required String bookingId,
    required String studentId,
    required String teacherId,
    required String skill,
  }) async {
    String targetDocId = bookingId;

    // 1. Find the real Firestore Document ID using internal 'bookingId' field
    final querySnapshot = await _firestore
        .collection('bookings')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      targetDocId = querySnapshot.docs.first.id;
    } else {
      // Fallback: check if document exists directly by Document ID
      final directDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!directDoc.exists) {
        throw Exception("Booking document not found for ID or field '$bookingId'");
      }
    }

    // 2. Update booking status safely using actual Document ID
    await _firestore.collection('bookings').doc(targetDocId).update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // 3. Initialize Learning Progress document
    final progressRef = _firestore.collection('learning_progress').doc(bookingId);

    await progressRef.set({
      'bookingId': bookingId,
      'studentId': studentId,
      'teacherId': teacherId,
      'skill': skill,
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 4. Initialize default learning modules
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
  }
}