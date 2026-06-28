import 'package:flutter/material.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';
import 'package:school_world/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: color ?? (isDark ? SchoolColors.darkMuted : SchoolColors.muted),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// MODERN SETTING TILE
// ─────────────────────────────────────────────────────────────────
class ModernSettingTile extends StatelessWidget {
  const ModernSettingTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PROFILE CARD
// ─────────────────────────────────────────────────────────────────
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.sub,
    required this.isTeacher,
    this.classesCount,
    this.avatarUrl,
    this.onEditAvatar,
  });
  
  final String name, sub;
  final bool isTeacher;
  final int? classesCount;
  final String? avatarUrl;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: const EdgeInsets.all(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isTeacher ? SchoolColors.red : SchoolColors.primary)
                        .withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: avatarUrl == null
                          ? LinearGradient(
                              colors: isTeacher
                                  ? [SchoolColors.red, SchoolColors.yellow]
                                  : [SchoolColors.green, SchoolColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SchoolAvatar(
                      name: name,
                      avatarUrl: avatarUrl,
                      radius: 32,
                      color: avatarUrl != null ? null : Colors.transparent,
                      onEditAvatar: onEditAvatar,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: SchoolColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SchoolColors.muted,
                      ),
                    ),
                    if (isTeacher || classesCount != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (classesCount != null) ...[
                            StatusChip(
                              label: isTeacher ? '$classesCount классов' : '$classesCount предметов',
                              color: SchoolColors.primary.withOpacity(0.1),
                              textColor: SchoolColors.primary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          StatusChip(
                            label: AppLocalizations.of(context)!.verified,
                            color: SchoolColors.green,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STAT MINI CARD
// ─────────────────────────────────────────────────────────────────
class StatMiniCard extends StatelessWidget {
  const StatMiniCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SchoolCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: SchoolColors.muted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
