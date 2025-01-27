import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../models/order.dart' as app_order;
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/review.dart';
import 'auth_service.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(ref);
});

class RealtimeService {
  final Ref _ref;
  final _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription> _listeners = {};

  RealtimeService(this._ref);

  // ============= Seller Dashboard Listeners =============
  
  /// Listen to all seller statistics in real-time
  StreamSubscription listenToSellerDashboard(String sellerId, Function(Map<String, dynamic>) onUpdate) {
    // Create a merged stream for all seller-related data
    final statsStream = _firestore
        .collection('sellers')
        .doc(sellerId)
        .snapshots();

    final ordersStream = _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots();

    final productsStream = _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots();

    final reviewsStream = _firestore
        .collection('reviews')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots();

    // Combine all streams
    final subscription = Rx.combineLatest4(
      statsStream,
      ordersStream,
      productsStream,
      reviewsStream,
      (
        DocumentSnapshot sellerStats,
        QuerySnapshot orders,
        QuerySnapshot products,
        QuerySnapshot reviews,
      ) {
        // Calculate real-time statistics
        final ordersList = orders.docs.map((doc) => app_order.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        
        final totalSales = ordersList.fold(0.0, (sum, order) => 
          order.status != 'cancelled' && order.status != 'refunded' 
            ? sum + order.total 
            : sum
        );
        
        final processingOrders = ordersList.where((order) => order.status == 'processing').length;
        
        final averageRating = reviews.docs.isEmpty 
          ? 0.0 
          : reviews.docs.fold<double>(0.0, (sum, doc) => sum + ((doc.data() as Map<String, dynamic>)['rating'] as num).toDouble()) / reviews.docs.length;

        return {
          'statistics': {
            'totalSales': totalSales,
            'balance': (sellerStats.data() as Map<String, dynamic>)?['balance']?.toDouble() ?? 0.0,
            'totalOrders': ordersList.length,
            'processingOrders': processingOrders,
            'totalProducts': products.docs.length,
            'averageRating': averageRating,
            'reviewCount': reviews.docs.length,
          },
          'recentOrders': ordersList.take(5).toList(),
        };
      },
    ).listen(onUpdate);

    _listeners['seller_dashboard_$sellerId'] = subscription;
    return subscription;
  }

  // ============= Order Management Listeners =============
  
  /// Listen to seller's orders with optional status filter
  StreamSubscription listenToOrders(String sellerId, Function(List<app_order.Order>) onUpdate, {String? status}) {
    var query = _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true);

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    final subscription = query.snapshots().listen((snapshot) {
      final orders = snapshot.docs
          .map((doc) => app_order.Order.fromMap(doc.data(), doc.id))
          .toList();
      onUpdate(orders);
    });

    _listeners['orders_${sellerId}_${status ?? 'all'}'] = subscription;
    return subscription;
  }

  // ============= Product Management Listeners =============
  
  /// Listen to product changes including stock and variants
  StreamSubscription listenToProducts(String sellerId, Function(List<Product>) onUpdate) {
    final subscription = _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .listen((snapshot) {
          final products = snapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id))
              .toList();
          onUpdate(products);
        });

    _listeners['products_$sellerId'] = subscription;
    return subscription;
  }

  /// Listen to specific product's stock and variants
  StreamSubscription listenToProductStock(String productId, Function(Product) onUpdate) {
    final subscription = _firestore
        .collection('products')
        .doc(productId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final product = Product.fromMap(snapshot.data()!, snapshot.id);
            onUpdate(product);
          }
        });

    _listeners['product_stock_$productId'] = subscription;
    return subscription;
  }

  /// Listen to multiple products' stock and variants
  StreamSubscription listenToMultipleProducts(List<String> productIds, Function(List<Product>) onUpdate) {
    final streams = productIds.map((id) => 
      _firestore.collection('products').doc(id).snapshots()
    ).toList();

    final subscription = Rx.combineLatestList(streams).listen((snapshots) {
      final products = snapshots
          .where((snapshot) => snapshot.exists)
          .map((snapshot) => Product.fromMap(snapshot.data()!, snapshot.id))
          .toList();
      onUpdate(products);
    });

    _listeners['multiple_products_${productIds.join("_")}'] = subscription;
    return subscription;
  }

  /// Listen to buyer's cart updates with real-time product data
  StreamSubscription listenToCart(String buyerId, Function(List<CartItem>) onUpdate) {
    final subscription = _firestore
        .collection('carts')
        .doc(buyerId)
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.exists) {
            final cartData = snapshot.data()!;
            final items = cartData['items'] as List<dynamic>;
            
            if (items.isEmpty) {
              onUpdate([]);
              return;
            }

            // Get all product IDs from cart items
            final productIds = items
                .map((item) => item['productId'] as String)
                .toSet()
                .toList();

            // Get real-time product data
            final productDocs = await Future.wait(
              productIds.map((id) => 
                _firestore.collection('products').doc(id).get()
              )
            );

            final products = Map.fromEntries(
              productDocs
                  .where((doc) => doc.exists)
                  .map((doc) => MapEntry(
                        doc.id,
                        Product.fromMap(doc.data()!, doc.id),
                      ))
            );

            // Create cart items with latest product data
            final cartItems = items.map((item) {
              final productId = item['productId'] as String;
              final product = products[productId];
              if (product == null) return null;

              return CartItem.fromMap(
                item as Map<String, dynamic>,
                product,
              );
            }).whereType<CartItem>().toList();

            onUpdate(cartItems);
          } else {
            onUpdate([]);
          }
        });

    _listeners['cart_$buyerId'] = subscription;
    return subscription;
  }

  // ============= Review Listeners =============
  
  /// Listen to product reviews
  StreamSubscription listenToProductReviews(String productId, Function(List<Review>) onUpdate) {
    final subscription = _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => Review.fromMap(doc.data(), doc.id))
              .toList();
          onUpdate(reviews);
        });

    _listeners['product_reviews_$productId'] = subscription;
    return subscription;
  }

  /// Listen to seller reviews
  StreamSubscription listenToSellerReviews(String sellerId, Function(List<Review>) onUpdate) {
    final subscription = _firestore
        .collection('reviews')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => Review.fromMap(doc.data(), doc.id))
              .toList();
          onUpdate(reviews);
        });

    _listeners['seller_reviews_$sellerId'] = subscription;
    return subscription;
  }

  // ============= Buyer Side Listeners =============
  
  /// Listen to buyer's orders
  StreamSubscription listenToBuyerOrders(String buyerId, Function(List<app_order.Order>) onUpdate) {
    final subscription = _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final orders = snapshot.docs
              .map((doc) => app_order.Order.fromMap(doc.data(), doc.id))
              .toList();
          onUpdate(orders);
        });

    _listeners['buyer_orders_$buyerId'] = subscription;
    return subscription;
  }

  // ============= Listener Management =============
  
  /// Cancel a specific listener
  void cancelListener(String key) {
    _listeners[key]?.cancel();
    _listeners.remove(key);
  }

  /// Cancel all listeners
  void dispose() {
    for (var subscription in _listeners.values) {
      subscription.cancel();
    }
    _listeners.clear();
  }
} 