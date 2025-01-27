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

  Future<List<app_order.Order>> getOrders({String? search, String? status}) async {
    try {
      var query = _firestore.collection('orders')
          .orderBy('createdAt', descending: true);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) {
        return app_order.Order.fromMap(doc.data(), doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return orders.where((order) {
          return order.buyerName.toLowerCase().contains(searchLower) ||
              order.sellerName.toLowerCase().contains(searchLower) ||
              order.id.toLowerCase().contains(searchLower);
        }).toList();
      }

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<List<Seller>> getSellers({String? status}) async {
    try {
      var query = _firestore.collection('sellers')
          .orderBy('createdAt', descending: true);

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return Seller.fromMap(doc.data(), doc.id);
      }).toList();
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
        return Refund.fromMap(doc.data(), doc.id);
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
      // Get all orders with proper date filtering
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();

      final orders = ordersSnapshot.docs.map((doc) => app_order.Order.fromMap(doc.data(), doc.id)).toList();

      // Calculate order stats
      var totalSales = 0.0;
      var platformFees = 0.0;
      var totalOrders = 0;
      var processingOrders = 0;

      for (final order in orders) {
        if (order.status != 'cancelled' && order.status != 'refunded') {
          totalSales += order.total;
          platformFees += order.total * 0.1; // 10% platform fee
          totalOrders++;
        }
        if (order.status == 'processing') {
          processingOrders++;
        }
      }

      // Get active sellers
      final sellersSnapshot = await _firestore
          .collection('sellers')
          .where('isActive', isEqualTo: true)
          .get();
      
      final sellers = sellersSnapshot.docs.map((doc) => Seller.fromMap(doc.data()!, doc.id)).toList();

      // Calculate top sellers based on total sales
      final sellerSales = <String, double>{};
      for (final order in orders) {
        if (order.status != 'cancelled' && order.status != 'refunded') {
          sellerSales[order.sellerId] = (sellerSales[order.sellerId] ?? 0) + order.total;
        }
      }

      final topSellers = sellers.where((seller) => sellerSales.containsKey(seller.id))
          .toList()
        ..sort((a, b) => (sellerSales[b.id] ?? 0).compareTo(sellerSales[a.id] ?? 0));

      // Get total products count
      final productsSnapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      // Get pending verifications count
      final pendingVerificationsSnapshot = await _firestore
          .collection('sellers')
          .where('isVerified', isEqualTo: false)
          .count()
          .get();

      // Get pending withdrawals
      final pendingWithdrawalsSnapshot = await _firestore
          .collection('withdrawals')
          .where('status', isEqualTo: 'pending')
          .get();

      // Get pending refunds
      final pendingRefundsSnapshot = await _firestore
          .collection('refunds')
          .where('status', isEqualTo: 'pending')
          .get();

      // Prepare pending actions list
      final pendingActions = [
        ...pendingWithdrawalsSnapshot.docs.map((doc) => {
          'id': doc.id,
          'type': 'withdrawal',
          'amount': doc.data()['amount'],
          'sellerName': doc.data()['sellerName'],
          'createdAt': doc.data()['createdAt'],
        }),
        ...pendingRefundsSnapshot.docs.map((doc) => {
          'id': doc.id,
          'type': 'refund',
          'amount': doc.data()['amount'],
          'orderId': doc.data()['orderId'],
          'createdAt': doc.data()['createdAt'],
        }),
      ]..sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      return {
        'stats': {
          'totalSales': totalSales,
          'platformFees': platformFees,
          'totalOrders': totalOrders,
          'processingOrders': processingOrders,
          'activeSellers': sellersSnapshot.docs.length,
          'totalProducts': productsSnapshot.count,
          'pendingVerifications': pendingVerificationsSnapshot.count,
          'pendingWithdrawals': pendingWithdrawalsSnapshot.docs.length,
          'pendingRefunds': pendingRefundsSnapshot.docs.length,
        },
        'recentOrders': orders.take(5).toList(),
        'topSellers': topSellers.take(5).toList(),
        'pendingActions': pendingActions,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
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
} 