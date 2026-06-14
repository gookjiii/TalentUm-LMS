import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_world/main.dart';
import '../../../../theme.dart';
import '../../../../widgets/school_widgets.dart';

class EliteStudentFeed extends HookWidget {
  const EliteStudentFeed({super.key, required this.classId, this.onClassSelect, required this.classes});

  final String classId;
  final ValueChanged<String>? onClassSelect;
  final List<Map<String, dynamic>> classes;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 1200;
    final repo = AppScope.of(context).repository;
    
    final postsSnap = useStream(useMemoized(() => repo.postsForClass(classId), [classId]));

    return CustomScrollView(
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
                                Row(
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
                                    const Spacer(),
                                    if (classes.length > 1)
                                      EliteTactileButton(
                                        onTap: () => showClassSwitcher(
                                          context: context,
                                          classes: classes,
                                          currentClassId: classId,
                                          onSelect: onClassSelect ?? (_) {},
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: SchoolColors.darkBorder),
                                          ),
                                          child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                                        ),
                                      ),
                                  ],
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
                          if (!postsSnap.hasData)
                            const Center(child: BrandedLoader())
                          else if (postsSnap.data!.docs.isEmpty)
                            const EmptyStateWidget(
                              icon: Icons.rss_feed_rounded,
                              title: 'Nothing here yet',
                              subtitle: 'Check back later for updates from your teachers.',
                            )
                          else
                            ...postsSnap.data!.docs.asMap().entries.map((entry) {
                              final index = entry.key;
                              final doc = entry.value;
                              final data = doc.data();
                              final authorId = data['authorId']?.toString() ?? '';
                              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                              final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : 'Recently';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 40),
                                child: FadeInUp(
                                  delay: Duration(milliseconds: (100 * (index + 1)).toInt()),
                                  child: _PostCard(
                                    postId: doc.id,
                                    authorId: authorId,
                                    authorMeta: timeAgo,
                                    content: data['content']?.toString() ?? '',
                                    attachments: List<Map<String, dynamic>>.from(data['attachments'] ?? []),
                                    likes: List<String>.from(data['likes'] ?? []),
                                    comments: List<Map<String, dynamic>>.from(data['comments'] ?? []),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 48),
                      SizedBox(
                        width: 380,
                        child: _FeedSidebar(classId: classId),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _PostCard extends HookWidget {
  const _PostCard({
    required this.postId,
    required this.authorId,
    required this.authorMeta,
    required this.content,
    this.attachments = const [],
    this.likes = const [],
    this.comments = const [],
  });

  final String postId;
  final String authorId;
  final String authorMeta;
  final String content;
  final List<Map<String, dynamic>> attachments;
  final List<String> likes;
  final List<Map<String, dynamic>> comments;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final userAsync = useFuture(useMemoized(() => repo.getUserData(authorId), [authorId]));
    final userData = userAsync.data ?? {};
    final authorName = userData['name']?.toString() ?? 'User';
    final avatarUrl = userData['avatarUrl']?.toString();

    final isLiked = likes.contains(repo.uid);

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
                  SchoolAvatar(
                    name: authorName,
                    avatarUrl: avatarUrl,
                    radius: 26,
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
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...attachments.map((att) => _AttachmentItem(attachment: att)),
          ],
          const SizedBox(height: 24),
          const Divider(color: SchoolColors.darkBorder),
          const SizedBox(height: 24),
          Row(
            children: [
              _ActionBtn(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: '${likes.length} Likes',
                color: isLiked ? SchoolColors.red : null,
                onTap: () => repo.toggleLike(postId, isLiked),
              ),
              const SizedBox(width: 32),
              _ActionBtn(
                icon: Icons.chat_bubble_outline,
                label: '${comments.length} Comments',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  const _AttachmentItem({required this.attachment});
  final Map<String, dynamic> attachment;

  @override
  Widget build(BuildContext context) {
    final name = attachment['name']?.toString() ?? 'File';
    final type = attachment['type']?.toString() ?? 'file';
    final url = attachment['url']?.toString() ?? '';

    if (type == 'image') {
       return Padding(
         padding: const EdgeInsets.only(top: 12),
         child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            errorBuilder: (_,__,___) => const SizedBox.shrink(),
          ),
        ),
       );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
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
              child: Icon(Icons.description_outlined, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          EliteTactileButton(
            onTap: () {}, // Download logic
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
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EliteTactileButton(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? SchoolColors.darkMuted, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color ?? SchoolColors.darkMuted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedSidebar extends HookWidget {
  const _FeedSidebar({required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final assignmentsSnap = useStream(useMemoized(() => repo.assignmentsForClass(classId, limit: 3), [classId]));

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
              if (!assignmentsSnap.hasData)
                const BrandedLoader()
              else if (assignmentsSnap.data!.docs.isEmpty)
                Text('No upcoming deadlines', style: TextStyle(color: SchoolColors.darkMuted))
              else
                ...assignmentsSnap.data!.docs.map((doc) {
                  final data = doc.data();
                  final due = (data['dueDate'] as Timestamp?)?.toDate();
                  final hoursLeft = due?.difference(DateTime.now()).inHours ?? 0;
                  final isUrgent = hoursLeft > 0 && hoursLeft < 24;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GlassCard(
                      padding: const EdgeInsets.all(28),
                      onTap: () {},
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isUrgent ? SchoolColors.red : SchoolColors.primary).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUrgent ? 'DUE IN $hoursLeft HOURS' : 'UPCOMING',
                              style: TextStyle(
                                color: isUrgent ? SchoolColors.red : SchoolColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data['title']?.toString() ?? 'Assignment',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 40),
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WidgetTitle(title: 'Quick Actions'),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    GradientButton(
                      text: 'Create Post',
                      icon: Icons.add_comment_rounded,
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
