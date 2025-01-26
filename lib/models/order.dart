import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final Map<String, dynamic> buyerInfo;
  final Map<String, dynamic> sellerInfo;
  final Map<String, dynamic> shippingAddress;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? trackingNumber;
  final String? shippingCarrier;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.buyerInfo,
    required this.sellerInfo,
    required this.shippingAddress,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.trackingNumber,
    this.shippingCarrier,
  });

  // Getters for buyerInfo
  String get buyerName => buyerInfo['name'] as String;
  String get buyerPhone => buyerInfo['phone'] as String;
  String get buyerEmail => buyerInfo['email'] as String;

  // Getters for sellerInfo
  String get sellerName => sellerInfo['name'] as String;
  String get sellerPhone => sellerInfo['phone'] as String;
  String get sellerEmail => sellerInfo['email'] as String;

  // Getters for shippingAddress
  String get shippingAddressName => shippingAddress['name'] as String;
  String get shippingAddressAddress => shippingAddress['address'] as String;
  String get shippingAddressCity => shippingAddress['city'] as String;
  String get shippingAddressState => shippingAddress['state'] as String;
  String get shippingAddressZip => shippingAddress['zip'] as String;
  String get shippingAddressCountry => shippingAddress['country'] as String;
  String get shippingAddressPhone => shippingAddress['phone'] as String;

  // Additional getters for compatibility
  String get flag => status;

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return Order(
      id: id,
      buyerId: map['buyerId'] as String,
      sellerId: map['sellerId'] as String,
      buyerInfo: Map<String, dynamic>.from(map['buyerInfo'] as Map),
      sellerInfo: Map<String, dynamic>.from(map['sellerInfo'] as Map),
      shippingAddress: Map<String, dynamic>.from(map['shippingAddress'] as Map),
      items: List<OrderItem>.from(
        (map['items'] as List).map((x) => OrderItem.fromMap(Map<String, dynamic>.from(x as Map))),
      ),
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDateTime(map['updatedAt']) : null,
      trackingNumber: map['trackingNumber'] as String?,
      shippingCarrier: map['shippingCarrier'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerInfo': buyerInfo,
      'sellerInfo': sellerInfo,
      'shippingAddress': shippingAddress,
      'items': items.map((x) => x.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'trackingNumber': trackingNumber,
      'shippingCarrier': shippingCarrier,
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final Map<String, dynamic>? options;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.options,
  });

  String get productName => name;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity']?.toInt() ?? 0,
      imageUrl: map['imageUrl'],
      options: map['options'] != null ? Map<String, dynamic>.from(map['options']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'options': options,
    };
  }
} 