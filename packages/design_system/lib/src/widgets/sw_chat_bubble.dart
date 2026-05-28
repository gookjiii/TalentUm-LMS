import 'package:flutter/material.dart';

class SwChatBubble extends StatelessWidget {
  const SwChatBubble({
    required this.content,
    required this.isMine,
    super.key,
  });

  final String content;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isMine ? colors.primaryContainer : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(content),
        ),
      ),
    );
  }
}
