import 'package:cloud_firestore/cloud_firestore.dart';

class Seller {
  final String id;
  final String userId;
  final String storeName;
  final String description;
  final String? logo;
  final String? banner;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zip;
  final String phone;
  final String email;
  final bool isVerified;
  final String createdAt;
  final String? updatedAt;
  final double balance;
  final Map<String, dynamic>? paymentDetails;
  final double averageRating;
  final int reviewCount;
  final double shippingFee;
  final String? shippingInfo;
  final String? paymentInfo;

  Seller({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.description,
    this.logo,
    this.banner,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zip,
    required this.phone,
    required this.email,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.balance = 0.0,
    this.paymentDetails,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.shippingFee = 0.0,
    this.shippingInfo,
    this.paymentInfo,
  });

  factory Seller.fromMap(Map<String, dynamic> map, String id) {
    return Seller(
      id: id,
      userId: map['userId'] ?? '',
      storeName: map['storeName'] ?? '',
      description: map['description'] ?? '',
      logo: map['logo'],
      banner: map['banner'],
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      zip: map['zip'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      paymentDetails: map['paymentDetails'],
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      shippingFee: (map['shippingFee'] ?? 0.0).toDouble(),
      shippingInfo: map['shippingInfo'],
      paymentInfo: map['paymentInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'storeName': storeName,
      'description': description,
      'logo': logo,
      'banner': banner,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip': zip,
      'phone': phone,
      'email': email,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'balance': balance,
      'paymentDetails': paymentDetails,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'shippingFee': shippingFee,
      'shippingInfo': shippingInfo,
      'paymentInfo': paymentInfo,
    };
  }

  Seller copyWith({
    String? id,
    String? userId,
    String? storeName,
    String? description,
    String? logo,
    String? banner,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zip,
    String? phone,
    String? email,
    bool? isVerified,
    String? createdAt,
    String? updatedAt,
    double? balance,
    Map<String, dynamic>? paymentDetails,
    double? averageRating,
    int? reviewCount,
    double? shippingFee,
    String? shippingInfo,
    String? paymentInfo,
  }) {
    return Seller(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeName: storeName ?? this.storeName,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zip: zip ?? this.zip,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balance: balance ?? this.balance,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      shippingFee: shippingFee ?? this.shippingFee,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }
} 