import 'package:cloud_firestore/cloud_firestore.dart';
import 'shipping_address.dart';

class MerchUser {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? photoUrl;
  final bool isAdmin;
  final bool isSeller;
  final String? sellerId;
  final DateTime? sellerSince;
  final List<ShippingAddress> shippingAddresses;
  final ShippingAddress? defaultShippingAddress;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;

  MerchUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.photoUrl,
    this.isAdmin = false,
    this.isSeller = false,
    this.sellerId,
    this.sellerSince,
    this.shippingAddresses = const [],
    this.defaultShippingAddress,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
  });

  factory MerchUser.fromMap(Map<String, dynamic> map, String id) {
    final addresses = (map['shippingAddresses'] as List<dynamic>? ?? [])
        .asMap()
        .entries
        .map((entry) => ShippingAddress.fromMap(
              Map<String, dynamic>.from(entry.value),
              entry.key.toString(),
            ))
        .toList();

    final defaultAddress = map['defaultShippingAddress'] != null
        ? ShippingAddress.fromMap(
            Map<String, dynamic>.from(map['defaultShippingAddress']),
            map['defaultShippingAddress']['id'] ?? '0',
          )
        : null;

    return MerchUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'],
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      isAdmin: map['isAdmin'] ?? false,
      isSeller: map['isSeller'] ?? false,
      sellerId: map['sellerId'],
      sellerSince: map['sellerSince'] != null
          ? (map['sellerSince'] as Timestamp).toDate()
          : null,
      shippingAddresses: addresses,
      defaultShippingAddress: defaultAddress,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is String 
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] is Timestamp 
          ? (map['lastLoginAt'] as Timestamp).toDate() 
          : map['lastLoginAt'] is String 
              ? DateTime.parse(map['lastLoginAt'])
              : null,
      preferences: map['preferences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'isSeller': isSeller,
      'sellerId': sellerId,
      'sellerSince': sellerSince != null ? Timestamp.fromDate(sellerSince!) : null,
      'shippingAddresses': shippingAddresses.map((addr) => addr.toMap()).toList(),
      'defaultShippingAddress': defaultShippingAddress?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'preferences': preferences,
    };
  }

  MerchUser copyWith({
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    bool? isAdmin,
    bool? isSeller,
    String? sellerId,
    DateTime? sellerSince,
    List<ShippingAddress>? shippingAddresses,
    ShippingAddress? defaultShippingAddress,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return MerchUser(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isSeller: isSeller ?? this.isSeller,
      sellerId: sellerId ?? this.sellerId,
      sellerSince: sellerSince ?? this.sellerSince,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
      defaultShippingAddress: defaultShippingAddress ?? this.defaultShippingAddress,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }
} 