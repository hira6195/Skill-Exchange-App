import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Existing method ...

  /// Update individual module completion and progress percentage
  Future<void> updateModuleProgress({
    required String bookingId,
    required int completedModuleIndex,
    required String studentId,
    required String teacherId,
  }) async {
    final progressRef = _firestore.collection('learning_progress').doc(bookingId);
    final modulesRef = progressRef.collection('modules');

    // 1. Mark current module as Completed
    await modulesRef.doc('module_$completedModuleIndex').set({
      'status': 'Completed',
    }, SetOptions(merge: true));

    // 2. Unlock/Set next module to 'In Progress' if it exists
    final nextModuleIndex = completedModuleIndex + 1;
    final nextModuleDoc = await modulesRef.doc('module_$nextModuleIndex').get();

    if (nextModuleDoc.exists) {
      await modulesRef.doc('module_$nextModuleIndex').set({
        'status': 'In Progress',
      }, SetOptions(merge: true));
    }

    // 3. Calculate new progress percentage (e.g., 5 modules = 20% per module)
    final int newProgress = (completedModuleIndex * 20).clamp(0, 100);

    // 4. Update overall progress in parent document
    await progressRef.set({
      'progress': newProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}