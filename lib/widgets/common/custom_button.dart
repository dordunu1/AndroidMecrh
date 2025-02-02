import 'package:flutter/material.dart';

enum CustomButtonStyle {
  filled,
  outlined,
  text
}

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool outlined;
  final bool isLoading;
  final CustomButtonStyle style;
  final Color? color;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.onPressed,
    this.text,
    this.child,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius = 8,
    this.padding,
    this.outlined = false,
    this.isLoading = false,
    this.style = CustomButtonStyle.filled,
    this.color,
    this.icon,
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final buttonColor = color ?? theme.colorScheme.primary;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (text != null) ...[
          Text(
            text!,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? buttonColor,
          foregroundColor: textColor ?? Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: outlined ? BorderSide(color: textColor ?? primaryColor) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
} 