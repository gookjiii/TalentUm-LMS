import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:school_world/src/firebase/school_repository.dart';
import 'package:school_world/src/models/schedule.dart';
import 'package:school_world/src/providers/app_providers.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_world/main.dart';

import 'package:school_world/src/features/grades/presentation/screens/grades_screen.dart';
import 'package:school_world/src/screens/settings_screen.dart';
import 'package:school_world/src/features/today/presentation/widgets/learning_streak_widget.dart';

class StudentToday extends ConsumerWidget {
  const StudentToday({
    super.key,
    required this.classes,
    required this.selectedClassId,
    required this.onTabSelect,
    required this.onHomeworkTap,
    this.showSidebar = false,
  });
  final List<Map<String, dynamic>> classes;
  final String? selectedClassId;
  final ValueChanged<int> onTabSelect;
  final VoidCallback onHomeworkTap;
  final bool showSidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    final userAsync = ref.watch(userDocumentProvider);
    final userData = userAsync.value ?? {};
    final rawName = userData['name']?.toString() ?? user?.displayName ?? l10n.student;
    final name = rawName.trim().isNotEmpty
        ? rawName.split(RegExp(r'\s+')).first
        : l10n.student;
    final avatarUrl = userData['avatarUrl']?.toString();

    final now = DateTime.now();
    final date = DateFormat('EEEE, MMMM d', l10n.localeName).format(now);
    final hour = now.hour;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 17
        ? l10n.goodAfternoon
        : l10n.goodEvening;

    final todaySchedules = ref.watch(studentTodaySchedulesProvider);
    final classNames = {
      for (final c in classes) c['id'].toString(): c['name']?.toString() ?? 'Класс',
    };

    ResolvedScheduleItem? upcomingClass;
    for (final item in todaySchedules) {
      if (item.cancelled) continue;
      final diff = item.start.difference(now).inMinutes;
      if (diff > 0 && diff <= 15) {
        upcomingClass = item;
        break;
      }
    }

