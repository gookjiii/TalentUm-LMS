import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_state.dart';
import '../../../../firebase/school_repository.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';
import 'package:school_world/main.dart';
import 'package:school_world/l10n/app_localizations.dart';

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
                    
                    const SizedBox(height: 24),

                    // 2. QUICK STATS
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      offset: 30,
                      child: _QuickStatsSection(
                        repo: repo,
                        isMobile: isMobile,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 3. TWO COLUMN LAYOUT (Timeline & Action Required)
                    if (isMobile) ...[
                      _SectionTitle(title: AppLocalizations.of(context)!.todaySchedule, icon: Icons.schedule_rounded, color: AppColors.primary),
                      const SizedBox(height: 16),
                      _TimelineList(classes: widget.classes),
                      const SizedBox(height: 32),
                      _SectionTitle(title: AppLocalizations.of(context)!.requiresAttention, icon: Icons.error_outline_rounded, color: SchoolColors.orange),
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
                                _SectionTitle(title: AppLocalizations.of(context)!.todaySchedule, icon: Icons.schedule_rounded, color: AppColors.primary),
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
                                _SectionTitle(title: AppLocalizations.of(context)!.requiresAttention, icon: Icons.error_outline_rounded, color: SchoolColors.orange),
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
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: Theme.of(context).colorScheme.onSurface,
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

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final today = DateFormat('EEEE, d MMMM', l10n.localeName).format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: _submissionsStream,
      builder: (context, snapshot) {
        final assignments = snapshot.data?.docs.length ?? 0;
        final greeting = _getGreeting(context);

        return Container(
          padding: EdgeInsets.all(widget.isMobile ? 20 : 32),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withOpacity(0.8)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.primary.withOpacity(0.25)
                  : AppColors.primary.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(isDark ? 0.1 : 0.06),
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Date badge + avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      today,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // Task count badge
                  if (assignments > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: SchoolColors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SchoolColors.orange.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_outlined, size: 12, color: SchoolColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '$assignments',
                            style: TextStyle(
                              color: SchoolColors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Greeting text
              Text(
                greeting,
                style: TextStyle(
                  fontSize: widget.isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  '${widget.studentName}!',
                  style: TextStyle(
                    fontSize: widget.isMobile ? 28 : 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action button
              _ActionButton(onPressed: widget.onAction),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.feed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
        final assignmentsCount = gradedDocs.length;

        final stats = [
          (title: 'Средняя оценка', value: avgStr, icon: Icons.trending_up_rounded, color: SchoolColors.green),
          (title: 'Заданий', value: assignmentsCount.toString(), icon: Icons.assignment_rounded, color: SchoolColors.orange),
          (title: 'Посещаемость', value: '98%', icon: Icons.event_available_rounded, color: AppColors.primary),
        ];

        if (widget.isMobile) {
          // Horizontal scroll on mobile
          return SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: stats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: 140,
                child: _StatCard(
                  title: stats[i].title,
                  value: stats[i].value,
                  icon: stats[i].icon,
                  iconColor: stats[i].color,
                ),
              ),
            ),
          );
        }

        return Row(
          children: stats.map((s) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: stats.last == s ? 0 : 24),
              child: _StatCard(
                title: s.title,
                value: s.value,
                icon: s.icon,
                iconColor: s.color,
              ),
            ),
          )).toList(),
        );
      },
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withOpacity(0.7)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? iconColor.withOpacity(0.2)
              : iconColor.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(isDark ? 0.08 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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

    List<Map<String, dynamic>> events = [];
    if (classes.isEmpty) {
      events = [
        {'time': '—', 'subject': 'Нет классов', 'room': '-', 'active': false},
      ];
    } else {
      for (var i = 0; i < classes.length; i++) {
        final c = classes[i];
        events.add({
          'time': 'Класс ${i + 1}',
          'subject': c['name'] ?? 'Неизвестно',
          'room': 'Онлайн',
          'active': i == 0,
        });
      }
    }

    return StaggeredList(
      delayStep: const Duration(milliseconds: 80),
      children: events.map((event) {
        final isActive = event['active'] as bool;
        final accentColor = isActive ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? (isActive ? AppColors.primary.withOpacity(0.08) : AppColors.darkSurface.withOpacity(0.6))
                  : (isActive ? AppColors.primary.withOpacity(0.05) : Colors.white.withOpacity(0.9)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withOpacity(0.4)
                    : (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['time'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event['subject'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            event['room'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Войти',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _attentionStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? SchoolColors.green.withOpacity(0.08)
                  : SchoolColors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: SchoolColors.green.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SchoolColors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_outline_rounded, color: SchoolColors.green, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  'Всё готово! 🎉',
                  style: TextStyle(
                    color: SchoolColors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        return StaggeredList(
          delayStep: const Duration(milliseconds: 80),
          children: docs.map((doc) {
            final data = doc.data();
            final title = data['assignmentId']?.toString() ?? 'Задание';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withOpacity(0.6)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: SchoolColors.orange.withOpacity(0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SchoolColors.orange.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: SchoolColors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.assignment_outlined, size: 18, color: SchoolColors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: SchoolColors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ВАЖНО',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: SchoolColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
