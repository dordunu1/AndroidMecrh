import 'package:cloud_firestore/cloud_firestore.dart';
import 'shipping_address.dart';

class MerchUser {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final bool isAdmin;
  final bool isSeller;
  final String createdAt;
  final List<ShippingAddress> shippingAddresses;
  final ShippingAddress? defaultShippingAddress;

  MerchUser({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    this.isAdmin = false,
    this.isSeller = false,
    required this.createdAt,
    required this.shippingAddresses,
    this.defaultShippingAddress,
  });

  factory MerchUser.fromMap(Map<String, dynamic> map) {
    final addresses = (map['shippingAddresses'] as List<dynamic>?)?.map((addr) => 
      ShippingAddress.fromMap(addr as Map<String, dynamic>)
    ).toList() ?? [];

    final defaultAddr = map['defaultShippingAddress'] != null ? 
      ShippingAddress.fromMap(map['defaultShippingAddress'] as Map<String, dynamic>) : null;

    return MerchUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      isAdmin: map['isAdmin'] ?? false,
      isSeller: map['isSeller'] ?? false,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      shippingAddresses: addresses,
      defaultShippingAddress: defaultAddr,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'isSeller': isSeller,
      'createdAt': createdAt,
      'shippingAddresses': shippingAddresses.map((addr) => addr.toMap()).toList(),
      'defaultShippingAddress': defaultShippingAddress?.toMap(),
    };
  }

  MerchUser copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    bool? isAdmin,
    bool? isSeller,
    String? createdAt,
    List<ShippingAddress>? shippingAddresses,
    ShippingAddress? defaultShippingAddress,
  }) {
    return MerchUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isSeller: isSeller ?? this.isSeller,
      createdAt: createdAt ?? this.createdAt,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
      defaultShippingAddress: defaultShippingAddress ?? this.defaultShippingAddress,
    );
  }
} 