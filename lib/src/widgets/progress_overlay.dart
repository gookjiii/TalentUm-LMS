import 'package:flutter/material.dart';
import '../theme.dart';

/// Simple overlay that shows a centered circular progress indicator when
/// [show] is true. The child is displayed underneath with a dark translucent
/// barrier.
class ProgressOverlay extends StatelessWidget {
  const ProgressOverlay({required this.show, required this.child, super.key});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (show)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SchoolColors.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
