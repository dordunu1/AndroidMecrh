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
    final existingIndex = state.indexWhere((i) => i.product.id == item.product.id);
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state);
      updatedItems[existingIndex] = CartItem(
        product: item.product,
        quantity: state[existingIndex].quantity + item.quantity,
      );
      state = updatedItems;
    } else {
      state = [...state, item];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    final updatedItems = state.map((item) {
      if (item.product.id == productId) {
        return CartItem(
          product: item.product,
          quantity: quantity,
        );
      }
      return item;
    }).toList();
    state = updatedItems;
  }

  void clearCart() {
    state = [];
  }
} 