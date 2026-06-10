import 'package:flutter/material.dart';

class SwPrimaryButton extends StatefulWidget {
  const SwPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<SwPrimaryButton> createState() => _SwPrimaryButtonState();
}

class _SwPrimaryButtonState extends State<SwPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const SpringCurve(stiffness: 100, damping: 20),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.onPressed == null 
                ? colorScheme.outline 
                : colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon, 
                  color: colorScheme.onPrimary, 
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpringCurve extends Curve {
  const SpringCurve({this.stiffness = 100, this.damping = 20});
  final double stiffness;
  final double damping;

  @override
  double transformInternal(double t) {
    return Curves.easeOutQuad.transform(t);
  }
}
