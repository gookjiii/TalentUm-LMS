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

    return RepaintBoundary(
      child: Shimmer.fromColors(
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
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const SkeletalLoader(width: 32, height: 32, borderRadius: 16),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                    SkeletalLoader(
                      width: 30,
                      height: 16,
                      borderRadius: 8,
                    ),
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

class AssignmentCardSkeleton extends StatelessWidget {
  const AssignmentCardSkeleton({super.key, this.isFeatured = false});
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: isFeatured
          ? const EdgeInsets.all(20)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            isFeatured ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SkeletalLoader(
            width: isFeatured ? 48 : 40,
            height: isFeatured ? 48 : 40,
            borderRadius: isFeatured ? 14 : 10,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SkeletalLoader(
                      width: isFeatured ? 160 : 130,
                      height: isFeatured ? 16 : 14,
                      borderRadius: 4,
                    ),
                    const Spacer(),
                    const SkeletalLoader(width: 60, height: 20, borderRadius: 10),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    SkeletalLoader(width: 90, height: 12, borderRadius: 4),
                    SizedBox(width: 12),
                    SkeletalLoader(width: 70, height: 12, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JournalGridSkeleton extends StatelessWidget {
  const JournalGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header row
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const SkeletalLoader(width: 120, height: 14, borderRadius: 4),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(
                          6,
                          (index) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SkeletalLoader(width: 36, height: 14, borderRadius: 4),
                              SizedBox(height: 6),
                              SkeletalLoader(width: 24, height: 10, borderRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body rows
              ...List.generate(
                6,
                (rowIdx) => Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: const [
                          SkeletalLoader(width: 32, height: 32, borderRadius: 16),
                          SizedBox(width: 12),
                          SkeletalLoader(width: 100, height: 12, borderRadius: 4),
                        ],
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(
                            6,
                            (colIdx) => const SkeletalLoader(
                              width: 28,
                              height: 28,
                              borderRadius: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
