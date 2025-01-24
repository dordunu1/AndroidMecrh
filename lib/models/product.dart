import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String sellerName;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final List<String> images;
  final String category;
  final String? subCategory;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;
  final double shippingFee;
  final String? shippingInfo;
  final bool hasVariants;
  final List<String> sizes;
  final List<String> colors;
  final Map<String, int> colorQuantities;
  final bool hasDiscount;
  final double discountPercent;
  final String? discountEndsAt;
  final double? discountedPrice;
  final int soldCount;

  int get stock => stockQuantity;

  Product({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.images,
    required this.category,
    this.subCategory,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.shippingFee,
    this.shippingInfo,
    this.hasVariants = false,
    this.sizes = const [],
    this.colors = const [],
    this.colorQuantities = const {},
    this.hasDiscount = false,
    this.discountPercent = 0,
    this.discountEndsAt,
    this.discountedPrice,
    this.soldCount = 0,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    String? getTimestampString(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      }
      return value.toString();
    }

    return Product(
      id: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      images: List<String>.from(map['images'] ?? []),
      category: map['category'] ?? '',
      subCategory: map['subCategory'],
      isActive: map['isActive'] ?? true,
      createdAt: getTimestampString(map['createdAt']) ?? DateTime.now().toIso8601String(),
      updatedAt: getTimestampString(map['updatedAt']),
      shippingFee: (map['shippingFee'] ?? 0.0).toDouble(),
      shippingInfo: map['shippingInfo'],
      hasVariants: map['hasVariants'] ?? false,
      sizes: List<String>.from(map['sizes'] ?? []),
      colors: List<String>.from(map['colors'] ?? []),
      colorQuantities: Map<String, int>.from(map['colorQuantities'] ?? {}),
      hasDiscount: map['hasDiscount'] ?? false,
      discountPercent: (map['discountPercent'] ?? 0.0).toDouble(),
      discountEndsAt: getTimestampString(map['discountEndsAt']),
      discountedPrice: (map['discountedPrice'] ?? 0.0).toDouble(),
      soldCount: map['soldCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'name': name,
      'description': description,
      'price': price,
      'stockQuantity': stockQuantity,
      'images': images,
      'category': category,
      'subCategory': subCategory,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'shippingFee': shippingFee,
      'shippingInfo': shippingInfo,
      'hasVariants': hasVariants,
      'sizes': sizes,
      'colors': colors,
      'colorQuantities': colorQuantities,
      'hasDiscount': hasDiscount,
      'discountPercent': discountPercent,
      'discountEndsAt': discountEndsAt,
      'discountedPrice': discountedPrice,
      'soldCount': soldCount,
    };
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    List<String>? images,
    String? category,
    String? subCategory,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    double? shippingFee,
    String? shippingInfo,
    bool? hasVariants,
    List<String>? sizes,
    List<String>? colors,
    Map<String, int>? colorQuantities,
    bool? hasDiscount,
    double? discountPercent,
    String? discountEndsAt,
    double? discountedPrice,
    int? soldCount,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      images: images ?? this.images,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippingFee: shippingFee ?? this.shippingFee,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      hasVariants: hasVariants ?? this.hasVariants,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      colorQuantities: colorQuantities ?? this.colorQuantities,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercent: discountPercent ?? this.discountPercent,
      discountEndsAt: discountEndsAt ?? this.discountEndsAt,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      soldCount: soldCount ?? this.soldCount,
    );
  }
} 