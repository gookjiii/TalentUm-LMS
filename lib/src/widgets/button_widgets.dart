import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

// ─────────────────────────────────────────────────────────────────
// GRADIENT BUTTON (Positive Action)
// ─────────────────────────────────────────────────────────────────
class GradientButton extends HookWidget {
  const GradientButton({super.key, required this.text, required this.onTap, this.icon});
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);
    final isHovered = useState(false);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        onTap: onTap,
        child: AnimatedScale(
          scale: isPressed.value ? 0.96 : (isHovered.value ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: SchoolColors.gradPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: SchoolColors.primary.withValues(alpha: isHovered.value ? 0.4 : 0.25),
                  blurRadius: isHovered.value ? 24 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ELITE TACTILE BUTTON (Guidelines 2.5)
// ─────────────────────────────────────────────────────────────────
class EliteTactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const EliteTactileButton({super.key, required this.child, required this.onTap});

  @override
  State<EliteTactileButton> createState() => _EliteTactileButtonState();
}

class _EliteTactileButtonState extends State<EliteTactileButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
