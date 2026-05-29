import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:school_world/src/theme.dart';

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.width, required this.height, this.radius = 12});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? SchoolColors.darkSurfaceElevated : SchoolColors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

Widget _shimmerWrap(BuildContext context, Widget child) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Shimmer.fromColors(
    baseColor: isDark ? SchoolColors.darkSurfaceElevated : const Color(0xFFE8EAF0),
    highlightColor: isDark ? SchoolColors.darkBorder : Colors.white,
    child: child,
  );
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key, this.hasSubtitle = true});
  final bool hasSubtitle;

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      context,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        child: Row(
          children: [
            _ShimmerBox(width: 44, height: 44, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: double.infinity, height: 14, radius: 6),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 8),
                    _ShimmerBox(width: 160, height: 11, radius: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ShimmerBox(width: 60, height: 28, radius: 14),
          ],
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 80});
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _shimmerWrap(
      context,
      Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? SchoolColors.darkSurface : Colors.white,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: isDark ? SchoolColors.darkBorder : SchoolColors.border,
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: const Row(
          children: [
            _ShimmerBox(width: 48, height: 48, radius: 12),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: double.infinity, height: 14, radius: 6),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 120, height: 11, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerHomeworkList extends StatelessWidget {
  const ShimmerHomeworkList({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: ShimmerListTile(),
        ),
      ),
    );
  }
}
