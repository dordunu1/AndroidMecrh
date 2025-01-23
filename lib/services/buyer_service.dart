import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as app_order;
import '../models/refund.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/merch_user.dart';
import '../models/shipping_address.dart';

final buyerServiceProvider = Provider<BuyerService>((ref) {
  return BuyerService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class BuyerService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BuyerService(this._firestore, this._auth);

  // Cart Methods
  Future<List<CartItem>> getCartItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection('carts').doc(user.uid).get();
      if (!doc.exists) return [];

      final items = List<Map<String, dynamic>>.from(doc.data()!['items'] as List);
      return await Future.wait(items.map((item) async {
        final productDoc = await _firestore.collection('products').doc(item['productId'] as String).get();
        if (!productDoc.exists) throw Exception('Product not found');

        final product = Product.fromMap(productDoc.data()!, productDoc.id);

        return CartItem(
          product: product,
          quantity: item['quantity'] as int,
        );
      }));
    } catch (e) {
      throw Exception('Failed to get cart items: $e');
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) throw Exception('Product not found');

      final product = Product.fromMap(productDoc.data()!, productDoc.id);

      if (!product.isActive) throw Exception('Product is not available');
      if (quantity > product.stock) throw Exception('Not enough stock');

      final cartRef = _firestore.collection('carts').doc(user.uid);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        await cartRef.set({
          'items': [{
            'productId': productId,
            'quantity': quantity,
          }],
        });
      } else {
        final items = List<Map<String, dynamic>>.from(cartDoc.data()!['items'] as List);
        final existingItemIndex = items.indexWhere((item) => item['productId'] == productId);

        if (existingItemIndex != -1) {
          final existingQuantity = items[existingItemIndex]['quantity'] as int;
          final newQuantity = existingQuantity + quantity;
          if (newQuantity > product.stock) throw Exception('Not enough stock');
          items[existingItemIndex]['quantity'] = newQuantity;
        } else {
          items.add({
            'productId': productId,
            'quantity': quantity,
          });
        }

        await cartRef.update({'items': items});
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  Future<void> updateCartItemQuantity(String productId, int quantity) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (quantity <= 0) {
        await removeFromCart(productId);
        return;
      }

      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) throw Exception('Product not found');

      final product = Product.fromMap(productDoc.data()!, productDoc.id);

      if (quantity > product.stock) throw Exception('Not enough stock');

      final cartRef = _firestore.collection('carts').doc(user.uid);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) throw Exception('Cart not found');

      final items = List<Map<String, dynamic>>.from(cartDoc.data()!['items'] as List);
      final existingItemIndex = items.indexWhere((item) => item['productId'] == productId);

      if (existingItemIndex == -1) throw Exception('Item not found in cart');

      items[existingItemIndex]['quantity'] = quantity;
      await cartRef.update({'items': items});
    } catch (e) {
      throw Exception('Failed to update cart item quantity: $e');
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final cartRef = _firestore.collection('carts').doc(user.uid);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) return;

      final items = List<Map<String, dynamic>>.from(cartDoc.data()!['items'] as List);
      items.removeWhere((item) => item['productId'] == productId);

      if (items.isEmpty) {
        await cartRef.delete();
      } else {
        await cartRef.update({'items': items});
      }
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('carts').doc(user.uid).delete();
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Order Methods
  Future<List<app_order.Order>> getOrders({String? search, String? status}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      var query = _firestore.collection('orders')
          .where('buyerId', isEqualTo: user.uid);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) {
        return app_order.Order.fromMap(doc.data(), doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return orders.where((order) {
          return order.sellerName.toLowerCase().contains(searchLower) ||
              order.id.toLowerCase().contains(searchLower);
        }).toList();
      }

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Stream<List<app_order.Order>> watchOrders() {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = _firestore.collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return app_order.Order.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to watch orders: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order = app_order.Order.fromMap(orderDoc.data()!, orderDoc.id);

      if (order.buyerId != user.uid) {
        throw Exception('Not authorized to cancel this order');
      }

      if (order.status != 'processing') {
        throw Exception('Order cannot be cancelled');
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  Future<void> placeOrder({
    required List<CartItem> items,
    required String shippingAddressId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');

      final buyer = MerchUser.fromMap({
        ...userDoc.data()!,
        'id': userDoc.id,
      });

      // Get shipping address
      final address = buyer.shippingAddresses.firstWhere(
        (addr) => addr.id == shippingAddressId,
        orElse: () => throw Exception('Shipping address not found'),
      );

      // Group items by seller
      final itemsBySeller = <String, List<CartItem>>{};
      for (final item in items) {
        final sellerId = item.product.sellerId;
        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        itemsBySeller[sellerId]!.add(item);
      }

      // Start a batch write
      final batch = _firestore.batch();

      // Create an order for each seller
      for (final entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;

        // Get seller profile
        final sellerDoc = await _firestore.collection('sellers').doc(sellerId).get();
        if (!sellerDoc.exists) throw Exception('Seller not found');

        // Calculate total
        double total = 0;
        for (final item in sellerItems) {
          total += item.product.price * item.quantity;
        }

        // Create order
        final orderRef = _firestore.collection('orders').doc();
        batch.set(orderRef, {
          'buyerId': user.uid,
          'buyerInfo': {
            'name': buyer.name,
            'email': buyer.email,
          },
          'sellerId': sellerId,
          'sellerName': sellerDoc.data()!['storeName'],
          'items': sellerItems.map((item) => {
            'productId': item.product.id,
            'productName': item.product.name,
            'price': item.product.price,
            'quantity': item.quantity,
          }).toList(),
          'total': total,
          'status': 'processing',
          'shippingAddress': address.toMap(),
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Update product stock
        for (final item in sellerItems) {
          final productRef = _firestore.collection('products').doc(item.product.id);
          batch.update(productRef, {
            'stock': FieldValue.increment(-item.quantity),
          });
        }

        // Update seller stats
        batch.update(sellerDoc.reference, {
          'totalOrders': FieldValue.increment(1),
          'balance': FieldValue.increment(total * 0.9), // 90% of total (10% platform fee)
        });
      }

      // Clear cart
      batch.delete(_firestore.collection('carts').doc(user.uid));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  // Refund Methods
  Future<List<Refund>> getRefunds({String? search, String? status}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      var query = _firestore.collection('refunds')
          .where('buyerId', isEqualTo: user.uid);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      final refunds = snapshot.docs.map((doc) {
        return Refund.fromMap(doc.data(), doc.id);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return refunds.where((refund) {
          return refund.orderId.toLowerCase().contains(searchLower) ||
              refund.reason.toLowerCase().contains(searchLower);
        }).toList();
      }

      return refunds;
    } catch (e) {
      throw Exception('Failed to fetch refunds: $e');
    }
  }

  Future<void> requestRefund({
    required String orderId,
    required String reason,
    required List<String> images,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order = app_order.Order.fromMap(orderDoc.data()!, orderDoc.id);

      if (order.buyerId != user.uid) {
        throw Exception('Not authorized to request refund for this order');
      }

      if (order.status != 'delivered') {
        throw Exception('Refund can only be requested for delivered orders');
      }

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');

      final buyer = MerchUser.fromMap({
        ...userDoc.data()!,
        'id': userDoc.id,
      });

      await _firestore.collection('refunds').add({
        'orderId': orderId,
        'buyerId': user.uid,
        'buyerName': buyer.name,
        'sellerId': order.sellerId,
        'sellerName': order.sellerName,
        'amount': order.total,
        'reason': reason,
        'images': images,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to request refund: $e');
    }
  }

  Future<MerchUser> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) throw Exception('User profile not found');

      return MerchUser.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> addShippingAddress(ShippingAddress address) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');

      final addresses = List<Map<String, dynamic>>.from(
        userDoc.data()!['shippingAddresses'] as List? ?? [],
      );

      final newAddress = {
        ...address.toMap(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      addresses.add(newAddress);

      await _firestore.collection('users').doc(user.uid).update({
        'shippingAddresses': addresses,
        if (addresses.length == 1)
          'defaultShippingAddress': newAddress,
      });
    } catch (e) {
      throw Exception('Failed to add shipping address: $e');
    }
  }

  Future<void> updateShippingAddress(ShippingAddress address) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');

      final addresses = List<Map<String, dynamic>>.from(
        userDoc.data()!['shippingAddresses'] as List? ?? [],
      );

      final index = addresses.indexWhere((a) => a['id'] == address.id);
      if (index == -1) throw Exception('Address not found');

      addresses[index] = address.toMap();

      final defaultAddress = userDoc.data()!['defaultShippingAddress'] as Map<String, dynamic>?;
      await _firestore.collection('users').doc(user.uid).update({
        'shippingAddresses': addresses,
        if (defaultAddress != null && defaultAddress['id'] == address.id)
          'defaultShippingAddress': address.toMap(),
      });
    } catch (e) {
      throw Exception('Failed to update shipping address: $e');
    }
  }

  Future<void> deleteShippingAddress(String addressId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');

      final addresses = List<Map<String, dynamic>>.from(
        userDoc.data()!['shippingAddresses'] as List? ?? [],
      );

      final index = addresses.indexWhere((a) => a['id'] == addressId);
      if (index == -1) throw Exception('Address not found');

      addresses.removeAt(index);

      final defaultAddress = userDoc.data()!['defaultShippingAddress'] as Map<String, dynamic>?;
      await _firestore.collection('users').doc(user.uid).update({
        'shippingAddresses': addresses,
        if (defaultAddress != null && defaultAddress['id'] == addressId)
          'defaultShippingAddress': addresses.isNotEmpty ? addresses.first : null,
      });
    } catch (e) {
      throw Exception('Failed to delete shipping address: $e');
    }
  }

  Future<void> setDefaultShippingAddress(String addressId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');

      final addresses = List<Map<String, dynamic>>.from(
        userDoc.data()!['shippingAddresses'] as List? ?? [],
      );

      final address = addresses.firstWhere(
        (a) => a['id'] == addressId,
        orElse: () => throw Exception('Address not found'),
      );

      await _firestore.collection('users').doc(user.uid).update({
        'defaultShippingAddress': address,
      });
    } catch (e) {
      throw Exception('Failed to set default shipping address: $e');
    }
  }

  Future<List<Product>> getProducts({
    String? category,
    String? search,
    String? sortBy,
  }) async {
    var query = _firestore.collection('products')
      .where('isActive', isEqualTo: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (sortBy != null) {
      switch (sortBy) {
        case 'price_asc':
          query = query.orderBy('price', descending: false);
          break;
        case 'price_desc':
          query = query.orderBy('price', descending: true);
          break;
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    final snapshot = await query.get();
    final products = snapshot.docs.map((doc) {
      return Product.fromMap(doc.data(), doc.id);
    }).toList();

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      return products.where((product) =>
        product.name.toLowerCase().contains(searchLower) ||
        product.description.toLowerCase().contains(searchLower)
      ).toList();
    }

    return products;
  }

  Future<Product> getProduct(String productId) async {
    final productDoc = await _firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      throw Exception('Product not found');
    }
    return Product.fromMap(productDoc.data()!, productDoc.id);
  }
} 