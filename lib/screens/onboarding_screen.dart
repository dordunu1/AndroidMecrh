import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import '../routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _backgroundController;
  late AnimationController _elementController;
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to TFAC Merch Store',
      description: 'Your one-stop destination for unique and trendy merchandise.',
      illustration: (animation) => WelcomeIllustration(animation: animation),
    ),
    OnboardingPage(
      title: 'Shop with Confidence',
      description: 'Browse through a wide selection of products from trusted sellers.',
      illustration: (animation) => ShoppingIllustration(animation: animation),
    ),
    OnboardingPage(
      title: 'Real-time Chat & Support',
      description: 'Connect instantly with sellers to customize orders, track updates, and get personalized support.',
      illustration: (animation) => ChatIllustration(animation: animation),
    ),
    OnboardingPage(
      title: 'Sell Your Products',
      description: 'Start your business journey and reach customers worldwide.',
      illustration: (animation) => SellerIllustration(animation: animation),
    ),
    OnboardingPage(
      title: 'Fast & Secure Delivery',
      description: 'Get your products delivered safely to your doorstep.',
      illustration: (animation) => DeliveryIllustration(animation: animation),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _elementController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    _elementController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isLastPage = page == _pages.length - 1;
    });
    _elementController
      ..reset()
      ..forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(
                  animation: _backgroundController,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                size: Size.infinite,
              );
            },
          ),
          
          // Skip button
          Positioned(
            top: 48,
            right: 16,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'Skip',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Main content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 300,
                            child: page.illustration(_elementController),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            page.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page.description,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Page indicator and next button
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page indicator
                    Row(
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    
                    // Next/Get Started button
                    ElevatedButton(
                      onPressed: _isLastPage ? _completeOnboarding : () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_isLastPage ? 'Get Started' : 'Next'),
                          const SizedBox(width: 8),
                          Icon(
                            _isLastPage
                                ? Icons.done
                                : Icons.arrow_forward,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final Widget Function(Animation<double>) illustration;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  BackgroundPainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    for (var i = 0; i < 3; i++) {
      final offset = animation.value * 2 * math.pi + (i * math.pi / 1.5);
      path.addOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (0.2 + 0.3 * math.cos(offset)),
            size.height * (0.2 + 0.3 * math.sin(offset)),
          ),
          width: size.width * 0.6,
          height: size.width * 0.6,
        ),
      );
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}

class WelcomeIllustration extends StatelessWidget {
  final Animation<double> animation;

