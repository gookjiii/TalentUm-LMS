import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
    final topPadding = MediaQuery.paddingOf(context).top;
    final isMobile = MediaQuery.sizeOf(context).width < 1024; // lg breakpoint in tailwind

    // Mock data for UI to match the prototype
    final String studentName = "Alex Nguyen";
    final int assignments = 3;
    final String gpa = "8.5";
    final String attendance = "95%";

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
                    studentName: studentName,
                    assignments: assignments,
                    isMobile: isMobile,
                    onAction: () => onTabSelect(1), // Assume tab 1 is classes
                  ),
                ),
                
                const SizedBox(height: 40),

                // 2. QUICK STATS
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  offset: 30,
                  child: _QuickStatsSection(
                    gpa: gpa,
                    assignments: assignments.toString(),
                    attendance: attendance,
                    isMobile: isMobile,
                  ),
                ),

                const SizedBox(height: 40),

                // 3. TWO COLUMN LAYOUT (Timeline & Action Required)
                if (isMobile) ...[
                  const _SectionTitle(title: 'Lịch trình hôm nay', icon: Icons.schedule_rounded, color: SchoolColors.primary),
                  const SizedBox(height: 16),
                  const _TimelineList(),
                  const SizedBox(height: 40),
                  const _SectionTitle(title: 'Cần xử lý', icon: Icons.error_outline_rounded, color: SchoolColors.orange),
                  const SizedBox(height: 16),
                  const _UpcomingTasksList(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline (7 cols)
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _SectionTitle(title: 'Lịch trình hôm nay', icon: Icons.schedule_rounded, color: SchoolColors.primary),
                            SizedBox(height: 16),
                            _TimelineList(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Homework (5 cols)
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _SectionTitle(title: 'Cần xử lý', icon: Icons.error_outline_rounded, color: SchoolColors.orange),
                            SizedBox(height: 16),
                            _UpcomingTasksList(),
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
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.studentName,
    required this.assignments,
    required this.isMobile,
    required this.onAction,
  });

  final String studentName;
  final int assignments;
  final bool isMobile;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameParts = studentName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : studentName;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Chào buổi sáng, ',
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
                      '$firstName!',
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
                'Hôm nay bạn có $assignments nhiệm vụ cần hoàn thành.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? SchoolColors.darkTextSecondary : SchoolColors.textSecondary,
                ),
              ),
              if (isMobile) ...[
                const SizedBox(height: 24),
                _ActionButton(onPressed: onAction),
              ],
            ],
          ),
        ),
        if (!isMobile) _ActionButton(onPressed: onAction),
      ],
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
                  'Vào lớp học',
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
class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection({
    required this.gpa,
    required this.assignments,
    required this.attendance,
    required this.isMobile,
  });
  
  final String gpa;
  final String assignments;
  final String attendance;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final children = [
      _StatCard(title: 'Điểm số / Đánh giá', value: gpa, icon: Icons.trending_up_rounded, iconColor: SchoolColors.green),
      _StatCard(title: 'Bài tập / Nhiệm vụ', value: assignments, icon: Icons.assignment_rounded, iconColor: SchoolColors.orange),
      _StatCard(title: 'Chuyên cần', value: attendance, icon: Icons.event_available_rounded, iconColor: SchoolColors.primary),
    ];

    if (isMobile) {
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
    
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TIMELINE LIST
// ─────────────────────────────────────────────────────────────────
class _TimelineList extends StatelessWidget {
  const _TimelineList();

  @override
  Widget build(BuildContext context) {
    final events = [
      {'time': '08:00 - 09:30', 'subject': 'Toán Học Cao Cấp', 'room': 'Phòng 102 - Cơ sở A', 'active': false},
      {'time': '10:00 - 11:30', 'subject': 'Lập trình Web', 'room': 'Lab 3', 'active': true},
      {'time': '13:30 - 15:00', 'subject': 'Thiết kế UI/UX', 'room': 'Online via Zoom', 'active': false},
    ];

    return StaggeredList(
      delayStep: const Duration(milliseconds: 100),
      children: events.map((event) {
        final isActive = event['active'] as bool;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            color: isActive ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white) : null,
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
                    child: const Text('Tham gia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
class _UpcomingTasksList extends StatelessWidget {
  const _UpcomingTasksList();

  @override
  Widget build(BuildContext context) {
    final tasks = [
      {'title': 'Bài tập lớn React', 'due': 'Hôm nay, 23:59', 'status': 'warning'},
      {'title': 'Báo cáo UI UX', 'due': 'Ngày mai', 'status': 'success'},
      {'title': 'Thiết kế Figma', 'due': 'Trễ hạn 1 ngày', 'status': 'danger'},
    ];

    return StaggeredList(
      delayStep: const Duration(milliseconds: 100),
      children: tasks.map((task) {
        final status = task['status'] as String;
        Color statusColor;
        switch(status) {
          case 'warning': statusColor = SchoolColors.orange; break;
          case 'success': statusColor = SchoolColors.green; break;
          case 'danger': statusColor = SchoolColors.red; break;
          default: statusColor = SchoolColors.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] as String,
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
                        status.toUpperCase(),
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
                  task['due'] as String,
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
}
