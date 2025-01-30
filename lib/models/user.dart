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
  final bool isBuyer;
  final String? sellerId;
  final DateTime? sellerSince;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zip;
  final List<ShippingAddress> shippingAddresses;
  final ShippingAddress? defaultShippingAddress;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;
  final bool hasSubmittedSellerRegistration;
  final String? sellerRegistrationStatus;

  MerchUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.photoUrl,
    this.isAdmin = false,
    this.isSeller = false,
    this.isBuyer = true,
    this.sellerId,
    this.sellerSince,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zip,
    this.shippingAddresses = const [],
    this.defaultShippingAddress,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
    this.hasSubmittedSellerRegistration = false,
    this.sellerRegistrationStatus,
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
      isBuyer: map['isBuyer'] ?? true,
      sellerId: map['sellerId'],
      sellerSince: map['sellerSince'] != null
          ? (map['sellerSince'] as Timestamp).toDate()
          : null,
      address: map['address'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
      zip: map['zip'],
      shippingAddresses: addresses,
      defaultShippingAddress: defaultAddress,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is String 
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] is Timestamp 
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : null,
      preferences: map['preferences'] != null
          ? Map<String, dynamic>.from(map['preferences'])
          : null,
      hasSubmittedSellerRegistration: map['hasSubmittedSellerRegistration'] ?? false,
      sellerRegistrationStatus: map['sellerRegistrationStatus'],
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'phone': phone,
    'photoUrl': photoUrl,
    'isAdmin': isAdmin,
    'isSeller': isSeller,
    'isBuyer': isBuyer,
    'sellerId': sellerId,
    'sellerSince': sellerSince?.toIso8601String(),
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'zip': zip,
    'shippingAddresses': shippingAddresses.map((addr) => addr.toMap()).toList(),
    'defaultShippingAddress': defaultShippingAddress?.toMap(),
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'preferences': preferences,
    'hasSubmittedSellerRegistration': hasSubmittedSellerRegistration,
    'sellerRegistrationStatus': sellerRegistrationStatus,
  };

  MerchUser copyWith({
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    bool? isAdmin,
    bool? isSeller,
    bool? isBuyer,
    String? sellerId,
    DateTime? sellerSince,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zip,
    List<ShippingAddress>? shippingAddresses,
    ShippingAddress? defaultShippingAddress,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    bool? hasSubmittedSellerRegistration,
    String? sellerRegistrationStatus,
  }) {
    return MerchUser(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isSeller: isSeller ?? this.isSeller,
      isBuyer: isBuyer ?? this.isBuyer,
      sellerId: sellerId ?? this.sellerId,
      sellerSince: sellerSince ?? this.sellerSince,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zip: zip ?? this.zip,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
      defaultShippingAddress: defaultShippingAddress ?? this.defaultShippingAddress,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      hasSubmittedSellerRegistration: hasSubmittedSellerRegistration ?? this.hasSubmittedSellerRegistration,
      sellerRegistrationStatus: sellerRegistrationStatus ?? this.sellerRegistrationStatus,
    );
  }
} 