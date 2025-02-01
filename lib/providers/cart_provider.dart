import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../services/buyer_service.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.length;
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref _ref;
  
  CartNotifier(this._ref) : super([]);

  Future<void> addToCart(CartItem item) async {
    final existingIndex = state.indexWhere((i) => 
      i.product.id == item.product.id && 
      i.selectedColor == item.selectedColor && 
      i.selectedSize == item.selectedSize
    );
    
    if (existingIndex >= 0) {
      // Check if adding more items would exceed the available quantity
      final existingItem = state[existingIndex];
      final newQuantity = existingItem.quantity + item.quantity;
      
      // Get the available quantity for the selected color
      final availableQuantity = item.selectedColor != null 
          ? item.product.colorQuantities[item.selectedColor] ?? 0
          : item.product.stockQuantity;
      
      if (newQuantity > availableQuantity) {
        throw Exception('Not enough stock available');
      }
      
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: newQuantity),
        ...state.sublist(existingIndex + 1),
      ];

      // Sync with Firestore
      await _ref.read(buyerServiceProvider).addToCart(
        item.product.id,
        newQuantity,
        selectedSize: item.selectedSize,
        selectedColor: item.selectedColor,
        selectedColorImage: item.selectedColorImage,
      );
    } else {
      // Check if the initial quantity is available
      final availableQuantity = item.selectedColor != null 
          ? item.product.colorQuantities[item.selectedColor] ?? 0
          : item.product.stockQuantity;
          
      if (item.quantity > availableQuantity) {
        throw Exception('Not enough stock available');
      }
      
      state = [...state, item];

      // Sync with Firestore
      await _ref.read(buyerServiceProvider).addToCart(
        item.product.id,
        item.quantity,
        selectedSize: item.selectedSize,
        selectedColor: item.selectedColor,
        selectedColorImage: item.selectedColorImage,
      );
    }
  }

  Future<void> removeFromCart(String productId) async {
    state = state.where((item) => item.product.id != productId).toList();
    
    // Sync with Firestore
    await _ref.read(buyerServiceProvider).removeFromCart(productId);
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    // Sync with Firestore
    await _ref.read(buyerServiceProvider).updateCartItemQuantity(productId, quantity);
  }

  Future<void> clearCart() async {
    state = [];
    
    // Sync with Firestore
    await _ref.read(buyerServiceProvider).clearCart();
  }

  // Load cart from Firestore
  Future<void> loadCart() async {
    final items = await _ref.read(buyerServiceProvider).getCartItems();
    state = items;
  }
} 