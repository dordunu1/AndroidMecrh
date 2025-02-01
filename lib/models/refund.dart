import 'package:cloud_firestore/cloud_firestore.dart';

class Refund {
  final String id;
  final String orderId;
  final String shortOrderId;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerName;
  final double amount;
  final String reason;
  final List<String> images;
  final String? orderImage;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNote;

  Refund({
    required this.id,
    required this.orderId,
    required this.shortOrderId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerName,
    required this.amount,
    required this.reason,
    required this.images,
    this.orderImage,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminNote,
  });

  factory Refund.fromMap(Map<String, dynamic> map, String id) {
    print('DEBUG: Creating Refund from map: $map'); // Debug print
    return Refund(
      id: id,
      orderId: map['orderId'] as String,
      shortOrderId: map['shortOrderId'] as String? ?? map['orderId'].substring(0, 8),
      buyerId: map['buyerId'] as String,
      sellerId: map['sellerId'] as String,
      buyerName: map['buyerName'] as String,
      buyerPhone: map['phoneNumber'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? 'Unknown Seller',
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] as String,
      images: List<String>.from(map['images'] as List? ?? []),
      orderImage: map['orderImage'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt'] as String) : null,
      adminNote: map['adminNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'shortOrderId': shortOrderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'sellerName': sellerName,
      'amount': amount,
      'reason': reason,
      'images': images,
      'orderImage': orderImage,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'adminNote': adminNote,
    };
  }

  Refund copyWith({
    String? id,
    String? orderId,
    String? shortOrderId,
    String? buyerId,
    String? sellerId,
    String? buyerName,
    String? buyerPhone,
    String? sellerName,
    double? amount,
    String? reason,
    List<String>? images,
    String? orderImage,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminNote,
  }) {
    return Refund(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      shortOrderId: shortOrderId ?? this.shortOrderId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      sellerName: sellerName ?? this.sellerName,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      images: images ?? this.images,
      orderImage: orderImage ?? this.orderImage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNote: adminNote ?? this.adminNote,
    );
  }
} 