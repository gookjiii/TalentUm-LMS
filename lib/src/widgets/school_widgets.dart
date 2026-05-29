import 'package:school_world/l10n/app_localizations.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../main.dart';
import '../theme.dart';
export 'cached_stream_builder.dart';

// ─────────────────────────────────────────────────────────────────
// HOVERABLE
// ─────────────────────────────────────────────────────────────────
class Hoverable extends HookWidget {
  const Hoverable({
    super.key,
    required this.builder,
    this.onTap,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget Function(bool isHovered) builder;
  final VoidCallback? onTap;
  final MouseCursor cursor;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);

    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(onTap: onTap, child: builder(isHovered.value)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STUDENT NAME (async fetch)
// ─────────────────────────────────────────────────────────────────
class StudentName extends StatefulWidget {
  const StudentName({super.key, required this.studentId, this.style});
  final String studentId;
  final TextStyle? style;

  @override
  State<StudentName> createState() => _StudentNameState();
}

class _StudentNameState extends State<StudentName> {
  Future<Map<String, dynamic>?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void didUpdateWidget(covariant StudentName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      _future = _load();
    }
  }

  Future<Map<String, dynamic>?> _load() {
    final repo = AppScope.of(context).repository;
    return repo.getCachedOrFetch('users', widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return Text(widget.studentId, style: widget.style);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Text(
            snapshot.data!['name']?.toString() ?? widget.studentId,
            style: widget.style,
          );
        }
        return Text(widget.studentId, style: widget.style);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SCHOOL LOGO
// ─────────────────────────────────────────────────────────────────
class SchoolLogo extends StatelessWidget {
  const SchoolLogo({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .28),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AppScope.of(context).repository.systemSettingsStream(),
        builder: (context, snapshot) {
          final doc = snapshot.data;
          final logoUrl = (doc != null && doc.exists)
              ? (doc.data()?['logoUrl'] as String?)
              : null;

          if (logoUrl != null && logoUrl.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: logoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: size,
                height: size,
                color: Colors.grey.withOpacity(0.08),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Image.asset(
                'assets/school-world-logo.jpg',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            );
          }

          return Image.asset(
            'assets/school-world-logo.jpg',
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SCHOOL CARD  (improved hover + shadow)
// ─────────────────────────────────────────────────────────────────
class SchoolCard extends HookWidget {
  const SchoolCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius = 20,
    this.borderColor,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        color ?? (isDark ? SchoolColors.darkSurface : Colors.white);
    final resolvedBorderColor = borderColor ??
        (color == null
            ? (isHovered.value
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                : (isDark
                    ? SchoolColors.darkBorder
                    : SchoolColors.border))
            : Colors.white.withValues(alpha: 0.15));

    return MouseRegion(
      onEnter: onTap != null ? (_) => isHovered.value = true : null,
      onExit: onTap != null ? (_) => isHovered.value = false : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: margin,
        transform: (onTap != null && isHovered.value)
            ? (Matrix4.identity()..translate(0, -3.0, 0))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: resolvedBorderColor, width: 1),
          boxShadow: boxShadow ?? [
            if (isHovered.value && onTap != null)
              SchoolColors.cardShadowHover
            else
              SchoolColors.cardShadow,
          ],
        ),
        child: Material(
          color: themeColor,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GLASS CARD  (frosted glassmorphism surface)
// ─────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20.0,
    this.color,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.65));

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(borderRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CLASS BADGE
// ─────────────────────────────────────────────────────────────────
class ClassBadge extends StatelessWidget {
  const ClassBadge({
    super.key,
    required this.name,
    this.color = SchoolColors.primary,
    this.size = 44,
    this.radius,
    this.avatarUrl,
  });

  final String name;
  final Color color;
  final double size;
  final double? radius;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? size * .3),
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _buildInitials(),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    final lighter = Color.lerp(color, Colors.white, .3) ?? color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, lighter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius ?? size * .3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * .42,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SCHOOL AVATAR
// ─────────────────────────────────────────────────────────────────
class SchoolAvatar extends HookWidget {
  const SchoolAvatar({
    super.key,
    required this.name,
    this.radius = 18,
    this.color,
    this.avatarUrl,
    this.onTap,
    this.onEditAvatar,
    this.showBorder = false,
    this.userId,
  });

  final String name;
  final double radius;
  final Color? color;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final VoidCallback? onEditAvatar;
  final bool showBorder;
  final String? userId;

  String _getInitials(String inputName) {
    final parts = inputName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  Color _resolveColorForName(Color? customColor, String resolvedName) {
    if (customColor != null) return customColor;
    const colors = [
      SchoolColors.primary,
      SchoolColors.green,
      SchoolColors.purple,
      SchoolColors.secondary,
      SchoolColors.red,
    ];
    return colors[resolvedName.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final isHovered = useState(false);

    final userStream = useMemoized(
      () => userId != null
          ? repo.firestore.collection('users').doc(userId).snapshots()
          : const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty(),
      [userId],
    );
    final userSnap = useStream(userStream);

    final Map<String, dynamic> userData = userSnap.data?.data() ?? {};
    final String resolvedName = userData['name'] as String? ?? name;
    final String? resolvedAvatarUrl = userData['avatarUrl'] as String? ?? avatarUrl;

    final c = _resolveColorForName(color, resolvedName);
    
    final statusStream = useMemoized(
      () => userId != null ? repo.userStatusStream(userId!) : const Stream<Map<String, dynamic>>.empty(),
      [userId],
    );
    final statusSnap = useStream(statusStream);
    final isOnline = statusSnap.data?['state'] == 'online';

    final rippleController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );
    
    useEffect(() {
      if (isOnline) {
        rippleController.repeat();
      } else {
        rippleController.stop();
      }
      return null;
    }, [isOnline]);

    final rippleScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: rippleController, curve: Curves.easeOut),
    );
    final rippleOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: rippleController, curve: Curves.easeOut),
    );

    Widget avatar = resolvedAvatarUrl != null && resolvedAvatarUrl.isNotEmpty
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: resolvedAvatarUrl,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              errorWidget: (_, __, ___) => _buildDefaultAvatar(c, resolvedName),
            ),
          )
        : _buildDefaultAvatar(c, resolvedName);

    if (showBorder) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: avatar,
      );
    }

    Widget content = MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isOnline)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: rippleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: rippleScale.value,
                    child: Opacity(
                      opacity: rippleOpacity.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SchoolColors.green,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          avatar,
          if (onEditAvatar != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: isHovered.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: radius * 0.8,
                    ),
                  ),
                ),
              ),
            ),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: radius * 0.55,
                height: radius * 0.55,
                decoration: BoxDecoration(
                  color: SchoolColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: SchoolColors.green.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    final tapTarget = onEditAvatar ?? onTap;
    if (tapTarget != null) {
      return InkWell(
        onTap: tapTarget,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      );
    }
    return content;
  }

  Widget _buildDefaultAvatar(Color c, String resolvedName) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, Colors.white, .25) ?? c],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _getInitials(resolvedName),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * .75,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STATUS CHIP  (with animated dot variant)
