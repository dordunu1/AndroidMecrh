import 'package:cloud_firestore/cloud_firestore.dart';

class MerchUser {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final bool isAdmin;
  final bool isSeller;
  final String? sellerId;
  final List<Map<String, dynamic>> shippingAddresses;
  final Map<String, dynamic>? defaultShippingAddress;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;

  MerchUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.isAdmin = false,
    this.isSeller = false,
    this.sellerId,
    this.shippingAddresses = const [],
    this.defaultShippingAddress,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
  });

  factory MerchUser.fromMap(Map<String, dynamic> map, String id) {
    return MerchUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'],
      photoUrl: map['photoUrl'],
      isAdmin: map['isAdmin'] ?? false,
      isSeller: map['isSeller'] ?? false,
      sellerId: map['sellerId'],
      shippingAddresses: List<Map<String, dynamic>>.from(map['shippingAddresses'] ?? []),
      defaultShippingAddress: map['defaultShippingAddress'],
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
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'isSeller': isSeller,
      'sellerId': sellerId,
      'shippingAddresses': shippingAddresses,
      'defaultShippingAddress': defaultShippingAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'preferences': preferences,
    };
  }

  MerchUser copyWith({
    String? email,
    String? name,
    String? photoUrl,
    bool? isAdmin,
    bool? isSeller,
    String? sellerId,
    List<Map<String, dynamic>>? shippingAddresses,
    Map<String, dynamic>? defaultShippingAddress,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return MerchUser(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isSeller: isSeller ?? this.isSeller,
      sellerId: sellerId ?? this.sellerId,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
      defaultShippingAddress: defaultShippingAddress ?? this.defaultShippingAddress,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }
} 