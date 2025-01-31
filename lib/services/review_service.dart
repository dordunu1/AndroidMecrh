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
      print('Adding review for order: ${review.orderId}');
      print('User ID: ${review.userId}');
      print('Product ID: ${review.productId}');

      // Create the review ID using the same format as in security rules
      final reviewId = '${review.orderId}_${review.userId}_${review.productId}';
      print('Generated review ID: $reviewId');
      
      if (review.id != reviewId) {
        print('Review ID mismatch: ${review.id} vs $reviewId');
        throw Exception('Invalid review ID format');
      }

      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      
      // Check if review already exists
      final existingReview = await reviewRef.get();
      if (existingReview.exists) {
        throw Exception('You have already reviewed this product from this order');
      }

      // Check if order exists and is delivered
      final orderRef = _firestore.collection('orders').doc(review.orderId);
      final orderDoc = await orderRef.get();
      print('Order exists: ${orderDoc.exists}');
      
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data();
      print('Order data: $orderData');
      
      if (orderData == null) {
        throw Exception('Order data is invalid');
      }

      print('Order status: ${orderData['status']}');
      print('Order buyerId: ${orderData['buyerId']}');
      print('Review userId: ${review.userId}');

      if (orderData['status'] != 'delivered') {
        throw Exception('Can only review delivered orders');
      }

      if (orderData['buyerId'] != review.userId) {
        throw Exception('Not authorized to review this order');
      }

      // Verify that the product exists in the order
      final orderItems = List<Map<String, dynamic>>.from(orderData['items'] as List);
      print('Order items: $orderItems');
      
      final productExists = orderItems.any((item) => item['productId'] == review.productId);
      print('Product exists in order: $productExists');
      
      if (!productExists) {
        throw Exception('Product not found in this order');
      }

      // Start a batch write
      final batch = _firestore.batch();

      print('Adding review to Firestore...');
      // Add the review
      batch.set(reviewRef, review.toMap());

      // Update product rating
      final productRef = _firestore.collection('products').doc(review.productId);
      final productDoc = await productRef.get();
      if (productDoc.exists) {
        final currentRating = productDoc.data()?['rating'] ?? 0.0;
        final currentCount = productDoc.data()?['reviewCount'] ?? 0;
        final newRating = ((currentRating * currentCount) + review.rating) / (currentCount + 1);
        batch.update(productRef, {
          'rating': newRating,
          'reviewCount': currentCount + 1,
        });
      }

      // Update seller rating
      final sellerRef = _firestore.collection('sellers').doc(review.sellerId);
      final sellerDoc = await sellerRef.get();
      if (sellerDoc.exists) {
        final currentRating = sellerDoc.data()?['rating'] ?? 0.0;
        final currentCount = sellerDoc.data()?['reviewCount'] ?? 0;
        final newRating = ((currentRating * currentCount) + review.rating) / (currentCount + 1);
        batch.update(sellerRef, {
          'rating': newRating,
          'reviewCount': currentCount + 1,
        });
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          throw Exception('Not authorized to add review. Please ensure you have purchased and received this product.');
        }
      }
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