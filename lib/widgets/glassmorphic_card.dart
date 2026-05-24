import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color borderColor;
  final Color cardColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? customBorder;
  final List<BoxShadow>? customShadow;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.08,
    this.borderRadius = 16.0,
    this.borderColor = Colors.white12,
    this.cardColor = const Color(0xFF1E213A),
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.customBorder,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: customShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: customBorder ?? Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
