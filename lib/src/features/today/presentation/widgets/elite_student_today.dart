import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:school_world/main.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';
import '../../../../models/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EliteStudentToday extends HookWidget {
  const EliteStudentToday({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final repo = scope.repository;
    
    final userSnap = useStream(repo.userDocStream());
    final userData = userSnap.data?.data() ?? {};
    final String name = userData['name']?.toString() ?? 'Student';
    final int streak = userData['streak'] as int? ?? 0;
    final List<String> classIds = List<String>.from(userData['classIds'] ?? []);

    final classesSnap = useStream(useMemoized(() => repo.studentClassesCached(), [repo.uid]));
    final classes = classesSnap.data ?? [];

    final schedulesSnap = useStream(useMemoized(() => repo.studentSchedulesStream(classIds), [classIds]));
    final overridesSnap = useStream(useMemoized(() => repo.studentScheduleOverridesStream(classIds), [classIds]));
    
    final assignmentsSnap = useStream(useMemoized(() => repo.assignmentsForClasses(classIds, limit: 10), [classIds]));

    // Calculate Today's Timeline
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 (Mon) - 7 (Sun)
    
    final List<_TimelineData> timeline = [];
    if (schedulesSnap.hasData) {
      for (final entry in schedulesSnap.data!) {
        if (entry.dayOfWeek == todayWeekday) {
          // Check for overrides
          final override = overridesSnap.data?.firstWhere(
            (o) => o.scheduleId == entry.id && 
                   o.date.year == now.year && 
                   o.date.month == now.month && 
                   o.date.day == now.day,
            orElse: () => ScheduleOverride(id: '', scheduleId: '', date: now, cancelled: false),
          );

          if (override?.cancelled == true) continue;

          final startMinute = override?.newStartMinute ?? entry.startMinute;
          final endMinute = override?.newEndMinute ?? entry.endMinute;
          
          final cls = classes.firstWhere((c) => c['id'] == entry.classId, orElse: () => {});
          final subject = cls['name']?.toString() ?? 'Class';

          timeline.add(_TimelineData(
            time: _formatTime(startMinute),
            title: subject,
            subtitle: entry.room ?? 'Room',
            status: _getStatus(startMinute, endMinute),
            startMinute: startMinute,
          ));
        }
      }
      timeline.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    }

    // Find Next Deadline
    Map<String, dynamic>? nextDeadline;
    if (assignmentsSnap.hasData) {
      final docs = assignmentsSnap.data!.docs;
      final futureAssignments = docs.where((doc) {
        final due = (doc.data()['dueDate'] as Timestamp?)?.toDate();
        return due != null && due.isAfter(now);
      }).toList();
      
      if (futureAssignments.isNotEmpty) {
        futureAssignments.sort((a, b) {
            final aDue = (a.data()['dueDate'] as Timestamp).toDate();
            final bDue = (b.data()['dueDate'] as Timestamp).toDate();
            return aDue.compareTo(bDue);
        });
        nextDeadline = futureAssignments.first.data();
      }
    }

    return Scaffold(
      backgroundColor: SchoolColors.darkBg,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -150,
            left: -150,
            child: _AmbientGlow(color: SchoolColors.primary.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: -200,
            right: -100,
            child: _AmbientGlow(color: SchoolColors.success.withValues(alpha: 0.08)),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _EliteHeader(name: name),
              SliverPadding(
                padding: const EdgeInsets.all(32),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionHeader(title: 'Mission Timeline', icon: Icons.auto_awesome),
                            const SizedBox(height: 24),
                            if (timeline.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: EmptyStateWidget(
                                  icon: Icons.calendar_today_outlined,
                                  title: 'No classes today',
                                  subtitle: 'Enjoy your free time or catch up on assignments!',
                                ),
                              )
                            else
                              ...List.generate(timeline.length, (index) {
                                final item = timeline[index];
                                return _TimelineItem(
                                  time: item.time,
                                  title: item.title,
                                  subtitle: item.subtitle,
                                  status: item.status,
                                  isActive: item.status == 'Ongoing',
                                  isFirst: index == 0,
                                  isLast: index == timeline.length - 1,
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _VitalityCard(streak: streak, taskCount: 0), // Task count placeholder
                            const SizedBox(height: 24),
                            if (nextDeadline != null)
                              _UpcomingAssignmentCard(assignment: nextDeadline),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _getStatus(int start, int end) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    if (nowMinutes < start) return 'Upcoming';
    if (nowMinutes > end) return 'Completed';
    return 'Ongoing';
  }
}

class _TimelineData {
  final String time;
  final String title;
  final String subtitle;
  final String status;
  final int startMinute;

  _TimelineData({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.startMinute,
  });
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 500,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _EliteHeader extends StatelessWidget {
  const _EliteHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 180,
      collapsedHeight: 100,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK,',
                style: AppTextStyle.labelSm.copyWith(
                  color: SchoolColors.darkMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const _LivePulse(),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: SchoolColors.darkSurface,
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _LivePulse extends HookWidget {
  const _LivePulse();

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SchoolColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: SchoolColors.success.withValues(alpha: 0.2 + 0.3 * controller.value),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SchoolColors.success,
                  boxShadow: [
                    BoxShadow(
                      color: SchoolColors.success,
                      blurRadius: 8 * controller.value,
                      spreadRadius: 2 * controller.value,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE',
                style: AppTextStyle.labelSm.copyWith(
                  color: SchoolColors.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SchoolColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.status,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  final String time;
  final String title;
  final String subtitle;
  final String status;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Time Column
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(
                  time,
                  style: AppTextStyle.mono(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isActive ? SchoolColors.primary : SchoolColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AM',
                  style: AppTextStyle.labelSm.copyWith(color: SchoolColors.darkMuted),
                ),
              ],
            ),
          ),
          // Connector Column
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : SchoolColors.darkBorder,
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? SchoolColors.primary : SchoolColors.darkSurface,
                    border: Border.all(
                      color: isActive ? SchoolColors.primaryLight : SchoolColors.darkBorder,
                      width: 3,
                    ),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: SchoolColors.primary.withValues(alpha: 0.5),
                        blurRadius: 10,
                      )
                    ] : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : SchoolColors.darkBorder,
                  ),
                ),
              ],
            ),
          ),
          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: GlassCard(
                onTap: () {},
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTextStyle.bodyMd.copyWith(color: SchoolColors.darkMuted),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: status, isActive: isActive),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isActive});
  final String status;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Completed' 
        ? SchoolColors.success 
        : isActive ? SchoolColors.primary : SchoolColors.darkMuted;
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyle.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VitalityCard extends StatelessWidget {
  const _VitalityCard({required this.streak, required this.taskCount});
  final int streak;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    return NestedBezelCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STUDY VITALITY',
                style: AppTextStyle.labelSm.copyWith(color: SchoolColors.darkMuted),
              ),
              const Icon(Icons.show_chart, color: SchoolColors.success, size: 16),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '88%',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optimal Focus Range',
            style: AppTextStyle.bodyMd.copyWith(color: SchoolColors.success, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'STREAK', value: '${streak}d')),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'TASKS', value: '$taskCount/6')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.labelSm.copyWith(fontSize: 10, color: SchoolColors.darkMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyle.mono(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _UpcomingAssignmentCard extends StatelessWidget {
  const _UpcomingAssignmentCard({required this.assignment});
  final Map<String, dynamic> assignment;

  @override
  Widget build(BuildContext context) {
    final dueDate = (assignment['dueDate'] as Timestamp?)?.toDate();
    final timeStr = dueDate != null ? DateFormat('HH:mm').format(dueDate) : 'Unknown';
    final diff = dueDate?.difference(DateTime.now());
    final hoursLeft = diff?.inHours ?? 0;

    return NestedBezelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT DEADLINE',
            style: AppTextStyle.labelSm.copyWith(color: SchoolColors.darkMuted),
          ),
          const SizedBox(height: 24),
          Text(
            assignment['title']?.toString() ?? 'Assignment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Due at $timeStr • ${hoursLeft}h left',
            style: AppTextStyle.bodyMd.copyWith(
              color: hoursLeft < 24 ? SchoolColors.red : SchoolColors.orange, 
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Nộp bài ngay',
            onTap: () {}, // Logic will be added
          ),
        ],
      ),
    );
  }
}
