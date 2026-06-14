import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';

class EliteStudentFeed extends HookWidget {
  const EliteStudentFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 1200;

    return Scaffold(
      backgroundColor: SchoolColors.darkBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24,
                vertical: isDesktop ? 60 : 32,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1500),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeInUp(
                                delay: const Duration(milliseconds: 100),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Classroom Feed',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Latest highlights from your campus community',
                                      style: AppTextStyle.bodyMd.copyWith(
                                        fontSize: 16,
                                        color: SchoolColors.darkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                              FadeInUp(
                                delay: const Duration(milliseconds: 200),
                                child: const _PostCard(
                                  authorName: 'Dr. Sarah Jenkins',
                                  authorMeta: 'Advanced Calculus • 2h ago',
                                  avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=128&h=128&auto=format&fit=crop',
                                  content: "Hi everyone! I've uploaded the practice problems for next week's midterm. Please review them before Monday's lecture. Don't hesitate to reach out if you have any questions.",
                                  attachmentName: 'Midterm_Practice_Set_2026.pdf',
                                  attachmentMeta: '1.2 MB • Mathematics Unit 4',
                                  likes: 24,
                                  comments: 12,
                                ),
                              ),
                              const SizedBox(height: 40),
                              FadeInUp(
                                delay: const Duration(milliseconds: 300),
                                child: const _PostCard(
                                  authorName: 'Prof. Michael Chen',
                                  authorMeta: 'Quantum Physics • 5h ago',
                                  avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=128&h=128&auto=format&fit=crop',
                                  content: 'Some snapshots from our last lab session on wave-particle duality. Great energy in the room today!',
                                  imageUrl: 'https://images.unsplash.com/photo-1532187863486-abf9d39d99c5?q=80&w=1200&h=600&auto=format&fit=crop',
                                  likes: 56,
                                  comments: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 48),
                          const SizedBox(
                            width: 380,
                            child: _FeedSidebar(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.authorName,
    required this.authorMeta,
    required this.avatarUrl,
    required this.content,
    this.attachmentName,
    this.attachmentMeta,
    this.imageUrl,
    required this.likes,
    required this.comments,
  });

  final String authorName;
  final String authorMeta;
  final String avatarUrl;
  final String content;
  final String? attachmentName;
  final String? attachmentMeta;
  final String? imageUrl;
  final int likes;
  final int comments;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      avatarUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authorMeta,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SchoolColors.darkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              EliteTactileButton(
                onTap: () {},
                child: const Icon(Icons.more_horiz, color: SchoolColors.darkMuted),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            content,
            style: const TextStyle(
              fontSize: 17,
              height: 1.6,
              color: Colors.white,
            ),
          ),
          if (attachmentName != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SchoolColors.darkBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: SchoolColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: SchoolColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachmentName!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          attachmentMeta!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SchoolColors.darkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  EliteTactileButton(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: SchoolColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Download',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (imageUrl != null) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(color: SchoolColors.darkBorder),
          const SizedBox(height: 24),
          Row(
            children: [
              _ActionBtn(icon: Icons.favorite_border, label: '$likes Likes'),
              const SizedBox(width: 32),
              _ActionBtn(icon: Icons.chat_bubble_outline, label: '$comments Comments'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return EliteTactileButton(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: SchoolColors.darkMuted, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: SchoolColors.darkMuted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedSidebar extends StatelessWidget {
  const _FeedSidebar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WidgetTitle(title: 'Upcoming Deadlines'),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.only(bottom: 20),
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SchoolColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DUE IN 4 HOURS',
                        style: TextStyle(
                          color: SchoolColors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Physics Lab Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Quantum Mechanics Lab A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SchoolColors.darkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GlassCard(
                padding: const EdgeInsets.all(28),
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SchoolColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DUE IN 2 DAYS',
                        style: TextStyle(
                          color: SchoolColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Calculus Assignment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Problem Set #4 • Integrals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SchoolColors.darkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WidgetTitle(title: 'Active Communities'),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const _CommunityItem(
                      initial: 'AI',
                      name: 'AI Explorers',
                      meta: '1.2k members • 42 online',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    const _CommunityItem(
                      initial: 'PH',
                      name: 'Physics Hub',
                      meta: '840 members • 15 online',
                      color: SchoolColors.success,
                    ),
                    const SizedBox(height: 28),
                    GradientButton(
                      text: 'Explore All',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WidgetTitle extends StatelessWidget {
  const _WidgetTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: SchoolColors.darkMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 12),
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

class _CommunityItem extends StatelessWidget {
  const _CommunityItem({
    required this.initial,
    required this.name,
    required this.meta,
    required this.color,
  });

  final String initial;
  final String name;
  final String meta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SchoolColors.darkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
