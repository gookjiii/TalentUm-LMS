import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../utils/responsive_utils.dart';

// ─────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        spacing: 8,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.2,
            ),
          ),
          if (action != null && action!.isNotEmpty)
            Semantics(
              label: action,
              button: true,
              child: TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(
                  action!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: SchoolColors.primary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.classContext,
    this.onClassContextTap,
    this.trailing,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
    this.icon, // Extended for Elite
  });

  final String title;
  final String? subtitle;
  final String? classContext;
  final VoidCallback? onClassContextTap;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: padding ??
          EdgeInsets.fromLTRB(
            context.isMobile ? 16 : 24,
            topPadding + (context.isMobile ? 16 : 24),
            context.isMobile ? 16 : 24,
            16,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (classContext != null) ...[
            _ContextBadge(
              label: classContext!,
              onTap: onClassContextTap,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SchoolColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: SchoolColors.primary, size: 28),
                ),
                const SizedBox(width: 20),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleStyle ?? GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: subtitleStyle ?? theme.textTheme.bodyMedium?.copyWith(
                          color: SchoolColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

class _ContextBadge extends StatelessWidget {
  const _ContextBadge({required this.label, this.onTap, this.color});
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? SchoolColors.primary;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            onTap != null ? Icons.swap_horiz_rounded : Icons.school_rounded,
            size: 14,
            color: c,
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: c,
              letterSpacing: 1,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: c.withOpacity(0.7),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return badge;

    return GestureDetector(
      onTap: onTap,
      child: badge,
    );
  }
}
