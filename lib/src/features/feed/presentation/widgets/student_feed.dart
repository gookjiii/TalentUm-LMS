import 'package:school_world/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_world/main.dart';
import 'package:school_world/src/theme.dart';
import 'package:school_world/src/utils/responsive_utils.dart';
import 'package:school_world/src/widgets/school_widgets.dart';
import '../../../../screens/settings_screen.dart';

import './feed_widgets.dart';

class StudentFeed extends StatefulWidget {
  const StudentFeed({
    super.key,
    required this.classId,
    required this.classes,
    required this.onClassSelect,
    this.onProfileTap,
  });
  final String classId;
  final List<Map<String, dynamic>> classes;
  final ValueChanged<String> onClassSelect;
  final VoidCallback? onProfileTap;

  @override
  State<StudentFeed> createState() => _StudentFeedState();
}

class _StudentFeedState extends State<StudentFeed> {
  String _searchQuery = '';
  Stream<QuerySnapshot<Map<String, dynamic>>>? _postsStream;
  bool _initialized = false;
  int _limit = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initStream();
    }
  }

  @override
  void didUpdateWidget(covariant StudentFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _limit = 20;
      _initStream();
    }
  }

  void _initStream() {
    final repo = AppScope.of(context).repository;
    setState(() {
      _postsStream = widget.classId == 'all'
          ? repo.firestore
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .limit(_limit)
                .snapshots()
          : repo.postsForClass(widget.classId, limit: _limit);
    });
  }

  void _loadMore() {
    setState(() {
      _limit += 20;
      _initStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? AppLocalizations.of(context)!.student;
    final selectedClassName = widget.classId == 'all'
        ? AppLocalizations.of(context)!.allClasses
        : widget.classes
              .firstWhere(
                (c) => c['id'] == widget.classId,
                orElse: () => const <String, dynamic>{},
              )['name']
              ?.toString();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: SizedBox.expand(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
                _loadMore();
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalPadding,
                      context.isMobile ? 18 : 12,
                      context.horizontalPadding,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PageHeader(
                          padding: EdgeInsets.zero,
                          title: AppLocalizations.of(context)!.ribbon,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.announcementsFromYourTeachers,
                          classContext: selectedClassName,
                          trailing: SchoolAvatar(
                            name: name,
                            userId: user?.uid,
                            radius: 22,
                            onTap: widget.onProfileTap ??
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => SettingsScreen(
                                      repository: AppScope.of(ctx).repository,
                                      appState: AppScope.of(ctx).appState,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SchoolCard(
                          padding: EdgeInsets.all(context.isMobile ? 16 : 20),
                          borderRadius: 22,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _FeedStatPill(
                                    icon: Icons.campaign_outlined,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.allClasses,
                                    value: widget.classId == 'all'
                                        ? '${widget.classes.length}'
                                        : '1',
                                  ),
                                  _FeedStatPill(
                                    icon: Icons.view_stream_outlined,
                                    label: AppLocalizations.of(context)!.ribbon,
                                    value: 'Live',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                onChanged: (v) => setState(
                                  () => _searchQuery = v.trim().toLowerCase(),
                                ),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.searchByAdvertisements,
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  filled: true,
                                  fillColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? SchoolColors.darkSurface
                                      : SchoolColors.surfaceElevated,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FeedFilterChip(
                                      label: AppLocalizations.of(
                                        context,
                                      )!.allClasses,
                                      active: widget.classId == 'all',
                                      onTap: () => widget.onClassSelect('all'),
                                    ),
                                    ...widget.classes.map(
                                      (c) => _FeedFilterChip(
                                        label: c['name']?.toString() ?? '',
                                        active: c['id'] == widget.classId,
                                        onTap: () => widget.onClassSelect(
                                          c['id'] as String,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _postsStream,
                  builder: (context, snapshot) {
                    var posts = snapshot.data?.docs ?? [];

                    if (_searchQuery.isNotEmpty) {
                      posts = posts.where((doc) {
                        final content =
                            doc.data()['content']?.toString().toLowerCase() ??
                            '';
                        return content.contains(_searchQuery);
                      }).toList();
                    }

                    if (posts.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: AppLocalizations.of(
                            context,
                          )!.thereAreNoAnnouncementsYet,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.announcementsFromYourTeachers,
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        context.horizontalPadding,
                        8,
                        context.horizontalPadding,
                        40 + MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = posts[index];
                          final data = doc.data();
                          final cId = data['classId']?.toString();
                          final classData = widget.classes.firstWhere(
                            (c) => c['id'] == cId,
                            orElse: () => widget.classes.isNotEmpty
                                ? widget.classes.first
                                : {},
                          );

                          if (classData.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PostCard(
                              doc: doc,
                              classData: classData,
                              canManage: false,
                            ),
                          );
                        }, childCount: posts.length),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedFilterChip extends StatelessWidget {
  const _FeedFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = active
        ? SchoolColors.primary
        : SchoolColors.surfaceElevated;

    return Semantics(
      button: true,
      selected: active,
      label: 'Фильтр: $label',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? SchoolColors.primary : SchoolColors.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : SchoolColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedStatPill extends StatelessWidget {
  const _FeedStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SchoolColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SchoolColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: SchoolColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SchoolColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: SchoolColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
