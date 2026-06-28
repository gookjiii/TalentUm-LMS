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
import 'package:sw_design_system/design_system.dart';
import 'package:school_world/src/utils/responsive_utils.dart';

import 'package:school_world/src/screens/settings_screen.dart';
import 'package:school_world/src/screens/student_shell.dart';


class StudentToday extends ConsumerWidget {
  const StudentToday({
    super.key,
    required this.classes,
    required this.selectedClassId,
    required this.onTabSelect,
    required this.onHomeworkTap,
    this.onProfileTap,
    this.showSidebar = false,
  });
  final List<Map<String, dynamic>> classes;
  final String? selectedClassId;
  final ValueChanged<int> onTabSelect;
  final VoidCallback onHomeworkTap;
  final VoidCallback? onProfileTap;
  final bool showSidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    final userAsync = ref.watch(userDocumentProvider);
    final userData = userAsync.value ?? {};
    final rawName =
        userData['name']?.toString() ?? user?.displayName ?? l10n.student;
    final name = rawName.trim().isNotEmpty
        ? rawName.split(RegExp(r'\s+')).first
        : l10n.student;
    final avatarUrl = userData['avatarUrl']?.toString();

    final now = DateTime.now();
    final date = DateFormat('EEEE, MMMM d', l10n.localeName).format(now);
    final greeting = l10n.welcomeToTalentum;

    final todaySchedules = ref.watch(studentTodaySchedulesProvider);
    final classInfo = {
      for (final c in classes)
        c['id'].toString(): (
          name: c['name']?.toString() ?? 'Класс',
          subject: c['subject']?.toString() ?? '',
        ),
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

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding,
              vertical: 16,
            ),
            child: PageHeader(
              padding: EdgeInsets.zero,
              title: '$greeting!',
              subtitle: date,
              trailing: SchoolAvatar(
                name: name,
                avatarUrl: avatarUrl,
                radius: 23,
                onTap: onProfileTap ??
                    () => Navigator.push(
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
            ),
          ),
        ),

        // ── Bento Grid Section ─────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _BentoStats(
                          classCount: classes.length,
                          todayLessons: todaySchedules.length,
                          activeLessons: activeLessons,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: StreakCard(
                          classIds: classes
                              .map((c) => (c['id'] ?? '').toString())
                              .toList(),
                          onTap: onHomeworkTap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (upcomingClass != null) ...[
                  _UpcomingClassReminder(
                    item: upcomingClass,
                    className:
                        classInfo[upcomingClass.classId]?.name ?? 'Класс',
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // ── Today's classes ───────────────────────────────────────
        if (!showSidebar) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
              ),
              child: SectionHeader(
                title: l10n.todaysClasses.toUpperCase(),
                action: l10n.viewAll,
                onActionTap: () => onTabSelect(4),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (todaySchedules.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                ),
                child: SwBentoCard(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 32,
                          color: SchoolColors.muted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noLessonsForToday,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SchoolColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = todaySchedules[index];
                    if (index >= 3) return null;
                    final info = classInfo[item.classId];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StudentScheduleCard(
                        item: item,
                        className: info?.name ?? 'Класс',
                        subject: info?.subject ?? '',
                      ),
                    );
                  },
                  childCount: todaySchedules.length > 3
                      ? 3
                      : todaySchedules.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],

        // ── Quick links ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding,
            ),
            child: SectionHeader(title: l10n.quickLinks),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            delegate: SliverChildListDelegate([
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
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => JoinClassDialog(
                    repository: AppScope.of(context).repository,
                  ),
                ),
                icon: Icons.group_add_outlined,
                label: l10n.joinAClass,
                color: SchoolColors.secondary,
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _BentoStats extends StatelessWidget {
  const _BentoStats({
    required this.classCount,
    required this.todayLessons,
    required this.activeLessons,
  });
  final int classCount;
  final int todayLessons;
  final int activeLessons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SchoolColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: SwTheme.diffusionShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$todayLessons',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'LESSONS TODAY',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: SchoolColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$activeLessons ACTIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
                      color: SchoolColors.primary.withValues(
                        alpha: _hovered ? 0.45 : 0.28,
                      ),
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
    required this.subject,
  });

  final ResolvedScheduleItem item;
  final String className;
  final String subject;

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

    final primaryTitle = widget.subject.isNotEmpty
        ? widget.subject
        : widget.className;
    final subtitle = widget.subject.isNotEmpty ? widget.className : '';

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
                                    '$startLabel · ${AppLocalizations.of(context)!.cabinetWithNumber(room)}',
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
                                    primaryTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty)
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? SchoolColors.darkTextSecondary
                                            : SchoolColors.textSecondary,
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
