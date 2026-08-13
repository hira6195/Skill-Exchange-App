import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Submit Review & Rating
  Future<void> submitReview({
    required String bookingId,
    required String teacherId,
    required String studentId,
    required double rating,
    required String reviewText,
  }) async {
    final WriteBatch batch = _db.batch();

    // Create Review doc
    DocumentReference reviewRef = _db.collection('reviews').doc();
    batch.set(reviewRef, {
      'reviewId': reviewRef.id,
      'bookingId': bookingId,
      'teacherId': teacherId,
      'studentId': studentId,
      'rating': rating,
      'review': reviewText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update Booking status
    DocumentReference bookingRef = _db.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'reviewSubmitted': true,
      'rating': rating,
      'review': reviewText,
    });

    await batch.commit();
  }

  // 2. Issue Certificate (Teacher Flow)
  Future<void> issueCertificate({
    required String bookingId,
    required String studentId,
    required String teacherId,
    required String learnerName,
    required String courseName,
    required String issuedBy,
    required String pdfUrl,
  }) async {
    final WriteBatch batch = _db.batch();

    DocumentReference certRef = _db.collection('certificates').doc();
    batch.set(certRef, {
      'certificateId': certRef.id,
      'bookingId': bookingId,
      'studentId': studentId,
      'teacherId': teacherId,
      'learnerName': learnerName,
      'courseName': courseName,
      'issuedBy': issuedBy,
      'issueDate': FieldValue.serverTimestamp(),
      'certificateUrl': pdfUrl,
      'status': 'Issued',
    });

    // Update Bookings Document Flag
    batch.update(_db.collection('bookings').doc(bookingId), {
      'certificateIssued': true,
      'certificateUrl': pdfUrl,
    });

    // Notify Student
    DocumentReference notifRef = _db.collection('notifications').doc();
    batch.set(notifRef, {
      'receiverId': studentId,
      'senderId': teacherId,
      'title': 'Certificate Issued! 🎓',
      'body': 'Congratulations! Your certificate for $courseName has been generated.',
      'type': 'certificate_issued',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}