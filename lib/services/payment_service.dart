import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static const String _baseUrl = 'https://api.paystack.co';
  final String _publicKey;
  final String _secretKey;

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

    print('Using secret key: $_secretKey'); // Temporary debug log

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
        'metadata': metadata,
        'callback_url': 'merch-store-mobile://payment-callback',
      }),
    );

    print('Response status code: ${response.statusCode}'); // Temporary debug log
    print('Response body: ${response.body}'); // Temporary debug log

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true && data['data'] != null) {
        return data['data']['authorization_url'];
      }
    }
    
    final error = jsonDecode(response.body);
    throw Exception('Failed to initialize transaction: ${error['message']}');
  }

  Future<void> launchPaymentPage(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } else {
      throw Exception('Could not launch payment page');
    }
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
      return data['status'] == true && data['data']['status'] == 'success';
    }
    return false;
  }
} 