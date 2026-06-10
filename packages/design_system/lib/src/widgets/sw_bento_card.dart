import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SwBentoCard extends StatelessWidget {
  const SwBentoCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(32),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: isDark ? null : SwTheme.diffusionShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
