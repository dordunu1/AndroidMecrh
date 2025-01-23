import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 96,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Placed Successfully!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thank you for your order. You can track your order status in the Orders section.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    );
                  },
                  text: 'Continue Shopping',
                ),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: () {
                    // TODO: Navigate to orders screen
                  },
                  text: 'View Orders',
                  backgroundColor: Colors.grey[200],
                  textColor: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 