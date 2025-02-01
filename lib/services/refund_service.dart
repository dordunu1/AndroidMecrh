import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/refund.dart';
import '../models/order.dart' as app_order;
import 'package:firebase_auth/firebase_auth.dart';

final refundServiceProvider = Provider((ref) => RefundService());

class RefundService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<Refund>> getRefunds({String? search, String? status}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      var query = _db.collection('refunds')
          .where('buyerId', isEqualTo: user.uid);

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

  Future<Refund> createRefund(String orderId, String reason, List<String> images) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order = app_order.Order.fromMap(orderDoc.data()!, orderDoc.id);
      if (order.buyerId != user.uid) throw Exception('Not authorized to create refund for this order');

      final refundDoc = await _db.collection('refunds').add({
        'orderId': orderId,
        'buyerId': user.uid,
        'buyerName': order.buyerName,
        'sellerId': order.sellerId,
        'sellerName': order.sellerName,
        'amount': order.total,
        'reason': reason,
        'images': images,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      final refundData = await refundDoc.get();
      return Refund.fromMap(refundData.data()!, refundDoc.id);
    } catch (e) {
      throw Exception('Failed to create refund: $e');
    }
  }

  Future<void> updateRefundStatus(String refundId, String status, {String? adminNote}) async {
    final data = {
      'status': status,
      'resolvedAt': DateTime.now().toIso8601String(),
      if (adminNote != null) 'adminNote': adminNote,
    };
    
    await _db.collection('refunds').doc(refundId).update(data);
  }
} 