import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_world/l10n/app_localizations.dart';
import '../utils/string_extensions.dart';
import '../theme.dart';
import '../../main.dart';

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
    final performanceMode = AppScope.of(context).appState.performanceMode;
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
            final cacheSize = (size * 2.5).round();
            return CachedNetworkImage(
              imageUrl: logoUrl.toDirectImageUrl.toOptimizedCloudinary(
                performance: performanceMode,
              ),
              width: size,
              height: size,
              fit: BoxFit.cover,
              memCacheWidth: cacheSize,
              memCacheHeight: cacheSize,
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
    final performanceMode = AppScope.of(context).appState.performanceMode;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? size * .3),
        child: CachedNetworkImage(
          imageUrl: avatarUrl!.toDirectImageUrl.toOptimizedCloudinary(
            performance: performanceMode,
          ),
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * 2.5).round(),
          memCacheHeight: (size * 2.5).round(),
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
    final appState = AppScope.of(context).appState;
    final isPerformance = appState.performanceMode;
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
    final String? resolvedAvatarUrl =
        userData['avatarUrl'] as String? ?? avatarUrl;

    final c = _resolveColorForName(color, resolvedName);

    final statusStream = useMemoized(
      () => userId != null
          ? repo.userStatusStream(userId!)
          : const Stream<Map<String, dynamic>>.empty(),
      [userId],
    );
    final statusSnap = useStream(statusStream);
    final isOnline = statusSnap.data?['state'] == 'online';

    final rippleController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );

    useEffect(() {
      if (isOnline && !isPerformance) {
        rippleController.repeat();
      } else {
        rippleController.stop();
      }
      return null;
    }, [isOnline, isPerformance]);

    final rippleScale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: rippleController, curve: Curves.easeOut));
    final rippleOpacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: rippleController, curve: Curves.easeOut));

    final cacheSize = (radius * 2 * 2.5).round();
    Widget avatar = resolvedAvatarUrl != null && resolvedAvatarUrl.isNotEmpty
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: resolvedAvatarUrl.toDirectImageUrl
                  .toOptimizedCloudinary(performance: isPerformance),
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              memCacheWidth: cacheSize,
              memCacheHeight: cacheSize,
              placeholder: (context, url) =>
                  Container(color: Colors.grey.withValues(alpha: 0.1)),
              errorWidget: (_, __, ___) => _buildDefaultAvatar(c, resolvedName),
            ),
          )
        : _buildDefaultAvatar(c, resolvedName);

    if (showBorder) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
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
                style: const TextStyle(
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