    final activeLessons = todaySchedules.where((s) {
      final n = DateTime.now();
      return !s.cancelled && n.isAfter(s.start) && n.isBefore(s.end);
    }).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
      children: [
        // ── Header ────────────────────────────────────────────────
        FadeIn(
          delay: Duration.zero,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        color: SchoolColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$greeting, $name 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              SchoolAvatar(
                name: name,
                avatarUrl: avatarUrl,
                radius: 23,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => SettingsScreen(
                      repository: AppScope.of(ctx).repository,
                      appState: AppScope.of(ctx).appState,
                    ),
                  ),
                ),
                showBorder: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Stats row ─────────────────────────────────────────────
        FadeIn(
          delay: const Duration(milliseconds: 60),
          child: _StatsRow(
            classCount: classes.length,
            todayLessons: todaySchedules.length,
            activeLessons: activeLessons,
          ),
        ),
        const SizedBox(height: 16),

        // ── Upcoming class reminder ────────────────────────────────
        if (upcomingClass != null) ...[
          FadeIn(
            delay: const Duration(milliseconds: 80),
            child: _UpcomingClassReminder(
              item: upcomingClass,
              className: classNames[upcomingClass.classId] ?? 'Класс',
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Streak / homework progress ─────────────────────────────
        FadeIn(
          delay: const Duration(milliseconds: 100),
          child: const LearningStreakWidget(),
        ),
        const SizedBox(height: 12),
        FadeIn(
          delay: const Duration(milliseconds: 120),
          child: StreakCard(
            classIds: classes.map((c) => c['id'] as String).toList(),
            onTap: onHomeworkTap,
          ),
        ),
        const SizedBox(height: 24),

        // ── Today's classes ───────────────────────────────────────
        if (!showSidebar) ...[
          FadeIn(
            delay: const Duration(milliseconds: 160),
            child: SectionHeader(
              title: l10n.todaysClasses.toUpperCase(),
              action: l10n.viewAll,
              onActionTap: () => onTabSelect(4),
            ),
          ),
          const SizedBox(height: 12),
          FadeIn(
            delay: const Duration(milliseconds: 180),
            child: todaySchedules.isEmpty
                ? SchoolCard(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 32, color: SchoolColors.muted),
                          const SizedBox(height: 10),
                          Text(
                            l10n.noLessonsForToday,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SchoolColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : StaggeredList(
                    children: todaySchedules.take(3).map(
                      (item) => StudentScheduleCard(
                        item: item,
                        className: classNames[item.classId] ?? 'Класс',
                      ),
                    ).toList(),
                  ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Quick links ───────────────────────────────────────────
        FadeIn(
          delay: const Duration(milliseconds: 220),
          child: SectionHeader(title: l10n.quickLinks),
        ),
        const SizedBox(height: 12),
        FadeIn(
          delay: const Duration(milliseconds: 240),
          child: GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              QuickTile(
                onTap: () => onTabSelect(5),
                icon: Icons.library_books_outlined,
                label: l10n.library,
                color: SchoolColors.primary,
              ),
              QuickTile(
                onTap: () => onTabSelect(6),
                icon: Icons.ondemand_video_outlined,
                label: l10n.webinars,
                color: SchoolColors.accent,
              ),
              QuickTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RosterGradesScreen()),
                ),
                icon: Icons.school_outlined,
                label: l10n.myGrades,
                color: SchoolColors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.classCount,
    required this.todayLessons,
    required this.activeLessons,
  });
  final int classCount;
  final int todayLessons;
  final int activeLessons;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _StatMini(
          icon: Icons.school_rounded,
          value: '$classCount',
          label: l10n.allClasses,
          color: SchoolColors.primary,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatMini(
          icon: Icons.calendar_today_rounded,
          value: '$todayLessons',
          label: l10n.todaysClasses,
          color: SchoolColors.accent,
          isDark: isDark,
        ),
        if (activeLessons > 0) ...[
          const SizedBox(width: 10),
          _StatMini(
            icon: Icons.play_circle_rounded,
            value: '$activeLessons',
            label: AppLocalizations.of(context)!.now,
            color: SchoolColors.green,
            isDark: isDark,
            pulsing: true,
          ),
        ],
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    this.pulsing = false,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? SchoolColors.darkTextSecondary
                          : SchoolColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STREAK / HOMEWORK PROGRESS CARD
// ─────────────────────────────────────────────────────────────────
class StreakCard extends StatefulWidget {
  const StreakCard({super.key, required this.classIds, required this.onTap});

  final List<String> classIds;
  final VoidCallback onTap;

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  Future<_HomeworkProgress>? _progressFuture;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = AppScope.of(context).repository;
    _progressFuture ??= _loadProgress(repo, repo.uid, widget.classIds);
  }

  @override
  void didUpdateWidget(covariant StreakCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classIds != widget.classIds) {
      final repo = AppScope.of(context).repository;
      _progressFuture = _loadProgress(repo, repo.uid, widget.classIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<_HomeworkProgress>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final progress =
            snapshot.data ?? const _HomeworkProgress(done: 0, total: 0);
        final fraction = progress.total == 0
            ? 0.0
            : (progress.done / progress.total).clamp(0.0, 1.0);
        final percent = (fraction * 100).round();

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.96 : (_hovered ? 1.025 : 1.0),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SchoolColors.primaryDark, SchoolColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SchoolColors.primary.withValues(alpha: _hovered ? 0.45 : 0.28),
                      blurRadius: _hovered ? 28 : 20,
                      offset: Offset(0, _hovered ? 12 : 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated ring
                    CircularProgressRing(
                      percent: fraction,
                      color: Colors.white,
                      size: 56,
                      strokeWidth: 4,
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homework,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.homeworksDone(progress.done, progress.total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_HomeworkProgress> _loadProgress(
    SchoolRepository repo,
    String? uid,
    List<String> classIds,
  ) async {
    if (uid == null || classIds.isEmpty) {
      return const _HomeworkProgress(done: 0, total: 0);
    }

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final ids = classIds.take(10).toList(growable: false);

    final assignments = await repo.firestore
        .collection('assignments')
        .where('classId', whereIn: ids)
        .get();

    final relevantAssignments = assignments.docs
        .where((doc) {
          final dueAt = doc.data()['dueDate'];
          if (dueAt is! Timestamp) return false;
          final due = dueAt.toDate();
          return !due.isBefore(start) && due.isBefore(end);
        })
        .toList(growable: false);

    final effectiveAssignments = relevantAssignments.isEmpty
        ? assignments.docs
        : relevantAssignments;
    if (effectiveAssignments.isEmpty) {
      return const _HomeworkProgress(done: 0, total: 0);
    }

    final assignmentIds = effectiveAssignments.map((doc) => doc.id).toSet();
    final submissions = await repo.firestore
        .collection('submissions')
        .where('studentId', isEqualTo: uid)
        .get();
    final done = submissions.docs
        .where((doc) => assignmentIds.contains(doc.data()['assignmentId']))
        .length;

    return _HomeworkProgress(done: done, total: effectiveAssignments.length);
  }
}

class _HomeworkProgress {
  const _HomeworkProgress({required this.done, required this.total});
  final int done;
  final int total;
}

// ─────────────────────────────────────────────────────────────────
// UPCOMING CLASS REMINDER
// ─────────────────────────────────────────────────────────────────
class _UpcomingClassReminder extends StatelessWidget {
  const _UpcomingClassReminder({required this.item, required this.className});
  final ResolvedScheduleItem item;
  final String className;

  @override
  Widget build(BuildContext context) {
    final diff = item.start.difference(DateTime.now()).inMinutes;
    final l10n = AppLocalizations.of(context)!;

    return GlassCard(
      color: SchoolColors.orange.withValues(alpha: 0.12),
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: SchoolColors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'УРОК НАЧНЕТСЯ ЧЕРЕЗ $diff МИН!',
                  style: const TextStyle(
                    color: SchoolColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$className · Кабинет ${item.room ?? '—'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.joinLessonSoon)));
            },
            style: FilledButton.styleFrom(
              backgroundColor: SchoolColors.orange,
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.join,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SCHEDULE CARD
// ─────────────────────────────────────────────────────────────────
class StudentScheduleCard extends StatefulWidget {
  const StudentScheduleCard({
    super.key,
    required this.item,
    required this.className,
  });

  final ResolvedScheduleItem item;
  final String className;

  @override
  State<StudentScheduleCard> createState() => _StudentScheduleCardState();
}

class _StudentScheduleCardState extends State<StudentScheduleCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = widget.item.start;
    final end = widget.item.end;
    final isNow =
        now.isAfter(start) && now.isBefore(end) && !widget.item.cancelled;
    final isNext = now.isBefore(start) && !widget.item.cancelled;
    final startLabel = DateFormat('HH:mm').format(start);
    final room = widget.item.room?.toString().trim() ?? '—';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectColor = widget.item.cancelled
        ? Colors.grey
        : (isNow
              ? SchoolColors.green
              : isNext
              ? SchoolColors.orange
              : isDark
              ? SchoolColors.darkMuted
              : SchoolColors.muted);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : (_hovered ? 1.015 : 1.0),
            duration: const Duration(milliseconds: 150),
            child: GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              color: _hovered
                  ? subjectColor.withValues(alpha: isDark ? 0.10 : 0.04)
                  : null,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: subjectColor,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SchoolColors.green.withValues(
                              alpha: isNow ? 0.5 : 0.0,
                            ),
                            blurRadius: isNow ? 8 : 0,
                            spreadRadius: isNow ? 1 : 0,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$startLabel · Кабинет $room',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? SchoolColors.darkMuted
                                          : SchoolColors.muted,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.className,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (widget.item.note != null &&
                                      widget.item.note!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: Text(
                                        widget.item.note!.trim(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(
                              isNow: isNow,
                              isNext: isNext,
                              isCancelled: widget.item.cancelled,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.isNow,
    required this.isNext,
    required this.isCancelled,
  });
  final bool isNow, isNext, isCancelled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isCancelled) {
      return StatusChip(
        label: AppLocalizations.of(context)!.canceled,
        color: SchoolColors.red,
        icon: Icons.cancel_outlined,
      );
    }
    if (isNow) {
      return StatusChip(
        label: l10n.now,
        color: SchoolColors.green,
        pulseDot: true,
      );
    }
    if (isNext) {
      return StatusChip(
        label: AppLocalizations.of(context)!.soon,
        color: SchoolColors.orange,
        icon: Icons.access_time_rounded,
      );
    }
    return StatusChip(label: l10n.later, color: SchoolColors.muted);
  }
}
