import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme.dart';
import '../../main.dart';

// ─────────────────────────────────────────────────────────────────
// SCHOOL CARD  (improved hover + shadow)
// ─────────────────────────────────────────────────────────────────
class SchoolCard extends HookWidget {
  const SchoolCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius = 24, // Unified larger radius
    this.borderColor,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final isPressed = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedPadding =
        padding ??
        (MediaQuery.sizeOf(context).width < 600
            ? const EdgeInsets.all(AppSpacing.md)
            : const EdgeInsets.all(AppSpacing.lg));

    final effectiveColor =
        color ?? (isDark ? SchoolColors.darkSurface : Colors.white);
    final effectiveBorderColor =
        borderColor ?? (isDark ? SchoolColors.darkBorder : SchoolColors.border);

    // Optimized transform for subtle feel
    Matrix4 transform = Matrix4.identity();
    if (onTap != null) {
      if (isPressed.value) {
        transform.scale(0.98);
      } else if (isHovered.value) {
        transform.translate(0.0, -4.0, 0.0);
      }
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: margin,
      transform: transform,
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorderColor, width: 1.2),
        boxShadow: boxShadow ??
            [
              if (isHovered.value && onTap != null && !isPressed.value)
                SchoolColors.cardShadowHover
              else if (!isDark)
                SchoolColors.lightNavyShadow
              else
                SchoolColors.cardShadow,
            ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Semantics(
            button: onTap != null,
            child: Padding(padding: resolvedPadding, child: child),
          ),
        ),
      ),
    );

    if (onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GLASS CARD  (frosted glassmorphism surface)
// ─────────────────────────────────────────────────────────────────
class GlassCard extends HookWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20.0,
    this.color,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final isPressed = useState(false);

    final resolvedPadding =
        padding ??
        (MediaQuery.sizeOf(context).width < 600
            ? const EdgeInsets.all(AppSpacing.md)
            : const EdgeInsets.all(AppSpacing.lg));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.65));

    bool isPerformance = false;
    try {
      isPerformance = AppScope.of(context).appState.performanceMode;
    } catch (_) {}

    Matrix4 transform = Matrix4.identity();
    if (onTap != null && !isPerformance) {
      if (isPressed.value) {
        transform.scale(0.97);
      } else if (isHovered.value) {
        transform.translate(0.0, -4.0, 0.0);
      }
    }

    final Widget innerCard = isPerformance
      ? Container(
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? SchoolColors.darkBorder
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Material(
            color:
                color ??
                (isDark ? SchoolColors.darkSurface : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(borderRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(padding: resolvedPadding, child: child),
            ),
          ),
        )
      : AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: const Cubic(0.34, 1.56, 0.64, 1.0),
          margin: margin,
          transform: transform,
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              if (isHovered.value && onTap != null && !isPressed.value)
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.4) : SchoolColors.navyShadowColor.withValues(alpha: 0.2),
                  blurRadius: 120,
                  offset: const Offset(0, 60),
                )
              else if (!isDark)
                SchoolColors.lightNavyShadow
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 100,
                  offset: const Offset(0, 40),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Guidelines 2.5: Reduced to 16px
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isDark
                        ? SchoolColors.darkBorder
                        : SchoolColors.border.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(borderRadius),
                          gradient: isDark ? SchoolColors.gradSurface : SchoolColors.gradSurfaceLight,
                        ),
                      ),
                    ),
                    Material(
                      color: bg,
                      borderRadius: BorderRadius.circular(borderRadius),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: Padding(padding: resolvedPadding, child: child),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    if (onTap == null) return innerCard;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        onTap: onTap,
        child: innerCard,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// NESTED BEZEL CARD (Double-Bezel High-Fidelity Container)
// ─────────────────────────────────────────────────────────────────
class NestedBezelCard extends StatelessWidget {
  const NestedBezelCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? SchoolColors.darkBorder : SchoolColors.border),
      ),
      child: GlassCard(
        borderRadius: 26,
        padding: padding,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ELITE NESTED BEZEL (Guidelines 2.5)
// ─────────────────────────────────────────────────────────────────
class EliteNestedBezel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool? isPerformanceMode;

  const EliteNestedBezel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
    this.isPerformanceMode,
  });

  @override
  Widget build(BuildContext context) {
    final performance = isPerformanceMode ?? AppScope.of(context).appState.performanceMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
          color: isDark ? SchoolColors.darkBg : SchoolColors.bg,
        ),
        padding: padding,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: performance 
            ? _buildFallbackGlass(isDark) 
            : _buildTrueGlass(isDark),
        ),
      ),
    );
  }

  Widget _buildTrueGlass(bool isDark) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.65),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildFallbackGlass(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? SchoolColors.darkSurface.withOpacity(0.9) : SchoolColors.surfaceElevated.withOpacity(0.9),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
      ),
      child: child,
    );
  }
}
