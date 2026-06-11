import 'package:flutter/material.dart';
import '../theme.dart';

class AmbientGlowBackground extends StatelessWidget {
  const AmbientGlowBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return child;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: SchoolColors.darkBg,
          ),
        ),
        // Glow 1 (Top Left)
        Positioned(
          top: -200,
          left: -200,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2563EB).withValues(alpha: 0.15),
                  const Color(0xFF2563EB).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Glow 2 (Bottom Right)
        Positioned(
          bottom: -250,
          right: -250,
          child: Container(
            width: 800,
            height: 800,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.10),
                  const Color(0xFF6366F1).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}
