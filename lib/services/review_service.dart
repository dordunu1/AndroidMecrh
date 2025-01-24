import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Review>> getProductReviews(
    String productId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? sortBy,
  }) async {
    try {
      Query query = _firestore.collection('reviews')
          .where('productId', isEqualTo: productId);

      switch (sortBy) {
        case 'rating_high':
          query = query.orderBy('rating', descending: true);
          break;
        case 'rating_low':
          query = query.orderBy('rating', descending: false);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch product reviews: $e');
    }
  }

  Future<List<Review>> getSellerReviews(
    String sellerId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? sortBy,
  }) async {
    try {
      Query query = _firestore.collection('reviews')
          .where('sellerId', isEqualTo: sellerId);

      switch (sortBy) {
        case 'rating_high':
          query = query.orderBy('rating', descending: true);
          break;
        case 'rating_low':
          query = query.orderBy('rating', descending: false);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch seller reviews: $e');
    }
  }

  Future<void> addReview(Review review) async {
    try {
      await _firestore.collection('reviews').add(review.toMap());
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<void> updateReview(String reviewId, Review review) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update(review.toMap());
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      final review = await _firestore.collection('reviews').doc(reviewId).get();
      final productId = review.data()!['productId'];

      await _firestore.collection('reviews').doc(reviewId).delete();

      // Update product rating
      await _updateProductRating(productId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  Future<void> addSellerResponse(String reviewId, Map<String, dynamic> response) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'sellerResponse': {
          ...response,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      throw Exception('Failed to add seller response: $e');
    }
  }

  Future<void> _updateProductRating(String productId) async {
    try {
      final reviews = await _firestore.collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (reviews.docs.isEmpty) {
        await _firestore.collection('products').doc(productId).update({
          'rating': 0.0,
          'reviewCount': 0,
        });
        return;
      }

      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += doc.data()['rating'] as double;
      }

      final averageRating = totalRating / reviews.docs.length;
      await _firestore.collection('products').doc(productId).update({
        'rating': averageRating,
        'reviewCount': reviews.docs.length,
      });
    } catch (e) {
      throw Exception('Failed to update product rating: $e');
    }
  }

  Stream<List<Review>> watchProductReviews(String productId) {
    return _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
} 