import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import 'package:firebase_auth/firebase_auth.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> updateSellerRating(String sellerId, double newRating) async {
    try {
      final sellerRef = _firestore.collection('sellers').doc(sellerId);
      
      return await _firestore.runTransaction((transaction) async {
        final sellerDoc = await transaction.get(sellerRef);
        
        if (!sellerDoc.exists) {
          throw Exception('Seller not found');
        }
        
        final currentRating = (sellerDoc.data()?['averageRating'] as num?)?.toDouble() ?? 0.0;
        final currentReviewCount = (sellerDoc.data()?['reviewCount'] as num?)?.toInt() ?? 0;
        
        // Calculate new average rating
        final newAverageRating = ((currentRating * currentReviewCount) + newRating) / (currentReviewCount + 1);
        
        // Update seller document with new rating and review count
        transaction.update(sellerRef, {
          'averageRating': newAverageRating,
          'reviewCount': currentReviewCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error updating seller rating: $e');
      rethrow;
    }
  }

  Future<void> addReview(Review review) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final reviewId = '${review.orderId}_${user.uid}_${review.productId}';
      if (review.id != reviewId) {
        throw Exception('Invalid review ID format');
      }

      // Check if review already exists
      final existingReview = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (existingReview.exists) {
        throw Exception('Review already exists for this order');
      }

      // Get order document
      final orderDoc = await _firestore
          .collection('orders')
          .doc(review.orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data();
      if (orderData == null) {
        throw Exception('Order data is invalid');
      }

      // Check if order is delivered
      if (orderData['status'] != 'delivered') {
        throw Exception('Order must be delivered before reviewing');
      }

      // Check if product exists in order
      final orderItems = List<Map<String, dynamic>>.from(orderData['items'] as List);
      final productExists = orderItems.any((item) => item['productId'] == review.productId);
      if (!productExists) {
        throw Exception('Product not found in this order');
      }

      // Add review
      await _firestore.collection('reviews').doc(reviewId).set(review.toMap());

      // Update seller rating
      await updateSellerRating(review.sellerId, review.rating);

    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  Future<void> updateReview(String reviewId, Review review) async {
    try {
      final oldReview = await _firestore.collection('reviews').doc(reviewId).get();
      if (!oldReview.exists) {
        throw Exception('Review not found');
      }

      final batch = _firestore.batch();

      // Update the review
      batch.update(_firestore.collection('reviews').doc(reviewId), review.toMap());

      // Update product rating
      if (oldReview.data()?['rating'] != review.rating) {
        final productRef = _firestore.collection('products').doc(review.productId);
        final productDoc = await productRef.get();
        if (productDoc.exists) {
          final currentRating = productDoc.data()?['rating'] ?? 0.0;
          final currentCount = productDoc.data()?['reviewCount'] ?? 0;
          final oldRating = oldReview.data()?['rating'] ?? 0.0;
          final newRating = ((currentRating * currentCount) - oldRating + review.rating) / currentCount;
          batch.update(productRef, {'rating': newRating});
        }

        // Update seller rating
        final sellerRef = _firestore.collection('sellers').doc(review.sellerId);
        final sellerDoc = await sellerRef.get();
        if (sellerDoc.exists) {
          final currentRating = sellerDoc.data()?['rating'] ?? 0.0;
          final currentCount = sellerDoc.data()?['reviewCount'] ?? 0;
          final oldRating = oldReview.data()?['rating'] ?? 0.0;
          final newRating = ((currentRating * currentCount) - oldRating + review.rating) / currentCount;
          batch.update(sellerRef, {'rating': newRating});
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }

      final batch = _firestore.batch();

      // Delete the review
      batch.delete(_firestore.collection('reviews').doc(reviewId));

      // Update product rating
      final productId = reviewDoc.data()?['productId'];
      final rating = reviewDoc.data()?['rating'] ?? 0.0;
      if (productId != null) {
        final productRef = _firestore.collection('products').doc(productId);
        final productDoc = await productRef.get();
        if (productDoc.exists) {
          final currentRating = productDoc.data()?['rating'] ?? 0.0;
          final currentCount = productDoc.data()?['reviewCount'] ?? 0;
          if (currentCount > 1) {
            final newRating = ((currentRating * currentCount) - rating) / (currentCount - 1);
            batch.update(productRef, {
              'rating': newRating,
              'reviewCount': currentCount - 1,
            });
          } else {
            batch.update(productRef, {
              'rating': 0.0,
              'reviewCount': 0,
            });
          }
        }
      }

      // Update seller rating
      final sellerId = reviewDoc.data()?['sellerId'];
      if (sellerId != null) {
        final sellerRef = _firestore.collection('sellers').doc(sellerId);
        final sellerDoc = await sellerRef.get();
        if (sellerDoc.exists) {
          final currentRating = sellerDoc.data()?['rating'] ?? 0.0;
          final currentCount = sellerDoc.data()?['reviewCount'] ?? 0;
          if (currentCount > 1) {
            final newRating = ((currentRating * currentCount) - rating) / (currentCount - 1);
            batch.update(sellerRef, {
              'rating': newRating,
              'reviewCount': currentCount - 1,
            });
          } else {
            batch.update(sellerRef, {
              'rating': 0.0,
              'reviewCount': 0,
            });
          }
        }
      }

      await batch.commit();
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