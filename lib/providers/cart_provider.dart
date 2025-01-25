import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartItemCountProvider = Provider<int>((ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.length;
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(CartItem item) {
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
    } else {
      // Check if the initial quantity is available
      final availableQuantity = item.selectedColor != null 
          ? item.product.colorQuantities[item.selectedColor] ?? 0
          : item.product.stockQuantity;
          
      if (item.quantity > availableQuantity) {
        throw Exception('Not enough stock available');
      }
      
      state = [...state, item];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }
} 