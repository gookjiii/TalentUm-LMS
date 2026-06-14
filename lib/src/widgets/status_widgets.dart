import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme.dart';

// ─────────────────────────────────────────────────────────────────
// STATUS CHIP (with pulse variant)
// ─────────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.textColor,
    this.iconSize = 12,
    this.pulseDot = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Color? textColor;
  final double iconSize;
  final bool pulseDot;

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulseDot) ...[
            _PulseDot(color: color),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: iconSize, color: effectiveTextColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends HookWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    final scale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    final opacity = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Transform.scale(
        scale: scale.value,
        child: Opacity(
          opacity: opacity.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;
  final Color? color;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = widget.color ?? SchoolColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 8 * math.sin(_controller.value * 2 * math.pi)),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? SchoolColors.darkSurface : SchoolColors.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.05),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 48,
                      color: isDark ? SchoolColors.primaryLight : primaryColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: SchoolColors.muted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.action != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: widget.action,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(widget.actionLabel ?? 'Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EMPTY STATE WIDGET (Simplified)
// ─────────────────────────────────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BRANDED LOADER
// ─────────────────────────────────────────────────────────────────
class BrandedLoader extends StatelessWidget {
  const BrandedLoader({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(SchoolColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: SchoolColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GRADIENT ICON BOX
// ─────────────────────────────────────────────────────────────────
class GradientIconBox extends StatelessWidget {
  const GradientIconBox({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 48,
    this.iconSize = 24,
    this.borderRadius = 14,
  });

  final IconData icon;
  final List<Color> colors;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CIRCULAR PROGRESS RING
// ─────────────────────────────────────────────────────────────────
class CircularProgressRing extends HookWidget {
  const CircularProgressRing({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 6,
    this.color = SchoolColors.primary,
  });

  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 1),
    );
    final animation = Tween<double>(begin: 0, end: progress).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    useEffect(() {
      controller.forward(from: 0);
      return null;
    }, [progress]);

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: animation.value,
              color: color,
              strokeWidth: strokeWidth,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
