import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';

final cartServiceProvider = Provider<CartService>((ref) {
  return CartService();
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
}); 