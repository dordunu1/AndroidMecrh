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
      title: 'Welcome to Merch Store',
      description: 'Your one-stop destination for unique and trendy merchandise.',
      illustration: (animation) => WelcomeIllustration(animation: animation),
    ),
    OnboardingPage(
      title: 'Shop with Confidence',
      description: 'Browse through a wide selection of products from trusted sellers.',
      illustration: (animation) => ShoppingIllustration(animation: animation),
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
    return Stack(
      children: [
        // Store building
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
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
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
                    // Store window
                    Positioned(
                      top: 40,
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Store door
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
                      ),
                    ),
                    // Store sign
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 32,
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
        // Floating items
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
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                  color: Theme.of(context).colorScheme.primary,
                ),
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
        // Main shopping cart
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
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
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
        // Floating product cards
        ...List.generate(
          3,
          (index) => Positioned(
            top: 40.0 + (index * 80),
            left: 20.0 + (index * 30),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.5, -0.5),
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
                width: 100,
                height: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      [
                        Icons.inventory_2_outlined,
                        Icons.category_outlined,
                        Icons.local_offer_outlined,
                      ][index],
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
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
        // Store icon
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
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
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
                  Icons.store_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        // Business metrics
        ...List.generate(
          4,
          (index) => Positioned(
            top: 40.0 + (index * 60),
            right: 20.0 + (index * 20),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, -0.5),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 8,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
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
        // Delivery truck
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
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
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
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        // Route markers
        ...List.generate(
          3,
          (index) => Positioned(
            top: 60.0 + (index * 70),
            left: 40.0 + (index * 100),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.5, -0.5),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  [
                    Icons.location_on_outlined,
                    Icons.navigation_outlined,
                    Icons.flag_outlined,
                  ][index],
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        // Route line
        Positioned(
          top: 100,
          left: 60,
          right: 60,
          child: CustomPaint(
            painter: RoutePainter(
              animation: animation,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            size: const Size(double.infinity, 2),
          ),
        ),
      ],
    );
  }
}

class RoutePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  RoutePainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width * animation.value, size.height / 2);

    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 3; i++) {
      final x = size.width * (i / 2);
      canvas.drawCircle(
        Offset(x, size.height / 2),
        4,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) => true;
} 