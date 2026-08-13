import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String bookingId;
  final String expertId;
  final String learnerId;
  final String learnerName;
  final double rating;
  final String reviewText;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.expertId,
    required this.learnerId,
    required this.learnerName,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'bookingId': bookingId,
      'expertId': expertId,
      'learnerId': learnerId,
      'learnerName': learnerName,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}