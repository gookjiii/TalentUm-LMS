import 'package:flutter/material.dart';

class SwPrimaryButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final child = Text(label);
    if (icon == null) {
      return FilledButton(onPressed: onPressed, child: child);
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: child,
    );
  }
}
