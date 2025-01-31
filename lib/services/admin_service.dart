import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as app_order;
import '../models/seller.dart';
import '../models/refund.dart';
import '../models/withdrawal.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class AdminService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminService(this._firestore, this._auth);

  Future<List<app_order.Order>> getOrders({String? search, String? status, String? sellerId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final isAdmin = await this.isAdmin(user.uid);
      if (!isAdmin) throw Exception('User is not an admin');

      var query = _firestore.collection('orders').orderBy('createdAt', descending: true);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      if (sellerId != null) {
        query = query.where('sellerId', isEqualTo: sellerId);
      }

      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) {
        return app_order.Order.fromMap(doc.data(), doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return orders.where((order) {
          return order.id.toLowerCase().contains(searchLower) ||
              order.buyerInfo['name'].toLowerCase().contains(searchLower) ||
              order.sellerInfo['name'].toLowerCase().contains(searchLower);
        }).toList();
      }

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<List<Seller>> getSellers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final isAdmin = await this.isAdmin(user.uid);
      if (!isAdmin) throw Exception('User is not an admin');

      final snapshot = await _firestore.collection('sellers').get();
      return snapshot.docs.map((doc) => Seller.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to fetch sellers: $e');
    }
  }

  Future<void> verifyStore(String sellerId, bool isVerified, {String? message}) async {
    try {
      await _firestore.collection('sellers').doc(sellerId).update({
        'isVerified': isVerified,
        'verificationMessage': message,
        'verifiedAt': isVerified ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      throw Exception('Failed to verify store: $e');
    }
  }

  Future<List<app_order.Order>> getOrdersByDateRange(DateTime start, DateTime end) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final snapshot = await _firestore.collection('orders')
      .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
      .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
      .orderBy('createdAt', descending: true)
      .get();

    return snapshot.docs.map((doc) => app_order.Order.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Refund>> getRefunds({String? search, String? status}) async {
    try {
      var query = _firestore.collection('refunds')
          .orderBy('createdAt', descending: true);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      final refunds = snapshot.docs.map((doc) {
        final data = doc.data();
        print('DEBUG: Refund document data: $data');
        return Refund.fromMap(data, doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return refunds.where((refund) {
          return refund.orderId.toLowerCase().contains(searchLower) ||
              refund.reason.toLowerCase().contains(searchLower);
        }).toList();
      }

      return refunds;
    } catch (e) {
      print('Error fetching refunds: $e');
      throw Exception('Failed to fetch refunds: $e');
    }
  }

  Future<void> updateRefundStatus(String refundId, String status) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final isUserAdmin = await isAdmin(user.uid);
    if (!isUserAdmin) throw Exception('User is not an admin');

    await _firestore.collection('refunds').doc(refundId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'approved') {
      final refund = await _firestore.collection('refunds').doc(refundId).get();
      final refundData = refund.data()!;
      final orderId = refundData['orderId'];
      final amount = refundData['amount'];

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'refunded',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the order to find the seller
      final order = await _firestore.collection('orders').doc(orderId).get();
      final orderData = order.data()!;
      final sellerId = orderData['sellerId'];

      // Update seller's balance and stats
      await _firestore.collection('sellers').doc(sellerId).update({
        'balance': FieldValue.increment(-amount),
        'totalSales': FieldValue.increment(-amount),
        'totalOrders': FieldValue.increment(-1),
      });
    }
  }

  Future<List<Withdrawal>> getWithdrawals({String? search, String? status}) async {
    try {
      var query = _firestore.collection('withdrawals')
          .orderBy('createdAt', descending: true);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      final withdrawals = snapshot.docs.map((doc) {
        return Withdrawal.fromMap(doc.data(), doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return withdrawals.where((withdrawal) {
          return withdrawal.sellerName.toLowerCase().contains(searchLower) ||
              withdrawal.id.toLowerCase().contains(searchLower);
        }).toList();
      }

      return withdrawals;
    } catch (e) {
      throw Exception('Failed to fetch withdrawals: $e');
    }
  }

  Future<void> updateWithdrawalStatus(String withdrawalId, String status) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final isUserAdmin = await isAdmin(user.uid);
    if (!isUserAdmin) throw Exception('User is not an admin');

    await _firestore.collection('withdrawals').doc(withdrawalId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final isUserAdmin = await isAdmin(user.uid);
    if (!isUserAdmin) throw Exception('User is not an admin');

    try {
      // Get all orders
      final ordersSnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      final orders = ordersSnapshot.docs
          .map((doc) => app_order.Order.fromMap(doc.data(), doc.id))
          .toList();

      // Calculate total sales and refunds
      final totalSales = orders.fold(0.0, (sum, order) => 
        order.status != 'cancelled' && order.status != 'refunded' 
          ? sum + order.total 
          : sum);

      final totalRefunds = orders.fold(0.0, (sum, order) => 
        order.status == 'refunded'
          ? sum + order.total 
          : sum);

      // Get all sellers to calculate total registration fees
      final sellersSnapshot = await _firestore
          .collection('sellers')
          .get();

      // Calculate total registration fees
      final totalRegistrationFees = sellersSnapshot.docs.fold(0.0, (sum, doc) {
        final registrationFee = doc.data()['registrationFee'] ?? 1.0;
        return sum + registrationFee;
      });

      // Get total products
      final productsSnapshot = await _firestore
          .collection('products')
          .get();

      // Get total customers
      final customersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'buyer')
          .get();

      return {
        'stats': {
          'totalSales': totalSales,
          'currentSales': totalSales - totalRefunds,
          'totalRefunds': totalRefunds,
          'totalRegistrationFees': totalRegistrationFees,
          'activeSellers': sellersSnapshot.docs.length,
          'totalOrders': orders.length,
          'totalProducts': productsSnapshot.docs.length,
          'totalCustomers': customersSnapshot.docs.length,
        },
        'recentOrders': orders.take(10).map((order) => {
          'id': order.id,
          'seller': order.sellerName,
          'customer': order.buyerName,
          'amount': order.total,
          'status': order.status,
          'date': order.createdAt.toIso8601String(),
        }).toList(),
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  Future<List<Seller>> getPendingVerifications({String? search}) async {
    try {
      final snapshot = await _firestore.collection('sellers')
        .where('isVerified', isEqualTo: false)
        .get();

      final sellers = snapshot.docs.map((doc) => Seller.fromMap(doc.data()!, doc.id)).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return sellers.where((seller) {
          return seller.storeName.toLowerCase().contains(searchLower) ||
              seller.email.toLowerCase().contains(searchLower);
        }).toList();
      }

      return sellers;
    } catch (e) {
      throw Exception('Failed to get pending verifications: $e');
    }
  }

  Future<void> processRefund({
    required String refundId,
    required bool approved,
    String? message,
  }) async {
    try {
      final refundDoc = await _firestore.collection('refunds').doc(refundId).get();
      if (!refundDoc.exists) throw Exception('Refund not found');

      final refund = Refund.fromMap(refundDoc.data()!, refundDoc.id);
      final orderDoc = await _firestore.collection('orders').doc(refund.orderId).get();
      
      if (!orderDoc.exists) throw Exception('Order not found');

      final batch = _firestore.batch();

      // Update refund status
      batch.update(_firestore.collection('refunds').doc(refundId), {
        'status': approved ? 'approved' : 'rejected',
        'resolvedAt': DateTime.now().toIso8601String(),
        if (message != null) 'adminNote': message,
      });

      // If approved:
      // 1. Update seller balance
      // 2. Update seller total sales
      // 3. Update order status
      if (approved) {
        // Update seller balance and stats
        batch.update(_firestore.collection('sellers').doc(refund.sellerId), {
          'balance': FieldValue.increment(-refund.amount),
          'totalSales': FieldValue.increment(-refund.amount),
          'totalOrders': FieldValue.increment(-1),
        });

        // Update order status to refunded
        batch.update(_firestore.collection('orders').doc(refund.orderId), {
          'status': 'refunded',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // If rejected, update order status back to previous state
        batch.update(_firestore.collection('orders').doc(refund.orderId), {
          'status': 'cancelled',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  Future<void> processWithdrawal({
    required String withdrawalId,
    required bool approved,
    String? message,
  }) async {
    try {
      await _firestore.collection('withdrawals').doc(withdrawalId).update({
        'status': approved ? 'approved' : 'rejected',
        'processedAt': DateTime.now().toIso8601String(),
        if (message != null) 'adminNote': message,
      });
    } catch (e) {
      throw Exception('Failed to process withdrawal: $e');
    }
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists && doc.data()?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateSellerVerification(String sellerId, bool isVerified) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final isUserAdmin = await isAdmin(user.uid);
    if (!isUserAdmin) throw Exception('User is not an admin');

    await _firestore.collection('sellers').doc(sellerId).update({
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getStoreRevenue(String sellerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final isAdmin = await this.isAdmin(user.uid);
      if (!isAdmin) throw Exception('User is not an admin');

      final seller = await _firestore.collection('sellers').doc(sellerId).get();
      if (!seller.exists) throw Exception('Store not found');

      final sellerData = seller.data()!;

      // Get all orders for this seller
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = ordersSnapshot.docs
          .map((doc) => app_order.Order.fromMap(doc.data(), doc.id))
          .toList();

      // Calculate revenue metrics
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      final previousMonth = now.subtract(const Duration(days: 60));

      final lastMonthOrders = orders
          .where((order) => order.createdAt.isAfter(lastMonth))
          .toList();

      final previousMonthOrders = orders
          .where((order) => 
            order.createdAt.isAfter(previousMonth) && 
            order.createdAt.isBefore(lastMonth))
          .toList();

      // Calculate revenue
      final allTimeRevenue = orders.fold(0.0, (sum, order) => 
        order.status != 'cancelled' && order.status != 'refunded' 
          ? sum + order.total 
          : sum);

      final lastMonthRevenue = lastMonthOrders.fold(0.0, (sum, order) => 
        order.status != 'cancelled' && order.status != 'refunded' 
          ? sum + order.total 
          : sum);

      final previousMonthRevenue = previousMonthOrders.fold(0.0, (sum, order) => 
        order.status != 'cancelled' && order.status != 'refunded' 
          ? sum + order.total 
          : sum);

      // Calculate growth percentages
      final revenueGrowth = previousMonthRevenue == 0 
        ? 100 
        : ((lastMonthRevenue - previousMonthRevenue) / previousMonthRevenue * 100).round();

      final ordersGrowth = previousMonthOrders.isEmpty 
        ? 100 
        : ((lastMonthOrders.length - previousMonthOrders.length) / previousMonthOrders.length * 100).round();

      // Calculate unique customers
      final uniqueCustomers = orders
          .where((order) => order.status != 'cancelled')
          .map((order) => order.buyerId)
          .toSet();

      final lastMonthCustomers = lastMonthOrders
          .where((order) => order.status != 'cancelled')
          .map((order) => order.buyerId)
          .toSet();

      final previousMonthCustomers = previousMonthOrders
          .where((order) => order.status != 'cancelled')
          .map((order) => order.buyerId)
          .toSet();

      final customersGrowth = previousMonthCustomers.isEmpty 
        ? 100 
        : ((lastMonthCustomers.length - previousMonthCustomers.length) / previousMonthCustomers.length * 100).round();

      return {
        'id': seller.id,
        'name': sellerData['storeName'] ?? 'Unknown Store',
        'verified': sellerData['verified'] ?? false,
        'allTimeRevenue': allTimeRevenue,
        'netRevenue': allTimeRevenue * 0.9, // 90% after platform fee
        'withdrawn': sellerData['totalWithdrawn'] ?? 0.0,
        'totalOrders': orders.length,
        'totalCustomers': uniqueCustomers.length,
        'revenueGrowth': revenueGrowth,
        'ordersGrowth': ordersGrowth,
        'customersGrowth': customersGrowth,
        'withdrawalHistory': sellerData['withdrawalHistory'] ?? [],
      };
    } catch (e) {
      throw Exception('Failed to fetch store revenue: $e');
    }
  }

  Future<List<Seller>> getPendingSellerRegistrations({
    String? status,
    String? search,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final isUserAdmin = await isAdmin(user.uid);
    if (!isUserAdmin) throw Exception('User is not an admin');

    try {
      var query = _firestore.collection('sellers').where('registrationStatus', isEqualTo: status ?? 'pending');

      if (search != null && search.isNotEmpty) {
        query = query.where('storeName', isGreaterThanOrEqualTo: search)
            .where('storeName', isLessThan: '${search}z');
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Seller.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to load seller registrations: $e');
    }
  }

  Future<void> processSellerRegistration({
    required String sellerId,
    required bool approved,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final isUserAdmin = await isAdmin(user.uid);
    if (!isUserAdmin) throw Exception('User is not an admin');

    try {
      final batch = _firestore.batch();
      final sellerRef = _firestore.collection('sellers').doc(sellerId);
      final userRef = _firestore.collection('users').doc(sellerId);

      if (approved) {
        batch.update(sellerRef, {
          'registrationStatus': 'approved',
          'isActive': true,
          'adminMessage': message,
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': user.uid,
        });

        batch.update(userRef, {
          'isSeller': true,
        });
      } else {
        batch.update(sellerRef, {
          'registrationStatus': 'rejected',
          'adminMessage': message,
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': user.uid,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to process seller registration: $e');
    }
  }
} 