import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:skill_exchange/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Confirm Booking - Create Document(s) in Firestore
  Future<bool> createBooking({
    required String expertId,
    required String expertName,
    required String skill,
    required double amount,
    DateTime? date,
    String sessionTime = '10:00 AM',
    String sessionType = 'Online',
    String duration = '60 Minutes',
    String notes = '',
    required int totalSessions,
    required int sessionNumber,
  }) async {
    try {
      final uid = currentUserId ?? 'guest_user';
      final selectedDate = date ?? DateTime.now();

      // Double-Booking Check (Availability Match)
      final isSlotBusy = await isTimeSlotBooked(
        expertId: expertId,
        dateFormatted: DateFormat('dd MMMM yyyy').format(selectedDate),
        sessionTime: sessionTime,
      );

      if (isSlotBusy) {
        debugPrint('Slot is already booked for this expert.');
        return false;
      }

      // If multiple sessions are selected, schedule weekly recurring sessions
      for (int i = 0; i < totalSessions; i++) {
        final docRef = _firestore.collection('bookings').doc();
        // Each session is scheduled 7 days after the previous one
        final sessionDate = selectedDate.add(Duration(days: 7 * i));

        final newBookingData = {
          'bookingId': docRef.id,
          'studentId': uid,
          'studentName': _auth.currentUser?.displayName ?? 'Student',
          'teacherId': expertId,
          'teacherName': expertName,
          'skill': skill,
          'amount': amount,
          'sessionDate': DateFormat('dd MMMM yyyy').format(sessionDate),
          'sessionTime': sessionTime,
          'sessionType': sessionType,
          'duration': duration,
          'notes': notes.isNotEmpty ? notes : 'Booked via Expert Screen',
          'status': 'Confirmed',
          'bookingDate': DateTime.now().toIso8601String(),
          'totalSessions': totalSessions,
          'sessionNumber': i + 1,
          'meetingLink': 'https://meet.jit.si/SkillExchange_${docRef.id}',
          'recordingUrl': '',
          'isReviewed': false,
        };

        await docRef.set(newBookingData);
      }

      return true;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return false;
    }
  }

  // Check Availability / Double Booking Prevention
  Future<bool> isTimeSlotBooked({
    required String expertId,
    required String dateFormatted,
    required String sessionTime,
  }) async {
    try {
      final query = await _firestore
          .collection('bookings')
          .where('teacherId', isEqualTo: expertId)
          .where('sessionDate', isEqualTo: dateFormatted)
          .where('sessionTime', isEqualTo: sessionTime)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking availability: $e');
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
        'status': 'Completed',
      });
      return true;
    } catch (e) {
      debugPrint('Error saving recording: $e');
      return false;
    }
  }

  // Submit Review and Complete Meeting Status
  Future<bool> submitSessionReview({
    required String bookingId,
    required double rating,
    required String reviewText,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'rating': rating,
        'reviewText': reviewText,
        'isReviewed': true,
        'status': 'Completed',
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return false;
    }
  }
}