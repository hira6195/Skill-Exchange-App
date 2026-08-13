import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String skill;
  final String sessionDate;
  final String sessionTime;
  final DateTime bookingDate;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String sessionType;
  final String duration;
  final String notes;
  final double amount;

  BookingModel({
    required this.bookingId,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    this.studentName = '',
    this.skill = '',
    this.sessionDate = '',
    this.sessionTime = '',
    DateTime? bookingDate,
    this.status = 'pending',
    this.sessionType = 'Online Session',
    this.duration = '60 Mins',
    this.notes = '',
    this.amount = 0.0,
  }) : bookingDate = bookingDate ?? DateTime.now();

  // Backward Compatibility Getters (Purane code ke saath compatibility ke liye)
  String get id => bookingId;
  String get userId => studentId;
  String get expertId => teacherId;
  String get expertName => teacherName;
  DateTime get date => bookingDate;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentId': studentId,
      'studentName': studentName,
      'skill': skill,
      'sessionDate': sessionDate,
      'sessionTime': sessionTime,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'status': status,
      'sessionType': sessionType,
      'duration': duration,
      'notes': notes,
      'amount': amount,
    };
  }

  // Factory constructor from Map / Document ID
  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedBookingDate;

    if (map['bookingDate'] is Timestamp) {
      parsedBookingDate = (map['bookingDate'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedBookingDate = DateTime.tryParse(map['date']) ?? DateTime.now();
    } else if (map['bookingDate'] is String) {
      parsedBookingDate = DateTime.tryParse(map['bookingDate']) ?? DateTime.now();
    } else {
      parsedBookingDate = DateTime.now();
    }

    return BookingModel(
      bookingId: docId.isNotEmpty ? docId : (map['bookingId'] ?? map['id'] ?? ''),
      teacherId: map['teacherId'] ?? map['expertId'] ?? '',
      teacherName: map['teacherName'] ?? map['expertName'] ?? '',
      studentId: map['studentId'] ?? map['userId'] ?? '',
      studentName: map['studentName'] ?? '',
      skill: map['skill'] ?? '',
      sessionDate: map['sessionDate'] ?? '',
      sessionTime: map['sessionTime'] ?? '',
      bookingDate: parsedBookingDate,
      status: map['status'] ?? 'pending',
      sessionType: map['sessionType'] ?? 'Online Session',
      duration: map['duration'] ?? '60 Mins',
      notes: map['notes'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }

  // Factory constructor from Firestore DocumentSnapshot
  factory BookingModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookingModel.fromMap(data, doc.id);
  }

  // CopyWith Method for easy updates
  BookingModel copyWith({
    String? bookingId,
    String? teacherId,
    String? teacherName,
    String? studentId,
    String? studentName,
    String? skill,
    String? sessionDate,
    String? sessionTime,
    DateTime? bookingDate,
    String? status,
    String? sessionType,
    String? duration,
    String? notes,
    double? amount,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      skill: skill ?? this.skill,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionTime: sessionTime ?? this.sessionTime,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      sessionType: sessionType ?? this.sessionType,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
    );
  }
}