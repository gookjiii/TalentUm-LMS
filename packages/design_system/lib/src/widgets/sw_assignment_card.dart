import 'package:flutter/material.dart';

class SwAssignmentCard extends StatelessWidget {
  const SwAssignmentCard({
    required this.title,
    required this.subtitle,
    required this.dueDateLabel,
    super.key,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String dueDateLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(dueDateLabel),
      ),
    );
  }
}
