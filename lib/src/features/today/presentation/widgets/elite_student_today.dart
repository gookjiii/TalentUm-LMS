import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';

class EliteStudentToday extends HookWidget {
  const EliteStudentToday({super.key});

  @override
  Widget build(BuildContext context) {
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
              const _EliteHeader(),
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
                            _TimelineItem(
                              time: '08:30',
                              title: 'Advanced Calculus',
                              subtitle: 'Room 402 • Dr. Jenkins',
                              status: 'Completed',
                              isFirst: true,
                            ),
                            _TimelineItem(
                              time: '10:15',
                              title: 'Computational Thinking',
                              subtitle: 'Lab 2 • Prof. Sarah',
                              status: 'Ongoing',
                              isActive: true,
                            ),
                            _TimelineItem(
                              time: '13:00',
                              title: 'AI Ethics & Society',
                              subtitle: 'Auditorium • Dr. Aris',
                              status: 'Upcoming',
                            ),
                            _TimelineItem(
                              time: '15:30',
                              title: 'Physics Lab',
                              subtitle: 'Science Wing • Mr. Newton',
                              status: 'Upcoming',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            const _VitalityCard(),
                            const SizedBox(height: 24),
                            const _UpcomingAssignmentCard(),
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
  const _EliteHeader();

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
                    'Alex Rivera',
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
  const _VitalityCard();

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
              Expanded(child: _MiniStat(label: 'STREAK', value: '12d')),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'TASKS', value: '4/6')),
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
  const _UpcomingAssignmentCard();

  @override
  Widget build(BuildContext context) {
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
            'Tích phân bội ba nâng cao',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Advanced Calculus • Due in 4h',
            style: AppTextStyle.bodyMd.copyWith(color: SchoolColors.orange, fontWeight: FontWeight.w600),
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
