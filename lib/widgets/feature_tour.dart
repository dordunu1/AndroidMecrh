import 'package:flutter/material.dart';

class FeatureTourStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final EdgeInsets padding;

  FeatureTourStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.padding = const EdgeInsets.all(8),
  });
}

class FeatureTour extends StatefulWidget {
  final List<FeatureTourStep> steps;
  final VoidCallback onComplete;
  final bool showSkipButton;

  const FeatureTour({
    super.key,
    required this.steps,
    required this.onComplete,
    this.showSkipButton = true,
  });

  @override
  State<FeatureTour> createState() => _FeatureTourState();
}

class _FeatureTourState extends State<FeatureTour> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentStep = 0;
  Offset _targetOffset = Offset.zero;
  Size _targetSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetPosition());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateTargetPosition() {
    final targetContext = widget.steps[_currentStep].targetKey.currentContext;
    if (targetContext != null) {
      final RenderBox box = targetContext.findRenderObject() as RenderBox;
      final Offset offset = box.localToGlobal(Offset.zero);
      setState(() {
        _targetOffset = offset;
        _targetSize = box.size;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
        _updateTargetPosition();
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skipTour() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Backdrop with spotlight
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(screenSize.width, screenSize.height),
                painter: SpotlightPainter(
                  targetOffset: _targetOffset,
                  targetSize: _targetSize,
                  padding: widget.steps[_currentStep].padding,
                  animation: _animation,
                ),
              );
            },
          ),

          // Content
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.steps[_currentStep].title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.steps[_currentStep].description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.showSkipButton)
                            TextButton(
                              onPressed: _skipTour,
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                              ),
                              child: const Text('Skip'),
                            )
                          else
                            const SizedBox.shrink(),
                          Row(
                            children: [
                              ...List.generate(
                                widget.steps.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _currentStep
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.primary.withOpacity(0.2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentStep < widget.steps.length - 1
                                  ? 'Next'
                                  : 'Done',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Offset targetOffset;
  final Size targetSize;
  final EdgeInsets padding;
  final Animation<double> animation;

  SpotlightPainter({
    required this.targetOffset,
    required this.targetSize,
    required this.padding,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.75 * animation.value)
      ..style = PaintingStyle.fill;

    final spotlightRect = Rect.fromLTWH(
      targetOffset.dx - padding.left,
      targetOffset.dy - padding.top,
      targetSize.width + padding.left + padding.right,
      targetSize.height + padding.top + padding.bottom,
    );

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()
        ..addRRect(RRect.fromRectAndRadius(
          spotlightRect,
          const Radius.circular(8),
        )),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return targetOffset != oldDelegate.targetOffset ||
        targetSize != oldDelegate.targetSize ||
        animation.value != oldDelegate.animation.value;
  }
} 