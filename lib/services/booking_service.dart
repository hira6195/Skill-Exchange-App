import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:skill_exchange/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Confirm Booking - Create Document in Firestore
  Future<bool> createBooking({
    required String expertId,
    required String expertName,
    required String skill,
    required double amount,
    DateTime? date,
  }) async {
    try {
      final uid = currentUserId ?? 'guest_user';
      final docRef = _firestore.collection('bookings').doc();
      final selectedDate = date ?? DateTime.now();

      final newBooking = BookingModel(
        bookingId: docRef.id,
        studentId: uid,
        studentName: _auth.currentUser?.displayName ?? 'Student',
        teacherId: expertId,
        teacherName: expertName,
        skill: skill,
        sessionDate: DateFormat('dd MMMM yyyy').format(selectedDate),
        sessionTime: '10:00 AM',
        sessionType: 'One-on-One',
        duration: '1 Hour',
        notes: 'Booked via Expert Screen',
        status: 'Confirmed',
        bookingDate: DateTime.now(),
      );

      await docRef.set(newBooking.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return false;
    }
  }

  // Stream user's bookings (as a student) for MyBookingsScreen
  Stream<List<BookingModel>> getUserBookingsStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('bookings')
        .where('studentId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by booking timestamp descending (newest first)
      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      return bookings;
    });
  }

  // Save Session Recording URL & Update Status to Completed
  Future<bool> saveSessionRecording({
    required String bookingId,
    required String recordingUrl,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'recordingUrl': recordingUrl,
        'status': 'completed',
      });
      return true;
    } catch (e) {
      debugPrint('Error saving recording: $e');
      return false;
    }
  }
}