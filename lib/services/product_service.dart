import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Product>> getProducts({
    String? category,
    String? sellerId,
    String? searchQuery,
    String? sortBy,
    bool? isActive,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection('products');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (sellerId != null) {
        query = query.where('sellerId', isEqualTo: sellerId);
      }

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.where('searchKeywords', arrayContains: searchQuery.toLowerCase());
      }

      switch (sortBy) {
        case 'price_asc':
          query = query.orderBy('price', descending: false);
          break;
        case 'price_desc':
          query = query.orderBy('price', descending: true);
          break;
        case 'rating':
          query = query.orderBy('rating', descending: true);
          break;
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) {
        throw Exception('Product not found');
      }
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final docRef = await _firestore.collection('products').add({
        ...productData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Product> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc = await _firestore.collection('products').doc(productId).get();
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> updateProductQuantity(String productId, int quantity) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'quantity': FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update product quantity: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final doc = await _firestore.collection('metadata').doc('categories').get();
      if (!doc.exists) return [];
      return List<String>.from(doc.data()?['list'] ?? []);
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Stream<Product> watchProduct(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((doc) => Product.fromMap(doc.data()!, doc.id));
  }

  Future<List<Product>> getSellerProducts(String sellerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch seller products: $e');
    }
  }
} 