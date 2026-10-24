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
  final String status; // 'pending', 'Confirmed', 'Completed', 'cancelled'
  final String sessionType;
  final String duration;
  final String notes;
  final double amount;

  // Multi-session & Series fields
  final int totalSessions;
  final int sessionNumber;
  final String seriesId;
  final String meetingLink;

  // Completion & Review fields
  final bool sessionCompleted;
  final DateTime? completedAt;
  final String recordingUrl;
  final bool recordingSavedInApp;
  final bool recordingSavedInGallery;
  final bool isReviewed;
  final double? rating;
  final String reviewText;

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
    this.totalSessions = 1,
    this.sessionNumber = 1,
    this.seriesId = '',
    this.meetingLink = '',
    this.sessionCompleted = false,
    this.completedAt,
    this.recordingUrl = '',
    this.recordingSavedInApp = false,
    this.recordingSavedInGallery = false,
    this.isReviewed = false,
    this.rating,
    this.reviewText = '',
  }) : bookingDate = bookingDate ?? DateTime.now();

  // Backward Compatibility Getters
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
      'totalSessions': totalSessions,
      'sessionNumber': sessionNumber,
      'seriesId': seriesId,
      'meetingLink': meetingLink,
      'sessionCompleted': sessionCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'recordingUrl': recordingUrl,
      'recordingSavedInApp': recordingSavedInApp,
      'recordingSavedInGallery': recordingSavedInGallery,
      'isReviewed': isReviewed,
      'rating': rating,
      'reviewText': reviewText,
    };
  }

  // Factory constructor from Map / Document ID
  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateField(dynamic dateVal) {
      if (dateVal is Timestamp) {
        return dateVal.toDate();
      } else if (dateVal is String) {
        return DateTime.tryParse(dateVal) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic dateVal) {
      if (dateVal == null) return null;
      if (dateVal is Timestamp) return dateVal.toDate();
      if (dateVal is String) return DateTime.tryParse(dateVal);
      return null;
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
      bookingDate: parseDateField(map['bookingDate'] ?? map['date']),
      status: map['status'] ?? 'pending',
      sessionType: map['sessionType'] ?? 'Online Session',
      duration: map['duration'] ?? '60 Mins',
      notes: map['notes'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      totalSessions: map['totalSessions'] ?? 1,
      sessionNumber: map['sessionNumber'] ?? 1,
      seriesId: map['seriesId'] ?? '',
      meetingLink: map['meetingLink'] ?? '',
      sessionCompleted: map['sessionCompleted'] ?? false,
      completedAt: parseNullableDate(map['completedAt']),
      recordingUrl: map['recordingUrl'] ?? '',
      recordingSavedInApp: map['recordingSavedInApp'] ?? false,
      recordingSavedInGallery: map['recordingSavedInGallery'] ?? false,
      isReviewed: map['isReviewed'] ?? false,
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      reviewText: map['reviewText'] ?? '',
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
    int? totalSessions,
    int? sessionNumber,
    String? seriesId,
    String? meetingLink,
    bool? sessionCompleted,
    DateTime? completedAt,
    String? recordingUrl,
    bool? recordingSavedInApp,
    bool? recordingSavedInGallery,
    bool? isReviewed,
    double? rating,
    String? reviewText,
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
      totalSessions: totalSessions ?? this.totalSessions,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      seriesId: seriesId ?? this.seriesId,
      meetingLink: meetingLink ?? this.meetingLink,
      sessionCompleted: sessionCompleted ?? this.sessionCompleted,
      completedAt: completedAt ?? this.completedAt,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      recordingSavedInApp: recordingSavedInApp ?? this.recordingSavedInApp,
      recordingSavedInGallery: recordingSavedInGallery ?? this.recordingSavedInGallery,
      isReviewed: isReviewed ?? this.isReviewed,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
    );
  }
}