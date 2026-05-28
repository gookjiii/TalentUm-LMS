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
    final rawName =
        userData['name']?.toString() ?? user?.displayName ?? 'Ученик';
    final name = rawName.trim().isNotEmpty
        ? rawName.split(RegExp(r'\s+')).first
        : 'Ученик';

    final now = DateTime.now();
    final date = DateFormat('EEEE, d MMMM', l10n.localeName).format(now);

    final todaySchedules = ref.watch(studentTodaySchedulesProvider);
    final classNames = {
      for (final c in classes)
        c['id'].toString(): c['name']?.toString() ?? 'Класс',
    };

    ResolvedScheduleItem? upcomingClass;
    for (final item in todaySchedules) {
      if (item.cancelled) continue;
      final diff = item.start.difference(DateTime.now()).inMinutes;
      if (diff > 0 && diff <= 15) {
        upcomingClass = item;
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Hero ──────────────────────────────────────────────
            FadeIn(
              delay: Duration.zero,
              child: wide
                  ? _StudentHero(
                      name: name,
                      onTabSelect: onTabSelect,
                      onHomeworkTap: onHomeworkTap,
                    )
                  : _MobileHeader(
                      name: name,
                      date: date,
                      classes: classes,
                      onHomeworkTap: onHomeworkTap,
                    ),
            ),

            if (upcomingClass != null)
              FadeIn(
                delay: const Duration(milliseconds: 60),
                child: _UpcomingClassReminder(
                  item: upcomingClass,
                  className: classNames[upcomingClass.classId] ?? 'Класс',
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: FadeIn(
                delay: const Duration(milliseconds: 100),
                child: const LearningStreakWidget(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Today's classes ───────────────────────────────────
            if (!showSidebar) ...[
              FadeIn(
                delay: const Duration(milliseconds: 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SectionHeader(
                        title: l10n.todaysClasses,
                        action: l10n.viewAll,
                        onActionTap: () => onTabSelect(4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: todaySchedules.isEmpty
                          ? GlassCard(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 16,
                              ),
                              child: Center(
                                child: Text(
                                  'Нет уроков на сегодня',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            )
                          : StaggeredList(
                              children: todaySchedules
                                  .take(3)
                                  .map(
                                    (item) => StudentScheduleCard(
                                      item: item,
                                      className:
                                          classNames[item.classId] ?? 'Класс',
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // ── Quick links ───────────────────────────────────────
            FadeIn(
              delay: const Duration(milliseconds: 260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SectionHeader(title: l10n.quickLinks),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: wide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        QuickTile(
                          onTap: () => onTabSelect(5),
                          icon: Icons.library_books_outlined,
                          label: 'Библиотека',
                          color: SchoolColors.primary,
                        ),
                        QuickTile(
                          onTap: () => onTabSelect(6),
                          icon: Icons.ondemand_video_outlined,
                          label: 'Вебинары',
                          color: SchoolColors.accent,
                        ),
                        QuickTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RosterGradesScreen(),
                            ),
                          ),
                          icon: Icons.school_outlined,
                          label: l10n.myGrades,
                          color: SchoolColors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  String _getDisplayName(User? user) {
    return (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.split(RegExp(r'\s+')).first
        : 'Ученик';
  }
}

// ─────────────────────────────────────────────────────────────────
// MOBILE HEADER  (greeting + streak card)
// ─────────────────────────────────────────────────────────────────
class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.name,
    required this.date,
    required this.classes,
    required this.onHomeworkTap,
  });

  final String name;
  final String date;
  final List<Map<String, dynamic>> classes;
  final VoidCallback onHomeworkTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  SchoolColors.darkSurface,
                  Color.lerp(
                        SchoolColors.darkSurface,
                        SchoolColors.primary,
                        0.03,
                      ) ??
                      SchoolColors.darkSurface,
                ]
              : [
                  Colors.white,
                  Color.lerp(Colors.white, SchoolColors.primary, 0.02) ??
                      Colors.white,
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? SchoolColors.darkBorder.withValues(alpha: 0.6)
                : SchoolColors.border.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date.toUpperCase(),
                      style: TextStyle(
                        color: isDark
                            ? SchoolColors.darkMuted.withValues(alpha: 0.7)
                            : SchoolColors.muted.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_greeting()}, $name 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        color: isDark ? Colors.white : SchoolColors.darkText,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SchoolAvatar(
                name: name,
                radius: 25,
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
          const SizedBox(height: 24),
          StreakCard(
            classIds: classes.map((c) => c['id'] as String).toList(),
            onTap: onHomeworkTap,
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 17) return 'Добрый день';
    return 'Добрый вечер';
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDE HERO BANNER
// ─────────────────────────────────────────────────────────────────
class _StudentHero extends StatelessWidget {
  const _StudentHero({
    required this.name,
    required this.onTabSelect,
    required this.onHomeworkTap,
  });

  final String name;
  final ValueChanged<int> onTabSelect;
  final VoidCallback onHomeworkTap;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 17) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 44, 40, 44),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SchoolColors.primary.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: 80,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $name',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Готовы к\nновым знаниям?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _HeroButton(
                    label: l10n.join,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.joinLessonSoon)),
                    ),
                    filled: true,
                  ),
                  const SizedBox(width: 12),
                  _HeroButton(
                    label: l10n.homework,
                    onTap: onHomeworkTap,
                    filled: false,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatefulWidget {
  const _HeroButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: widget.filled
                ? Colors.white
                : Colors.white.withValues(alpha: _pressed ? 0.15 : 0.0),
            borderRadius: BorderRadius.circular(12),
            border: widget.filled
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
            boxShadow: widget.filled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.filled ? SchoolColors.primary : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
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
                    colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF2563EB,
                      ).withValues(alpha: _hovered ? 0.45 : 0.28),
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
      return const StatusChip(
        label: 'ОТМЕНЕНО',
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
        label: 'СКОРО',
        color: SchoolColors.orange,
        icon: Icons.access_time_rounded,
      );
    }
    return StatusChip(label: l10n.later, color: SchoolColors.muted);
  }
}
