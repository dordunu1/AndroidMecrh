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
  final bool isActive;
  final String createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? options;

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
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.options,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      sellerId: map['sellerId'] as String,
      sellerName: map['sellerName'] as String? ?? 'Unknown Seller',
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      stockQuantity: (map['stockQuantity'] as num).toInt(),
      images: List<String>.from(map['images'] as List),
      category: map['category'] as String,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String?,
      options: map['options'] as Map<String, dynamic>?,
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
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'options': options,
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
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? options,
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
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      options: options ?? this.options,
    );
  }
} 