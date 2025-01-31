import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/seller.dart';
import '../models/order.dart' as app_order;
import '../models/withdrawal.dart';
import '../models/product.dart';
import '../models/refund.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';

final sellerServiceProvider = Provider<SellerService>((ref) {
  return SellerService();
});

class SellerService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<Seller> getSellerProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final doc = await _firestore.collection('sellers').doc(user.uid).get();
    if (!doc.exists) throw Exception('Seller profile not found');
    
    return Seller.fromMap(doc.data()!, doc.id);
  }

  Future<List<app_order.Order>> getSellerOrders({String? search}) async {
    try {
      final sellerId = _auth.currentUser!.uid;
      final query = _firestore.collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) {
        return app_order.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return orders.where((order) {
          return order.buyerName.toLowerCase().contains(searchLower) ||
              order.id.toLowerCase().contains(searchLower);
        }).toList();
      }

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch seller orders: $e');
    }
  }

  Stream<List<app_order.Order>> watchSellerOrders() {
    try {
      final sellerId = _auth.currentUser!.uid;
      final query = _firestore.collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return app_order.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to watch seller orders: $e');
    }
  }

  Future<List<Product>> getProducts({
    String? category,
    String? search,
    String? sortBy,
    bool? isActive,
  }) async {
    try {
      var query = _firestore.collection('products')
          .where('sellerId', isEqualTo: _auth.currentUser!.uid);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      if (sortBy != null) {
        switch (sortBy) {
          case 'price_asc':
            query = query.orderBy('price', descending: false);
            break;
          case 'price_desc':
            query = query.orderBy('price', descending: true);
            break;
          case 'newest':
            query = query.orderBy('createdAt', descending: true);
            break;
          case 'oldest':
            query = query.orderBy('createdAt', descending: false);
            break;
        }
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      final snapshot = await query.get();
      final products = snapshot.docs.map((doc) {
        return Product.fromMap({
          ...doc.data()!,
          'id': doc.id,
        }, doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return products.where((product) {
          return product.name.toLowerCase().contains(searchLower) ||
              product.description.toLowerCase().contains(searchLower);
        }).toList();
      }

      return products;
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<void> createSellerProfile(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create seller document
      await _firestore.collection('sellers').doc(user.uid).set({
        ...data,
        'userId': user.uid,
        'email': user.email,
        'isVerified': false,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update user document with seller role
      await _firestore.collection('users').doc(user.uid).update({
        'isSeller': true,
        'sellerId': user.uid,
      });
    } catch (e) {
      throw Exception('Failed to create seller profile: $e');
    }
  }

  Future<void> updateSellerProfile(Seller seller) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('sellers').doc(user.uid).update({
      'storeName': seller.storeName,
      'description': seller.description,
      'logo': seller.logo,
      'address': seller.address,
      'city': seller.city,
      'state': seller.state,
      'country': seller.country,
      'zip': seller.zip,
      'phone': seller.phone,
      'shippingInfo': seller.shippingInfo,
      'paymentInfo': seller.paymentInfo,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getSellerStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      var totalSales = 0.0;
      var totalOrders = 0;
      var processingOrders = 0;

      for (final doc in ordersSnapshot.docs) {
        final order = app_order.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (order.status != 'cancelled' && order.status != 'refunded') {
          totalSales += order.total;
          totalOrders++;
        }
        if (order.status == 'processing') {
          processingOrders++;
        }
      }

      final sellerDoc = await _firestore.collection('sellers').doc(user.uid).get();
      final seller = Seller.fromMap(sellerDoc.data()!, sellerDoc.id);

      return {
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'processingOrders': processingOrders,
        'balance': seller.balance,
        'averageRating': seller.averageRating,
        'reviewCount': seller.reviewCount,
      };
    } catch (e) {
      throw Exception('Failed to get seller stats: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order = app_order.Order.fromMap(orderDoc.data() as Map<String, dynamic>, orderId);
      if (order.sellerId != user.uid) {
        throw Exception('Not authorized to update this order');
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> updateShippingInfo(String orderId, Map<String, dynamic> shippingInfo) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order = app_order.Order.fromMap(orderDoc.data() as Map<String, dynamic>, orderId);
      if (order.sellerId != user.uid) {
        throw Exception('Not authorized to update this order');
      }

      await _firestore.collection('orders').doc(orderId).update({
        'shippingInfo': shippingInfo,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update shipping info: $e');
    }
  }

  Future<double> getBalance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection('sellers').doc(user.uid).get();
      if (!doc.exists) throw Exception('Seller profile not found');

      return (doc.data()!['balance'] as num).toDouble();
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  Future<List<Withdrawal>> getWithdrawals({String? status, String? search}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      var query = _firestore
          .collection('withdrawals')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      final withdrawals = snapshot.docs
          .map((doc) => Withdrawal.fromMap(doc.data(), doc.id))
          .toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return withdrawals.where((withdrawal) {
          return withdrawal.id.toLowerCase().contains(searchLower);
        }).toList();
      }

      return withdrawals;
    } catch (e) {
      throw Exception('Failed to get withdrawals: $e');
    }
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final sellerDoc = await _firestore.collection('sellers').doc(user.uid).get();
      if (!sellerDoc.exists) throw Exception('Seller profile not found');

      final currentBalance = (sellerDoc.data()!['balance'] as num).toDouble();
      if (currentBalance < amount) {
        throw Exception('Insufficient balance');
      }

      final batch = _firestore.batch();

      // Create withdrawal request
      final withdrawalRef = _firestore.collection('withdrawals').doc();
      batch.set(withdrawalRef, {
        'sellerId': user.uid,
        'sellerName': sellerDoc.data()!['storeName'] ?? 'Unknown Store',
        'amount': amount,
        'status': 'pending',
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Update seller balance
      batch.update(sellerDoc.reference, {
        'balance': currentBalance - amount,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to request withdrawal: $e');
    }
  }

  // Dashboard Data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get seller profile
      final sellerDoc = await _firestore.collection('sellers').doc(user.uid).get();
      if (!sellerDoc.exists) throw Exception('Seller profile not found');

      // Get all orders for the seller
      final orders = await getOrders();
      
      // Calculate statistics
      final totalSales = orders.fold(0.0, (sum, order) => 
        order.status != 'cancelled' && order.status != 'refunded' 
          ? sum + order.total 
          : sum
      );
      
      final processingOrders = orders.where((order) => order.status == 'processing').length;

      // Get total products count
      final productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .count()
          .get();

      return {
        'statistics': {
          'totalSales': totalSales,
          'balance': sellerDoc.data()?['balance'] ?? 0.0,
          'totalOrders': orders.length,
          'processingOrders': processingOrders,
          'totalProducts': productsSnapshot.count,
          'averageRating': sellerDoc.data()?['averageRating'] ?? 0.0,
          'reviewCount': sellerDoc.data()?['reviewCount'] ?? 0,
        },
        'recentOrders': orders.take(5).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get dashboard data: $e');
    }
  }

  // Products
  Future<void> toggleProductStatus(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) throw Exception('Product not found');

      final product = Product.fromMap({
        ...productDoc.data()!,
        'id': productDoc.id,
      }, productDoc.id);

      if (product.sellerId != user.uid) {
        throw Exception('Unauthorized to update this product');
      }

      await _firestore.collection('products').doc(productId).update({
        'isActive': !product.isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to toggle product status: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) throw Exception('Product not found');

      final product = Product.fromMap({
        ...productDoc.data()!,
        'id': productDoc.id,
      }, productDoc.id);

      if (product.sellerId != user.uid) {
        throw Exception('Unauthorized to delete this product');
      }

      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> createProduct(Product product) async {
    try {
      // Get seller profile to get the store name and city
      final seller = await getSellerProfile();
      
      // Extract main category from subCategory if category is empty
      String category = product.category;
      if (category.isEmpty && product.subCategory != null) {
        category = product.subCategory!.split(' - ').first.toLowerCase();
      }
      
      final docRef = await _firestore.collection('products').add({
        ...product.toMap(),
        'sellerId': _auth.currentUser!.uid,
        'sellerName': seller.storeName,
        'sellerCity': seller.city,
        'category': category,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await docRef.update({
        'id': docRef.id,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<void> updateProduct(String productId, Product updatedProduct) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        ...updatedProduct.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Orders
  Future<List<app_order.Order>> getOrders({String? status, String? search}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore.collection('orders').where('sellerId', isEqualTo: user.uid);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      final orders = snapshot.docs.map((doc) {
        return app_order.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return orders.where((order) {
          return order.id.toLowerCase().contains(searchLower) ||
              order.buyerName.toLowerCase().contains(searchLower);
        }).toList();
      }

      return orders;
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  Stream<List<app_order.Order>> watchOrders({String? status}) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    Query query = _firestore.collection('orders').where('sellerId', isEqualTo: user.uid);

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return app_order.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<List<Refund>> getRefunds({String? search, String? status}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    var query = _firestore.collection('refunds')
      .where('sellerId', isEqualTo: user.uid);

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    final refunds = snapshot.docs.map((doc) {
      return Refund.fromMap(doc.data(), doc.id);
    }).toList();

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      return refunds.where((refund) =>
        refund.orderId.toLowerCase().contains(searchLower) ||
        refund.reason.toLowerCase().contains(searchLower)
      ).toList();
    }

    return refunds;
  }

  Future<bool> isSellerVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection('sellers').doc(user.uid).get();
      if (!doc.exists) return false;

      return doc.data()?['isVerified'] == true;
    } catch (e) {
      throw Exception('Failed to check seller verification: $e');
    }
  }

  Future<String?> getSellerStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection('sellers').doc(user.uid).get();
      if (!doc.exists) return null;

      return doc.data()?['status'] as String?;
    } catch (e) {
      throw Exception('Failed to get seller status: $e');
    }
  }

  Future<void> verifyPayment(String reference, Map<String, dynamic> metadata) async {
    try {
      final user = await _auth.currentUser;
      if (user == null) throw 'User not found';

      await _firestore.collection('sellers').doc(user.uid).set({
        'userId': user.uid,
        'storeName': metadata['storeName'],
        'description': metadata['storeDescription'],
        'address': metadata['address'],
        'city': metadata['city'] ?? '',
        'state': metadata['state'] ?? '',
        'country': metadata['country'] ?? '',
        'zip': metadata['zip'] ?? '',
        'phone': user.phoneNumber ?? '',
        'email': user.email ?? '',
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
        'balance': 0.0,
        'averageRating': 0.0,
        'reviewCount': 0,
        'deliveryFee': 0.0,
        'shippingInfo': metadata['shippingInfo'],
        'latitude': metadata['latitude'],
        'longitude': metadata['longitude'],
        'followersCount': 0,
        'followers': [],
        'acceptedPaymentMethods': metadata['acceptedPaymentMethods'],
        'paymentPhoneNumbers': metadata['paymentPhoneNumbers'],
        'paymentNames': metadata['paymentNames'],
      });
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      rethrow;
    }
  }

  Future<void> submitSellerRegistration(Map<String, dynamic> metadata) async {
    try {
      final user = await _auth.currentUser;
      if (user == null) throw 'User not found';

      // Create a seller document with isSeller set to false
      await _firestore.collection('sellers').doc(user.uid).set({
        'userId': user.uid,
        'storeName': metadata['storeName'],
        'description': metadata['storeDescription'],
        'address': metadata['address'],
        'country': metadata['country'] ?? '',
        'shippingInfo': metadata['shippingInfo'],
        'latitude': metadata['latitude'],
        'longitude': metadata['longitude'],
        'acceptedPaymentMethods': metadata['acceptedPaymentMethods'],
        'paymentPhoneNumbers': metadata['paymentPhoneNumbers'],
        'paymentNames': metadata['paymentNames'],
        'paymentReference': metadata['paymentReference'],
        'registrationFee': metadata['registrationFee'] ?? 800.00,
        'registrationStatus': 'pending',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': false,
        'isSeller': false,
        'balance': 0.0,
        'totalSales': 0.0,
        'totalOrders': 0,
        'averageRating': 0.0,
        'reviewCount': 0,
        'logo': null,
        'banner': null,
      });

      // Update user document to mark registration as pending
      await _firestore.collection('users').doc(user.uid).update({
        'hasSubmittedSellerRegistration': true,
        'sellerRegistrationStatus': 'pending',
      });
    } catch (e) {
      debugPrint('Error submitting seller registration: $e');
      rethrow;
    }
  }

  Future<List<MerchUser>> getSellersByIds(List<String> sellerIds) async {
    if (sellerIds.isEmpty) return [];

    final sellerDocs = await _firestore
        .collection('users')
        .where('isSeller', isEqualTo: true)
        .where(FieldPath.documentId, whereIn: sellerIds)
        .get();

    return sellerDocs.docs
        .map((doc) => MerchUser.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<MerchUser?> getSellerById(String sellerId) async {
    final sellerDoc = await _firestore
        .collection('users')
        .where('isSeller', isEqualTo: true)
        .where(FieldPath.documentId, isEqualTo: sellerId)
        .get();

    if (sellerDoc.docs.isEmpty) return null;
    return MerchUser.fromMap(sellerDoc.docs.first.data(), sellerDoc.docs.first.id);
  }

  Future<Product> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) throw Exception('Product not found');
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  Future<Seller?> getSellerProfileById(String sellerId) async {
    try {
      final doc = await _firestore.collection('sellers').doc(sellerId).get();
      if (!doc.exists) return null;
      return Seller.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Failed to get seller profile: $e');
      return null;
    }
  }

  Future<void> followSeller(String sellerId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final sellerRef = _firestore.collection('sellers').doc(sellerId);
    final sellerDoc = await sellerRef.get();
    
    if (!sellerDoc.exists) throw 'Seller not found';

    await _firestore.runTransaction((transaction) async {
      final seller = Seller.fromMap(sellerDoc.data()!, sellerId);
      final updatedFollowers = List<String>.from(seller.followers);
      
      if (!updatedFollowers.contains(currentUser.uid)) {
        updatedFollowers.add(currentUser.uid);
        transaction.update(sellerRef, {
          'followers': updatedFollowers,
          'followersCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> unfollowSeller(String sellerId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final sellerRef = _firestore.collection('sellers').doc(sellerId);
    final sellerDoc = await sellerRef.get();
    
    if (!sellerDoc.exists) throw 'Seller not found';

    await _firestore.runTransaction((transaction) async {
      final seller = Seller.fromMap(sellerDoc.data()!, sellerId);
      final updatedFollowers = List<String>.from(seller.followers);
      
      if (updatedFollowers.contains(currentUser.uid)) {
        updatedFollowers.remove(currentUser.uid);
        transaction.update(sellerRef, {
          'followers': updatedFollowers,
          'followersCount': FieldValue.increment(-1),
        });
      }
    });
  }
} 