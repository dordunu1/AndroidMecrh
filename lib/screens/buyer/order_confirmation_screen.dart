import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';
import 'buyer_orders_screen.dart';
import 'buyer_navigation_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BuyerNavigationScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Confirmation'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Placed Successfully!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const BuyerNavigationScreen()),
                        (route) => false,
                      );
                    },
                    text: 'Continue Shopping',
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyerNavigationScreen(initialIndex: 2),
                        ),
                        (route) => false,
                      );
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
      ),
    );
  }
} 