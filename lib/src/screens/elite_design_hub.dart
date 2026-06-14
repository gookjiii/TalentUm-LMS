import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../theme.dart';
import '../widgets/school_widgets.dart';
import '../features/today/presentation/widgets/elite_student_today.dart';
import '../features/shared/presentation/widgets/elite_placeholders.dart';

import '../app_state.dart';
import '../firebase/school_repository.dart';
import '../../main.dart';

class EliteDesignHub extends HookWidget {
  const EliteDesignHub({super.key, required this.repository, required this.appState});
  final SchoolRepository repository;
  final SchoolAppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolColors.darkBg,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SchoolColors.primary.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const _SliverTicker(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: const _HubContent(),
                    ),
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

class _SliverTicker extends HookWidget {
  const _SliverTicker();

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 30),
    )..repeat();

    return SliverToBoxAdapter(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xCC0F172A),
          border: Border(
            bottom: BorderSide(color: SchoolColors.darkBorder),
          ),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -controller.value * 500,
                    child: Row(
                      children: List.generate(10, (index) => const _TickerItem()),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TickerItem extends StatelessWidget {
  const _TickerItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SchoolColors.success,
              boxShadow: [
                BoxShadow(
                  color: SchoolColors.success,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'API GATEWAY: OPERATIONAL   CORE SERVICES: 99.9% UPTIME   DESIGN SYSTEM: SYNCED (V2.6.0)',
            style: AppTextStyle.mono(fontSize: 11, color: SchoolColors.darkMuted),
          ),
        ],
      ),
    );
  }
}

class _HubContent extends StatelessWidget {
  const _HubContent();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 1200;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _BrandHero(),
              SizedBox(height: 80),
              _ProductGrid(),
            ],
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 80),
          const SizedBox(
            width: 400,
            child: _HubSidebar(),
          ),
        ],
      ],
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: SchoolColors.gradPrimary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: SchoolColors.primary.withValues(alpha: 0.3),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.school, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Elite Digital\nCampus.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 100,
            fontWeight: FontWeight.w900,
            height: 0.85,
            letterSpacing: -5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            SizedBox(
              width: 240,
              child: GradientButton(
                text: 'Launch Full App',
                onTap: () {
                  final scope = AppScope.of(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthGate(
                        repository: scope.repository,
                        appState: scope.appState,
                      ),
                    ),
                  ); 
                },
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {},
              child: const Text('View Source Spec', style: TextStyle(color: SchoolColors.darkMuted)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 32,
      crossAxisSpacing: 32,
      childAspectRatio: 1.5,
      children: [
        _ProductCard(
          title: 'Today Screen',
          description: 'Hệ thống Mission Control học tập với dòng thời gian trực quan, chỉ số tiến độ D3.js và quản lý tác vụ thông minh.',
          icon: Icons.dashboard_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EliteStudentToday()),
            );
          },
        ),
        _ProductCard(
          title: 'Classroom Feed',
          description: 'Không gian kết nối giảng đường 2 cột, tối ưu cho việc theo dõi thông báo, tài liệu và tương tác cộng đồng.',
          icon: Icons.rss_feed,
          iconColor: SchoolColors.success,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EliteStudentFeed()),
            );
          },
        ),
        _ProductCard(
          title: 'Campus Chat',
          description: 'Hệ thống nhắn tin Elite với cấu trúc Double-Bezel, chỉ báo trạng thái sống động và quản lý tệp đính kèm thông minh.',
          icon: Icons.chat_bubble_outline,
          iconColor: Colors.blue,
          badge: 'Elite v4',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EliteCampusChat()),
            );
          },
        ),
        _ProductCard(
          title: 'Assignment Hub',
          description: 'Quản lý tiến độ học tập, nộp bài với khu vực Drag & Drop Glassmorphism và trạng thái cảnh báo Overdue trực quan.',
          icon: Icons.assignment_outlined,
          iconColor: SchoolColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EliteAssignmentHub()),
            );
          },
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
    this.badge,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (iconColor ?? SchoolColors.primary).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor ?? SchoolColors.primary, size: 32),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: SchoolColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyle.labelSm.copyWith(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyle.bodyMd.copyWith(color: SchoolColors.darkMuted),
          ),
        ],
      ),
    );
  }
}

class _HubSidebar extends StatelessWidget {
  const _HubSidebar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NestedBezelCard(
          child: Column(
            children: [
              const _DnaTitle(title: 'System Integrity'),
              const SizedBox(height: 40),
              // Radar Placeholder
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: SchoolColors.primary.withValues(alpha: 0.2), width: 2),
                ),
                child: Center(
                  child: Icon(Icons.radar, color: SchoolColors.primary.withValues(alpha: 0.5), size: 100),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '99.2%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: SchoolColors.success.withValues(alpha: 0.1),
                  border: Border.all(color: SchoolColors.success.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Audit Passed',
                  style: AppTextStyle.labelMd.copyWith(color: SchoolColors.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        NestedBezelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DnaTitle(title: 'Design DNA'),
              const SizedBox(height: 24),
              Text(
                'Elite Architecture: Double Bezel & Glassmorphism 24px.',
                style: AppTextStyle.bodyMd.copyWith(color: SchoolColors.darkMuted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: SchoolColors.gradPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: SchoolColors.darkSurface,
                  border: Border.all(color: SchoolColors.darkBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DnaTitle extends StatelessWidget {
  const _DnaTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyle.labelSm.copyWith(
            color: SchoolColors.darkMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            color: SchoolColors.darkBorder,
          ),
        ),
      ],
    );
  }
}