  const WelcomeIllustration({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        // Animated background circles
        ...List.generate(3, (index) => Positioned.fill(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: animation.value * (index + 1) * 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        )),
        
        // Store building with pulsing effect
        Positioned.fill(
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
              )),
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated store window
                    Positioned(
                      top: 40,
                      left: 40,
                      right: 40,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.9,
                          end: 1.0,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
                        )),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // Store door with shine effect
                    Positioned(
                      bottom: 0,
                      left: 60,
                      child: Container(
                        width: 60,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                30 * math.sin(animation.value * 2 * math.pi),
                                0,
                              ),
                              child: Container(
                                width: 20,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0),
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Animated store sign
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.5,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
                          )),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'TFAC',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating colored icons with rotation
        ...List.generate(
          5,
          (index) => Positioned(
            top: 40.0 + (index * 40),
            right: 20.0 + (index * 15),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, -0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.1 * index,
                  0.7 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: animation.value * math.pi * (index % 2 == 0 ? 1 : -1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            [
                              const Color(0xFFFF6B6B),
                              const Color(0xFFFF8787),
                              const Color(0xFF4ECDC4),
                              const Color(0xFFFFBE0B),
                              const Color(0xFF9B5DE5),
                            ][index],
                            [
                              const Color(0xFFF06292),
                              const Color(0xFF64B5F6),
                              const Color(0xFF81C784),
                              const Color(0xFFFFD54F),
                              const Color(0xFF7986CB),
                            ][index],
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        [
                          Icons.shopping_cart_outlined,
                          Icons.local_offer_outlined,
                          Icons.inventory_2_outlined,
                          Icons.category_outlined,
                          Icons.star_outline,
                        ][index],
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShoppingIllustration extends StatelessWidget {
  final Animation<double> animation;

  const ShoppingIllustration({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main shopping cart with gradient
        Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
            )),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4ECDC4),
                    const Color(0xFF81C784),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        // Floating product cards with colorful gradients
        ...List.generate(
          4,
          (index) => Positioned(
            top: 40.0 + (index * 70),
            left: index.isEven ? 20.0 + (index * 30) : null,
            right: index.isEven ? null : 20.0 + (index * 30),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(index.isEven ? -0.5 : 0.5, -0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.1 * index,
                  0.7 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      [
                        const Color(0xFFFF6B6B),
                        const Color(0xFFF06292),
                        const Color(0xFF4ECDC4),
                        const Color(0xFFFFBE0B),
                      ][index],
                      [
                        const Color(0xFFFF8787),
                        const Color(0xFF64B5F6),
                        const Color(0xFF81C784),
                        const Color(0xFFFFD54F),
                      ][index],
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      [
                        Icons.inventory_2_outlined,
                        Icons.category_outlined,
                        Icons.local_offer_outlined,
                        Icons.star_outline,
                      ][index],
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 8,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Animated floating icons
        ...List.generate(
          3,
          (index) => Positioned(
            top: 60.0 + (index * 80),
            right: 30.0 + (index * 20),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.2 + (0.1 * index),
                  0.8 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: animation.value * math.pi * (index % 2 == 0 ? 1 : -1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            [
                              const Color(0xFF9B5DE5),
                              const Color(0xFFFF6B6B),
                              const Color(0xFF4ECDC4),
                            ][index],
                            [
                              const Color(0xFF7986CB),
                              const Color(0xFFF06292),
                              const Color(0xFF81C784),
                            ][index],
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        [
                          Icons.shopping_basket_outlined,
                          Icons.favorite_outline,
                          Icons.local_shipping_outlined,
                        ][index],
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SellerIllustration extends StatelessWidget {
  final Animation<double> animation;

  const SellerIllustration({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main store icon with gradient
        Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
            )),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9B5DE5),  // Purple
                    Color(0xFF7986CB),  // Blue-purple
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.store_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  // Animated shine effect
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            200 * math.sin(animation.value * 2 * math.pi),
                            0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Floating business metrics with colorful gradients
        ...List.generate(
          4,
          (index) => Positioned(
            top: 40.0 + (index * 70),
            left: index.isEven ? 20.0 + (index * 30) : null,
            right: index.isEven ? null : 20.0 + (index * 30),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(index.isEven ? -0.5 : 0.5, -0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.1 * index,
                  0.7 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      [
                        const Color(0xFFFF6B6B),  // Red
                        const Color(0xFF4ECDC4),  // Teal
                        const Color(0xFFFFBE0B),  // Yellow
                        const Color(0xFF9B5DE5),  // Purple
                      ][index],
                      [
                        const Color(0xFFFF8787),  // Light red
                        const Color(0xFF81C784),  // Green
                        const Color(0xFFFFD54F),  // Light yellow
                        const Color(0xFF7986CB),  // Blue-purple
                      ][index],
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      [
                        Icons.trending_up_outlined,
                        Icons.people_outline,
                        Icons.inventory_2_outlined,
                        Icons.star_outline,
                      ][index],
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 8,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Rotating achievement badges
        ...List.generate(
          3,
          (index) => Positioned(
            top: 60.0 + (index * 80),
            right: 30.0 + (index * 20),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.2 + (0.1 * index),
                  0.8 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: animation.value * math.pi * (index % 2 == 0 ? 1 : -1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            [
                              const Color(0xFFFFBE0B),  // Yellow
                              const Color(0xFF4ECDC4),  // Teal
                              const Color(0xFFFF6B6B),  // Red
                            ][index],
                            [
                              const Color(0xFFFFD54F),  // Light yellow
                              const Color(0xFF81C784),  // Green
                              const Color(0xFFFF8787),  // Light red
                            ][index],
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        [
                          Icons.workspace_premium_outlined,
                          Icons.verified_outlined,
                          Icons.emoji_events_outlined,
                        ][index],
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DeliveryIllustration extends StatelessWidget {
  final Animation<double> animation;

  const DeliveryIllustration({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main delivery truck with gradient
        Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
            )),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4ECDC4),  // Teal
                    Color(0xFF81C784),  // Green
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.local_shipping_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  // Animated shine effect
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            200 * math.sin(animation.value * 2 * math.pi),
                            0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Floating location markers with gradients
        ...List.generate(
          4,
          (index) => Positioned(
            top: 40.0 + (index * 70),
            left: index.isEven ? 20.0 + (index * 30) : null,
            right: index.isEven ? null : 20.0 + (index * 30),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(index.isEven ? -0.5 : 0.5, -0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.1 * index,
                  0.7 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      [
                        const Color(0xFFFF6B6B),  // Red
                        const Color(0xFF9B5DE5),  // Purple
                        const Color(0xFFFFBE0B),  // Yellow
                        const Color(0xFF4ECDC4),  // Teal
                      ][index],
                      [
                        const Color(0xFFFF8787),  // Light red
                        const Color(0xFF7986CB),  // Blue-purple
                        const Color(0xFFFFD54F),  // Light yellow
                        const Color(0xFF81C784),  // Green
                      ][index],
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      [
                        Icons.location_on_outlined,
                        Icons.navigation_outlined,
                        Icons.flag_outlined,
                        Icons.check_circle_outline,
                      ][index],
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 8,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Animated route line with dots
        Positioned(
          top: 100,
          left: 60,
          right: 60,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
            )),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: Stack(
                children: List.generate(
                  3,
                  (index) => Positioned(
                    left: index * 100.0,
                    bottom: 0,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.5,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Interval(
                          0.4 + (index * 0.1),
                          0.7 + (index * 0.1),
                          curve: Curves.elasticOut,
                        ),
                      )),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Rotating delivery status icons
        ...List.generate(
          3,
          (index) => Positioned(
            top: 60.0 + (index * 80),
            right: 30.0 + (index * 20),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.2 + (0.1 * index),
                  0.8 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: animation.value * math.pi * (index % 2 == 0 ? 1 : -1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            [
                              const Color(0xFFFFBE0B),  // Yellow
                              const Color(0xFF4ECDC4),  // Teal
                              const Color(0xFFFF6B6B),  // Red
                            ][index],
                            [
                              const Color(0xFFFFD54F),  // Light yellow
                              const Color(0xFF81C784),  // Green
                              const Color(0xFFFF8787),  // Light red
                            ][index],
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        [
                          Icons.local_shipping_outlined,
                          Icons.access_time_outlined,
                          Icons.inventory_2_outlined,
                        ][index],
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatIllustration extends StatelessWidget {
  final Animation<double> animation;

  const ChatIllustration({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main chat bubble with gradient
        Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
            )),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9B5DE5),  // Purple
                    Color(0xFF7986CB),  // Blue-purple
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  // Animated shine effect
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            200 * math.sin(animation.value * 2 * math.pi),
                            0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Animated typing dots
                  ...List.generate(3, (index) => Positioned(
                    bottom: 50,
                    left: 80 + (index * 20),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.5,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Interval(
                          0.3 + (index * 0.2),
                          0.7 + (index * 0.1),
                          curve: Curves.elasticOut,
                        ),
                      )),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
        // Floating message bubbles with gradients
        ...List.generate(
          4,
          (index) => Positioned(
            top: 40.0 + (index * 60),
            left: index.isEven ? 20 : null,
            right: index.isEven ? null : 20,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(index.isEven ? -0.5 : 0.5, -0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.1 * index,
                  0.7 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      [
                        const Color(0xFFFF6B6B),  // Red
                        const Color(0xFF4ECDC4),  // Teal
                        const Color(0xFFFFBE0B),  // Yellow
                        const Color(0xFF9B5DE5),  // Purple
                      ][index],
                      [
                        const Color(0xFFFF8787),  // Light red
                        const Color(0xFF81C784),  // Green
                        const Color(0xFFFFD54F),  // Light yellow
                        const Color(0xFF7986CB),  // Blue-purple
                      ][index],
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      [
                        Icons.support_agent_rounded,
                        Icons.edit_note_rounded,
                        Icons.local_shipping_rounded,
                        Icons.thumb_up_rounded,
                      ][index],
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 8,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Rotating support icons
        ...List.generate(
          3,
          (index) => Positioned(
            top: 60.0 + (index * 80),
            right: 30.0 + (index * 20),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(
                  0.2 + (0.1 * index),
                  0.8 + (0.05 * index),
                  curve: Curves.easeOut,
                ),
              )),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: animation.value * math.pi * (index % 2 == 0 ? 1 : -1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            [
                              const Color(0xFFFFBE0B),  // Yellow
                              const Color(0xFF4ECDC4),  // Teal
                              const Color(0xFFFF6B6B),  // Red
                            ][index],
                            [
                              const Color(0xFFFFD54F),  // Light yellow
                              const Color(0xFF81C784),  // Green
                              const Color(0xFFFF8787),  // Light red
                            ][index],
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        [
                          Icons.chat_outlined,
                          Icons.headset_mic_outlined,
                          Icons.rate_review_outlined,
                        ][index],
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
} 