// ─────────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.textColor,
    this.iconSize = 12,
    this.pulseDot = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Color? textColor;
  final double iconSize;
  final bool pulseDot;

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulseDot) ...[
            _PulseDot(color: color),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: iconSize, color: effectiveTextColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends HookWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    final scale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    final opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Transform.scale(
        scale: scale.value,
        child: Opacity(
          opacity: opacity.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TEACHER TAG
// ─────────────────────────────────────────────────────────────────
class TeacherTag extends StatefulWidget {
  const TeacherTag({super.key, required this.userId});
  final String userId;

  @override
  State<TeacherTag> createState() => _TeacherTagState();
}

class _TeacherTagState extends State<TeacherTag> {
  Future<Map<String, dynamic>?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void didUpdateWidget(covariant TeacherTag oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _future = _load();
    }
  }

  Future<Map<String, dynamic>?> _load() {
    final repo = AppScope.of(context).repository;
    return repo.getCachedOrFetch('users', widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final role = snapshot.data!['role'] as String?;
          if (role == 'teacher' || role == 'admin' || role == 'leadTeacher') {
            return Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SchoolColors.primary, SchoolColors.secondary],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                AppLocalizations.of(context)!.teacher1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// UTILITIES
// ─────────────────────────────────────────────────────────────────
Color parseHexColor(Object? value, [Color fallback = SchoolColors.primary]) {
  if (value is! String || value.isEmpty) return fallback;
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

DateTime? toDate(dynamic val) {
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return null;
}

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
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (action != null && action!.isNotEmpty)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SchoolColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// QUICK TILE  (with animated press scale)
// ─────────────────────────────────────────────────────────────────
class QuickTile extends HookWidget {
  const QuickTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);
    final isHovered = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: onTap != null ? (_) => isHovered.value = true : null,
      onExit: onTap != null ? (_) => isHovered.value = false : null,
      child: GestureDetector(
        onTapDown: onTap != null ? (_) => isPressed.value = true : null,
        onTapUp: onTap != null ? (_) => isPressed.value = false : null,
        onTapCancel: onTap != null ? () => isPressed.value = false : null,
        onTap: onTap,
        child: AnimatedScale(
          scale: isPressed.value ? 0.95 : (isHovered.value ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: SchoolCard(
            padding: const EdgeInsets.all(14),
            onTap: null,
            borderRadius: 20,
            color: isHovered.value
                ? (isDark
                    ? color.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.04))
                : null,
            borderColor: isHovered.value
                ? color.withValues(alpha: 0.35)
                : null,
            boxShadow: [
              if (isHovered.value)
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
              else
                SchoolColors.cardShadow,
            ],
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isHovered.value
                                ? [
                                    color.withValues(alpha: 0.25),
                                    color.withValues(alpha: 0.12),
                                  ]
                                : [
                                    color.withValues(alpha: 0.15),
                                    color.withValues(alpha: 0.08),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (isHovered.value)
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                          ],
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _BadgeCount(count: badge!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeCount extends StatelessWidget {
  const _BadgeCount({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: SchoolColors.red,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: SchoolColors.red.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class NotificationQuickTile extends StatelessWidget {
  const NotificationQuickTile({
    super.key,
    required this.onTap,
    required this.label,
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return QuickTile(
      onTap: onTap,
      icon: Icons.notifications_none_rounded,
      label: label,
      color: SchoolColors.orange,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EMPTY STATE  (reusable illustrated placeholder)
// ─────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [c.withValues(alpha: 0.12), c.withValues(alpha: 0.0)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: c.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: action,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ANIMATED COUNTER  (number ticker)
// ─────────────────────────────────────────────────────────────────
class AnimatedCounter extends HookWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final animation = useAnimationController(duration: duration)
      ..forward();
    final tween = useMemoized(
      () => IntTween(begin: 0, end: value).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      [value],
    );

    return AnimatedBuilder(
      animation: tween,
      builder: (_, __) => Text(
        '$prefix${tween.value}$suffix',
        style: style,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BRANDED LOADER  (themed spinner with logo)
// ─────────────────────────────────────────────────────────────────
class BrandedLoader extends StatelessWidget {
  const BrandedLoader({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FADE IN WRAPPER
// ─────────────────────────────────────────────────────────────────
class FadeIn extends HookWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 12),
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    final opacity = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: Offset(offset.dx / 100, offset.dy / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    useEffect(() {
      Future.delayed(delay, () {
        if (controller.isCompleted == false) controller.forward();
      });
      return null;
    }, []);

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// GRADIENT CIRCLE DECORATION  (reusable hero icon background)
// ─────────────────────────────────────────────────────────────────
class GradientIconBox extends StatelessWidget {
  const GradientIconBox({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 48,
    this.iconSize = 24,
    this.borderRadius = 14,
  });

  final IconData icon;
  final List<Color> colors;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CIRCULAR PROGRESS RING  (for stats / streaks)
// ─────────────────────────────────────────────────────────────────
class CircularProgressRing extends HookWidget {
  const CircularProgressRing({
    super.key,
    required this.percent,
    required this.color,
    this.size = 64,
    this.strokeWidth = 5,
    this.child,
    this.animate = true,
  });

  final double percent;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1000),
    );

    useEffect(() {
      controller.forward();
      return null;
    }, [percent]);

    final Animation<double> animatedPercent = animate
        ? Tween<double>(begin: 0, end: percent.clamp(0, 1)).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
          )
        : AlwaysStoppedAnimation(percent.clamp(0, 1));

    return AnimatedBuilder(
      animation: animatedPercent,
      builder: (_, __) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: animatedPercent.value,
                color: color,
                trackColor: color.withValues(alpha: 0.12),
                strokeWidth: strokeWidth,
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────
// FADE INDEXED STACK  (state-preserving smooth tab switcher)
// ─────────────────────────────────────────────────────────────────
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 260),
    this.slideOffset = const Offset(0.015, 0.0),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;
  final Offset slideOffset;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: IndexedStack(
          index: widget.index,
          children: widget.children,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STAGGERED LIST  (smooth item enter cascade)
// ─────────────────────────────────────────────────────────────────
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 350),
    this.delayStep = const Duration(milliseconds: 40),
    this.slideOffset = const Offset(0, 8),
    this.physics,
    this.shrinkWrap = true,
  });

  final List<Widget> children;
  final Duration duration;
  final Duration delayStep;
  final Offset slideOffset;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return FadeIn(
          duration: duration,
          delay: delayStep * index,
          offset: slideOffset,
          child: children[index],
        );
      },
    );
  }
}
