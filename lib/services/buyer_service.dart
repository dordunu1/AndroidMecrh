import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../models/cart_item.dart';
import '../models/order.dart' as app_order;
import '../models/refund.dart';
import '../models/product.dart';
import '../models/shipping_address.dart';

final buyerServiceProvider = Provider<BuyerService>((ref) {
  return BuyerService(
    FirebaseFirestore.instance,
    auth.FirebaseAuth.instance,
  );
});

class BuyerService {
  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth _auth;

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
          selectedSize: item['selectedSize'] as String?,
          selectedColor: item['selectedColor'] as String?,
          selectedColorImage: item['selectedColorImage'] as String?,
        );
      }));
    } catch (e) {
      throw Exception('Failed to get cart items: $e');
    }
  }

  Future<void> addToCart(
    String productId,
    int quantity, {
    String? selectedSize,
    String? selectedColor,
    String? selectedColorImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) throw Exception('Product not found');

      final product = Product.fromMap(productDoc.data()!, productDoc.id);

      if (!product.isActive) throw Exception('Product is not available');
      
      // Check available quantity based on color selection
      final availableQuantity = selectedColor != null 
          ? product.colorQuantities[selectedColor] ?? 0
          : product.stockQuantity;
          
      if (quantity > availableQuantity) throw Exception('Not enough stock');

      final cartRef = _firestore.collection('carts').doc(user.uid);
      final cartDoc = await cartRef.get();

      if (!cartDoc.exists) {
        await cartRef.set({
          'items': [{
            'productId': productId,
            'quantity': quantity,
            'selectedSize': selectedSize,
            'selectedColor': selectedColor,
            'selectedColorImage': selectedColorImage,
          }],
        });
      } else {
        final items = List<Map<String, dynamic>>.from(cartDoc.data()!['items'] as List);
        final existingItemIndex = items.indexWhere((item) => 
          item['productId'] == productId && 
          item['selectedColor'] == selectedColor && 
          item['selectedSize'] == selectedSize
        );

        if (existingItemIndex != -1) {
          final existingQuantity = items[existingItemIndex]['quantity'] as int;
          final newQuantity = existingQuantity + quantity;
          if (newQuantity > availableQuantity) throw Exception('Not enough stock');
          items[existingItemIndex]['quantity'] = newQuantity;
        } else {
          items.add({
            'productId': productId,
            'quantity': quantity,
            'selectedSize': selectedSize,
            'selectedColor': selectedColor,
            'selectedColorImage': selectedColorImage,
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

      if (quantity > product.stockQuantity) throw Exception('Not enough stock');

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

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order = app_order.Order.fromMap(orderDoc.data()!, orderDoc.id);

      if (order.buyerId != user.uid) {
        throw Exception('Not authorized to update this order');
      }

      // Only allow buyers to mark orders as delivered
      if (status != 'delivered') {
        throw Exception('Invalid status update');
      }

      // Only allow marking shipped orders as delivered
      if (order.status != 'shipped') {
        throw Exception('Order must be shipped before marking as delivered');
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> placeOrder({
    required List<CartItem> items,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required String buyerPaymentName,
    required double total,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user data for buyerInfo
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User data not found');
      final userData = userDoc.data()!;

      // Group items by seller
      final itemsBySeller = <String, List<CartItem>>{};
      for (var item in items) {
        if (!itemsBySeller.containsKey(item.product.sellerId)) {
          itemsBySeller[item.product.sellerId] = [];
        }
        itemsBySeller[item.product.sellerId]!.add(item);
      }

      // Create an order for each seller
      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;
        
        // Get seller data for sellerInfo
        final sellerDoc = await _firestore.collection('sellers').doc(sellerId).get();
        if (!sellerDoc.exists) throw Exception('Seller data not found');
        final sellerData = sellerDoc.data()!;

        // Get delivery fee from first product in order
        final firstProduct = sellerItems.first.product;
        final deliveryFee = firstProduct.deliveryFee ?? 0.5;
        
        // Calculate total for this seller's items including delivery fee
        final itemsTotal = sellerItems.fold(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );
        final sellerTotal = itemsTotal + deliveryFee;

        // Create a new document with auto-generated ID
        final orderRef = _firestore.collection('orders').doc();
        
        final now = DateTime.now().toUtc();
        final createdAtStr = now.toIso8601String();

        await orderRef.set({
          'buyerId': user.uid,
          'buyerInfo': {
            'email': userData['email'] ?? '',
            'name': userData['name'] ?? '',
            'phone': userData['phone'] ?? '',
          },
          'sellerId': sellerId,
          'sellerInfo': {
            'email': sellerData['email'] ?? '',
            'name': sellerData['storeName'] ?? '',
            'phone': sellerData['phone'] ?? '',
          },
          'items': sellerItems.map((item) => {
            'productId': item.product.id,
            'name': item.product.name,
            'price': item.product.price,
            'quantity': item.quantity,
            'imageUrl': item.selectedColorImage ?? item.product.images.first,
            'options': {
              'selectedColor': item.selectedColor,
              'selectedSize': item.selectedSize,
              'selectedColorImage': item.selectedColorImage,
            },
          }).toList(),
          'shippingAddress': shippingAddress,
          'status': 'processing',
          'total': sellerTotal,
          'deliveryFee': deliveryFee,
          'paymentStatus': 'paid',
          'paymentMethod': paymentMethod,
          'buyerPaymentName': buyerPaymentName,
          'paymentPhoneNumber': sellerData['paymentPhoneNumbers'][paymentMethod] ?? '',
          'createdAt': createdAtStr,
          'updatedAt': createdAtStr,
        });

        // Update product quantities
        for (var item in sellerItems) {
          final productRef = _firestore.collection('products').doc(item.product.id);
          
          if (item.selectedColor != null) {
            // Update color-specific quantity
            await productRef.update({
              'colorQuantities.${item.selectedColor}': FieldValue.increment(-item.quantity),
              'stockQuantity': FieldValue.increment(-item.quantity),
              'soldCount': FieldValue.increment(item.quantity),
            });
          } else {
            // Update general quantity
            await productRef.update({
              'stockQuantity': FieldValue.increment(-item.quantity),
              'soldCount': FieldValue.increment(item.quantity),
            });
          }
        }
      }
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
    required String phoneNumber,
    required List<String> images,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the order details
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Order not found');

      final order = app_order.Order.fromMap(orderDoc.data()!, orderDoc.id);

      if (order.buyerId != user.uid) {
        throw Exception('Not authorized to request refund for this order');
      }

      // Get seller data to ensure we have the correct name
      final sellerDoc = await _firestore.collection('sellers').doc(order.sellerId).get();
      if (!sellerDoc.exists) throw Exception('Seller not found');
      final sellerData = sellerDoc.data()!;
      print('DEBUG: Seller data: $sellerData'); // Debug print
      final sellerName = sellerData['storeName'] as String? ?? 'Unknown Seller';
      print('DEBUG: Seller name resolved to: $sellerName'); // Debug print

      // Get the first item's image and details from the order
      String? orderImage;
      if (order.items.isNotEmpty) {
        final firstItem = order.items.first;
        print('DEBUG: First order item: ${firstItem.toMap()}'); // Debug print
        // First try to get the selected color image, then the main image URL
        orderImage = firstItem.selectedColorImage ?? firstItem.imageUrl;
        print('DEBUG: Order image resolved to: $orderImage'); // Debug print
      }

      // Get user's phone number from their profile if not provided
      String buyerPhone = phoneNumber;
      if (buyerPhone.isEmpty) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          buyerPhone = userDoc.data()?['phone'] as String? ?? phoneNumber;
        }
      }

      // Create refund document
      final refundData = {
        'orderId': orderId,
        'shortOrderId': orderId.substring(0, 8),
        'buyerId': user.uid,
        'buyerName': order.buyerName,
        'phoneNumber': buyerPhone,
        'sellerId': order.sellerId,
        'sellerName': sellerName,
        'amount': order.total,
        'reason': reason,
        'images': images,
        'orderImage': orderImage ?? '',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      print('DEBUG: Creating refund with data: $refundData'); // Debug print

      // Create the refund document
      await _firestore.collection('refunds').add(refundData);

      // Update order status to 'refund_requested'
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'refund_requested',
        'updatedAt': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      throw Exception('Failed to request refund: $e');
    }
  }

  Future<MerchUser> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw Exception('User profile not found');

    // Just return the user data as is without any modifications
    return MerchUser.fromMap(userDoc.data()!, userDoc.id);
  }

  Future<void> updateProfile(MerchUser user) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update(user.toMap());
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

      addresses.add(address.toMap());

      await _firestore.collection('users').doc(user.uid).update({
        'shippingAddresses': addresses,
        'defaultShippingAddress': addresses.isNotEmpty ? addresses.first : null,
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
    try {
      print('BuyerService.getProducts called with:');
      print('  category: $category');
      print('  search: $search');
      print('  sortBy: $sortBy');

      var query = _firestore.collection('products')
          .where('isActive', isEqualTo: true);

      // Add sorting
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

      print('Executing Firestore query...');
      final snapshot = await query.get();
      print('Query returned ${snapshot.docs.length} documents');

      final allProducts = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      
      print('Converted to ${allProducts.length} Product objects');
      print('Products before filtering:');
      for (var product in allProducts) {
        print('  - ${product.name} (category: ${product.category}, stock: ${product.stockQuantity})');
      }

      // Filter products by category (case-insensitive) and stock
      final products = allProducts
          .where((product) => 
            product.stockQuantity > 0 && 
            (category == null || 
             category.isEmpty || 
             product.category.toLowerCase() == category.toLowerCase()))
          .toList();

      print('After filtering:');
      print('  - ${products.length} products remaining');
      for (var product in products) {
        print('  - ${product.name} (category: ${product.category}, stock: ${product.stockQuantity})');
      }

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return products.where((product) =>
          product.name.toLowerCase().contains(searchLower) ||
          product.description.toLowerCase().contains(searchLower)
        ).toList();
      }

      return products;
    } catch (e) {
      print('Error in getProducts: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }

  Stream<List<Product>> getProductsStream({
    String? category,
    String? search,
    String? sortBy,
  }) {
    print('BuyerService.getProductsStream called with:');
    print('  category: $category');
    print('  search: $search');
    print('  sortBy: $sortBy');

    var query = _firestore.collection('products')
        .where('isActive', isEqualTo: true);

    // Add sorting
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

    print('Starting Firestore stream...');
    return query.snapshots().map((snapshot) {
      print('Stream received ${snapshot.docs.length} documents');

      final allProducts = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      
      print('Converted to ${allProducts.length} Product objects');
      print('Products before filtering:');
      for (var product in allProducts) {
        print('  - ${product.name} (category: ${product.category}, stock: ${product.stockQuantity})');
      }

      // Filter products by category (case-insensitive) and stock
      final products = allProducts
          .where((product) => 
            product.stockQuantity > 0 && 
            (category == null || 
             category.isEmpty || 
             product.category.toLowerCase() == category.toLowerCase()))
          .toList();

      print('After filtering:');
      print('  - ${products.length} products remaining');
      for (var product in products) {
        print('  - ${product.name} (category: ${product.category}, stock: ${product.stockQuantity})');
      }

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return products.where((product) =>
          product.name.toLowerCase().contains(searchLower) ||
          product.description.toLowerCase().contains(searchLower)
        ).toList();
      }

      return products;
    });
  }

  Future<Product> getProduct(String productId) async {
    final productDoc = await _firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      throw Exception('Product not found');
    }
    return Product.fromMap(productDoc.data()!, productDoc.id);
  }
} 