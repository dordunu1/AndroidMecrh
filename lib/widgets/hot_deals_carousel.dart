import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/common/cached_image.dart';
import '../routes.dart';

class HotDealsCarousel extends StatefulWidget {
  final List<Product> products;

  const HotDealsCarousel({
    super.key,
    required this.products,
  });

  @override
  State<HotDealsCarousel> createState() => _HotDealsCarouselState();
}

class _HotDealsCarouselState extends State<HotDealsCarousel> {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  Timer? _countdownTimer;
  int _currentPage = 0;
  Map<String, String> _countdowns = {};

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage < widget.products.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startCountdownTimer() {
    // Update countdowns immediately
    _updateCountdowns();
    
    // Then update every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdowns();
    });
  }

  void _updateCountdowns() {
    if (!mounted) return;
    
    setState(() {
      for (final product in widget.products) {
        if (product.discountEndsAt != null) {
          final remaining = product.discountEndsAt!.difference(DateTime.now());
          if (remaining.isNegative) {
            _countdowns[product.id] = 'Ended';
          } else {
            final days = remaining.inDays;
            final hours = remaining.inHours % 24;
            final minutes = remaining.inMinutes % 60;
            final seconds = remaining.inSeconds % 60;
            
            if (days > 0) {
              _countdowns[product.id] = '$days days left';
            } else if (hours > 0) {
              _countdowns[product.id] = '$hours hrs ${minutes}m left';
            } else if (minutes > 0) {
              _countdowns[product.id] = '$minutes mins ${seconds}s left';
            } else {
              _countdowns[product.id] = '$seconds seconds left';
            }
          }
        } else {
          _countdowns[product.id] = 'Limited time';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hot Deals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.products.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final product = widget.products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.productDetails,
                      arguments: {'product': product},
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedImage(
                            imageUrl: product.images.first,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '-${product.discountPercent.toStringAsFixed(0)}%',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GHS ${product.discountedPrice?.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'GHS ${product.price.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withOpacity(0.7),
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _countdowns[product.id] ?? 'Limited time',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.products.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 