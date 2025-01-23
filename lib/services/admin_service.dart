import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as app_order;
import '../models/seller.dart';
import '../models/refund.dart';
import '../models/withdrawal.dart';

final adminServiceProvider = Provider((ref) => AdminService());

class AdminService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<app_order.Order>> getOrders({String? search, String? status}) async {
    try {
      var query = _db.collection('orders')
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
      var query = _db.collection('sellers')
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
      await _db.collection('sellers').doc(sellerId).update({
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

    final snapshot = await _db.collection('orders')
      .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
      .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
      .orderBy('createdAt', descending: true)
      .get();

    return snapshot.docs.map((doc) => app_order.Order.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Refund>> getRefunds({String? search, String? status}) async {
    try {
      var query = _db.collection('refunds')
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

  Future<void> updateRefundStatus(String refundId, String status, {String? adminNote}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final refundDoc = await _db.collection('refunds').doc(refundId).get();
    if (!refundDoc.exists) throw Exception('Refund not found');

    final refund = Refund.fromMap(refundDoc.data()!, refundDoc.id);

    final batch = _db.batch();

    // Update refund status
    batch.update(_db.collection('refunds').doc(refundId), {
      'status': status,
      'resolvedAt': DateTime.now().toIso8601String(),
      if (adminNote != null) 'adminNote': adminNote,
    });

    // If approved, update seller balance
    if (status == 'approved') {
      batch.update(_db.collection('sellers').doc(refund.sellerId), {
        'balance': FieldValue.increment(-refund.amount),
      });
    }

    await batch.commit();
  }

  Future<List<Withdrawal>> getWithdrawals({String? search, String? status}) async {
    try {
      var query = _db.collection('withdrawals')
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

  Future<void> updateWithdrawalStatus(String withdrawalId, String status, {String? adminNote}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _db.collection('withdrawals').doc(withdrawalId).update({
      'status': status,
      'resolvedAt': DateTime.now().toIso8601String(),
      if (adminNote != null) 'adminNote': adminNote,
    });
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final ordersSnapshot = await _db.collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .get();

      var totalSales = 0.0;
      var totalOrders = 0;
      var processingOrders = 0;

      for (final doc in ordersSnapshot.docs) {
        final order = app_order.Order.fromMap(doc.data(), doc.id);
        if (order.status != 'cancelled' && order.status != 'refunded') {
          totalSales += order.total;
          totalOrders++;
        }
        if (order.status == 'processing') {
          processingOrders++;
        }
      }

      final sellersSnapshot = await _db.collection('sellers').get();
      final totalSellers = sellersSnapshot.docs.length;
      final pendingVerifications = sellersSnapshot.docs
        .where((doc) => doc.data()['isVerified'] == false)
        .length;

      final refundsSnapshot = await _db.collection('refunds')
        .where('status', isEqualTo: 'pending')
        .get();
      final pendingRefunds = refundsSnapshot.docs.length;

      final withdrawalsSnapshot = await _db.collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .get();
      final pendingWithdrawals = withdrawalsSnapshot.docs.length;

      return {
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'processingOrders': processingOrders,
        'totalSellers': totalSellers,
        'pendingVerifications': pendingVerifications,
        'pendingRefunds': pendingRefunds,
        'pendingWithdrawals': pendingWithdrawals,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard data: $e');
    }
  }

  Future<List<Seller>> getPendingVerifications({String? search}) async {
    try {
      final snapshot = await _db.collection('sellers')
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
      final refundDoc = await _db.collection('refunds').doc(refundId).get();
      if (!refundDoc.exists) throw Exception('Refund not found');

      final refund = Refund.fromMap(refundDoc.data()!, refundDoc.id);

      final batch = _db.batch();

      // Update refund status
      batch.update(_db.collection('refunds').doc(refundId), {
        'status': approved ? 'approved' : 'rejected',
        'resolvedAt': DateTime.now().toIso8601String(),
        if (message != null) 'adminNote': message,
      });

      // If approved, update seller balance
      if (approved) {
        batch.update(_db.collection('sellers').doc(refund.sellerId), {
          'balance': FieldValue.increment(-refund.amount),
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
      await _db.collection('withdrawals').doc(withdrawalId).update({
        'status': approved ? 'approved' : 'rejected',
        'processedAt': DateTime.now().toIso8601String(),
        if (message != null) 'adminNote': message,
      });
    } catch (e) {
      throw Exception('Failed to process withdrawal: $e');
    }
  }
} 