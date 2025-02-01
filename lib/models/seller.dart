import 'package:cloud_firestore/cloud_firestore.dart';

class Seller {
  final String id;
  final String userId;
  final String storeName;
  final String description;
  final String? logo;
  final String? banner;
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
  final double deliveryFee;
  final String? shippingInfo;
  final String? paymentInfo;
  final double? latitude;
  final double? longitude;
  final int followersCount;
  final List<String> followers;
  final List<String> acceptedPaymentMethods;
  final Map<String, String> paymentPhoneNumbers;
  final Map<String, String> paymentNames;
  final String? paymentReference;
  final String registrationStatus;
  final String address;
  final bool isActive;
  final double registrationFee;
  final String? whatsappNumber;
  final String? instagramHandle;
  final String? tiktokHandle;

  Seller({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.description,
    this.logo,
    this.banner,
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
    this.deliveryFee = 0.0,
    this.shippingInfo,
    this.paymentInfo,
    this.latitude,
    this.longitude,
    this.followersCount = 0,
    this.followers = const [],
    this.acceptedPaymentMethods = const [],
    this.paymentPhoneNumbers = const {},
    this.paymentNames = const {},
    this.paymentReference,
    this.registrationStatus = 'pending',
    required this.address,
    this.isActive = false,
    required this.registrationFee,
    this.whatsappNumber,
    this.instagramHandle,
    this.tiktokHandle,
  });

  factory Seller.fromMap(Map<String, dynamic> map, String id) {
    return Seller(
      id: id,
      userId: map['userId'] ?? '',
      storeName: map['storeName'] ?? '',
      description: map['description'] ?? '',
      logo: map['logo'],
      banner: map['banner'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      zip: map['zip'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate().toIso8601String()
          : map['updatedAt'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      paymentDetails: map['paymentDetails'],
      averageRating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      shippingInfo: map['shippingInfo'],
      paymentInfo: map['paymentInfo'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      followersCount: map['followersCount'] ?? 0,
      followers: List<String>.from(map['followers'] ?? []),
      acceptedPaymentMethods: List<String>.from(map['acceptedPaymentMethods'] ?? []),
      paymentPhoneNumbers: Map<String, String>.from(map['paymentPhoneNumbers'] ?? {}),
      paymentNames: Map<String, String>.from(map['paymentNames'] ?? {}),
      paymentReference: map['paymentReference'],
      registrationStatus: map['registrationStatus'] ?? 'pending',
      address: map['address'] ?? '',
      isActive: map['isActive'] ?? false,
      registrationFee: (map['registrationFee'] ?? 800.0).toDouble(),
      whatsappNumber: map['whatsappNumber'],
      instagramHandle: map['instagramHandle'],
      tiktokHandle: map['tiktokHandle'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'storeName': storeName,
      'description': description,
      'logo': logo,
      'banner': banner,
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
      'deliveryFee': deliveryFee,
      'shippingInfo': shippingInfo,
      'paymentInfo': paymentInfo,
      'latitude': latitude,
      'longitude': longitude,
      'followersCount': followersCount,
      'followers': followers,
      'acceptedPaymentMethods': acceptedPaymentMethods,
      'paymentPhoneNumbers': paymentPhoneNumbers,
      'paymentNames': paymentNames,
      'paymentReference': paymentReference,
      'registrationStatus': registrationStatus,
      'address': address,
      'isActive': isActive,
      'registrationFee': registrationFee,
      'whatsappNumber': whatsappNumber,
      'instagramHandle': instagramHandle,
      'tiktokHandle': tiktokHandle,
    };
  }

  Seller copyWith({
    String? id,
    String? userId,
    String? storeName,
    String? description,
    String? logo,
    String? banner,
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
    double? deliveryFee,
    String? shippingInfo,
    String? paymentInfo,
    double? latitude,
    double? longitude,
    int? followersCount,
    List<String>? followers,
    List<String>? acceptedPaymentMethods,
    Map<String, String>? paymentPhoneNumbers,
    Map<String, String>? paymentNames,
    String? paymentReference,
    String? registrationStatus,
    String? address,
    bool? isActive,
    double? registrationFee,
    String? whatsappNumber,
    String? instagramHandle,
    String? tiktokHandle,
  }) {
    return Seller(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeName: storeName ?? this.storeName,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
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
      deliveryFee: deliveryFee ?? this.deliveryFee,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      followersCount: followersCount ?? this.followersCount,
      followers: followers ?? this.followers,
      acceptedPaymentMethods: acceptedPaymentMethods ?? this.acceptedPaymentMethods,
      paymentPhoneNumbers: paymentPhoneNumbers ?? this.paymentPhoneNumbers,
      paymentNames: paymentNames ?? this.paymentNames,
      paymentReference: paymentReference ?? this.paymentReference,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      registrationFee: registrationFee ?? this.registrationFee,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      tiktokHandle: tiktokHandle ?? this.tiktokHandle,
    );
  }
} 