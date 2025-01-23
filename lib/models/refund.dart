import 'package:cloud_firestore/cloud_firestore.dart';

class Refund {
  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final double amount;
  final String reason;
  final List<String> images;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNote;

  Refund({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.sellerName,
    required this.amount,
    required this.reason,
    required this.images,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminNote,
  });

  factory Refund.fromMap(Map<String, dynamic> map, String id) {
    return Refund(
      id: id,
      orderId: map['orderId'] as String,
      buyerId: map['buyerId'] as String,
      sellerId: map['sellerId'] as String,
      buyerName: map['buyerName'] as String,
      sellerName: map['sellerName'] as String,
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] as String,
      images: List<String>.from(map['images'] as List),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt'] as String) : null,
      adminNote: map['adminNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerName': buyerName,
      'sellerName': sellerName,
      'amount': amount,
      'reason': reason,
      'images': images,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'adminNote': adminNote,
    };
  }

  Refund copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    String? sellerId,
    String? buyerName,
    String? sellerName,
    double? amount,
    String? reason,
    List<String>? images,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminNote,
  }) {
    return Refund(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      buyerName: buyerName ?? this.buyerName,
      sellerName: sellerName ?? this.sellerName,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNote: adminNote ?? this.adminNote,
    );
  }
} 