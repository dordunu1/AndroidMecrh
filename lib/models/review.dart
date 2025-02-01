import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String sellerId;
  final double rating;
  final String comment;
  final List<String>? images;
  final DateTime createdAt;
  final bool isVerifiedPurchase;
  final String? orderId;
  final Map<String, dynamic>? sellerResponse;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.sellerId,
    required this.rating,
    required this.comment,
    this.images,
    required this.createdAt,
    this.isVerifiedPurchase = false,
    this.orderId,
    this.sellerResponse,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'],
      sellerId: map['sellerId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerifiedPurchase: map['isVerifiedPurchase'] ?? false,
      orderId: map['orderId'],
      sellerResponse: map['sellerResponse'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'sellerId': sellerId,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerifiedPurchase': isVerifiedPurchase,
      'orderId': orderId,
      'sellerResponse': sellerResponse,
    };
  }

  Review copyWith({
    String? userName,
    String? userPhoto,
    double? rating,
    String? comment,
    List<String>? images,
    Map<String, dynamic>? sellerResponse,
  }) {
    return Review(
      id: id,
      productId: productId,
      userId: userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      sellerId: sellerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      createdAt: createdAt,
      isVerifiedPurchase: isVerifiedPurchase,
      orderId: orderId,
      sellerResponse: sellerResponse ?? this.sellerResponse,
    );
  }
} 