import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order.dart';
import '../../models/review.dart';
import '../../services/buyer_service.dart';
import '../../services/realtime_service.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../../widgets/common/custom_text_field.dart';
import 'refund_request_screen.dart';

class BuyerOrdersScreen extends ConsumerStatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  ConsumerState<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends ConsumerState<BuyerOrdersScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  bool _isLoading = true;
  List<Order> _orders = [];
  String? _error;
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupRealtimeUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      _ordersSubscription?.cancel();
      _ordersSubscription = ref
          .read(realtimeServiceProvider)
          .listenToBuyerOrders(
            user.uid,
            (orders) {
              if (mounted) {
                setState(() {
                  if (_selectedStatus == 'all') {
                    _orders = orders;
                  } else {
                    _orders = orders.where((order) => order.status == _selectedStatus).toList();
                  }
                  _isLoading = false;
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onStatusChanged(bool selected, String status) {
    if (selected) {
      setState(() {
        _selectedStatus = status;
      });
      _setupRealtimeUpdates();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            onPressed: _setupRealtimeUpdates,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchController,
                  label: 'Search orders',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (value) => _setupRealtimeUpdates(),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatusFilterChip(
                        label: 'All',
                        value: 'all',
                        selected: _selectedStatus == 'all',
                        onSelected: (selected) => _onStatusChanged(selected, 'all'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Processing',
                        value: 'processing',
                        selected: _selectedStatus == 'processing',
                        onSelected: (selected) => _onStatusChanged(selected, 'processing'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Shipped',
                        value: 'shipped',
                        selected: _selectedStatus == 'shipped',
                        onSelected: (selected) => _onStatusChanged(selected, 'shipped'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Delivered',
                        value: 'delivered',
                        selected: _selectedStatus == 'delivered',
                        onSelected: (selected) => _onStatusChanged(selected, 'delivered'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Cancelled',
                        value: 'cancelled',
                        selected: _selectedStatus == 'cancelled',
                        onSelected: (selected) => _onStatusChanged(selected, 'cancelled'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Refunded',
                        value: 'refunded',
                        selected: _selectedStatus == 'refunded',
                        onSelected: (selected) => _onStatusChanged(selected, 'refunded'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _setupRealtimeUpdates,
                        child: _orders.isEmpty
                            ? Center(
                                child: Text(
                                  'No orders found',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _orders.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  return _OrderCard(
                                    order: order,
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class StatusFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final void Function(bool) onSelected;

  const StatusFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (isSelected) {
        onSelected(isSelected);
      },
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final Order order;

  const _OrderCard({
    required this.order,
  });

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(BuildContext context) {
    switch (widget.order.status) {
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${widget.order.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${widget.order.sellerName}',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.order.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: GHS ${widget.order.total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Delivery Fee: GHS ${widget.order.deliveryFee.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Payment: ${widget.order.paymentMethod == 'mtn_momo' ? 'MTN MoMo' : 'Telecel Cash'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          'Pay to: ${widget.order.paymentPhoneNumber}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          widget.order.paymentStatus == 'paid' ? 'Paid' : 'Payment Pending',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: widget.order.paymentStatus == 'paid' 
                              ? Colors.green 
                              : theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created on ${_formatDate(widget.order.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Items: ${widget.order.items.fold(0, (sum, item) => sum + item.quantity)}',
                  style: theme.textTheme.bodySmall,
                ),

                // Show tracking info if available
                if (widget.order.trackingNumber != null && widget.order.shippingCarrier != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Tracking Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Carrier: ${widget.order.shippingCarrier}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'Tracking Number: ${widget.order.trackingNumber}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],

                // Show Received button if order is shipped
                if (widget.order.status == 'shipped') ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  ButtonBar(
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref.read(buyerServiceProvider).updateOrderStatus(widget.order.id, 'delivered');
                            if (mounted) {
                              _showReviewDialog(context, ref);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                        child: const Text('Mark as Received'),
                      ),
                    ],
                  ),
                ],

                // Show review button for delivered orders
                if (widget.order.status == 'delivered') ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  ButtonBar(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showReviewDialog(context, ref),
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Write Review'),
                      ),
                    ],
                  ),
                ],

                // Show refund button for cancelled orders
                if (widget.order.status == 'cancelled') ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  ButtonBar(
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RefundRequestScreen(order: widget.order),
                              ),
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Request Refund'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: widget.order.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = widget.order.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.selectedColorImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.selectedColorImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity}x ${item.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GHS ${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (item.selectedColor != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _getColorFromString(item.selectedColor!),
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.selectedColor!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (item.selectedSize != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Size: ${item.selectedSize}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ReviewDialog(
        order: widget.order,
        user: user,
        ref: ref,
      ),
    );
  }
}

class ReviewDialog extends StatefulWidget {
  final Order order;
  final User user;
  final WidgetRef ref;

  const ReviewDialog({
    super.key,
    required this.order,
    required this.user,
    required this.ref,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  late final TextEditingController _commentController;
  double _rating = 5.0;
  final List<String> _images = [];
  final List<File> _imageFiles = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      child: Dialog(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rate Your Purchase',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isUploading)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Rating'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = index + 1.0;
                        });
                      },
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Write your review',
                    hintText: 'Share your experience with this product...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add Photos'),
                    TextButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () async {
                              try {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 70,
                                );

                                if (pickedFile != null && mounted) {
                                  setState(() {
                                    _imageFiles.add(File(pickedFile.path));
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to pick image: $e')),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Photo'),
                    ),
                  ],
                ),
                if (_imageFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageFiles.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFiles[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                onPressed: _isUploading
                                    ? null
                                    : () {
                                        setState(() {
                                          _imageFiles.removeAt(index);
                                        });
                                      },
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isUploading 
                        ? null 
                        : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isUploading
                          ? null
                          : () async {
                              if (_commentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please write a review')),
                                );
                                return;
                              }

                              setState(() {
                                _isUploading = true;
                              });

                              try {
                                // Upload images if any
                                if (_imageFiles.isNotEmpty) {
                                  final storage = FirebaseStorage.instance;
                                  for (var file in _imageFiles) {
                                    final ref = storage.ref().child(
                                        'reviews/${widget.order.id}/${DateTime.now().millisecondsSinceEpoch}_${_images.length + 1}.jpg');
                                    await ref.putFile(file);
                                    final url = await ref.getDownloadURL();
                                    _images.add(url);
                                  }
                                }

                                final review = Review(
                                  id: '${widget.order.id}_${widget.user.uid}_${widget.order.items.first.productId}',
                                  productId: widget.order.items.first.productId,
                                  userId: widget.user.uid,
                                  userName: widget.user.displayName ?? 'Anonymous',
                                  userPhoto: widget.user.photoURL,
                                  sellerId: widget.order.sellerId,
                                  rating: _rating,
                                  comment: _commentController.text.trim(),
                                  images: _images.isEmpty ? null : _images,
                                  createdAt: DateTime.now(),
                                  isVerifiedPurchase: true,
                                  orderId: widget.order.id,
                                );

                                await widget.ref.read(reviewServiceProvider).addReview(review);
                                
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Review submitted successfully')),
                                  );
                                }
                              } catch (e) {
                                print('Review submission error: $e');
                                if (mounted) {
                                  setState(() {
                                    _isUploading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to submit review: ${e.toString()}'),
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text(_isUploading ? 'Submitting...' : 'Submit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 