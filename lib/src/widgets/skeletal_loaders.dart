import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletalLoader extends StatelessWidget {
  const SkeletalLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ChatMessageSkeleton extends StatelessWidget {
  const ChatMessageSkeleton({super.key, required this.isMe});
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const SkeletalLoader(width: 32, height: 32, borderRadius: 16),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 4),
                  child: SkeletalLoader(width: 60, height: 10),
                ),
              SkeletalLoader(
                width: 120 + (isMe ? 40 : 80).toDouble(),
                height: 44,
                borderRadius: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ClassCardSkeleton extends StatelessWidget {
  const ClassCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: const [
          SkeletalLoader(width: 52, height: 52, borderRadius: 26),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletalLoader(width: 120, height: 16),
                    Spacer(),
                    SkeletalLoader(width: 30, height: 16, borderRadius: 8),
                  ],
                ),
                SizedBox(height: 8),
                SkeletalLoader(width: 180, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
