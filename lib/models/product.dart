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
  final double? shippingFee;
  final String? shippingInfo;
  final bool hasVariants;
  final List<String> sizes;
  final List<String> colors;
  final Map<String, int> colorQuantities;
  final Map<String, String> imageColors;
  final bool hasDiscount;
  final double discountPercent;
  final DateTime? discountEndsAt;
  final double? discountedPrice;
  final int soldCount;
  final int cartCount;
  final double rating;
  final int reviewCount;
  final String? sellerCity;
  final String? sellerCountry;
  final Map<String, int>? variantQuantities;
  final double deliveryFee;
  final double? discountPrice;

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
    this.shippingFee,
    this.shippingInfo,
    required this.hasVariants,
    required this.sizes,
    required this.colors,
    required this.colorQuantities,
    required this.imageColors,
    required this.hasDiscount,
    required this.discountPercent,
    this.discountEndsAt,
    this.discountedPrice,
    required this.soldCount,
    this.cartCount = 0,
    required this.rating,
    required this.reviewCount,
    this.sellerCity,
    this.sellerCountry,
    this.variantQuantities,
    this.deliveryFee = 0.0,
    this.discountPrice,
  });

  String? get imageUrl => images.isNotEmpty ? images.first : null;

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    String? getTimestampString(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      }
      return value.toString();
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.parse(value);
      }
      return null;
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
      imageColors: Map<String, String>.from(map['imageColors'] ?? {}),
      hasDiscount: map['hasDiscount'] ?? false,
      discountPercent: (map['discountPercent'] ?? 0.0).toDouble(),
      discountEndsAt: parseDateTime(map['discountEndsAt']),
      discountedPrice: (map['discountedPrice'] ?? 0.0).toDouble(),
      soldCount: map['soldCount'] ?? 0,
      cartCount: map['cartCount'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      sellerCity: map['sellerCity'],
      sellerCountry: map['sellerCountry'],
      variantQuantities: map['variantQuantities'] != null 
          ? Map<String, int>.from(map['variantQuantities'])
          : null,
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      discountPrice: map['discountPrice']?.toDouble(),
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
      'imageColors': imageColors,
      'hasDiscount': hasDiscount,
      'discountPercent': discountPercent,
      'discountEndsAt': discountEndsAt?.toIso8601String(),
      'discountedPrice': discountedPrice,
      'soldCount': soldCount,
      'cartCount': cartCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'sellerCity': sellerCity,
      'sellerCountry': sellerCountry,
      'variantQuantities': variantQuantities,
      'deliveryFee': deliveryFee,
      'discountPrice': discountPrice,
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
    Map<String, String>? imageColors,
    bool? hasDiscount,
    double? discountPercent,
    DateTime? discountEndsAt,
    double? discountedPrice,
    int? soldCount,
    int? cartCount,
    double? rating,
    int? reviewCount,
    String? sellerCity,
    String? sellerCountry,
    Map<String, int>? variantQuantities,
    double? deliveryFee,
    double? discountPrice,
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
      imageColors: imageColors ?? this.imageColors,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercent: discountPercent ?? this.discountPercent,
      discountEndsAt: discountEndsAt ?? this.discountEndsAt,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      soldCount: soldCount ?? this.soldCount,
      cartCount: cartCount ?? this.cartCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      sellerCity: sellerCity ?? this.sellerCity,
      sellerCountry: sellerCountry ?? this.sellerCountry,
      variantQuantities: variantQuantities ?? this.variantQuantities,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountPrice: discountPrice ?? this.discountPrice,
    );
  }
} 