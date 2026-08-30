import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Item dữ liệu cho thanh điều hướng di động
class SchoolMobileNavItem {
  const SchoolMobileNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? badgeCount;
}

/// Thanh điều hướng di động nổi (Floating Glassmorphism Mobile Navigation Bar)
/// chuẩn Design System cho TalentUm-LMS.
///
/// Hỗ trợ:
/// - Hiệu ứng kính mờ (frosted glass) cao cấp với viền sắc nét và đổ bóng mềm.
/// - Cân bằng tỷ lệ vàng: không gây tràn layout dọc trên các thiết bị nhỏ (360px).
/// - Phản hồi xúc giác (Haptic Feedback) khi chuyển tab.
/// - Tự động điều chỉnh khoảng đệm Safe Area (iOS Home Indicator & Android Gestures).
class SchoolMobileNavBar extends StatelessWidget {
  const SchoolMobileNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
    this.onMoreTap,
    this.moreSelected = false,
    this.moreLabel = 'More',
    this.moreIcon = Icons.grid_view_outlined,
    this.moreSelectedIcon = Icons.grid_view_rounded,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<SchoolMobileNavItem> items;
  final VoidCallback? onMoreTap;
  final bool moreSelected;
  final String moreLabel;
  final IconData moreIcon;
  final IconData moreSelectedIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // Chiều cao thanh nav bar: 64px
    const double barHeight = 64.0;
    // Khoảng cách an toàn dưới đáy: nếu có home indicator (34px) thì bớt đi chút để cân đối
    final double safeBottom = bottomInset > 0 ? math.max(0.0, bottomInset - 6) : 8.0;

    return Padding(
      padding: EdgeInsets.only(bottom: safeBottom),
      child: Container(
        height: barHeight,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? SchoolColors.darkSurface.withValues(alpha: 0.82)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : SchoolColors.border.withValues(alpha: 0.7),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = selectedIndex == index;
                    return Expanded(
                      child: _NavBarTabItem(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: item.label,
                        isSelected: isSelected,
                        badgeCount: item.badgeCount,
                        isDark: isDark,
                        onTap: () {
                          if (!kIsWeb &&
                              (defaultTargetPlatform == TargetPlatform.iOS ||
                                  defaultTargetPlatform == TargetPlatform.android)) {
                            HapticFeedback.selectionClick();
                          }
                          onSelect(index);
                        },
                      ),
                    );
                  }),
                  if (onMoreTap != null)
                    Expanded(
                      child: _NavBarTabItem(
                        icon: moreIcon,
                        selectedIcon: moreSelectedIcon,
                        label: moreLabel,
                        isSelected: moreSelected,
                        isDark: isDark,
                        onTap: () {
                          if (!kIsWeb &&
                              (defaultTargetPlatform == TargetPlatform.iOS ||
                                  defaultTargetPlatform == TargetPlatform.android)) {
                            HapticFeedback.selectionClick();
                          }
                          onMoreTap!();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarTabItem extends StatelessWidget {
  const _NavBarTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final Color iconColor = isSelected
        ? primaryColor
        : (isDark
            ? SchoolColors.darkTextSecondary.withValues(alpha: 0.6)
            : SchoolColors.textSecondary.withValues(alpha: 0.65));

    final Color labelColor = isSelected
        ? primaryColor
        : (isDark
            ? SchoolColors.darkTextSecondary.withValues(alpha: 0.7)
            : SchoolColors.textSecondary.withValues(alpha: 0.75));

    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: primaryColor.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container với highlight active mềm
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? primaryColor.withValues(alpha: 0.2)
                            : primaryColor.withValues(alpha: 0.12))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? selectedIcon : icon,
                        size: 21,
                        color: iconColor,
                      ),
                      if (badgeCount != null && badgeCount! > 0)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: SchoolColors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Center(
                              child: Text(
                                badgeCount! > 99 ? '99+' : '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: labelColor,
                      letterSpacing: isSelected ? -0.1 : 0.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
