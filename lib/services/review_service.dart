import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_exchange/models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> submitReview(ReviewModel review) async {
    try {
      final docRef = _firestore.collection('reviews').doc();
      final newReview = ReviewModel(
        reviewId: docRef.id,
        bookingId: review.bookingId,
        expertId: review.expertId,
        learnerId: _auth.currentUser?.uid ?? '',
        learnerName: review.learnerName,
        rating: review.rating,
        reviewText: review.reviewText,
        createdAt: DateTime.now(),
      );

      // Save Review in 'reviews' collection
      await docRef.set(newReview.toMap());

      // Update Expert's Average Rating in 'experts' collection
      await _updateExpertRating(review.expertId);

      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  // Calculate and Update Expert Rating
  Future<void> _updateExpertRating(String expertId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('expertId', isEqualTo: expertId)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          totalRating += (doc.data()['rating'] as num).toDouble();
        }

        double avgRating = totalRating / reviewsSnapshot.docs.length;

        await _firestore.collection('experts').doc(expertId).update({
          'rating': double.parse(avgRating.toStringAsFixed(1)),
          'totalReviews': reviewsSnapshot.docs.length,
        });
      }
    } catch (e) {
      print('Error updating expert average rating: $e');
    }
  }
}