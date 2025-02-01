import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  final sections = const [
    {
      'title': 'Platform Overview',
      'icon': Icons.language,
      'items': [
        'These terms govern your use of our platform and services',
        'You must be 18 years or older to use the platform',
        'By using the platform, you agree to these terms and conditions',
        'We reserve the right to update these terms with notice to users'
      ]
    },
    {
      'title': 'Platform Fees and Charges',
      'icon': Icons.attach_money,
      'items': [
        '5% platform fee is automatically deducted from each sale',
        'Refund requests will have a 5% fee deducted (platform fee is non-refundable)',
        'Minimum withdrawal amount: 50 GHS for sellers',
        'Admin can update platform fees (maximum 10%)'
      ]
    },
    {
      'title': 'Order Processing and Shipping',
      'icon': Icons.local_shipping,
      'items': [
        'Sellers have 3 days to confirm shipping for orders',
        'Orders not shipped within 3 days may be automatically cancelled',
        'Sellers must provide valid tracking information when confirming shipping',
        'Buyers are responsible for providing correct delivery addresses'
      ]
    },
    {
      'title': 'Refunds and Cancellations',
      'icon': Icons.refresh,
      'items': [
        'Only cancelled orders are eligible for refund requests',
        'Refund requests typically take up to 1 week to process',
        'Refunds will be processed to the original payment method',
        'Platform fees (5%) are non-refundable on refunded orders',
        '3-day window to request refund for cancelled orders'
      ]
    },
    {
      'title': 'Payment and Withdrawals',
      'icon': Icons.account_balance_wallet,
      'items': [
        'Sellers can withdraw their earnings to their registered mobile money account',
        'Minimum withdrawal amount is 50 GHS',
        'Platform may hold funds for pending refunds',
        'Withdrawal processing requires confirmation of delivery for all orders',
        'If buyers don\'t confirm delivery, withdrawals will be processed 3 days after shipping confirmation'
      ]
    },
    {
      'title': 'Seller Obligations',
      'icon': Icons.verified_user,
      'items': [
        'Sellers must maintain accurate product listings',
        'Sellers are responsible for order fulfillment within the 3-day window',
        'Sellers must handle shipping and provide tracking information',
        'False shipping confirmations will result in rejected withdrawal requests',
        'Sellers\' available balance reflects total sales minus platform fees and pending refunds',
        'Sellers must comply with all applicable laws and regulations',
        'Posting of NSFW content is strictly prohibited and will result in immediate account termination',
        'Platform reserves the right to delete seller accounts without notice for NSFW violations'
      ]
    },
    {
      'title': 'Buyer Protection',
      'icon': Icons.security,
      'items': [
        '3-day window to request refund for cancelled orders',
        'Refund amounts will be processed minus the 5% platform fee',
        'Buyers can track order status and shipping information',
        'Buyers can view refund request status and transaction details',
        'Platform maintains records of all transactions for buyer security'
      ]
    },
    {
      'title': 'Account Security',
      'icon': Icons.lock,
      'items': [
        'Users are responsible for maintaining account security',
        'Account credentials must not be shared with third parties',
        'Users must notify us immediately of any unauthorized access',
        'We reserve the right to suspend accounts for security violations'
      ]
    },
    {
      'title': 'Platform Rights',
      'icon': Icons.settings,
      'items': [
        'The platform reserves the right to pause operations if necessary',
        'Admin can update platform fees (maximum 10%)',
        'Platform may hold funds for pending refunds',
        'Platform maintains records of all transactions and activities',
        'We may modify or terminate services with notice to users',
        'Any suspicious activity or attempts to manipulate sales will result in immediate account termination',
        'Platform monitors and audits all transactions for potential manipulation'
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'Terms and Conditions',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please read these terms and conditions carefully before using the MerchStore platform. These terms outline the rules and regulations for the use of our services.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Sections
          ...sections.map((section) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          section['icon'] as IconData,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          section['title'] as String,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section Items
                  ...(section['items'] as List<String>).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onBackground.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          )),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  'Last updated: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By using the MerchStore platform, you agree to these terms and conditions. We reserve the right to modify these terms at any time.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
} 