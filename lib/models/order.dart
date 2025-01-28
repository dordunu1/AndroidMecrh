import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String buyerId;
  final Map<String, dynamic> buyerInfo;
  final String sellerId;
  final Map<String, dynamic> sellerInfo;
  final List<OrderItem> items;
  final double total;
  final double deliveryFee;
  final String status;
  final Map<String, dynamic> shippingAddress;
  final DateTime createdAt;
  final String? trackingNumber;
  final String? shippingCarrier;
  final String? paymentStatus;
  final String? reference;

  Order({
    required this.id,
    required this.buyerId,
    required this.buyerInfo,
    required this.sellerId,
    required this.sellerInfo,
    required this.items,
    required this.total,
    required this.deliveryFee,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
    this.trackingNumber,
    this.shippingCarrier,
    this.paymentStatus,
    this.reference,
  });

  String get buyerName => buyerInfo['name'] as String? ?? 'Unknown';
  String get buyerEmail => buyerInfo['email'] as String? ?? '';
  String get buyerPhone => buyerInfo['phone'] as String? ?? '';

  String get sellerName => sellerInfo['name'] as String? ?? 'Unknown';
  String get sellerEmail => sellerInfo['email'] as String? ?? '';
  String get sellerPhone => sellerInfo['phone'] as String? ?? '';

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
    return Order(
      id: id,
      buyerId: map['buyerId'] as String,
      buyerInfo: Map<String, dynamic>.from(map['buyerInfo'] as Map),
      sellerId: map['sellerId'] as String,
      sellerInfo: Map<String, dynamic>.from(map['sellerInfo'] as Map),
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      total: (map['total'] as num).toDouble(),
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String,
      shippingAddress: Map<String, dynamic>.from(map['shippingAddress'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
      trackingNumber: map['trackingNumber'] as String?,
      shippingCarrier: map['shippingCarrier'] as String?,
      paymentStatus: map['paymentStatus'] as String?,
      reference: map['reference'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerInfo': buyerInfo,
      'sellerId': sellerId,
      'sellerInfo': sellerInfo,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'deliveryFee': deliveryFee,
      'status': status,
      'shippingAddress': shippingAddress,
      'createdAt': createdAt.toIso8601String(),
      'trackingNumber': trackingNumber,
      'shippingCarrier': shippingCarrier,
      'paymentStatus': paymentStatus,
      'reference': reference,
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;
  final Map<String, dynamic> options;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.options,
  });

  String? get selectedColor => options['selectedColor'] as String?;
  String? get selectedSize => options['selectedSize'] as String?;
  String? get selectedColorImage => options['selectedColorImage'] as String?;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      imageUrl: map['imageUrl'] as String,
      options: Map<String, dynamic>.from(map['options'] as Map),
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