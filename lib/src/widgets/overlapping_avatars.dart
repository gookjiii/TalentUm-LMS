import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable widget for overlapping avatar group
class OverlappingAvatars extends StatelessWidget {
  const OverlappingAvatars({
    super.key,
    required this.userIds,
    this.maxVisible = 6,
    this.avatarSize = 28.0,
    this.overlapOffset = 20.0,
    this.borderWidth = 2.0,
    this.borderColor = SchoolColors.bg,
  });

  final List<String> userIds;
  final int maxVisible;
  final double avatarSize;
  final double overlapOffset;
  final double borderWidth;
  final Color borderColor;

  static const _avatarColors = [
    SchoolColors.primary,
    SchoolColors.green,
    SchoolColors.orange,
    SchoolColors.purple,
    SchoolColors.secondary,
    Color(0xFF0F9D58),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleIds = userIds.take(maxVisible).toList();
    if (visibleIds.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: visibleIds.length * overlapOffset + (avatarSize - overlapOffset),
      height: avatarSize,
      child: Stack(
        children: [
          for (int i = 0; i < visibleIds.length; i++)
            Positioned(
              left: i * overlapOffset,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: _avatarColors[i % _avatarColors.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: Center(
                  child: Text(
                    visibleIds[i].isNotEmpty
                        ? visibleIds[i][0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: avatarSize * 0.36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
