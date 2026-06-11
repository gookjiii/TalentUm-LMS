import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app_state.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';
import 'package:school_world/main.dart';

class StudentToday extends HookConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    // Simulate fetching user name from state/repo (fallback to Alex Student)
    final appState = AppScope.of(context).appState;
    final String studentName = "Alex Student"; 

    // Find active class
    final activeClass = classes.firstWhere(
      (c) => c['id'] == selectedClassId,
      orElse: () => classes.isNotEmpty ? classes.first : {},
    );
    final String className = activeClass['name']?.toString() ?? 'Computer Science 101';
    final Color classColor = colorFromHex(
      activeClass['coverColor'] as String?,
      SchoolColors.primary,
    );

    return Scaffold(
      backgroundColor: Colors.transparent, // Let the shell handle the background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 32,
              topPadding + (isMobile ? 16 : 32),
              isMobile ? 16 : 32,
              40,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. ASYMMETRIC HERO SECTION (Glassmorphism)
                FadeInUp(
                  offset: 40,
                  duration: const Duration(milliseconds: 600),
                  child: _HeroSection(
                    studentName: studentName,
                    className: className,
                    classColor: classColor,
                    isMobile: isMobile,
                  ),
                ),
                
                const SizedBox(height: 32),

                // 2. QUICK STATS (Asymmetric Grid 2:1)
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  offset: 30,
                  child: _QuickStatsSection(isMobile: isMobile, classColor: classColor),
                ),

                const SizedBox(height: 40),

                // 3. UPCOMING TASKS (Staggered List)
                SectionHeader(
                  title: 'Upcoming Assignments',
                  action: 'View All',
                  onActionTap: onHomeworkTap,
                ),
                const SizedBox(height: 16),
                _UpcomingTasksList(classColor: classColor),
                
                const SizedBox(height: 80), // Bottom breathing room
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HERO SECTION (Glassmorphism + Asymmetric)
// ─────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.studentName,
    required this.className,
    required this.classColor,
    required this.isMobile,
  });

  final String studentName;
  final String className;
  final Color classColor;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Greeting logic
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return GlassCard(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      borderRadius: 24,
      color: isDark 
          ? classColor.withValues(alpha: 0.08) 
          : classColor.withValues(alpha: 0.04),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background abstract glow
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: classColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      label: className.toUpperCase(),
                      color: classColor,
                      pulseDot: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$greeting,\n$studentName.',
                      style: AppTextStyle.display(context).copyWith(
                        fontSize: isMobile ? 28 : 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You have 2 pending assignments and 1 upcoming webinar this week.',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: classColor,
                        minimumSize: const Size(140, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        )
                      ),
                      child: const Text('Resume Course'),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 40),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CircularProgressRing(
                      percent: 0.68,
                      color: classColor,
                      size: 140,
                      strokeWidth: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '68%',
                            style: AppTextStyle.mono(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : SchoolColors.text,
                            ),
                          ),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                              letterSpacing: 0.5,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// QUICK STATS (Asymmetric Layout)
// ─────────────────────────────────────────────────────────────────
class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection({required this.isMobile, required this.classColor});
  final bool isMobile;
  final Color classColor;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _StatCard(title: 'Current Grade', value: 'A-', subtitle: 'Top 15% of class', flex: 1, color: SchoolColors.green),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Attendance', value: '98%', subtitle: 'On track', color: SchoolColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Credits', value: '24', subtitle: 'Earned', color: SchoolColors.orange)),
            ],
          )
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _StatCard(
            title: 'Current Grade Average', 
            value: '92.4', 
            subtitle: 'Consistent performance this semester',
            color: SchoolColors.green,
            isLarge: true,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _StatCard(
            title: 'Attendance', 
            value: '98%', 
            subtitle: '2 missed sessions',
            color: SchoolColors.primary,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _StatCard(
            title: 'Rank', 
            value: '#4', 
            subtitle: 'Out of 120 students',
            color: SchoolColors.orange,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.flex = 1,
    this.isLarge = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final int flex;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SchoolCard(
      padding: EdgeInsets.all(isLarge ? 28 : 20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? SchoolColors.darkMuted : SchoolColors.muted,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
              )
            ],
          ),
          SizedBox(height: isLarge ? 24 : 16),
          Text(
            value,
            style: AppTextStyle.mono(
              fontSize: isLarge ? 42 : 32,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : SchoolColors.text,
            ).copyWith(letterSpacing: -1),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TASKS LIST (Staggered Animation + Hover physics)
// ─────────────────────────────────────────────────────────────────
class _UpcomingTasksList extends StatelessWidget {
  const _UpcomingTasksList({required this.classColor});
  final Color classColor;

  @override
  Widget build(BuildContext context) {
    final tasks = [
      {'title': 'Advanced Data Structures Quiz', 'due': 'Today, 23:59', 'type': 'Quiz', 'urgent': true},
      {'title': 'Module 4 Project Submission', 'due': 'Tomorrow, 12:00', 'type': 'Project', 'urgent': false},
      {'title': 'Read Chapter 5: Graph Theory', 'due': 'Wed, 09:00', 'type': 'Reading', 'urgent': false},
    ];

    return StaggeredList(
      delayStep: const Duration(milliseconds: 60),
      children: tasks.map((task) {
        final isUrgent = task['urgent'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SchoolCard(
            onTap: () {},
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            borderRadius: 16,
            borderColor: isUrgent ? SchoolColors.red.withValues(alpha: 0.3) : null,
            child: Row(
              children: [
                GradientIconBox(
                  icon: task['type'] == 'Quiz' ? Icons.timer_outlined 
                      : task['type'] == 'Project' ? Icons.folder_zip_outlined 
                      : Icons.menu_book_rounded,
                  colors: isUrgent 
                      ? [SchoolColors.red.withValues(alpha: 0.7), SchoolColors.red] 
                      : [classColor.withValues(alpha: 0.7), classColor],
                  size: 44,
                  iconSize: 20,
                  borderRadius: 12,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded, 
                            size: 13, 
                            color: isUrgent ? SchoolColors.red : SchoolColors.muted
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task['due'] as String,
                            style: AppTextStyle.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isUrgent ? SchoolColors.red : SchoolColors.muted,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
