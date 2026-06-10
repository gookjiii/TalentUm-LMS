import 'dart:ui';
import 'package:flutter/material.dart';

class SwLiquidGlass extends StatelessWidget {
  const SwLiquidGlass({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = const EdgeInsets.all(24),
    this.blur = 20.0,
    this.opacity = 0.15,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
