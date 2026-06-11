import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app_state.dart';
import '../../../../firebase/school_repository.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';
import 'package:school_world/main.dart';

class StudentToday extends StatefulHookConsumerWidget {
  const StudentToday({
    super.key,
    required this.classes,
    required this.selectedClassId,
    required this.onTabSelect,
    this.showSidebar = false,
    required this.onHomeworkTap,
  });

  final List<Map<String, dynamic>> classes;
  final String? selectedClassId;
  final ValueChanged<int> onTabSelect;
  final bool showSidebar;
  final VoidCallback onHomeworkTap;

  @override
  ConsumerState<StudentToday> createState() => _StudentTodayState();
}

class _StudentTodayState extends ConsumerState<StudentToday> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final repo = AppScope.of(context).repository;
      _userStream = repo.userDocStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isMobile = MediaQuery.sizeOf(context).width < 1024;
    final repo = AppScope.of(context).repository;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, profileSnap) {
        final profile = profileSnap.data?.data() ?? const <String, dynamic>{};
        final user = repo.auth.currentUser;
        final name = (profile['name']?.toString().trim().isNotEmpty ?? false)
            ? profile['name'].toString().trim()
            : (user?.displayName ?? "Студент"); // Student
            
        final firstName = name.split(RegExp(r'\s+')).first;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 32,
                  topPadding + (isMobile ? 16 : 32),
                  isMobile ? 16 : 32,
                  80,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. HERO SECTION
                    FadeInUp(
                      offset: 40,
                      duration: const Duration(milliseconds: 600),
                      child: _HeroSection(
                        studentName: firstName,
                        repo: repo,
                        isMobile: isMobile,
                        onAction: () => widget.onTabSelect(1),
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // 2. QUICK STATS
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      offset: 30,
                      child: _QuickStatsSection(
                        repo: repo,
                        isMobile: isMobile,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 3. TWO COLUMN LAYOUT (Timeline & Action Required)
                    if (isMobile) ...[
                      const _SectionTitle(title: 'Расписание на сегодня', icon: Icons.schedule_rounded, color: SchoolColors.primary),
                      const SizedBox(height: 16),
                      _TimelineList(classes: widget.classes),
                      const SizedBox(height: 40),
                      const _SectionTitle(title: 'Требует внимания', icon: Icons.error_outline_rounded, color: SchoolColors.orange),
                      const SizedBox(height: 16),
                      _UpcomingTasksList(repo: repo),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline (7 cols)
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(title: 'Расписание на сегодня', icon: Icons.schedule_rounded, color: SchoolColors.primary),
                                const SizedBox(height: 16),
                                _TimelineList(classes: widget.classes),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Homework (5 cols)
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(title: 'Требует внимания', icon: Icons.error_outline_rounded, color: SchoolColors.orange),
                                const SizedBox(height: 16),
                                _UpcomingTasksList(repo: repo),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  const _HeroSection({
    required this.studentName,
    required this.repo,
    required this.isMobile,
    required this.onAction,
  });

  final String studentName;
  final SchoolRepository repo;
  final bool isMobile;
  final VoidCallback onAction;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  Stream<QuerySnapshot>? _submissionsStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final uid = widget.repo.auth.currentUser?.uid;
      _submissionsStream = widget.repo.firestore
          .collection('submissions')
          .where('studentId', isEqualTo: uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: _submissionsStream,
      builder: (context, snapshot) {
        final assignments = snapshot.data?.docs.length ?? 0;
        
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.darkSurface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.darkBorder),
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: widget.isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Text('HỆ THỐNG TRỰC TUYẾN', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Доброе утро, ', // Good morning
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            '${widget.studentName}!',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Сегодня у вас $assignments задач для выполнения.', // Today you have X tasks
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                      ),
                    ),
                    if (widget.isMobile) ...[
                      const SizedBox(height: 24),
                      _ActionButton(onPressed: widget.onAction),
                    ],
                  ],
                ),
              ),
              if (!widget.isMobile) _ActionButton(onPressed: widget.onAction),
            ],
          ),
        );
      }
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Перейти к курсу', // Resume course
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

// ─────────────────────────────────────────────────────────────────
// QUICK STATS
// ─────────────────────────────────────────────────────────────────
class _QuickStatsSection extends StatefulWidget {
  const _QuickStatsSection({
    required this.repo,
    required this.isMobile,
  });
  
