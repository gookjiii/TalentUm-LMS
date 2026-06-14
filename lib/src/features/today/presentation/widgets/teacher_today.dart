import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../firebase/school_repository.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';
import 'package:school_world/main.dart';

class TeacherToday extends StatefulHookConsumerWidget {
  const TeacherToday({
    super.key,
    required this.classes,
    required this.selectedClassId,
    required this.onTabSelect,
    required this.onSelectClass,
    required this.onDeleteClass,
    required this.onCopyGuestLink,
    required this.onCreateClass,
    required this.onProfileTap,
    this.showSidebar = false,
  });

  final List<Map<String, dynamic>> classes;
  final String selectedClassId;
  final ValueChanged<int> onTabSelect;
  final ValueChanged<String> onSelectClass;
  final void Function(String classId, String className) onDeleteClass;
  final void Function(String classId, String inviteCode) onCopyGuestLink;
  final VoidCallback onCreateClass;
  final VoidCallback onProfileTap;
  final bool showSidebar;

  @override
  ConsumerState<TeacherToday> createState() => _TeacherTodayState();
}

class _TeacherTodayState extends ConsumerState<TeacherToday> {
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
            : (user?.displayName ?? "Преподаватель");
            
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
                        teacherName: firstName,
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
                        classes: widget.classes,
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
    required this.teacherName,
    required this.repo,
    required this.isMobile,
    required this.onAction,
  });

  final String teacherName;
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
      _submissionsStream = widget.repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'submitted')
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
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: widget.isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Обзор преподавания ', // Teaching Overview
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: Text(
                          '${widget.teacherName}!',
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
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
              children: const [
                Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Аналитика', // Analytics
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
    required this.classes,
    required this.isMobile,
  });
  
  final SchoolRepository repo;
  final List<Map<String, dynamic>> classes;
  final bool isMobile;

  @override
  State<_QuickStatsSection> createState() => _QuickStatsSectionState();
}

class _QuickStatsSectionState extends State<_QuickStatsSection> {
  Stream<QuerySnapshot>? _submissionsStream;
  Future<QuerySnapshot>? _gradedFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _submissionsStream = widget.repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'submitted')
          .snapshots();
      _gradedFuture = widget.repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'graded')
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentCount = widget.classes.fold<int>(
      0,
      (acc, c) => acc + ((c['studentIds'] as List?)?.length ?? 0),
    );

    return StreamBuilder<QuerySnapshot>(
      stream: _submissionsStream,
      builder: (context, submissionsSnap) {
        return FutureBuilder<QuerySnapshot>(
          future: _gradedFuture,
          builder: (context, gradedSnap) {
            final ungradedCount = submissionsSnap.data?.docs.length ?? 0;
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

            final children = [
              _StatCard(title: 'Средний балл', value: avgStr, icon: Icons.trending_up_rounded, iconColor: SchoolColors.green), // Avg Grade
              _StatCard(title: 'Ожидают проверки', value: ungradedCount.toString(), icon: Icons.assignment_rounded, iconColor: SchoolColors.orange), // Ungraded
              _StatCard(title: 'Всего студентов', value: studentCount.toString(), icon: Icons.group_rounded, iconColor: SchoolColors.primary), // Total Students
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return NestedBezelCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyle.mono(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : SchoolColors.text,
                  ),
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
          child: NestedBezelCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Text('Войти', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)), // Join
                      ),
                    ),
                  ),
              ],
            ),
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
      _attentionStream = widget.repo.firestore
          .collection('submissions')
          .where('status', isEqualTo: 'submitted')
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
          return NestedBezelCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: Text("Всё проверено!", style: TextStyle(color: SchoolColors.green, fontWeight: FontWeight.bold)), // All checked
              ),
            ),
          );
        }

        return StaggeredList(
          delayStep: const Duration(milliseconds: 100),
          children: docs.map((doc) {
            final data = doc.data();
            final title = data['assignmentId']?.toString() ?? 'Неизвестное задание'; // Unknown assignment
            const due = "Ожидает проверки"; // Pending review
            const statusColor = SchoolColors.orange;
            const statusStr = "важное"; // important

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NestedBezelCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
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
                      due,
                      style: AppTextStyle.mono(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        );
      }
    );
  }
}
