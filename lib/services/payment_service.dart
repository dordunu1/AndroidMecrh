import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

class PaymentService {
  static const String _baseUrl = 'https://api.paystack.co';
  final String _publicKey;
  final String _secretKey;
  late final WebViewController _controller;

  PaymentService()
      : _publicKey = dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '',
        _secretKey = dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';

  Future<String> initializeTransaction({
    required String email,
    required double amount,
    required String currency,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    if (_secretKey.isEmpty) {
      throw Exception('Paystack secret key not found in environment variables');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/transaction/initialize'),
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'amount': (amount * 100).toInt(), // Convert to pesewas
        'currency': currency,
        'reference': reference,
        'callback_url': 'https://standard.paystack.co/close',
        'metadata': metadata,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true && data['data'] != null) {
        return data['data']['authorization_url'];
      }
    }
    
    final error = jsonDecode(response.body);
    throw Exception('Failed to initialize transaction: ${error['message']}');
  }

  Future<bool> handlePayment(BuildContext context, String url) async {
    bool paymentSuccess = false;
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            print('Navigation request to: ${request.url}'); // Debug log
            
            final uri = Uri.parse(request.url);
            
            // Check if this is the Paystack close URL
            if (request.url.contains('paystack.co/close')) {
              // Extract transaction reference from the URL parameters
              final reference = uri.queryParameters['reference'];
              
              print('Payment completed. Reference: $reference');
              
              if (reference != null) {
                paymentSuccess = true;
                Navigator.pop(context, true);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Payment?'),
              content: const Text('Are you sure you want to cancel this payment?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('NO'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('YES'),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Payment'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        final shouldClose = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel Payment?'),
                            content: const Text('Are you sure you want to cancel this payment?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('NO'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('YES'),
                              ),
                            ],
                          ),
                        );
                        if (shouldClose == true) {
                          Navigator.pop(context, false);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: WebViewWidget(controller: _controller),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return paymentSuccess || (result ?? false);
  }

  Future<bool> verifyTransaction(String reference) async {
    if (_secretKey.isEmpty) {
      throw Exception('Paystack secret key not found in environment variables');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/transaction/verify/$reference'),
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == true && 
             data['data']['status'] == 'success';
    }
    
    return false;
  }
} 