  final SchoolRepository repo;
  final bool isMobile;

  @override
  State<_QuickStatsSection> createState() => _QuickStatsSectionState();
}

class _QuickStatsSectionState extends State<_QuickStatsSection> {
  Future<QuerySnapshot>? _gradedFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final uid = widget.repo.auth.currentUser?.uid;
      _gradedFuture = widget.repo.firestore
          .collection('submissions')
          .where('studentId', isEqualTo: uid)
          .where('status', isEqualTo: 'graded')
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _gradedFuture,
      builder: (context, gradedSnap) {
        final gradedDocs = gradedSnap.data?.docs ?? [];
        double avg = 0;
        if (gradedDocs.isNotEmpty) {
          final sum = gradedDocs.fold<double>(0, (acc, d) {
            final g = d.data() as Map<String, dynamic>;
            return acc + (double.tryParse(g['grade']?.toString() ?? '0') ?? 0);
          });
          avg = sum / gradedDocs.length;
        }

        final avgStr = avg == 0 ? "—" : avg.toStringAsFixed(1);
        final assignmentsCount = gradedDocs.length; // Approximate for assignments done

        final children = [
          _StatCard(title: 'Текущая оценка', value: avgStr, icon: Icons.trending_up_rounded, iconColor: SchoolColors.green), // Current Grade
          _StatCard(title: 'Задания', value: assignmentsCount.toString(), icon: Icons.assignment_rounded, iconColor: SchoolColors.orange), // Assignments
          const _StatCard(title: 'Посещаемость', value: "98%", icon: Icons.event_available_rounded, iconColor: SchoolColors.primary), // Attendance
        ];

        if (widget.isMobile) {
          return Column(
            children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
          );
        }

        return Row(
          children: children.map((c) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: children.last == c ? 0 : 24),
              child: c,
            ),
          )).toList(),
        );
      }
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2),
          ),
          const SizedBox(height: 4),
          Text('Phân tích chi tiết', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────
// TIMELINE LIST
// ─────────────────────────────────────────────────────────────────
class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.classes});
  final List<Map<String, dynamic>> classes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build timeline events from actual classes
    List<Map<String, dynamic>> events = [];
    if (classes.isEmpty) {
      events = [
        {'time': '08:00 - 09:30', 'subject': 'Нет классов', 'room': '-', 'active': false}, // No classes
      ];
    } else {
      for (var i = 0; i < classes.length; i++) {
        final c = classes[i];
        events.add({
          'time': 'Класс ${i + 1}', // Class #
          'subject': c['name'] ?? 'Неизвестно', // Unknown
          'room': 'Онлайн', // Online
          'active': i == 0, // Mock active state for the first one
        });
      }
    }

    return StaggeredList(
      delayStep: const Duration(milliseconds: 100),
      children: events.map((event) {
        final isActive = event['active'] as bool;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? AppColors.primary : AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isActive ? SchoolColors.primary : (isDark ? SchoolColors.darkMuted : SchoolColors.muted),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['time'] as String,
                        style: AppTextStyle.mono(
                          fontSize: 12,
                          color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event['subject'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            event['room'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: SchoolColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Войти', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), // Join
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// UPCOMING TASKS (Cần xử lý)
// ─────────────────────────────────────────────────────────────────
class _UpcomingTasksList extends StatefulWidget {
  const _UpcomingTasksList({required this.repo});
  final SchoolRepository repo;

  @override
  State<_UpcomingTasksList> createState() => _UpcomingTasksListState();
}

class _UpcomingTasksListState extends State<_UpcomingTasksList> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _attentionStream;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final uid = widget.repo.auth.currentUser?.uid;
      _attentionStream = widget.repo.firestore
          .collection('submissions')
          .where('studentId', isEqualTo: uid)
          .limit(3)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _attentionStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Center(
              child: Text("Завершено!", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)), // Completed!
            )
          );
        }

        return StaggeredList(
          delayStep: const Duration(milliseconds: 100),
          children: docs.map((doc) {
            final data = doc.data();
            final title = data['assignmentId']?.toString() ?? 'Задание'; // Assignment
            final statusStr = "важное"; // important
            final statusColor = SchoolColors.orange;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusStr.toUpperCase(),
                            style: AppTextStyle.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ).copyWith(letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Недавно', // Recently
                      style: AppTextStyle.mono(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }
    );
  }
}
